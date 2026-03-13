# Airbnb — LLD Questions (Senior Software Engineer, Payments)

> **Sources:** Glassdoor (live-fetched, 3 pages), Blind (live-fetched, 5 threads), Analysis Doc, Training Knowledge  
> **Role:** Senior Software Engineer, Payments (Backend)  
> **Target Level:** Senior (FAANG-tier)  
> **Last Updated:** 11 March 2026  

---

## Confirmed (From Analysis Doc)

| # | Topic | Key Patterns | Difficulty |
|---|---|---|---|
| 1 | **Design a Payment State Machine** | State pattern, Observer pattern, event-driven transitions | Medium-High |
| 2 | **Design a Circuit Breaker** | State pattern (Closed → Open → Half-Open), Decorator pattern | Medium |
| 3 | **Design a Rate Limiter (code-level)** | Strategy pattern, Sliding Window, Token Bucket | Medium |
| 4 | **Design a Job Scheduler** | Priority Queue, Observer, Strategy, Thread Pool | Medium-High |

## Likely (Based on Role & Domain)

| # | Topic | Key Patterns | Difficulty |
|---|---|---|---|
| 5 | **Design an LRU Cache** | LinkedHashMap, Doubly Linked List + HashMap | Medium |
| 6 | **Design a Retry Handler with Backoff** | Strategy pattern (different backoff strategies), Decorator | Medium |
| 7 | **Design a Pub-Sub / Event Bus** | Observer pattern, Publisher-Subscriber, in-memory event system | Medium |
| 8 | **Design a Booking/Calendar Manager** | Interval tree, Factory for calendar rules, Strategy for pricing | Medium-High |
| 9 | **Design a Rule Engine (Fraud/Compliance)** | Chain of Responsibility, Strategy pattern, Interpreter | Medium-High |
| 10 | **Design a Configuration Manager** | Singleton, Observer (config change notification), Builder | Medium |

---

## Detailed Preparation Notes

### 1. Payment State Machine (🔴 Must Prepare)

**States:** CREATED → AUTHORIZED → CAPTURED → SETTLED → COMPLETED (plus FAILED, CANCELLED, REFUNDED, PARTIALLY_REFUNDED)

**Design patterns:**
- **State Pattern** — each state is a class with allowed transitions
- **Observer Pattern** — notify listeners on state change (audit log, analytics, notifications)
- **Command Pattern** — encapsulate state transition requests as objects

**Key classes:**
```
PaymentState (interface) → CreatedState, AuthorizedState, CapturedState, etc.
PaymentContext — holds current state, delegates to state object
PaymentEvent — AUTHORIZE, CAPTURE, SETTLE, REFUND, FAIL
PaymentTransition — (fromState, event) → toState with guards/validators
PaymentObserver (interface) → AuditLogger, NotificationSender, AnalyticsTracker
```

**Edge cases:**
- Concurrent state transitions (thread safety)
- Invalid transitions (throw IllegalStateException)
- Idempotent transitions (same event applied twice)
- Compensating transactions (rollback from AUTHORIZED to CANCELLED)

### 2. Circuit Breaker (🟡 Should Prepare)

**States:** CLOSED → OPEN → HALF_OPEN → CLOSED (recovery)

**Key design:**
- Failure counter + threshold
- Timeout for OPEN → HALF_OPEN transition
- Success count in HALF_OPEN before returning to CLOSED
- Thread-safe (AtomicInteger for counters)

### 3. Rate Limiter (🟡 Should Prepare)

**Algorithms to implement:**
- Token Bucket (refill rate, bucket capacity)
- Sliding Window Log (timestamp queue)
- Sliding Window Counter (current + previous window weighted)

**Design:**
- Strategy pattern — `RateLimitStrategy` interface with different implementations
- `RateLimiter` class delegates to strategy
- Distributed: Redis-backed with Lua scripts for atomicity

---

## Prep Notes

- **Senior (FAANG-tier) expectation:** Clean OOP structure, design pattern knowledge, SOLID principles, handle concurrency
- **Always discuss:** Thread safety, extensibility, edge cases, testing strategy
- **Time management:** 45 min total — 5 min requirements, 10 min class design, 20 min implementation, 10 min edge cases
