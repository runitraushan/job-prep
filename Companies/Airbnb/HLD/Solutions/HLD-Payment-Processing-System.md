# HLD — Design a Payment Processing System

> **Company:** Airbnb  
> **Level:** Senior Software Engineer, Payments — Backend  
> **Difficulty:** High  
> **Time Budget:** 45 minutes  

---

## Assumptions

- Airbnb-scale: ~150M active users, ~100M bookings/year, $70B+ gross booking value/year
- Marketplace model: guest pays → Airbnb holds in escrow → host receives payout after check-in
- Split payment: every booking involves Airbnb service fee + host payout + taxes + cleaning fee
- Multiple PSPs: Stripe (primary), Braintree, Adyen — for redundancy and regional coverage
- PCI DSS Level 1 compliance: no raw card data touches our servers — all card handling via PSP tokenization
- Multi-currency: guests pay in their local currency, hosts receive payouts in theirs — Airbnb handles FX
- We handle: authorization, capture, refunds, partial refunds, chargebacks, payouts
- Payment methods: credit/debit cards, Apple Pay, Google Pay, PayPal, bank transfers (region-dependent)

---

## 1. Functional Requirements

### P0 — Must Have
1. **Process guest payments** — authorize on booking confirmation, capture after check-in
2. **Host payouts** — disburse funds to hosts 24 hours after guest check-in
3. **Split payment orchestration** — decompose booking amount into service fee, host payout, taxes, cleaning fee
4. **Multi-PSP support** — route payments through multiple processors with automatic failover
5. **Refund processing** — full and partial refunds based on cancellation policy (flexible, moderate, strict)
6. **Idempotency** — every payment operation is idempotent; retrying the same request produces the same result
7. **Payment state machine** — every payment transitions through well-defined states with audit trail
8. **Reconciliation** — daily reconciliation of internal ledger against PSP settlement reports
9. **Ledger / double-entry bookkeeping** — every money movement recorded as a debit + credit pair

### P1 — Nice to Have
10. **Multi-currency support** — FX conversion at authorization time, hedge exposure
11. **Chargeback handling** — ingest chargeback notifications from PSPs, automate dispute evidence submission
12. **Payout scheduling** — configurable payout schedules for hosts (weekly, bi-weekly)
13. **Payment method management** — store/manage guest payment methods, host payout methods
14. **Instalment payments** — split guest charges across multiple payments (Pay Less Upfront)

---

## 2. Non-Functional Requirements

| Attribute | Target | Rationale |
|---|---|---|
| **Latency** | Authorization: < 2s end-to-end; Capture/Refund: < 5s | Guest checkout UX is time-critical; capture/refund can be slightly slower |
| **Availability** | 99.99% (≈ 52 min downtime/year) | Payment failure = lost booking = lost revenue. Downtime directly impacts GMV |
| **Consistency** | Strong for ledger operations; Eventual for status propagation | Money can never be "lost" — ledger must be strictly consistent. Status updates to booking service can lag slightly |
| **Durability** | Zero data loss | Every cent must be accounted for — financial auditability is non-negotiable |
| **Scale** | 10K payment operations/sec at peak (holidays, summer travel) | ~100M bookings/year ≈ 300K/day average; 10x spike during peak |

---

## 3. Back-of-Envelope Estimation

### Traffic
- **Bookings/year:** ~100M
- **Bookings/day (avg):** 100M / 365 ≈ **275K/day**
- **Peak bookings/day (5x):** ~**1.4M/day** (holidays, summer)
- **Payment operations per booking:** ~4 (authorize, capture, service-fee split, host payout)
- **Avg payment operations/day:** 275K × 4 = **1.1M/day**
- **Peak payment operations/day:** 1.4M × 4 = **5.6M/day**

### QPS
- **Average QPS:** 1.1M / 86,400 ≈ **13 ops/sec**
- **Peak QPS:** 5.6M / 86,400 ≈ **65 ops/sec**
- **True burst peak (10x of peak for flash sales, etc.):** ~**650 ops/sec**
- **Including retries, status checks, webhooks:** ~**2,000 QPS peak total**

### Storage
- **Payment record:** ~1 KB (IDs, amounts, currencies, status, timestamps, PSP response, metadata)
- **Ledger entry:** ~500 bytes per debit/credit pair
- **Daily storage (avg):** 1.1M × 1KB (payments) + 1.1M × 1KB (ledger pairs) = **2.2 GB/day**
- **Annual storage:** 2.2 GB × 365 = **~800 GB/year**
- **Retention:** 7 years (financial regulations) → **~5.6 TB active**

### Bandwidth
- **Ingress (payment requests):** 650 ops/sec × 2KB = **1.3 MB/s** peak
- **Egress (PSP calls + responses):** 650 ops/sec × 4KB = **2.6 MB/s** peak
- **Webhook ingress from PSPs:** ~500 events/sec × 1KB = **0.5 MB/s**

### Cache
- **Idempotency keys:** 5.6M/day × 200B × 24h TTL = **~1.1 GB** (fits in one Redis node)
- **Payment method tokens:** 150M users × 200B average = **~30 GB** (Redis cluster)
- **PSP routing config:** < 1 MB (in-memory)

---

## 4. API Design

### Guest Checkout — Authorize Payment

