# Dashauli Connect — Product Requirements Document

> **Version:** v1.0 — MVP / Pilot Stage
> **Status:** Active
> **Target Region:** Dashauli & Kursi Road Corridor, Lucknow, UP
> **Date:** April 2026

---

## Table of Contents

1. [Product Vision & Problem Statement](#1-product-vision--problem-statement)
2. [Target Personas](#2-target-personas)
3. [Functional Requirements (MVP Features)](#3-functional-requirements-mvp-features)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [Technical Stack](#5-technical-stack-mvp-build)
6. [Success Metrics (KPIs)](#6-success-metrics-kpis)
7. [Phase-Wise Rollout Roadmap](#7-phase-wise-rollout-roadmap)
8. [Open Questions & Assumptions](#8-open-questions--assumptions)
- [Appendix A: Glossary](#appendix-a-glossary)

---

## 1. Product Vision & Problem Statement

### 1.1 Vision

To build a decentralised, peer-to-peer (P2P) logistics network where community members fulfil each other's delivery needs — eliminating the 30–40% "convenience tax" levied by centralised platforms.

### 1.2 The Problem

Three structural problems create the market opportunity:

- **High Fees:** Platform charges from Blinkit and Zomato (platform fee + delivery fee + surge pricing) make micro-orders uneconomical. A ₹100 grocery order often incurs ₹50–₹60 in platform charges.
- **Worker Dissatisfaction:** Professional gig workers face declining payouts — as low as ₹12 per delivery in 2026 — creating a dissatisfied, unstable courier fleet.
- **Suburban Gaps:** Peri-urban zones like Dashauli and Kursi Road face slower delivery, "out-of-zone" surcharges, or outright service gaps not covered by metropolitan platforms.

---

## 2. Target Personas

| Persona | Motivation | Use Case |
|---|---|---|
| **The Requester** (Neighbour/Student) | Save money on small daily essentials | *"I need bread and eggs but don't want to pay ₹60 in fees for a ₹100 order."* |
| **The Traveler** (Commuter/EV Owner) | Offset fuel/charging costs | *"I'm passing by the market on my way home; I'll pick up a neighbour's bag for ₹15."* |
| **The Merchant** (Local Kirana) | Reach customers without high commissions | *"I want to sell to hostels near Integral University without losing 25% to Swiggy."* |

---

## 3. Functional Requirements (MVP Features)

### 3.1 The "Along the Way" Matching Engine

#### Route Buffering
- The system identifies Travelers whose live GPS path passes within a **500-metre corridor** of the merchant-to-customer delivery route.
- Matching runs in real-time using Supabase real-time subscriptions against active Traveler position data.
- Only verified, KYC-complete Travelers appear in match results.

#### Delivery Mode Selection
- **Standard Mode:** Requester waits for a naturally passing Peer Traveler. Lower cost, longer wait window.
- **Express Mode:** Broadcasts to a wider geographic radius with an elevated bounty. Surfaces Travelers willing to make a short detour.

---

### 3.2 Peer-to-Peer Trust & Identity

#### Aadhaar Offline e-KYC
- Integration with the **UIDAI Sandbox 2026** (Paperless Offline e-KYC flow).
- Users upload an Aadhaar-encrypted XML file along with their 4-digit Share Code to complete verification.
- Verification is one-time per user and stored as a boolean flag; no raw Aadhaar data is retained on the platform.

#### OTP Handover Protocol
- Upon confirming an order, the Requester's app generates a secure **4-digit OTP**.
- The OTP is not visible to the Traveler until delivery is physically completed.
- Payment escrow is released only after the Requester enters the correct OTP in the app, confirming receipt.

#### Identity Display During Active Delivery
- The Traveler's Aadhaar-linked photograph and masked name are displayed persistently on the Requester's screen for the full duration of the trip.
- Requesters may report a mismatch; this immediately triggers an SOS workflow.

---

### 3.3 Payments & Escrow

- No internal wallet. The app triggers a direct **UPI Intent link** (GPay / PhonePe) from Requester to Traveler.
- Funds are held in a lightweight escrow state tracked server-side and released only upon OTP confirmation.
- **Commission during Pilot Phase: ₹0.** Post-pilot fee: flat ₹2 Maintenance Levy per completed delivery.

---

## 4. Non-Functional Requirements

### 4.1 Offline-First Reliability

- Delivery progress, OTP state, and status flags are written to local SQLite via **PowerSync** before any server write.
- If a Traveler enters a low-connectivity zone (hostel basement, underground area), the "Delivered" status persists locally and syncs automatically on reconnection.
- Conflict resolution uses last-write-wins on delivery status with server timestamp arbitration.

### 4.2 Regulatory Compliance — UP 2026

- **Emergency SOS** button is accessible from all active-delivery screens (max 2 taps). It dials Lucknow Police (112) and simultaneously pings the volunteer-run 24/7 help desk.
- Traveler photo must remain visible to the Requester throughout the active trip — a legal identity-display requirement.
- All personally identifiable data (Aadhaar XML) is encrypted at rest (AES-256) and in transit (TLS 1.3). Raw XML is purged post-verification.
- **Phase 3 trigger:** UP Aggregator License application is mandatory once the active daily fleet reaches 50+ vehicles.

---

## 5. Technical Stack (MVP Build)

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Flutter | Cross-platform mobile (Android + iOS) from a single codebase |
| Backend | Supabase | Auth, PostgreSQL database, real-time location subscriptions |
| Maps & Navigation | Google Maps SDK | Landmark-based navigation, route display, 500m corridor buffering |
| Offline Sync | PowerSync + SQLite | Offline-first delivery state; auto-syncs when connection is restored |
| Identity Verification | Aadhaar Offline e-KYC | XML + Share Code upload; UIDAI Sandbox 2026 integration |
| Payments | UPI Intent (GPay/PhonePe) | Direct P2P UPI flow — no internal wallet, zero platform fee |

---

## 6. Success Metrics (KPIs)

The pilot is considered successful if all KPIs are met by the end of Phase 1 (Month 2):

| KPI | Description | Target |
|---|---|---|
| Cost Savings Index | Avg. delivery cost on Dashauli Connect vs. market average | > 60% cheaper |
| Match Rate | Orders picked up by a Peer Traveler within 15 minutes | > 80% |
| Safety Incidents | Safety events during the first 1,000 deliveries | 0% |
| Merchant Onboarding | Active merchants enrolled in Phase 1 | 20 shops |
| Traveler Onboarding | Student travelers enrolled in Phase 1 | 50 travelers |

---

## 7. Phase-Wise Rollout Roadmap

### 🟢 Phase 1: University Pilot *(Month 1–2)*

- **Location:** Integral University Hostels → Kursi Road Mandi
- **Goal:** Onboard 20 local shops and 50 student Travelers
- **Approach:** Manual matching with structured feedback loops
- **KYC:** Basic Aadhaar XML upload during onboarding

### 🔵 Phase 2: Automation & Scaling *(Month 3–6)*

- **Location:** Expansion to Dashauli residential colonies
- **Goal:** Launch the "Along the Way" algorithm at scale
- **Integration:** Aadhaar API for automated, real-time onboarding
- **Feature:** "Express" delivery mode with higher bounty broadcast

### 🔴 Phase 3: Formal Aggregation *(Month 6+)*

- **Legal:** Apply for UP Aggregator License (₹5 Lakh fee) once fleet hits 50+ active daily vehicles
- **Insurance:** Partner with Insurtech provider for ₹5 Lakh health/accident coverage per Traveler
- **Revenue:** Introduce flat ₹2 Maintenance Levy per delivery
- **Expansion:** Adjacent corridors in Greater Lucknow suburbs

---

## 8. Open Questions & Assumptions

### 8.1 Assumptions

- Aadhaar UIDAI Sandbox 2026 remains accessible for non-commercial pilot use without a formal AUA/KUA agreement.
- UPI Intent flow is compliant with RBI's P2P payment guidelines for non-wallet platforms as of April 2026.
- Traveler liability during theft or damage is governed by a voluntarily signed Terms of Service, not as an employer-employee relationship.

### 8.2 Open Questions

- How does the platform handle a Traveler who accepts an order but goes offline? Define timeout + re-broadcast logic.
- What is the minimum viable incentive (bounty floor) for Travelers to maintain a healthy supply-side pool?
- How are disputes (missing/damaged items) resolved pre-license when no formal aggregator structure exists?
- Should the merchant have a separate interface/dashboard, or does the MVP route everything through the consumer app?

---

## Appendix A: Glossary

| Term | Definition |
|---|---|
| **Traveler** | A community member who picks up and delivers goods while en route to a destination they were already going to. |
| **Requester** | A community member who places a delivery request for goods from a nearby merchant. |
| **Merchant / Kirana** | A local shop owner listed on the platform who accepts orders from Requesters. |
| **Along the Way** | The core matching algorithm — pairing Requesters with Travelers whose route naturally passes the delivery corridor. |
| **OTP Handover** | The 4-digit delivery confirmation code that gates payment release. |
| **Bounty** | The delivery fee offered by the Requester, visible to potential Travelers before acceptance. |
| **PowerSync** | An open-source offline sync library used to persist delivery state to local SQLite. |

---

*Dashauli Connect — PRD v1.0 | Lucknow, UP 2026 | Confidential*