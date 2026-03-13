# Airbnb — HLD Questions (Senior Software Engineer, Payments)

> **Sources:** Glassdoor (live-fetched, 3 pages), Blind (live-fetched, 5 threads), LeetCode Discuss (login-walled — training knowledge), Analysis Doc, Training Knowledge  
> **Role:** Senior Software Engineer, Payments (Backend)  
> **Target Level:** Senior (FAANG-tier)  
> **Last Updated:** 11 March 2026  

> **Key insight from live data (Blind):**  
> - "Both Airbnb system design prompts were exactly like the internet suggested they would be" — Blind user who got Airbnb G9 offer (May 2025)  
> - "Expect marketplace or consumer platform problems" — Blind user (Feb 2026)  
> - "System design round expects end-to-end ownership — requirements, API, data model, scaling, trade-offs, monitoring" — analysis doc  
> - "The interviewer of system design has something in his mind about how the system should look like, and if your design is different from that, he has no patience to listen" — Glassdoor (Jul 2024)  
> - At Senior level, Airbnb expects deep expertise — not just breadth but **depth in trade-offs and operational concerns**

---

## Confirmed (From Interview Reports & Analysis Doc)

| # | Topic | Source | Difficulty | Key Focus Areas |
|---|---|---|---|---|
| 1 | **Design a Payment Processing System** | Role-specific (Payments team), Training Knowledge | High | Idempotency, exactly-once processing, reconciliation, retry with exponential backoff, payment state machines, PCI compliance, multi-PSP failover |
| 2 | **Design a Booking System** | Glassdoor, LeetCode Discuss, Training Knowledge | High | Availability calendars, double-booking prevention, distributed locking, eventual consistency, check-in/check-out logic, cancellation policies |
| 3 | **Design a Rental Room Inventory Management System** | Glassdoor (Jul 2024 — live-fetched) | Medium-High | Listing availability, pricing management, host calendar sync, inventory state management, search integration |
| 4 | **Design a Search and Ranking System** | Glassdoor, Training Knowledge | Medium-High | Inverted index, ranking algorithms (relevance + personalization), search filters (price, location, amenities), geospatial indexing, real-time availability |
| 5 | **Design a Monitoring / Alerting System** | JD focus (observability), Analysis Doc | Medium-High | Metrics collection pipeline, anomaly detection, alert routing, dashboards, SLO/SLI tracking, PagerDuty-like notification |
| 6 | **Design a Marketplace Platform** | Blind (confirmed — "marketplace or consumer platform problems") | High | Two-sided marketplace (hosts + guests), trust & safety, review system, pricing, matching |

## Likely (Based on Role & Domain)

| # | Topic | Why Likely | Key Focus Areas |
|---|---|---|---|
| 1 | **Design an Observability Platform** | Core JD responsibility — "flow-level observability" | Distributed tracing (OpenTelemetry/Jaeger), log aggregation (ELK), metrics pipeline (Prometheus/Grafana), SLO tracking, correlation IDs across services |
| 2 | **Design a Notification Service** | Cross-platform, payments alerts, multi-channel | Multi-channel delivery (push, email, SMS, in-app), template engine, rate limiting, retry logic, user preferences, delivery guarantees |
| 3 | **Design a Rate Limiter** | Payments reliability, API protection — explicitly in JD | Token bucket vs sliding window vs leaky bucket, distributed rate limiting (Redis), per-user vs per-service, graceful degradation |
| 4 | **Design a Service Health Dashboard** | Incident management focus in JD | Health checks, dependency graphs, status aggregation, SLI visualization, incident timeline, auto-escalation |
| 5 | **Design a Payment Reconciliation System** | Payments team domain-specific | Ledger design, double-entry bookkeeping, reconciliation jobs, discrepancy detection, settlement flows, audit trails |
| 6 | **Design a Fraud Detection System** | Payments domain — critical for payment reliability | Real-time scoring, rule engine + ML model pipeline, feature store, alerting, investigation workflow, false positive handling |
| 7 | **Design a Pricing / Dynamic Pricing Service** | Airbnb core feature — Smart Pricing | Demand forecasting, competitive price analysis, host price suggestions, surge pricing, A/B testing integration |
| 8 | **Design a Review / Rating System** | Airbnb core feature | Bidirectional reviews (host ↔ guest), trust scores, content moderation, aggregate ratings, review timing windows |

---

## Detailed Preparation Notes

### 1. Design a Payment Processing System (🔴 Must Prepare)

**Why this is critical:** You're interviewing for the Payments team. This WILL come up in some form.

**Requirements to cover:**
- Functional: process payments (charge, refund, partial refund), support multiple PSPs (Stripe, Braintree, Adyen), handle split payments (host payout + Airbnb fee + taxes)
- Non-functional: exactly-once processing, idempotency, <1s latency for charge, 99.99% availability

**Key architecture components:**
- **Payment Gateway Service** — orchestrates PSP calls, handles retries
- **Idempotency Layer** — idempotency key → dedup table (Redis + DB)
- **Payment State Machine** — INITIATED → AUTHORIZED → CAPTURED → SETTLED (or FAILED/REFUNDED)
- **Ledger Service** — double-entry bookkeeping, audit trail
- **Reconciliation Service** — batch job comparing internal records vs PSP records
- **PSP Abstraction** — adapter pattern for multiple payment providers

