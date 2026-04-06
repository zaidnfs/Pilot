-- ============================================================
-- Dashauli Connect — Initial Schema
-- Migration: 001_initial_schema.sql
-- Stack: Supabase (PostgreSQL 15+) + PostGIS
-- ============================================================

-- 1. Enable required extensions
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Profiles — extends Supabase auth.users
-- ============================================================
CREATE TABLE profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name     TEXT NOT NULL,
    phone         TEXT NOT NULL UNIQUE,
    avatar_url    TEXT,
    upi_id        TEXT,  -- Traveler's UPI VPA for receiving payments

    -- Aadhaar KYC (no raw data stored)
    aadhaar_verified   BOOLEAN NOT NULL DEFAULT false,
    aadhaar_masked_name TEXT,  -- e.g. "Za***"
    aadhaar_photo_url  TEXT,   -- Supabase Storage signed URL ref

    -- Dual-mode state
    active_mode   TEXT NOT NULL DEFAULT 'requester'
                  CHECK (active_mode IN ('requester', 'traveler')),

    -- Live location (updated by Traveler mode)
    current_lat   DOUBLE PRECISION,
    current_lng   DOUBLE PRECISION,
    current_location GEOGRAPHY(Point, 4326),  -- PostGIS auto-computed
    heading       DOUBLE PRECISION,           -- Direction in degrees
    is_online     BOOLEAN NOT NULL DEFAULT false,
    last_seen_at  TIMESTAMPTZ,

    -- Timestamps
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE profiles IS 'User profiles extending Supabase auth. Every user is both Requester and Traveler.';
COMMENT ON COLUMN profiles.upi_id IS 'UPI Virtual Payment Address for receiving delivery bounties.';
COMMENT ON COLUMN profiles.aadhaar_masked_name IS 'First 2 chars of Aadhaar name + masked suffix. Raw data never stored.';
COMMENT ON COLUMN profiles.current_location IS 'PostGIS point auto-computed from current_lat/lng via trigger.';

