-- Migration: 002_enforce_order_validation.sql
-- Description: Add server-side validation constraints to the orders table to ensure data integrity
-- and prevent bypass of client-side validation.
--
-- Verified: AppConstants.minBounty is 5.0 in lib/core/constants/app_constants.dart.
-- Note: bounty and items_description are already NOT NULL in 001_initial_schema.sql,
-- but we include IS NOT NULL checks for defense-in-depth.

ALTER TABLE orders
ADD CONSTRAINT bounty_min_check CHECK (bounty IS NOT NULL AND bounty >= 5.0),
ADD CONSTRAINT items_description_not_empty CHECK (items_description IS NOT NULL AND length(trim(items_description)) > 0),
ADD CONSTRAINT expires_at_future_check CHECK (expires_at IS NOT NULL AND expires_at > created_at);