```
POST /api/v1/payments/authorize
```
- **Auth:** OAuth 2.0 Bearer token (guest session)
- **Request Body:**
```json
{
  "idempotency_key": "idem_booking_abc123_auth",
  "booking_id": "bk_abc123",
  "guest_id": "usr_guest_001",
  "amount": {
    "value": 1500.00,
    "currency": "USD"
  },
  "payment_method_token": "pm_tok_xyz789",
  "breakdown": {
    "nightly_rate": 1200.00,
    "cleaning_fee": 100.00,
    "service_fee": 150.00,
    "taxes": 50.00
  },
  "metadata": {
    "listing_id": "lst_456",
    "check_in": "2026-04-01",
    "check_out": "2026-04-05"
  }
}
```
- **Response:** `201 Created`
```json
{
  "payment_id": "pay_001",
  "status": "AUTHORIZED",
  "psp": "stripe",
  "psp_reference": "ch_stripe_ref_123",
  "authorized_amount": { "value": 1500.00, "currency": "USD" },
  "expires_at": "2026-03-18T10:30:00Z"
}
```
- **Error:** `409 Conflict` (idempotency key reused with different params), `402 Payment Required` (declined)

### Capture Payment (Internal — triggered after check-in)

```
POST /api/v1/payments/{paymentId}/capture
```
- **Auth:** mTLS + service API key (internal only — Booking Service calls this)
- **Request Body:**
```json
{
  "idempotency_key": "idem_booking_abc123_capture",
  "capture_amount": { "value": 1500.00, "currency": "USD" }
}
```
- **Response:** `200 OK` with updated payment status `CAPTURED`

### Refund

```
POST /api/v1/payments/{paymentId}/refund
```
- **Auth:** mTLS + service API key
- **Request Body:**
```json
{
  "idempotency_key": "idem_booking_abc123_refund",
  "refund_amount": { "value": 750.00, "currency": "USD" },
  "reason": "CANCELLATION_MODERATE_POLICY",
  "initiated_by": "SYSTEM"
}
```
- **Response:** `200 OK` with refund details and updated payment status

### Host Payout (Internal — triggered by Payout Scheduler)

```
POST /api/v1/payouts
```
- **Auth:** mTLS + service API key
- **Request Body:**
```json
{
  "idempotency_key": "idem_payout_host_002_bk_abc123",
  "host_id": "usr_host_002",
  "booking_id": "bk_abc123",
  "amount": { "value": 1200.00, "currency": "USD" },
  "payout_method_id": "pm_bank_host_002"
}
```
- **Response:** `202 Accepted` (payouts are async — bank transfers take 1-3 business days)

### Rate Limiting
- Guest-facing (authorize): 10 RPM per user (prevents card testing attacks)
- Internal (capture, refund, payout): 1,000 RPM per service
- PSP calls: Managed by circuit breaker per PSP

---

## 5. Data Model

### Entity-Relationship (Text)

```
Booking (1) ──→ (1) Payment ──→ (N) PaymentAttempt
                      │                    │
                      │                    └──→ PSP (via adapter)
                      │
                      ├──→ (N) LedgerEntry (double-entry pairs)
                      ├──→ (N) Refund
                      └──→ (1) Payout

Guest (1) ──→ (N) PaymentMethod (tokenized)
Host  (1) ──→ (N) PayoutMethod

Payment (1) ──→ (1) IdempotencyRecord
```

### Table Schemas

#### `payments` (Core payment record)
| Column | Type | Notes |
|---|---|---|
| payment_id | UUID (PK) | |
| booking_id | UUID (FK, UNIQUE) | One payment per booking |
| guest_id | UUID | Payer |
| host_id | UUID | Payee |
| amount | DECIMAL(19,4) | Total charged amount |
| currency | VARCHAR(3) | ISO 4217 (USD, EUR, etc.) |
| status | ENUM | INITIATED, AUTHORIZED, CAPTURED, PARTIALLY_REFUNDED, REFUNDED, FAILED, EXPIRED |
| payment_method_token | VARCHAR(100) | PSP-issued token (no raw card data) |
| psp | VARCHAR(20) | stripe, braintree, adyen |
| psp_reference | VARCHAR(100) | PSP's transaction ID |
| idempotency_key | VARCHAR(100) UNIQUE | Client-provided dedup key |
| authorized_at | TIMESTAMP | |
| captured_at | TIMESTAMP | |
| created_at | TIMESTAMP | Indexed |
| updated_at | TIMESTAMP | |
| version | INT | Optimistic locking |

**Choice: PostgreSQL**
- Strong ACID guarantees for payment state transitions
- Optimistic locking via `version` column prevents concurrent state corruption
- Indexes: `(booking_id)`, `(guest_id, created_at DESC)`, `(status, created_at)` for reconciliation queries

#### `payment_attempts` (Every PSP call logged)
| Column | Type | Notes |
|---|---|---|
| attempt_id | UUID (PK) | |
| payment_id | UUID (FK) | |
| psp | VARCHAR(20) | Which PSP was tried |
| operation | ENUM | AUTHORIZE, CAPTURE, REFUND, VOID |
| request_payload | JSONB | Sanitized PSP request (no PCI data) |
| response_payload | JSONB | PSP response |
| response_code | VARCHAR(20) | PSP-specific code |
| http_status | INT | |
| success | BOOLEAN | |
| latency_ms | INT | |
| created_at | TIMESTAMP | |

**Choice: PostgreSQL (same DB, partitioned)**
- Append-only, write-heavy — monthly partitioning by `created_at`
- Critical for debugging, reconciliation, and dispute evidence
- Index: `(payment_id, created_at)` for fetching attempts per payment