-- 3. Stores — merchant/kirana shops
-- ============================================================
CREATE TABLE stores (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name         TEXT NOT NULL,
    description  TEXT,
    phone        TEXT NOT NULL,
    address      TEXT NOT NULL,
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    location     GEOGRAPHY(Point, 4326),  -- PostGIS auto-computed
    category     TEXT NOT NULL DEFAULT 'kirana'
                 CHECK (category IN ('kirana', 'pharmacy', 'bakery', 'stationery', 'other')),
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE stores IS 'Local merchants listed on the platform. Owned by a profile.';

-- 4. Orders — delivery lifecycle
-- ============================================================
CREATE TABLE orders (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    requester_id         UUID NOT NULL REFERENCES profiles(id),
    traveler_id          UUID REFERENCES profiles(id),  -- NULL until accepted
    store_id             BIGINT NOT NULL REFERENCES stores(id),

    -- Status lifecycle: requested → accepted → picked_up → delivered | cancelled
    status               TEXT NOT NULL DEFAULT 'requested'
                         CHECK (status IN ('requested', 'accepted', 'picked_up', 'delivered', 'cancelled')),
    delivery_mode        TEXT NOT NULL DEFAULT 'standard'
                         CHECK (delivery_mode IN ('standard', 'express')),

    -- Order details
    items_description    TEXT NOT NULL,
    items_estimated_cost NUMERIC(10,2) NOT NULL CHECK (items_estimated_cost > 0),
    bounty               NUMERIC(10,2) NOT NULL CHECK (bounty > 0),

    -- OTP handover protocol
    otp_code             TEXT,          -- 4-digit code, generated on acceptance
    otp_verified         BOOLEAN NOT NULL DEFAULT false,

    -- Payment state (UPI Intent — no actual escrow)
    payment_status       TEXT NOT NULL DEFAULT 'pending'
                         CHECK (payment_status IN ('pending', 'sent', 'confirmed', 'disputed')),
    upi_transaction_id   TEXT,

    -- Requester delivery location
    requester_lat        DOUBLE PRECISION NOT NULL,
    requester_lng        DOUBLE PRECISION NOT NULL,
    requester_location   GEOGRAPHY(Point, 4326),

    -- Lifecycle timestamps
    pickup_at            TIMESTAMPTZ,
    delivered_at         TIMESTAMPTZ,
    cancelled_at         TIMESTAMPTZ,
    cancel_reason        TEXT,
    expires_at           TIMESTAMPTZ,   -- Auto-cancel if no traveler accepts

    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE orders IS 'Delivery orders tracking the full lifecycle from request to delivery confirmation.';
COMMENT ON COLUMN orders.bounty IS 'Delivery fee offered by Requester, visible to Travelers before acceptance.';
COMMENT ON COLUMN orders.otp_code IS 'Secure 4-digit handover code. Only visible to Requester.';
COMMENT ON COLUMN orders.expires_at IS 'Order auto-cancels if no Traveler accepts before this timestamp.';

-- 5. Order Events — audit trail
-- ============================================================
CREATE TABLE order_events (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id     BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    actor_id     UUID NOT NULL REFERENCES profiles(id),
    event_type   TEXT NOT NULL
                 CHECK (event_type IN (
                     'created', 'accepted', 'picked_up', 'delivered',
                     'cancelled', 'payment_sent', 'payment_confirmed',
                     'sos_triggered', 'timeout_rebroadcast'
                 )),
    metadata     JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE order_events IS 'Immutable audit trail for every order state change and significant event.';

-- ============================================================
-- 6. Indexes
-- Per postgresql skill: FK columns MUST be manually indexed.
-- ============================================================

-- Profiles
CREATE INDEX idx_profiles_phone ON profiles (phone);
CREATE INDEX idx_profiles_location ON profiles USING GIST (current_location);
CREATE INDEX idx_profiles_online_travelers ON profiles (is_online)
    WHERE is_online = true AND active_mode = 'traveler' AND aadhaar_verified = true;

-- Stores
CREATE INDEX idx_stores_location ON stores USING GIST (location);
CREATE INDEX idx_stores_owner ON stores (owner_id);
CREATE INDEX idx_stores_active ON stores (is_active) WHERE is_active = true;

-- Orders (FK indexes + query-path indexes)
CREATE INDEX idx_orders_requester ON orders (requester_id);
CREATE INDEX idx_orders_traveler ON orders (traveler_id);
CREATE INDEX idx_orders_store ON orders (store_id);
CREATE INDEX idx_orders_active_status ON orders (status)
    WHERE status IN ('requested', 'accepted', 'picked_up');
CREATE INDEX idx_orders_created ON orders (created_at);
CREATE INDEX idx_orders_expires ON orders (expires_at)
    WHERE status = 'requested' AND expires_at IS NOT NULL;

-- Order Events (FK indexes)
CREATE INDEX idx_order_events_order ON order_events (order_id);
CREATE INDEX idx_order_events_actor ON order_events (actor_id);

-- ============================================================
-- 7. Triggers
-- ============================================================

-- Auto-compute PostGIS geography from lat/lng
CREATE OR REPLACE FUNCTION compute_geography_point()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- For profiles (current_lat / current_lng → current_location)
CREATE OR REPLACE FUNCTION compute_profile_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_lat IS NOT NULL AND NEW.current_lng IS NOT NULL THEN
        NEW.current_location := ST_SetSRID(ST_MakePoint(NEW.current_lng, NEW.current_lat), 4326)::geography;
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_location
    BEFORE INSERT OR UPDATE OF current_lat, current_lng ON profiles
    FOR EACH ROW EXECUTE FUNCTION compute_profile_location();

-- For stores
CREATE TRIGGER trg_stores_location
    BEFORE INSERT OR UPDATE OF lat, lng ON stores
    FOR EACH ROW EXECUTE FUNCTION compute_geography_point();

-- For orders (requester location)
CREATE OR REPLACE FUNCTION compute_order_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.requester_lat IS NOT NULL AND NEW.requester_lng IS NOT NULL THEN
        NEW.requester_location := ST_SetSRID(ST_MakePoint(NEW.requester_lng, NEW.requester_lat), 4326)::geography;
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_location
    BEFORE INSERT OR UPDATE OF requester_lat, requester_lng ON orders
    FOR EACH ROW EXECUTE FUNCTION compute_order_location();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_orders_updated
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- 8. PostGIS RPC: "Along the Way" Matching Engine
-- Finds online, verified Travelers within a corridor of the
-- Store→Customer line-string.
-- ============================================================

CREATE OR REPLACE FUNCTION find_travelers_along_route(
    p_store_lat      DOUBLE PRECISION,
    p_store_lng      DOUBLE PRECISION,
    p_customer_lat   DOUBLE PRECISION,
    p_customer_lng   DOUBLE PRECISION,
    p_corridor_meters INTEGER DEFAULT 500
)
RETURNS TABLE (
    id               UUID,
    full_name        TEXT,
    phone            TEXT,
    aadhaar_masked_name TEXT,
    aadhaar_photo_url TEXT,
    current_lat      DOUBLE PRECISION,
    current_lng      DOUBLE PRECISION,
    heading          DOUBLE PRECISION,
    distance_meters  DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.full_name,
        p.phone,
        p.aadhaar_masked_name,
        p.aadhaar_photo_url,
        p.current_lat,
        p.current_lng,
        p.heading,
        ST_Distance(
            p.current_location,
            ST_SetSRID(ST_MakePoint(p_store_lng, p_store_lat), 4326)::geography
        ) AS distance_meters
    FROM profiles p
    WHERE p.is_online = true
      AND p.aadhaar_verified = true
      AND p.active_mode = 'traveler'
      AND p.current_location IS NOT NULL
      AND ST_DWithin(
          p.current_location,
          ST_MakeLine(
              ST_SetSRID(ST_MakePoint(p_store_lng, p_store_lat), 4326),
              ST_SetSRID(ST_MakePoint(p_customer_lng, p_customer_lat), 4326)
          )::geography,
          p_corridor_meters
      )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION find_travelers_along_route IS
    'Core "Along the Way" matching engine. Returns online, KYC-verified Travelers within a corridor of the Store→Customer route.';

-- ============================================================
-- 9. RPC: Generate OTP for order
-- ============================================================

CREATE OR REPLACE FUNCTION generate_order_otp(p_order_id BIGINT, p_requester_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_otp TEXT;
BEGIN
    -- Verify the requester owns this order
    IF NOT EXISTS (
        SELECT 1 FROM orders
        WHERE id = p_order_id AND requester_id = p_requester_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: order does not belong to this user';
    END IF;

    -- Generate 4-digit OTP
    v_otp := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    UPDATE orders
    SET otp_code = v_otp, otp_verified = false
    WHERE id = p_order_id;

    RETURN v_otp;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 10. RPC: Verify OTP and complete delivery
-- ============================================================

CREATE OR REPLACE FUNCTION verify_delivery_otp(
    p_order_id    BIGINT,
    p_traveler_id UUID,
    p_otp         TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_valid BOOLEAN;
BEGIN
    SELECT (o.otp_code = p_otp AND o.traveler_id = p_traveler_id AND o.status = 'picked_up')
    INTO v_valid
    FROM orders o
    WHERE o.id = p_order_id;

    IF v_valid THEN
        UPDATE orders
        SET otp_verified = true,
            status = 'delivered',
            delivered_at = now(),
            payment_status = 'confirmed'
        WHERE id = p_order_id;

        INSERT INTO order_events (order_id, actor_id, event_type, metadata)
        VALUES (p_order_id, p_traveler_id, 'delivered', jsonb_build_object('otp_verified', true));

        RETURN true;
    ELSE
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 11. Row-Level Security (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_events ENABLE ROW LEVEL SECURITY;

-- Profiles: read all, update own
CREATE POLICY profiles_select ON profiles
    FOR SELECT USING (true);

CREATE POLICY profiles_insert ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_update ON profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Stores: read active, owner manages
CREATE POLICY stores_select ON stores
    FOR SELECT USING (is_active = true OR owner_id = auth.uid());

CREATE POLICY stores_insert ON stores
    FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY stores_update ON stores
    FOR UPDATE USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

-- Orders: involved parties + open orders visible to verified travelers
CREATE POLICY orders_select ON orders
    FOR SELECT USING (
        requester_id = auth.uid()
        OR traveler_id = auth.uid()
        OR (
            status = 'requested'
            AND EXISTS (
                SELECT 1 FROM profiles
                WHERE id = auth.uid()
                  AND aadhaar_verified = true
                  AND active_mode = 'traveler'
            )
        )
    );

CREATE POLICY orders_insert ON orders
    FOR INSERT WITH CHECK (requester_id = auth.uid());

CREATE POLICY orders_update ON orders
    FOR UPDATE USING (
        requester_id = auth.uid()
        OR traveler_id = auth.uid()
    );

-- Order Events: read by involved parties
CREATE POLICY order_events_select ON order_events
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_events.order_id
              AND (orders.requester_id = auth.uid() OR orders.traveler_id = auth.uid())
        )
    );

CREATE POLICY order_events_insert ON order_events
    FOR INSERT WITH CHECK (actor_id = auth.uid());

-- ============================================================
-- 12. Auto-create profile on new user signup
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, full_name, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        COALESCE(NEW.phone, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
