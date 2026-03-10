# PayPal — System Design Questions (Staff Backend Engineer)

> **Sources:** AmbitionBox (fetched), Glassdoor (training knowledge — login wall), Analysis Doc
> **Last Updated:** 9 March 2026

---

## HLD Questions

### Confirmed (Glassdoor / AmbitionBox)

#### 1. Design a Notification Service
- **Source:** Glassdoor (training knowledge) — confirmed asked at PayPal
- **Scope:** Multi-channel (email, SMS, push, in-app), templating, rate limiting, user preferences
- **PayPal Focus:** Transaction alerts, payment receipts, fraud warnings, compliance notifications
- **Key Topics:** Message queue (Kafka/SQS), fan-out, deduplication, delivery guarantees, retry with backoff, dead letter queue
- **Difficulty:** Medium-High

#### 2. Design an Expense Sharing App (Splitwise-like)
- **Source:** Glassdoor (training knowledge) — confirmed asked at PayPal
- **Scope:** Group management, expense splitting (equal/unequal/percentage), debt simplification, payment integration
- **PayPal Focus:** Extends into PayPal's P2P payments, currency conversion, settlement optimization
- **Key Topics:** Directed graph for debt tracking, DAG-based simplification, eventual consistency, distributed transactions
- **Difficulty:** Medium-High

#### 3. Design a Payment API / Payment Gateway
- **Source:** Glassdoor (training knowledge) + AmbitionBox ("Design a Payment Processing System" — MTS-1, 8 months ago)
- **Scope:** End-to-end payment processing (initiate → authorize → capture → settle), idempotency, multi-currency
- **PayPal Focus:** This IS PayPal's core business. Deep knowledge expected: PCI-DSS compliance, tokenization, 3D Secure, merchant integration
- **Key Topics:** Idempotency keys, saga pattern, two-phase commit, circuit breaker, reconciliation, audit trails
- **Difficulty:** High (expect deep follow-ups on fault tolerance and consistency)

### Likely (Based on Role & Team Focus)

#### 4. Design a Rate Limiter
- **Source:** Analysis Doc (likely topic)
- **Scope:** API rate limiting at scale — token bucket, sliding window, distributed counters
- **PayPal Focus:** API Gateway protection, merchant API quotas, abuse prevention
- **Key Topics:** Redis-based distributed counters, sliding window log, token bucket algorithm, Lua scripting for atomicity
- **Difficulty:** Medium

#### 5. Design a Fraud Detection System
- **Source:** Analysis Doc (likely topic)
- **Scope:** Real-time transaction scoring, rule engine + ML pipeline, alert generation
- **PayPal Focus:** Core to PayPal's value prop. Real-time risk scoring on every transaction
- **Key Topics:** Stream processing (Kafka Streams/Flink), feature store, model serving, rule engine, feedback loop, false positive management
- **Difficulty:** High

#### 6. Design a Distributed Cache
- **Source:** Analysis Doc (likely topic)
- **Scope:** Multi-tier caching (L1 local + L2 distributed), eviction, consistency
- **PayPal Focus:** Session caching, config caching, merchant data caching at PayPal scale
- **Key Topics:** Consistent hashing, cache-aside vs write-through, invalidation strategies, Redis Cluster, hot key handling
- **Difficulty:** Medium

#### 7. Design an Event-Driven Architecture / Message Bus
- **Source:** Analysis Doc (likely topic)
- **Scope:** Async event processing platform, event sourcing, CQRS
- **PayPal Focus:** Decoupling microservices, CDC for data sync, transaction event streaming
- **Key Topics:** Kafka/EventBridge, schema registry, exactly-once semantics, dead letter queue, event versioning, replay
- **Difficulty:** Medium-High

#### 8. Design a Digital Wallet Service
- **Source:** Analysis Doc (likely topic)
- **Scope:** Balance management, top-up, withdrawal, P2P transfers, multi-currency
- **PayPal Focus:** Core product — PayPal balance, Venmo balance, crypto wallet
- **Key Topics:** Double-entry bookkeeping, ledger design, distributed transactions, currency conversion, compliance (KYC/AML)
- **Difficulty:** High

#### 9. Design an API Gateway
- **Source:** Analysis Doc (likely topic)
- **Scope:** Request routing, auth, rate limiting, protocol translation, API versioning
- **PayPal Focus:** Single entry point for merchant APIs, partner integrations, mobile apps
- **Key Topics:** Reverse proxy, JWT validation, circuit breaker, request/response transformation, canary routing
- **Difficulty:** Medium

#### 10. Design a Reconciliation System
- **Source:** Training knowledge (common for payment companies)
- **Scope:** Matching internal records with bank/processor settlement files, detecting discrepancies
- **PayPal Focus:** Critical for financial accuracy — every payment must be accounted for
- **Key Topics:** Batch processing, fuzzy matching, idempotency, retry logic, alerting on mismatches, audit trail
- **Difficulty:** Medium-High

---

## LLD Questions

### 1. Design a Payment State Machine
- **Scope:** Model payment lifecycle (created → authorized → captured → settled → refunded/disputed)
- **Key Topics:** State pattern, event-driven transitions, idempotent operations, concurrent state changes
- **Patterns:** State Pattern, Strategy Pattern, Observer Pattern

### 2. Design a Retry Mechanism with Backoff
- **Scope:** Generic retry library with exponential backoff, jitter, max retries, circuit breaking
- **Key Topics:** Exponential backoff, decorrelated jitter, circuit breaker integration, async retry
- **Patterns:** Decorator Pattern, Strategy Pattern (for backoff policy)

### 3. Design a Transaction Ledger (Double-Entry)
- **Scope:** Every financial transaction creates a debit + credit entry. Model the ledger, ensure ACID.
- **Key Topics:** Immutable records, audit trail, balance calculation, multi-currency
- **Patterns:** Event Sourcing, Repository Pattern

### 4. Design a Rule Engine for Fraud Detection
- **Scope:** Configurable rule evaluation — rules can be added/modified without code changes
- **Key Topics:** Chain of Responsibility, rule prioritization, short-circuit evaluation, scoring
- **Patterns:** Chain of Responsibility, Strategy Pattern, Composite Pattern

### 5. Design a Rate Limiter (Code-Level)
- **Scope:** Token bucket / sliding window implementation in Java
- **Key Topics:** Thread safety, ConcurrentHashMap, ScheduledExecutorService, atomic operations
- **Patterns:** Singleton, Strategy Pattern (for algorithm selection)

---

## Prep Notes

- **Staff-level expectation:** You lead the design conversation. Start with requirements clarification, draw out the big picture, then dive deep into 2-3 areas.
- **PayPal domain knowledge matters:** Know the basics of payment processing flow (authorize → capture → settle), PCI-DSS, idempotency.
- **Always discuss:** Trade-offs (consistency vs availability), failure modes, monitoring/observability, scaling bottlenecks.
- **Time management:** 45 min total — 5 min requirements, 5 min high-level, 25 min deep dive, 10 min edge cases and scaling.