#### `ledger_entries` (Double-entry bookkeeping)
| Column | Type | Notes |
|---|---|---|
| entry_id | UUID (PK) | |
| payment_id | UUID (FK) | |
| account_id | VARCHAR(50) | e.g., "guest:usr_001", "airbnb:service_fee", "host:usr_002", "tax:CA_state" |
| entry_type | ENUM | DEBIT, CREDIT |
| amount | DECIMAL(19,4) | Always positive |
| currency | VARCHAR(3) | |
| description | VARCHAR(200) | "Booking bk_abc123 — nightly rate" |
| created_at | TIMESTAMP | Immutable — ledger entries never updated |

**Choice: PostgreSQL (separate database — Ledger DB)**
- Append-only, immutable — never UPDATE or DELETE
- Strong consistency is non-negotiable for accounting
- Sum of all debits must equal sum of all credits (invariant enforced at application level)
- Index: `(account_id, created_at)` for account balance queries

#### `idempotency_records`
| Column | Type | Notes |
|---|---|---|
| idempotency_key | VARCHAR(100) (PK) | |
| request_hash | VARCHAR(64) | SHA-256 of request body — detect misuse (same key, different request) |
| response_payload | JSONB | Cached response to return on replay |
| status | ENUM | IN_PROGRESS, COMPLETED, FAILED |
| created_at | TIMESTAMP | |
| expires_at | TIMESTAMP | TTL = 24 hours |

**Choice: Redis (primary) + PostgreSQL (fallback)**
- Redis for fast O(1) lookup on hot path
- PostgreSQL as durable fallback — if Redis is down, check DB
- TTL in Redis handles auto-cleanup; DB cleaned by scheduled job

#### `refunds`
| Column | Type | Notes |
|---|---|---|
| refund_id | UUID (PK) | |
| payment_id | UUID (FK) | |
| amount | DECIMAL(19,4) | |
| currency | VARCHAR(3) | |
| reason | VARCHAR(50) | CANCELLATION_FLEXIBLE, HOST_INITIATED, DISPUTE, etc. |
| status | ENUM | INITIATED, PROCESSING, COMPLETED, FAILED |
| psp_reference | VARCHAR(100) | |
| initiated_by | ENUM | GUEST, HOST, SYSTEM, SUPPORT |
| created_at | TIMESTAMP | |

**Choice: PostgreSQL** — same rationale as payments; needs ACID

#### `payouts`
| Column | Type | Notes |
|---|---|---|
| payout_id | UUID (PK) | |
| host_id | UUID | |
| booking_id | UUID | |
| amount | DECIMAL(19,4) | |
| currency | VARCHAR(3) | |
| status | ENUM | SCHEDULED, PROCESSING, COMPLETED, FAILED |
| payout_method_id | UUID | References host's bank account / PayPal |
| psp | VARCHAR(20) | Payout processor |
| psp_reference | VARCHAR(100) | |
| scheduled_at | TIMESTAMP | 24h after check-in |
| completed_at | TIMESTAMP | |
| created_at | TIMESTAMP | |

**Choice: PostgreSQL** — transactional integrity for money disbursement

---

## 6. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           CLIENTS                                        │
│     Mobile App (iOS/Android)  │  Web App  │  Booking Service (internal)  │
└───────────┬───────────────────────┬───────────────────┬──────────────────┘
            │                       │                   │
            ▼                       ▼                   ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     API GATEWAY (L7 — Envoy / AWS ALB)                   │
│           Rate Limiting │ Auth │ TLS Termination │ Routing                │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    PAYMENT ORCHESTRATOR SERVICE                           │
│                                                                          │
│  ┌─────────────────┐   ┌───────────────────┐   ┌──────────────────┐     │
│  │ Idempotency     │   │ Payment State     │   │ Split Payment    │     │
│  │ Guard           │──▶│ Machine           │──▶│ Calculator       │     │
│  │ (Redis + PG)    │   │                   │   │                  │     │
│  └─────────────────┘   └────────┬──────────┘   └──────────────────┘     │
│                                 │                                        │
│                    ┌────────────▼────────────┐                           │
│                    │   PSP Router            │                           │
│                    │   (Routing Rules +      │                           │
│                    │    Circuit Breaker)      │                           │
│                    └────────────┬────────────┘                           │
│                                 │                                        │
│          ┌──────────────────────┼──────────────────────┐                │
│          ▼                      ▼                      ▼                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │ Stripe       │    │ Braintree    │    │ Adyen        │              │
│  │ Adapter      │    │ Adapter      │    │ Adapter      │              │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘              │
│         │                   │                   │                       │
└─────────┼───────────────────┼───────────────────┼───────────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
    ┌──────────┐       ┌──────────┐        ┌──────────┐
    │  Stripe  │       │ Braintree│        │  Adyen   │
    │  (PSP)   │       │  (PSP)   │        │  (PSP)   │
    └────┬─────┘       └────┬─────┘        └────┬─────┘
         │                  │                    │
         ▼                  ▼                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                   PSP WEBHOOK HANDLER                                     │
│   Receives: auth_success, capture_complete, refund_complete, chargeback  │
│   Verifies signature → publishes to Kafka                                │
└───────────────────────────────┬──────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     EVENT BUS (Kafka)                                     │
│  Topics: payment.status │ payout.trigger │ refund.events │ ledger.events │
└────┬──────────────┬──────────────┬──────────────┬────────────────────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
┌──────────┐ ┌──────────────┐ ┌──────────┐ ┌──────────────────────┐
│ Booking  │ │ Payout       │ │ Ledger   │ │ Reconciliation       │
│ Service  │ │ Service      │ │ Service  │ │ Service              │
│ (status  │ │ (host        │ │ (double- │ │ (daily batch:        │
│  update) │ │  disburse)   │ │  entry)  │ │  internal vs PSP)    │
└──────────┘ └──────────────┘ └──────────┘ └──────────────────────┘
                                    │
                                    ▼
                          ┌──────────────────┐
                          │  LEDGER DB       │
                          │  (PostgreSQL)    │
                          │  Append-only     │
                          │  Double-entry    │
                          └──────────────────┘