**Critical topics to discuss:**
- Idempotency keys and exactly-once semantics
- Distributed transactions (Saga pattern for booking + payment)
- PCI DSS compliance (tokenization, no raw card data in your systems)
- Retry strategies with exponential backoff + circuit breaker
- Split payment flows (escrow: guest pays → Airbnb holds → host payout after check-in)
- Multi-currency handling
- Failure modes: PSP timeout, partial failure, double charge prevention

### 2. Design a Booking System (🔴 Must Prepare)

**Key focus areas:**
- Availability calendar (per listing, per day)
- Distributed locking to prevent double-booking (optimistic locking vs pessimistic)
- Pricing calculation (base price + cleaning fee + service fee + taxes)
- Booking state machine: PENDING → CONFIRMED → CHECKED_IN → COMPLETED → REVIEWED
- Cancellation policies (flexible, moderate, strict) with refund rules
- Integration with payment system (auth on book, capture on check-in)

**Architecture:**
- Listing Service → Availability Service → Pricing Service → Booking Service → Payment Service
- Calendar storage: date-range per listing in Cassandra/DynamoDB for fast reads
- Double-booking prevention: SELECT FOR UPDATE on availability row, or Redis distributed lock

### 3. Design a Search & Ranking System (🟡 Should Prepare)

**Key components:**
- Query parsing → filter pipeline → ranking → pagination
- Geospatial indexing (PostGIS, Elasticsearch geo queries, S2/H3 cells)
- Inverted index for text search (Elasticsearch)
- Ranking signals: relevance, price, reviews, host response rate, personalization
- Real-time availability filtering (check dates against calendar)
- Caching strategy: popular search results, listing data

### 4. Design a Monitoring / Alerting System (🟡 Should Prepare)

**Key components:**
- Metrics collection (agents on services push to collector)
- Time-series database (PromQL, InfluxDB)
- Alert rule engine (threshold, anomaly detection, rate of change)
- Alert routing (severity → team → escalation chain)
- Dashboard service (Grafana-like)
- SLO/SLI tracking with error budget burn rate alerts

---

## Domain-Specific Design Knowledge (Payments)

> Critical for the Payments team — interviewers will probe your understanding of payment domain

### Payment Processing Fundamentals

| Concept | What It Means | Why Airbnb Cares |
|---|---|---|
| **Idempotency** | Same request processed exactly once despite retries | Prevents double charges |
| **Exactly-once semantics** | Guarantee that a payment is processed exactly once | Core reliability requirement |
| **Reconciliation** | Matching internal records against PSP records | Detects discrepancies, ensures financial accuracy |
| **Double-entry bookkeeping** | Every transaction has equal debit and credit entries | Audit trail, financial integrity |
| **PCI DSS Compliance** | Standards for handling card data | Airbnb must comply; use tokenization, never store raw card |
| **Tokenization** | Replace card number with a token from PSP | Security; actual card data stays with PSP |
| **3D Secure (3DS)** | Additional authentication step for card payments | Reduces fraud, required in EU (PSD2/SCA) |
| **Split payments** | Dividing a payment among multiple parties | Airbnb: guest pays → platform holds → host receives after check-in |
| **Escrow** | Holding funds until conditions are met | Airbnb holds payment until check-in is confirmed |
| **Chargebacks** | Customer disputes a charge with their bank | Airbnb must handle disputes, provide evidence |

### Airbnb Payment Flow (Simplified)
```
Guest books → Auth on guest's card → Escrow (platform holds) →
Guest checks in → Capture funds →
Post-checkout → Calculate host payout (minus fees) → Settle to host
```

### Reliability Concepts (Observability Focus)

| Concept | What It Means |
|---|---|
| **SLI (Service Level Indicator)** | Measured metric (e.g., p99 latency, error rate) |
| **SLO (Service Level Objective)** | Target for SLI (e.g., p99 < 200ms, 99.9% success) |
| **Error Budget** | Allowed failure = 1 - SLO (e.g., 0.1% of requests can fail) |
| **Circuit Breaker** | Stops calling a failing downstream service |
| **Bulkhead** | Isolates failures to prevent cascade |
| **Retry with backoff** | Exponential backoff + jitter before retrying |
| **Saga Pattern** | Distributed transaction as sequence of local transactions with compensating actions |
| **Outbox Pattern** | Ensures reliable event publishing alongside DB writes |

---

## Tips for System Design at Airbnb

1. **Always start with requirements** — Clarify functional + non-functional; Airbnb expects you to scope before solving (confirmed analysis doc)
2. **Show end-to-end ownership** — Don't just draw boxes; discuss data models, API contracts, failure modes
3. **Discuss trade-offs explicitly** — Don't just pick a technology; explain WHY and what you're giving up
4. **Bring up monitoring/observability unprompted** — Given the role focus on reliability, this will score big points
5. **Payments domain depth** — If you get a payments question, show deep understanding of idempotency, reconciliation, compliance
6. **Be prepared for pushback** — One Glassdoor reviewer noted the interviewer "has something in mind" — defend your design calmly with trade-offs
7. **Practice the classics** — "Both Airbnb system design prompts were exactly like the internet suggested" (Blind, confirmed)