```

### Data Flow (Happy Path — Guest Books a Stay)

1. **Guest** clicks "Book" on the app → Booking Service validates availability and pricing
2. **Booking Service** calls **Payment Orchestrator** `POST /payments/authorize` with idempotency key
3. **Idempotency Guard** checks Redis — key not found → proceeds (if found and COMPLETED, returns cached response)
4. **Payment State Machine** creates payment record with status `INITIATED`, writes to Payments DB
5. **Split Calculator** computes breakdown: $1200 nightly + $100 cleaning + $150 service fee + $50 tax = $1500
6. **PSP Router** selects Stripe (primary for US cards), checks circuit breaker — healthy → routes
7. **Stripe Adapter** calls Stripe API `POST /v1/payment_intents` with tokenized card, amount, idempotency key
8. Stripe returns `succeeded` → Adapter maps to internal `AUTHORIZED` status
9. **State Machine** transitions payment: `INITIATED → AUTHORIZED`, logs PaymentAttempt, updates idempotency record to COMPLETED
10. **Ledger Service** receives event via Kafka → writes double-entry: DEBIT guest account $1500, CREDIT escrow account $1500
11. **Booking Service** receives `payment.status.AUTHORIZED` event → confirms booking with guest
12. _(Day of check-in)_ **Payout Scheduler** triggers capture: `POST /payments/{id}/capture`
13. Stripe captures the authorized amount → status transitions to `CAPTURED`
14. **Ledger Service** records: DEBIT escrow $1200, CREDIT host account $1200 (payout); DEBIT escrow $150, CREDIT Airbnb revenue $150 (service fee); DEBIT escrow $50, CREDIT tax holding $50; DEBIT escrow $100, CREDIT host account $100 (cleaning fee)
15. **Payout Service** triggers host bank transfer 24h after check-in → disburses $1300 (nightly + cleaning) to host

---

## 7. Database Choice

| Data Store | Technology | Justification |
|---|---|---|
| **Payments DB** | PostgreSQL 16 | ACID transactions for state machine transitions. Optimistic locking prevents concurrent updates. Well-suited for the moderate write volume (~65 payments/sec peak) |
| **Ledger DB** | PostgreSQL 16 (separate instance) | Immutable, append-only double-entry ledger. Strong consistency is non-negotiable for financial records. Separate instance to isolate ledger I/O from payment operations |
| **Idempotency Store** | Redis (primary) + PostgreSQL (durable fallback) | Redis for sub-ms dedup checks on the hot path. PG as fallback if Redis is unavailable |
| **Event Bus** | Apache Kafka | Durable event log for payment status changes. Enables decoupled consumers (ledger, payout, booking, reconciliation). Replay capability for reprocessing |
| **PSP Routing Config** | In-memory (loaded from DB on startup) | Tiny dataset — routing rules, circuit breaker state. Refreshed periodically or on config change event |

### Why Not NoSQL for Payments?

Payments require strict transactional guarantees. A payment transitioning from `AUTHORIZED → CAPTURED` while simultaneously being refunded would be catastrophic. PostgreSQL's row-level locking and MVCC handle this reliably. Cassandra or DynamoDB would require complex application-level concurrency control.

### Why Separate Ledger DB?

The ledger is the **source of truth** for all money movements. It has different access patterns (append-only writes, aggregation reads for balance queries) and different availability requirements (can tolerate slightly higher latency, but zero data loss). Isolating it prevents booking-spike write load from impacting financial reporting queries.

---

## 8. Caching Strategy

### What to Cache

| Data | Cache Layer | TTL | Size |
|---|---|---|---|
| Idempotency keys | Redis | 24 hours | ~1.1 GB |
| Payment method tokens | Redis | 1 hour (re-fetch from PSP token vault) | ~30 GB cluster |
| PSP routing rules | JVM heap (Caffeine) | Until config change event | < 1 MB |
| Recent payment status (for polling) | Redis | 5 min | ~500 MB |
| FX rates | Redis | 60 seconds (refresh from FX provider) | < 10 MB |

### Eviction Policy

- **Idempotency keys:** TTL-based (24h). No LRU needed — every key has fixed lifetime.
- **Payment method tokens:** TTL-based (1h). Re-tokenization handled by PSP if expired.
- **FX rates:** TTL-based (60s). Stale rates → financial risk, so short TTL.

### Cache Invalidation Strategy

- **Idempotency:** Write-through. On payment completion, write response to Redis with TTL. Reads check Redis first → PG fallback on miss.
- **PSP routing config:** Event-driven. Admin changes config → publishes `config.updated` Kafka event → all instances reload from DB.
- **Payment status:** Cache-aside. On status update, delete Redis key. Next poll repopulates.

### Cache Stampede Prevention

- **Idempotency:** Not a concern — each key is unique per request.
- **Payment method tokens:** Use `SETNX` with short lock TTL. Only one thread calls PSP token vault; others wait on the cache key.
- **FX rates:** Single-flight loading with a leader-election lock. One instance refreshes; all instances read the refreshed value.

---

## 9. Message Queues / Async Processing

### Why Async

Payment processing has multiple downstream effects (ledger entries, payout scheduling, notification, reconciliation). The payment orchestrator should NOT synchronously coordinate all of these — it would increase latency, create tight coupling, and make partial failures hard to handle.

### Technology: Apache Kafka

**Why Kafka:**
- **Durability** — payment events must never be lost; Kafka persists to disk with replication factor 3
- **Ordering** — events for the same payment must be processed in order (AUTHORIZED before CAPTURED). Partition key = `payment_id` guarantees this
- **Replay** — reconciliation service can replay events to rebuild state after issues
- **Consumer independence** — Ledger Service, Payout Service, Booking Service, and Notification Service each consume at their own pace

### Topic Design

| Topic | Partition Key | Consumers | Purpose |
|---|---|---|---|
| `payment.status` | `payment_id` | Booking Service, Notification Service, Analytics | Payment state changes (AUTHORIZED, CAPTURED, REFUNDED, etc.) |
| `ledger.commands` | `payment_id` | Ledger Service | Commands to write ledger entries |
| `payout.trigger` | `host_id` | Payout Service | Triggers host payouts after capture |
| `refund.events` | `payment_id` | Booking Service, Notification Service | Refund status changes |
| `psp.webhooks` | `payment_id` | Payment Orchestrator | Ingested PSP webhook events |
| `reconciliation.queue` | `date_bucket` | Reconciliation Service | Daily recon job triggers |
| `payment.dlq` | — | Ops / Manual Review | Failed events after max retries |

### Retry / DLQ Strategy

```
Attempt 1 → fail → wait 2s → Attempt 2 → fail → wait 10s → Attempt 3 → fail → wait 60s → Attempt 4 → fail → DLQ
```

- Max 4 retries with exponential backoff (2s, 10s, 60s, 300s)
- Higher retry count than typical services because payment events are high-value — we retry harder before giving up
- DLQ → alert on-call engineer immediately (any payment event in DLQ is a P0 incident)
- Idempotency ensures retries are safe — PSP calls are idempotent via idempotency key

---

## 10. Data Partitioning / Sharding

### Payments DB (PostgreSQL)

- **Strategy:** Range-based partitioning by `created_at` (monthly partitions using PostgreSQL declarative partitioning)
- **Why range over hash:** Payment queries are almost always time-scoped — "show recent payments for guest X," reconciliation queries by date range, regulatory audits by period
- **Partition scheme:** `payments_2026_01`, `payments_2026_02`, etc.
- **Index per partition:** `(booking_id)`, `(guest_id, created_at DESC)`, `(status, created_at)` — local indexes within each partition
- **Retention:** All partitions retained (7-year legal requirement). Partitions older than 1 year moved to slower storage (PG tablespace on cheaper EBS)

### Ledger DB (PostgreSQL)

- **Strategy:** Range-based by `created_at` (daily partitions — higher granularity due to regulatory needs)
- **Why daily:** Reconciliation runs daily — scanning a single day's partition is efficient. Also enables point-in-time audits by date.
- **Index per partition:** `(account_id, created_at)` for balance queries

### Hot Partition Handling

- Not a significant concern at Airbnb's payment volume (~65 QPS peak). PostgreSQL on a modern instance (r6g.2xlarge) handles this comfortably.
- If a specific date partition gets hot (e.g., New Year's Eve bookings), PostgreSQL connection pooling (PgBouncer) + read replicas absorb the load.

### Rebalancing

- No rebalancing needed — new month/day = new partition. Old partitions are static and gradually archived.
- Adding read replicas is the primary horizontal scaling lever.

---

## 11. Replication & Consistency

### Payments DB (PostgreSQL)

- **Primary + 2 read replicas** (3 AZs)
- **Writes:** Primary only — all payment state transitions go here
- **Reads:** Reporting and analytics queries → read replica. Payment status lookups → primary (consistency matters for payment status)
- **Replication:** Synchronous to one replica (zero data loss guarantee), async to second replica (for read scaling)
- **Failover:** AWS RDS Multi-AZ with automatic failover (< 60s); application retries during failover window

### Ledger DB (PostgreSQL)

- **Primary + 1 synchronous replica** (different AZ)
- **Writes:** Primary only — append-only, no updates
- **Reads:** Balance queries and reconciliation → read replica
- **Replication:** Synchronous only — cannot afford data loss on financial records
- **Point-in-time recovery:** Continuous WAL archiving to S3 for disaster recovery

### Redis

- **Cluster mode:** 6 nodes (3 primary + 3 replicas)
- **Replication:** Async (Redis default)
- **On failover:** Sentinel-based promotion. Brief window where idempotency check misses — acceptable because PSP-side idempotency key prevents double charge
- **Note:** Redis is a cache layer, not source of truth. PostgreSQL is always the fallback.

### Consistency Model

- **Payment operations:** Strongly consistent (read-your-write). After `authorize` returns, the payment is guaranteed to be in `AUTHORIZED` state in DB.
- **Cross-service propagation:** Eventually consistent. Booking Service sees the payment status update via Kafka within ~100ms typically. This is acceptable — the booking confirmation UI can show a brief "confirming..." state.
- **Ledger:** Strongly consistent. Ledger writes are in the same DB transaction as the command acknowledgment. Sum(debits) = Sum(credits) invariant always holds.

### CAP Positioning

This system prioritizes **CP (Consistency + Partition-tolerance)** over availability for the payment write path:
- A payment that returns "success" but didn't actually process is far worse than a temporary "service unavailable." Money must never be in an ambiguous state.
- We sacrifice some availability during DB failover (~60s) to maintain consistency guarantees.
- Read paths (payment status polling) can be more lenient — serve from read replica or cache (AP behavior).

---

## 12. Load Balancing

### API Gateway (Guest-Facing)

- **L7 Load Balancer** (AWS ALB or Envoy)
- **Strategy:** Round-robin — payment requests are stateless and uniform in cost
- **Why L7:** Path-based routing (`/payments/*` → Payment Orchestrator, `/payouts/*` → Payout Service), TLS termination, request logging, header injection (correlation ID)
- **Sticky sessions:** Not needed — all state is in DB

### Internal Services

- **gRPC with client-side load balancing** between Payment Orchestrator and PSP Adapters
- **Service discovery:** Kubernetes DNS or Consul
- **Strategy:** Round-robin with health checks

### PSP Load Balancing

- **Weighted routing** across PSPs based on:
  - Success rate (dynamic — prefer PSP with higher auth rate for the card type)
  - Latency (route to faster PSP)
  - Cost (prefer PSP with lower transaction fee when all else is equal)
  - Regional preference (Adyen for EU cards, Stripe for US cards)
- Implemented in the **PSP Router** component

### Health Checks

- **Liveness:** `/health/live` — JVM up, accepting connections
- **Readiness:** `/health/ready` — DB connection pool healthy, Redis reachable, at least one PSP circuit breaker is closed
- **PSP health:** Per-PSP circuit breaker. If a PSP fails 5 consecutive calls in 30s → circuit opens → traffic routed to fallback PSP
- **Interval:** 5s for critical services, unhealthy threshold: 2 consecutive failures

---

## 13. CDN / Blob Storage

### Limited Applicability

Payment processing is primarily data/API-driven, not content-heavy. However:

- **PCI audit logs & reconciliation reports:** Stored in **S3** with server-side encryption (AES-256), bucket versioning, and object lock (WORM — Write-Once-Read-Many) for regulatory compliance
  - Retention: 7 years
  - Access: Only reconciliation service and authorized auditors via pre-signed URLs
- **Chargeback dispute evidence:** PDF receipts, booking details screenshots stored in S3, attached to dispute submissions via PSP API
- **No CDN needed** — all content is internal or API-driven, not served to end users

---

## 14. Monitoring & Alerting

### Key Metrics

| Metric | Source | Alert Threshold |
|---|---|---|
| **Authorization success rate** per PSP | PSP Adapter metrics | < 95% over 5 min → P1 alert |
| **Payment latency** (auth end-to-end) | Application timer | P99 > 3s → P2; P99 > 5s → P1 |
| **PSP error rate** per PSP | Circuit breaker metrics | > 5% errors in 1 min → circuit opens |
| **Idempotency collision rate** | Redis metrics | Sudden spike → possible client bug or replay attack |
| **Ledger balance invariant** | Ledger Service health check | Sum(debits) ≠ Sum(credits) → **P0 CRITICAL** (never should happen) |
| **Kafka consumer lag** (payment.status) | Kafka metrics | > 10K messages → P1 |
| **Reconciliation discrepancy count** | Recon Service daily report | > 0 unexplained discrepancies → P1 |
| **DLQ depth** | Kafka DLQ topic | > 0 → P1 alert immediately |
| **Payout failure rate** | Payout Service | > 2% → P1 |
| **Capture-after-auth delay** | Custom metric | > 7 days → auth may expire, P2 |

### Logging Strategy

- **Structured JSON logs** with fields: `payment_id`, `booking_id`, `psp`, `operation`, `status`, `latency_ms`, `trace_id`
- **Correlation ID:** Every payment operation carries a `trace_id` through all services — Payment Orchestrator → PSP Adapter → Ledger → Payout
- **PCI compliance:** NEVER log: card numbers, CVV, full account numbers. Log only: last 4 digits, card brand, token references
- **PII handling:** Mask guest/host IDs in external-facing logs, full IDs in internal secure logs
- **Log aggregation:** Datadog Logs or ELK stack with role-based access control

### Dashboards

1. **Payment Operations** — Auth success rate, capture rate, refund rate, per-PSP breakdown, latency distribution
2. **Financial Health** — Daily GMV processed, payout volume, escrow balance, reconciliation status
3. **PSP Health** — Per-PSP availability, latency, error codes, circuit breaker state
4. **Alerts & Incidents** — DLQ depth, reconciliation discrepancies, payout failures

---

## 15. Trade-offs

### 1. Strong Consistency > High Availability (CP for Writes)

**Chose:** Strong consistency for payment write path  
**Trade-off:** ~60s unavailability during DB failover; payment requests fail during this window  
**Why:** A payment that says "success" but loses data is catastrophic — double charges, lost refunds, accounting errors. Brief downtime is acceptable; financial inconsistency is not. The read path (status queries) can serve from cache/replicas for higher availability.

### 2. Multi-PSP Complexity > Single PSP Simplicity

**Chose:** Three PSPs with intelligent routing and adapter pattern  
**Trade-off:** More operational complexity — 3 different APIs, 3 webhook formats, 3 sets of credentials to manage  
**Why:** Single-PSP dependency is a business-killing SPOF. When Stripe had a 2-hour outage, companies with no fallback lost millions. Multi-PSP gives us: failover (circuit breaker flips to backup), cost optimization (route to cheapest), regional optimization (Adyen for EU, Stripe for US), and negotiation leverage.

### 3. Separate Ledger DB > Embedded Ledger in Payments DB

**Chose:** Dedicated PostgreSQL instance for the ledger  
**Trade-off:** Cross-DB consistency requires Kafka-based eventual consistency (not a single ACID transaction for payment + ledger write)  
**Why:** The ledger has fundamentally different access patterns (append-only, aggregation-heavy, audit queries) and stricter durability requirements. Co-locating it with the payments DB would mean ledger audit queries compete with real-time payment operations for I/O. The trade-off is managed by making ledger writes idempotent — if the ledger consumer processes the same event twice, the idempotent write is a no-op.

### 4. Idempotency at Every Layer > Trust-the-Caller

**Chose:** Idempotency enforced at API level, service level, AND PSP level  
**Trade-off:** More storage (idempotency records), more latency (~1ms per Redis lookup), more code complexity  
**Why:** In a distributed system with retries, exactly-once is impossible without idempotency. A network timeout between our service and Stripe doesn't tell us if the charge went through. Without idempotency keys at Stripe, a retry would double-charge the guest. Belt-and-suspenders idempotency is the only safe approach for payments.

### 5. Auth-then-Capture > Direct Charge

**Chose:** Two-step payment (authorize on booking → capture on check-in)  
**Trade-off:** More complexity (must track auth expiry, handle void on cancellation), authorized funds are "held" on guest's card showing as pending  
**Why:** Airbnb's marketplace model requires escrow-like behavior. Guest books 3 months ahead — if we charge immediately, a cancellation refund takes 5-10 business days (bad UX). With auth-then-capture: cancellation = void the auth (instant fund release), and we only move real money when the stay happens.

---

## 16. Bottlenecks & Scaling

### Single Points of Failure

| SPOF | Mitigation |
|---|---|
| **Payments DB (Primary)** | Synchronous replica + RDS Multi-AZ auto-failover (< 60s). During failover, payment requests return 503 — clients retry |
| **Ledger DB (Primary)** | Synchronous replica + auto-failover. Kafka buffers events during failover — no ledger entries lost |
| **Kafka** | 5 brokers, replication factor 3, rack-aware placement. Tolerates 2 broker failures |
| **Redis** | Cluster mode with Sentinel. PSP-side idempotency protects against Redis failure |
| **PSP dependency** | Multi-PSP with circuit breaker failover. No single PSP failure takes down payments |
| **Payment Orchestrator** | Stateless — horizontal scaling behind LB. K8s ensures min 3 replicas |

### Scaling Strategy

| Component | Current (~65 QPS peak) | At 10x (~650 QPS) | At 100x (~6,500 QPS) |
|---|---|---|---|
| **Payment Orchestrator** | 3 pods | 10 pods | 30 pods + consider partitioning by region |
| **Payments DB** | Primary + 2 replicas (r6g.2xlarge) | Primary + 4 replicas (r6g.4xlarge) | Shard by region (US, EU, APAC) — each region has its own PG cluster |
| **Ledger DB** | Primary + 1 sync replica | Primary + 2 sync replicas | Shard by account_id hash; read-optimized replica cluster for reporting |
| **Kafka** | 5 brokers, 6 partitions/topic | 10 brokers, 12 partitions | 20 brokers, 24 partitions, dedicated clusters per region |
| **Redis** | 6 nodes | 12 nodes | 24 nodes + local L1 cache (Caffeine) for hot idempotency keys |

### Auto-Scaling Triggers

- **Payment Orchestrator pods:** Scale on request latency (P95 > 1s → add pods) and CPU (> 70% → add pods)
- **Kafka consumers:** Scale on consumer lag (lag > 5K → add consumer instances within consumer group)

### What Breaks at 100x

- **PostgreSQL write throughput.** At 6,500 write QPS, a single PG primary is stressed. Mitigation: regional sharding (US cluster, EU cluster, APAC cluster) — payments are naturally regional.
- **PSP rate limits.** Stripe has merchant-level rate limits. At 100x, we'd need to negotiate enterprise limits and implement client-side request queuing/smoothing.
- **Reconciliation job duration.** 100x more records to reconcile daily. Mitigation: parallelize recon by PSP and date chunk, use Spark for large-scale recon instead of single-threaded batch.

---

## 17. Failure Scenarios

### PSP Timeout (e.g., Stripe doesn't respond within 5s)

- **Impact:** We don't know if the charge went through.
- **Mitigation:** 
  1. Record attempt as `UNKNOWN` in payment_attempts table
  2. Query PSP status endpoint with the idempotency key: `GET /v1/payment_intents/{id}` 
  3. If PSP confirms charged → update to AUTHORIZED 
  4. If PSP confirms not charged → retry or failover to another PSP 
  5. If PSP is unreachable → circuit breaker opens → route to Braintree/Adyen
- **Key insight:** The idempotency key on the PSP side is our safety net. We can always ask "did this charge go through?" without risk of double-charging.

### Double-Charge Prevention

- **Scenario:** Network glitch → client retries → second authorize request arrives
- **Layer 1:** API idempotency key → Redis lookup returns cached response from first request
- **Layer 2:** Database UNIQUE constraint on `(booking_id)` in payments table → rejects duplicate
- **Layer 3:** PSP idempotency key → Stripe/Braintree reject duplicate charge
- **Three layers of defense** — even if one fails, the others catch it.

### Database Failover During Payment

- **Scenario:** Primary PG goes down mid-transaction (after PSP charge but before our DB commit)
- **Impact:** PSP charged the guest, but our DB doesn't have the record.
- **Mitigation:**
  1. On recovery, reconciliation service detects the PSP charge with no matching internal record
  2. Creates a "reconciliation exception" flagged for manual review
  3. If confirmed orphaned charge → initiate automatic void/refund via PSP
- **Prevention:** Use PostgreSQL's synchronous commit to sync replica. Failover promotes the replica which has its committed data.

### Kafka Down

- **Impact:** Payment status events don't propagate to Booking Service, Ledger Service, Payout Service.
- **Mitigation:**
  1. Payment Orchestrator writes to DB first (source of truth), then publishes to Kafka
  2. If Kafka publish fails → record event in an outbox table (`payment_outbox`)
  3. **Outbox pattern:** A periodic poller (every 5s) reads unpublished events from outbox and publishes to Kafka
  4. Booking Service can also poll payment status via API as a fallback
- **Key:** DB write happens first. Kafka is for propagation, not for the primary record.

### Partial Refund Failure

- **Scenario:** Guest cancels. Refund policy says refund 50%. PSP call to refund fails.
- **Mitigation:**
  1. Refund status set to `PROCESSING` in DB
  2. Retry with exponential backoff (up to 4 retries)
  3. If still failing → DLQ + alert ops team
  4. Ops team can manually trigger refund via admin tool or different PSP
  5. Guest sees "Refund processing — may take up to 5 business days" (expected behavior)
- **Ledger:** Refund ledger entry written only AFTER PSP confirms refund success — never before.

### Payout Failure (Host Bank Rejects Transfer)

- **Scenario:** Host payout to bank account fails (wrong account, bank error).
- **Mitigation:**
  1. Payout status set to `FAILED`
  2. Retry once after 24h (bank issues are often transient)
  3. If retry fails → notify host via email/push: "Payout failed — please update your bank details"
  4. Funds remain in Airbnb escrow — not lost
  5. Auto-retry daily for 7 days before escalating to support

### Clock Drift Between Services

- **Scenario:** Payment Orchestrator timestamps say 10:00:00, Ledger Service timestamps say 10:00:03 due to clock drift.
- **Impact:** Reconciliation could flag timing mismatches as discrepancies.
- **Mitigation:** Use `event_id` and `idempotency_key` as correlation keys, not timestamps. NTP on all instances. Tolerance window of ±5s in reconciliation logic.

---

## Appendix: Technology Stack Summary

| Layer | Technology | Notes |
|---|---|---|
| Language/Framework | Java 21 + Spring Boot 3.x | Airbnb uses Java + Kotlin; Spring Boot for rapid development |
| API Protocol | REST (external), gRPC (internal) | REST for client-facing; gRPC for low-latency inter-service calls |
| Payments DB | PostgreSQL 16 (RDS Multi-AZ) | ACID for payment state machine |
| Ledger DB | PostgreSQL 16 (separate RDS instance) | Append-only, double-entry bookkeeping |
| Event Bus | Apache Kafka (MSK) | Durable event propagation, ordering guarantees |
| Idempotency / Cache | Redis Cluster | Sub-ms dedup, rate limit counters |
| Local Cache | Caffeine | JVM-level cache for PSP config, FX rates |
| PSP Integration | Stripe (primary US), Braintree, Adyen (EU/APAC) | Adapter pattern for multi-PSP |
| Circuit Breaker | Resilience4j | Per-PSP circuit breaking, retry with backoff |
| Serialization | Avro + Confluent Schema Registry | Schema evolution for Kafka events |
| Monitoring | Prometheus + Grafana | Metrics collection and visualization |
| Logging | Datadog Logs (or ELK) | Structured JSON logs with PCI-compliant masking |
| Tracing | OpenTelemetry + Jaeger | End-to-end distributed tracing |
| Orchestration | Kubernetes (EKS) | Auto-scaling, health checks, rolling deploys |
| Secrets | AWS Secrets Manager / HashiCorp Vault | PSP API keys, DB credentials — rotated automatically |

---

## Appendix: Payment State Machine

```
                          ┌──────────┐
                          │ INITIATED│
                          └────┬─────┘
                               │ PSP auth call
                      ┌────────┴────────┐
                      ▼                 ▼
               ┌──────────┐      ┌──────────┐
               │AUTHORIZED│      │  FAILED  │
               └────┬─────┘      └──────────┘
                    │
           ┌────────┴────────┐
           │                 │
     (check-in)        (cancellation)
           │                 │
           ▼                 ▼
    ┌──────────┐      ┌──────────┐
    │ CAPTURED │      │  VOIDED  │
    └────┬─────┘      └──────────┘
         │
    ┌────┴──────────────┐
    │                   │
(partial refund)   (full refund)
    │                   │
    ▼                   ▼
┌────────────────┐ ┌──────────┐
│PARTIALLY_REFUND│ │ REFUNDED │
└────────────────┘ └──────────┘
```

**Transition Rules:**
- `INITIATED → AUTHORIZED`: PSP confirms authorization
- `INITIATED → FAILED`: PSP declines card or timeout after retries
- `AUTHORIZED → CAPTURED`: Triggered by check-in event (or manual capture)
- `AUTHORIZED → VOIDED`: Booking cancelled before check-in
- `AUTHORIZED → FAILED`: Authorization expires (7-30 days depending on PSP)
- `CAPTURED → PARTIALLY_REFUNDED`: Partial refund processed
- `CAPTURED → REFUNDED`: Full refund processed
- `PARTIALLY_REFUNDED → REFUNDED`: Remaining amount refunded
- **No backward transitions** — once captured, cannot go back to authorized. Once refunded, cannot capture again.
