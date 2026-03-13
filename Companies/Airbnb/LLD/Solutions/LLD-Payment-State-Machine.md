# LLD — Design a Payment State Machine

> **Company:** Airbnb  
> **Level:** Senior Software Engineer, Payments — Backend  
> **Patterns:** State Pattern, Observer Pattern, Strategy Pattern, Builder Pattern  
> **Difficulty:** Medium-High  

---

## Assumptions

- We're designing the **core domain model** for a payment's lifecycle within Airbnb's marketplace, not the full distributed system
- Airbnb is a two-sided marketplace: guest pays → Airbnb holds in escrow → host receives payout after check-in
- A payment moves through well-defined states: `CREATED → AUTHORIZED → CAPTURED → SPLIT → SETTLED` (happy path)
- The state machine must support Airbnb-specific concerns: **escrow hold**, **split payment** (service fee + host payout + tax + cleaning fee), and **cancellation policies** (flexible, moderate, strict)
- State transitions are triggered by external events (guest booking, check-in, cancellation, PSP callbacks, payout cron)
- Transitions must be **idempotent** — replaying the same event on the same state is a no-op
- Concurrent transition attempts on the same payment must be handled safely (optimistic locking)
- Each transition is logged as an immutable audit event (financial compliance)

---

## 1. Requirements Clarification

**What are we designing?**

A payment state machine that models the full lifecycle of an Airbnb booking payment — from the guest initiating payment through escrow, capture, split disbursement to the host, and handling cancellations/refunds.

**Scope:**
- **Included:** State definitions, valid transitions, transition rules/guards (including cancellation policy-based refund guards), idempotency, split payment tracking, audit logging, event notification, concurrent state change safety
- **Excluded:** PSP API integration, database persistence layer, REST API layer, distributed coordination, FX conversion logic (those are HLD concerns)

**Functional Requirements:**
- Define all valid payment states and transitions for the Airbnb booking lifecycle
- Enforce that only valid transitions are allowed (e.g., can't SETTLE from CREATED)
- Support **cancellation policies** (flexible, moderate, strict) as transition guards that determine refund amounts
- Track **split payment breakdown** (nightly rate, service fee, cleaning fee, taxes)
- Each state can have entry/exit behavior (e.g., on entering AUTHORIZED → reserve funds in escrow)
- Transitions are idempotent — same event applied to same state produces same result
- Every transition is recorded as an immutable audit event
- Observers are notified on state changes (notification service, analytics, booking service)
- Support partial refunds and full refunds based on cancellation policy

---

## 2. Use Cases / Actors

| Actor | Use Cases |
|---|---|
| **Guest** | Initiates booking payment (→ CREATED), cancels booking (→ triggers refund based on policy), requests refund |
| **Booking Service** | Triggers authorization on booking confirm, triggers capture on check-in, triggers void on cancellation |
| **PSP (Stripe/Braintree/Adyen)** | Confirms authorization, confirms capture, declines payment, sends settlement notification |
| **Payout Scheduler** | Triggers host payout 24h after check-in (→ PAYOUT_INITIATED → SETTLED) |
| **Host** | Receives payout; can also cancel (→ full refund to guest before check-in) |
| **Support Agent** | Force-transitions (e.g., manual refund, dispute resolution), views audit trail |
| **Reconciliation System** | Reads audit trail for daily PSP reconciliation |

---

## 3. Core Entities

| Entity | Attributes | Types |
|---|---|---|
| **Payment** | id, bookingId, guestId, hostId, totalAmount, currency, currentState, splitBreakdown, cancellationPolicy, createdAt, updatedAt, version, refundedAmount, idempotencyKey | UUID, UUID, UUID, UUID, BigDecimal, Currency, PaymentState, SplitBreakdown, CancellationPolicy, Instant, Instant, long, BigDecimal, String |
| **SplitBreakdown** | nightlyRate, cleaningFee, serviceFee, taxes, hostPayout | BigDecimal (each) |
| **PaymentState** (enum) | CREATED, AUTHORIZED, AUTHORIZATION_DECLINED, CAPTURED, VOIDED, REFUND_PENDING, PARTIALLY_REFUNDED, REFUNDED, PAYOUT_INITIATED, SETTLED, DISPUTED, DISPUTE_RESOLVED, FAILED | enum constants |
| **PaymentEvent** (enum) | AUTHORIZE, AUTHORIZE_DECLINED, CAPTURE, VOID, REQUEST_REFUND, PARTIAL_REFUND, FULL_REFUND, INITIATE_PAYOUT, SETTLE, DISPUTE_OPEN, DISPUTE_RESOLVE, FAIL | enum constants |
| **StateTransition** | fromState, toState, event, timestamp, metadata, performedBy | PaymentState, PaymentState, PaymentEvent, Instant, Map, String |
| **CancellationPolicy** (enum) | FLEXIBLE, MODERATE, STRICT | enum constants |
| **TransitionGuard** | — (interface) | boolean canTransition(Payment, PaymentEvent) |
| **StateChangeListener** | — (interface) | void onStateChange(Payment, StateTransition) |

---

## 4. Class Diagram

```
                              ┌─────────────────────────┐
                              │     «interface»          │
                              │   PaymentStateHandler    │
                              ├─────────────────────────┤
                              │ + handle(Payment,        │
                              │     PaymentEvent):       │
                              │     PaymentState         │
                              │ + supports(): PaymentState│
                              │ + allowedEvents():       │
                              │     Set<PaymentEvent>    │
                              └────────────┬────────────┘
                                           │ implements
          ┌──────────────┬─────────────────┼───────────────┬──────────────────┐
          │              │                 │               │                  │
  ┌───────▼──────┐ ┌─────▼────────┐ ┌─────▼──────┐ ┌─────▼───────┐ ┌───────▼────────┐
  │CreatedState  │ │Authorized    │ │CapturedState│ │PayoutInit.  │ │DisputedState   │
  │Handler       │ │StateHandler  │ │Handler      │ │StateHandler │ │Handler         │
  └──────────────┘ └──────────────┘ └─────────────┘ └─────────────┘ └────────────────┘
                                          ... (one per state)

  ┌────────────────────────┐
  │       Payment           │◆────── SplitBreakdown (composition)
  ├────────────────────────┤
  │ - id: UUID              │◆────── List<StateTransition> (audit trail)
  │ - bookingId: UUID       │
  │ - guestId: UUID         │
  │ - hostId: UUID          │
  │ - totalAmount: BigDec   │     1         1
  │ - currentState          │─────────────────┐
  │ - cancellationPolicy    │                 │
  │ - version: long         │                 ▼
  └────────────────────────┘  ┌─────────────────────────────────────┐
                               │      PaymentStateMachine            │
                               ├─────────────────────────────────────┤
                               │ - handlers: Map<State, Handler>     │
                               │ - guards: List<TransitionGuard>     │
                               │ - listeners: List<StateChangeLsnr>  │
                               ├─────────────────────────────────────┤
                               │ + apply(Payment, Event): Payment    │
                               │ + registerListener(...): void       │
                               │ + getAllowedEvents(Payment): Set    │
                               └────────┬───────────────┬────────────┘
                                        │               │
                                        ▼               ▼
                               ┌────────────────┐ ┌──────────────────────┐
                               │ «interface»     │ │ «interface»           │
                               │TransitionGuard  │ │StateChangeListener   │
                               └───────┬────────┘ └───────────┬──────────┘
                                       │                       │
                            ┌──────────┼──────────┐    ┌───────┼─────────┐
                            ▼          ▼          ▼    ▼       ▼         ▼
                       ┌────────┐ ┌────────┐ ┌───────┐ ┌──────┐ ┌────────┐
                       │AuthExp │ │Cancel  │ │Refund │ │Audit │ │Booking │
                       │Guard   │ │Policy  │ │Amount │ │Log   │ │Status  │
                       │        │ │Guard   │ │Guard  │ │Lsnr  │ │Lsnr    │
                       └────────┘ └────────┘ └───────┘ └──────┘ └────────┘


  ┌──────────────────────────┐        ┌─────────────────────────┐
  │   «interface»             │        │  «interface»             │
  │  RefundCalculator         │        │  CancellationPolicy     │
  │  (Strategy)               │        │  (enum implementing     │
  ├──────────────────────────┤        │   RefundCalculator)     │
  │ + calculateRefund(        │        └─────────────────────────┘
  │     Payment,              │             │ implements
  │     Instant): BigDecimal  │        ┌────┼────┬────────┐
  └──────────────────────────┘        ▼    ▼    ▼        │
                                  FLEXIBLE  MODERATE  STRICT
```

**Relationships:**
- `Payment` **has-a** `SplitBreakdown` (composition, 1-to-1)
- `Payment` **has-a** list of `StateTransition` (composition, 1-to-many)
- `Payment` **has-a** `CancellationPolicy` (enum reference)
- `PaymentStateMachine` **has-many** `PaymentStateHandler` (aggregation, one per state)
- `PaymentStateMachine` **has-many** `TransitionGuard` (aggregation)
- `PaymentStateMachine` **has-many** `StateChangeListener` (aggregation)
- `CancellationPolicy` **implements** `RefundCalculator` (strategy pattern)

---

## 5. Interfaces & Abstract Classes

### PaymentStateHandler (Strategy — one per state)

```java
/**
 * Each payment state has a handler that knows what events are valid
 * and how to transition. Replaces massive switch blocks with polymorphism.
 */
public interface PaymentStateHandler {
    PaymentState supports();
    PaymentState handle(Payment payment, PaymentEvent event);
    Set<PaymentEvent> allowedEvents();
}
```

**Justification:** Without this, you'd have a monolithic switch on `(currentState, event)`. Adding a new state (e.g., `ON_HOLD` for fraud review) means adding a new class — zero modification to existing code. **Open/Closed Principle.**

### TransitionGuard (Chain of validations)

```java
/**
 * Guards check preconditions before a transition is allowed.
 * e.g., "Can only capture if authorization hasn't expired."
 * e.g., "Refund amount depends on cancellation policy timing."
 * Multiple guards compose — ALL must pass.
 */
public interface TransitionGuard {
    boolean canTransition(Payment payment, PaymentEvent event);
    String reason();
}
```

**Justification:** Separates business rule validation from state transition logic. Airbnb's cancellation policies (flexible/moderate/strict) are naturally expressed as guards. Adding a new policy rule = adding a new guard. **Single Responsibility.**

### StateChangeListener (Observer — decoupled reactions)

```java
/**
 * Notified after a state change is committed. Used for audit logging,
 * booking service status updates, guest/host notifications, analytics.
 */
public interface StateChangeListener {
    void onStateChange(Payment payment, StateTransition transition);
}
```

**Justification:** The state machine shouldn't know about audit logs, notifications, or the booking service. Observer pattern keeps these decoupled. Adding a new side-effect = adding a new listener.

### RefundCalculator (Strategy — cancellation policy)

```java
/**
 * Calculates the refund amount based on cancellation policy and timing.
 * Each CancellationPolicy enum value implements this differently.
 */
public interface RefundCalculator {
    BigDecimal calculateRefund(Payment payment, Instant cancellationTime);
}
```

**Justification:** Airbnb has three cancellation policies with different refund rules. The Strategy pattern lets each policy define its own calculation without conditionals. **Open/Closed Principle** — adding a new policy (e.g., "Super Strict") = adding a new enum constant.

---

## 6. Method Signatures

```java
public class PaymentStateMachine {

    /**
     * Applies an event to a payment, triggering a state transition if valid.
     *
     * @param payment     the current payment entity
     * @param event       the event to apply
     * @param metadata    additional context (PSP reference, admin notes, etc.)
     * @param performedBy who triggered (SYSTEM, guest ID, host ID, admin ID)
     * @return the updated payment with new state
     * @throws InvalidTransitionException      if event not valid for current state
     * @throws TransitionGuardException        if a guard rejects the transition
     * @throws ConcurrentModificationException if optimistic lock version mismatch
     */
    public Payment apply(Payment payment, PaymentEvent event,
                         Map<String, String> metadata, String performedBy);

    /**
     * Convenience overload — defaults metadata to empty, performedBy to "SYSTEM".
     */
    public Payment apply(Payment payment, PaymentEvent event);

    /**
     * Registers a listener for state change notifications.
     */
    public void registerListener(StateChangeListener listener);

    /**
     * Returns all events valid for the payment's current state.
     */
    public Set<PaymentEvent> getAllowedEvents(Payment payment);
}

public class Payment {

    /**
     * Transitions to a new state and appends to audit trail.
     * Package-private — only the state machine should call this.
     */
    void transitionTo(PaymentState newState, PaymentEvent event,
                      Map<String, String> metadata, String performedBy);

    /**
     * Idempotency check — has this event already been processed?
     */
    public boolean hasProcessed(PaymentEvent event);

    /**
     * Returns unmodifiable audit trail ordered by timestamp.
     */
    public List<StateTransition> getAuditTrail();

    /**
     * Records a partial refund amount.
     */
    public void addRefundedAmount(BigDecimal refund);

    /**
     * How much can still be refunded.
     */
    public BigDecimal getRemainingRefundable();
}
```

---

## 7. Enums & Constants

```java
public enum PaymentState {
    CREATED("Payment initiated, awaiting authorization"),
    AUTHORIZED("Funds reserved on guest's card via PSP"),
    AUTHORIZATION_DECLINED("PSP declined the authorization"),
    CAPTURED("Funds captured from guest's card (check-in triggered)"),
    VOIDED("Authorization voided — booking cancelled before capture"),
    REFUND_PENDING("Refund requested, awaiting PSP confirmation"),
    PARTIALLY_REFUNDED("Partial refund issued (based on cancellation policy)"),
    REFUNDED("Full refund issued to guest"),
    PAYOUT_INITIATED("Host payout triggered — bank transfer in progress"),
    SETTLED("Host payout completed — payment lifecycle done"),
    DISPUTED("Guest filed a chargeback/dispute with their bank"),
    DISPUTE_RESOLVED("Dispute resolved (won by host or refunded)"),
    FAILED("Terminal failure — unrecoverable error");

    private final String description;

    PaymentState(String description) {
        this.description = description;
    }

    public String getDescription() { return description; }

    public boolean isTerminal() {
        return this == SETTLED || this == REFUNDED || this == AUTHORIZATION_DECLINED
                || this == VOIDED || this == FAILED || this == DISPUTE_RESOLVED;
    }
}

public enum PaymentEvent {
    AUTHORIZE,             // PSP authorization attempt
    AUTHORIZE_DECLINED,    // PSP declines
    CAPTURE,               // Funds captured (check-in)
    VOID,                  // Cancel authorization (pre-capture cancellation)
    REQUEST_REFUND,        // Guest/host/system requests refund
    PARTIAL_REFUND,        // Partial refund processed by PSP
    FULL_REFUND,           // Full refund processed by PSP
    INITIATE_PAYOUT,       // Trigger host bank transfer
    SETTLE,                // Payout completed
    DISPUTE_OPEN,          // Guest files chargeback
    DISPUTE_RESOLVE,       // Dispute resolved
    FAIL                   // Unrecoverable failure
}

public enum CancellationPolicy implements RefundCalculator {
    /**
     * Full refund if cancelled at least 24 hours before check-in.
     * After that: refund for nights not stayed minus first night + service fee.
     */
    FLEXIBLE {
        @Override
        public BigDecimal calculateRefund(Payment payment, Instant cancellationTime) {
            Instant checkIn = payment.getCheckInTime();
            long hoursBeforeCheckIn = Duration.between(cancellationTime, checkIn).toHours();

            if (hoursBeforeCheckIn >= 24) {
                // Full refund (minus service fee — Airbnb keeps it)
                return payment.getTotalAmount()
                        .subtract(payment.getSplitBreakdown().getServiceFee());
            }
            // Refund remaining nights minus first night
            return calculatePartialNightsRefund(payment, 1);
        }
    },

    /**
     * Full refund if cancelled 5+ days before check-in.
     * After: 50% of remaining nights refunded.
     */
    MODERATE {
        @Override
        public BigDecimal calculateRefund(Payment payment, Instant cancellationTime) {
            Instant checkIn = payment.getCheckInTime();
            long daysBeforeCheckIn = Duration.between(cancellationTime, checkIn).toDays();

            if (daysBeforeCheckIn >= 5) {
                return payment.getTotalAmount()
                        .subtract(payment.getSplitBreakdown().getServiceFee());
            }
            // 50% of remaining nights
            BigDecimal nightlyRefund = payment.getSplitBreakdown().getNightlyRate()
                    .multiply(BigDecimal.valueOf(0.5));
            return nightlyRefund;
        }
    },

    /**
     * Full refund only if cancelled within 48 hours of booking AND 14+ days before check-in.
     * Otherwise: no refund for first 30 days. After 30 days: 50% of remaining.
     */
    STRICT {
        @Override
        public BigDecimal calculateRefund(Payment payment, Instant cancellationTime) {
            long daysSinceBooking = Duration.between(payment.getCreatedAt(), cancellationTime).toDays();
            long daysBeforeCheckIn = Duration.between(cancellationTime, payment.getCheckInTime()).toDays();

            if (daysSinceBooking <= 2 && daysBeforeCheckIn >= 14) {
                return payment.getTotalAmount()
                        .subtract(payment.getSplitBreakdown().getServiceFee());
            }
            // After the grace period: 50% refund for the remaining portion
            BigDecimal nightlyRefund = payment.getSplitBreakdown().getNightlyRate()
                    .multiply(BigDecimal.valueOf(0.5));
            return nightlyRefund.max(BigDecimal.ZERO);
        }
    };

    protected BigDecimal calculatePartialNightsRefund(Payment payment, int nonRefundableNights) {
        // Simplified: total nightly rate minus non-refundable portion
        BigDecimal perNight = payment.getSplitBreakdown().getNightlyRate()
                .divide(BigDecimal.valueOf(payment.getNumberOfNights()), RoundingMode.HALF_UP);
        BigDecimal refundableNights = BigDecimal.valueOf(
                payment.getNumberOfNights() - nonRefundableNights);
        return perNight.multiply(refundableNights).max(BigDecimal.ZERO);
    }
}

public enum Currency {
    USD, EUR, GBP, INR, AUD, CAD, JPY, SGD, BRL, MXN
}
```

---

## 8. Design Patterns

### 1. State Pattern

**Problem:** A payment behaves differently depending on its current state. An AUTHORIZED payment can be captured or voided, but not settled. A CAPTURED payment can be refunded or have payout initiated, but not re-authorized.

**Naive approach:** A giant `switch(currentState)` with nested `switch(event)` — becomes unmaintainable as Airbnb adds states (e.g., `ON_HOLD` for fraud review, `PAYOUT_INITIATED` for the disbursement phase).

**Solution:** Each state is encapsulated in its own `PaymentStateHandler` class. The state machine delegates to the handler for the current state. Adding a new state = adding a new class. Zero modification to existing code.

### 2. Observer Pattern

**Problem:** After a state transition, multiple downstream effects happen — write audit log, update booking status, notify guest/host, update analytics dashboards, trigger payout scheduler. Putting all of this in the state machine creates a god class.

**Solution:** `StateChangeListener` interface. Listeners register with the state machine and get notified on every transition. The state machine doesn't know what listeners exist. Adding a new side-effect = adding a new listener class.

### 3. Strategy Pattern (Cancellation Policy as Refund Calculator)

**Problem:** Airbnb has three cancellation policies (flexible, moderate, strict) — each calculates refund amounts differently based on timing relative to check-in. If-else chains would be fragile and hard to extend.

**Solution:** `CancellationPolicy` enum implements `RefundCalculator`. Each policy variant encapsulates its own refund calculation. The `CancellationPolicyGuard` delegates to the policy to determine the allowed refund. Adding a new policy = adding a new enum constant.

### 4. Strategy Pattern (Guards)

**Problem:** Transition validation rules change independently — "auth expires after 7 days" might change to 14, "refund > remaining amount" is a permanent invariant. Mixing these into state handlers couples unrelated concerns.

**Solution:** `TransitionGuard` as separate strategy objects. Each guard encapsulates one validation rule. Guards compose — all must pass. Adding a new business rule = adding a new guard class.

### 5. Builder Pattern

**Problem:** `Payment` has 10+ fields, some are required (amount, guestId, hostId) and some optional (idempotencyKey, metadata). Telescoping constructors are a readability disaster.

**Solution:** `Payment.Builder` with fluent API and validation at build time. Prevents incomplete Payment objects from ever being created.

---

## 9. SOLID Principles

| Principle | Application |
|---|---|
| **S — Single Responsibility** | `PaymentStateHandler` handles transitions for ONE state. `TransitionGuard` validates ONE rule. `StateChangeListener` handles ONE side-effect. `CancellationPolicy` calculates refunds for ONE policy. `Payment` manages its own data and audit trail — doesn't know about the state machine. |
| **O — Open/Closed** | Adding new state (e.g., `ON_HOLD`) = new handler class. New guard = new class. New listener = new class. New cancellation policy = new enum constant. **Zero modification** to `PaymentStateMachine`. It's closed for modification, open for extension via registration. |
| **L — Liskov Substitution** | All `PaymentStateHandler` implementations are interchangeable. The state machine calls `handler.handle(payment, event)` without caring which concrete handler it is. Same for guards, listeners, and refund calculators. |
| **I — Interface Segregation** | `TransitionGuard` has one method: `canTransition()`. `StateChangeListener` has one method: `onStateChange()`. `RefundCalculator` has one method: `calculateRefund()`. No client is forced to implement methods it doesn't need. |
| **D — Dependency Inversion** | `PaymentStateMachine` depends on abstractions (`PaymentStateHandler`, `TransitionGuard`, `StateChangeListener`) — not on concrete implementations. All concrete handlers/guards/listeners are injected via constructor or registration. |

---

## 10. Sequence Diagrams

### Flow 1: Happy Path — Guest Books → Check-in → Host Payout

```
Guest        BookingService    PaymentStateMachine    CreatedHandler    Guards          Listeners
  │                │                   │                     │            │                │
  │── Book stay ──▶│                   │                     │            │                │
  │                │── apply(payment,  │                     │            │                │
  │                │   AUTHORIZE) ────▶│                     │            │                │
  │                │                   │── getHandler(       │            │                │
  │                │                   │   CREATED) ────────▶│            │                │
  │                │                   │── checkGuards() ───────────────▶│                │
  │                │                   │                     │            │── all pass ───▶│
  │                │                   │── handler.handle(   │            │                │
  │                │                   │   AUTHORIZE) ──────▶│            │                │
  │                │                   │                     │── returns  │                │
  │                │                   │                     │  AUTHORIZED│                │
  │                │                   │── payment.          │            │                │
  │                │                   │   transitionTo(     │            │                │
  │                │                   │   AUTHORIZED) ──────────────────────────────────▶│
  │                │                   │── notifyListeners() ───────────────────────────▶│
  │                │                   │                     │            │  AuditListener: │
  │                │                   │                     │            │  log transition │
  │                │                   │                     │            │  BookingListener:│
  │                │                   │                     │            │  confirm booking│
  │                │◀── AUTHORIZED ────│                     │            │                │
  │◀── Confirmed ──│                   │                     │            │                │
  │                │                   │                     │            │                │
  ═══ (days pass, guest checks in) ═══
  │                │                   │                     │            │                │
  │                │── apply(payment,  │                     │            │                │
  │                │   CAPTURE) ──────▶│                     │            │                │
  │                │                   │── [AuthorizedHandler] ─── returns CAPTURED        │
  │                │                   │── notifyListeners() → PayoutSchedulerListener:    │
  │                │                   │                         schedule payout in 24h    │
  │                │◀── CAPTURED ──────│                     │            │                │
  │                │                   │                     │            │                │
  ═══ (24h after check-in) ═══
  │                │                   │                     │            │                │
  │          PayoutScheduler           │                     │            │                │
  │                │── apply(payment,  │                     │            │                │
  │                │   INITIATE_PAYOUT)│                     │            │                │
  │                │                   │── [CapturedHandler] → PAYOUT_INITIATED           │
  │                │                   │                     │            │                │
  ═══ (bank transfer completes) ═══
  │                │── apply(payment,  │                     │            │                │
  │                │   SETTLE) ───────▶│                     │            │                │
  │                │                   │── [PayoutInitHandler] → SETTLED                  │
  │                │                   │── notifyListeners() → send host payout email     │
```

### Flow 2: Cancellation Before Check-in (VOID Path)

```
Guest         BookingService      PaymentStateMachine     AuthorizedHandler    CancelPolicyGuard
  │                │                      │                       │                  │
  │── Cancel ─────▶│                      │                       │                  │
  │  booking       │── apply(payment,     │                       │                  │
  │                │   VOID) ────────────▶│                       │                  │
  │                │                      │── getHandler(         │                  │
  │                │                      │   AUTHORIZED) ───────▶│                  │
  │                │                      │                       │                  │
  │                │                      │── checkGuards() ─────────────────────────▶│
  │                │                      │                       │                  │
  │                │                      │   CancelPolicyGuard:                     │
  │                │                      │   policy=FLEXIBLE,                       │
  │                │                      │   24h+ before check-in                   │
  │                │                      │   → full void allowed ──────────── true  │
  │                │                      │                       │                  │
  │                │                      │── handler.handle(     │                  │
  │                │                      │   VOID) ─────────────▶│                  │
  │                │                      │                       │── VOIDED         │
  │                │                      │── notifyListeners()                      │
  │                │                      │   → Guest: "Booking cancelled, full refund"
  │                │                      │   → Host: "Booking cancelled by guest"   │
  │                │◀── VOIDED ───────────│                       │                  │
  │◀── Cancelled ──│                      │                       │                  │
```

### Flow 3: Idempotent Replay (Same CAPTURE Event Arrives Twice)

```
PSP Callback      PaymentStateMachine          Payment
     │                    │                       │
     │── apply(payment,   │                       │
     │   CAPTURE) ───────▶│                       │
     │                    │── payment.hasProcessed │
     │                    │   (CAPTURE)? ─────────▶│
     │                    │                       │── checks last transition
     │                    │                       │── event=CAPTURE, state=CAPTURED
     │                    │◀── returns true ───────│
     │                    │                       │
     │◀── return payment  │   (no-op, no side     │
     │    unchanged       │    effects, no         │
     │                    │    listeners fired)    │
```

---

## 11. Code Implementation

### PaymentState.java

```java
public enum PaymentState {
    CREATED("Payment initiated, awaiting authorization"),
    AUTHORIZED("Funds reserved on guest's card via PSP"),
    AUTHORIZATION_DECLINED("PSP declined the authorization"),
    CAPTURED("Funds captured from guest's card — check-in triggered"),
    VOIDED("Authorization voided — booking cancelled before capture"),
    REFUND_PENDING("Refund requested, awaiting PSP confirmation"),
    PARTIALLY_REFUNDED("Partial refund issued based on cancellation policy"),
    REFUNDED("Full refund issued to guest"),
    PAYOUT_INITIATED("Host payout triggered — bank transfer in progress"),
    SETTLED("Host payout completed — payment lifecycle done"),
    DISPUTED("Guest filed a chargeback/dispute"),
    DISPUTE_RESOLVED("Dispute resolved"),
    FAILED("Terminal failure — unrecoverable");

    private final String description;

    PaymentState(String description) {
        this.description = description;
    }

    public String getDescription() { return description; }

    public boolean isTerminal() {
        return this == SETTLED || this == REFUNDED || this == AUTHORIZATION_DECLINED
                || this == VOIDED || this == FAILED || this == DISPUTE_RESOLVED;
    }
}
```

### PaymentEvent.java

```java
public enum PaymentEvent {
    AUTHORIZE,
    AUTHORIZE_DECLINED,
    CAPTURE,
    VOID,
    REQUEST_REFUND,
    PARTIAL_REFUND,
    FULL_REFUND,
    INITIATE_PAYOUT,
    SETTLE,
    DISPUTE_OPEN,
    DISPUTE_RESOLVE,
    FAIL
}
```

### SplitBreakdown.java

```java
import java.math.BigDecimal;

public record SplitBreakdown(
        BigDecimal nightlyRate,
        BigDecimal cleaningFee,
        BigDecimal serviceFee,
        BigDecimal taxes
) {
    /**
     * Host receives: nightly rate + cleaning fee (Airbnb keeps service fee + taxes).
     */
    public BigDecimal getHostPayout() {
        return nightlyRate.add(cleaningFee);
    }

    /**
     * Guest pays: nightly + cleaning + service fee + taxes.
     */
    public BigDecimal getGuestTotal() {
        return nightlyRate.add(cleaningFee).add(serviceFee).add(taxes);
    }

    public BigDecimal getNightlyRate() { return nightlyRate; }
    public BigDecimal getCleaningFee() { return cleaningFee; }
    public BigDecimal getServiceFee() { return serviceFee; }
    public BigDecimal getTaxes() { return taxes; }
}
```

### StateTransition.java

```java
import java.time.Instant;
import java.util.Map;

public record StateTransition(
        PaymentState fromState,
        PaymentState toState,
        PaymentEvent event,
        Instant timestamp,
        Map<String, String> metadata,
        String performedBy
) {}
```

### Payment.java

```java
import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

public class Payment {

    private final UUID id;
    private final UUID bookingId;
    private final UUID guestId;
    private final UUID hostId;
    private final BigDecimal totalAmount;
    private final Currency currency;
    private final SplitBreakdown splitBreakdown;
    private final CancellationPolicy cancellationPolicy;
    private final String idempotencyKey;
    private final Instant createdAt;
    private final Instant checkInTime;
    private final int numberOfNights;

    private PaymentState currentState;
    private Instant updatedAt;
    private long version;
    private BigDecimal refundedAmount;
    private final List<StateTransition> auditTrail;

    private Payment(Builder builder) {
        this.id = builder.id;
        this.bookingId = builder.bookingId;
        this.guestId = builder.guestId;
        this.hostId = builder.hostId;
        this.totalAmount = builder.totalAmount;
        this.currency = builder.currency;
        this.splitBreakdown = builder.splitBreakdown;
        this.cancellationPolicy = builder.cancellationPolicy;
        this.idempotencyKey = builder.idempotencyKey;
        this.checkInTime = builder.checkInTime;
        this.numberOfNights = builder.numberOfNights;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
        this.currentState = PaymentState.CREATED;
        this.version = 0;
        this.refundedAmount = BigDecimal.ZERO;
        this.auditTrail = new ArrayList<>();
    }

    // --- State transition (package-private — only state machine calls this) ---

    void transitionTo(PaymentState newState, PaymentEvent event,
                      Map<String, String> metadata, String performedBy) {
        StateTransition transition = new StateTransition(
                this.currentState, newState, event,
                Instant.now(), metadata, performedBy
        );
        this.auditTrail.add(transition);
        this.currentState = newState;
        this.updatedAt = Instant.now();
        this.version++;
    }

    public boolean hasProcessed(PaymentEvent event) {
        if (auditTrail.isEmpty()) {
            return false;
        }
        StateTransition last = auditTrail.getLast();
        return last.event() == event && last.toState() == this.currentState;
    }

    // --- Refund tracking ---

    public void addRefundedAmount(BigDecimal refund) {
        this.refundedAmount = this.refundedAmount.add(refund);
    }

    public BigDecimal getRemainingRefundable() {
        return this.totalAmount.subtract(this.refundedAmount);
    }

    // --- Getters ---

    public UUID getId() { return id; }
    public UUID getBookingId() { return bookingId; }
    public UUID getGuestId() { return guestId; }
    public UUID getHostId() { return hostId; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public Currency getCurrency() { return currency; }
    public SplitBreakdown getSplitBreakdown() { return splitBreakdown; }
    public CancellationPolicy getCancellationPolicy() { return cancellationPolicy; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public PaymentState getCurrentState() { return currentState; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public Instant getCheckInTime() { return checkInTime; }
    public int getNumberOfNights() { return numberOfNights; }
    public long getVersion() { return version; }
    public BigDecimal getRefundedAmount() { return refundedAmount; }

    public List<StateTransition> getAuditTrail() {
        return Collections.unmodifiableList(auditTrail);
    }

    // --- Builder ---

    public static class Builder {
        private UUID id = UUID.randomUUID();
        private UUID bookingId;
        private UUID guestId;
        private UUID hostId;
        private BigDecimal totalAmount;
        private Currency currency;
        private SplitBreakdown splitBreakdown;
        private CancellationPolicy cancellationPolicy;
        private String idempotencyKey;
        private Instant checkInTime;
        private int numberOfNights;

        public Builder bookingId(UUID bookingId) { this.bookingId = bookingId; return this; }
        public Builder guestId(UUID guestId) { this.guestId = guestId; return this; }
        public Builder hostId(UUID hostId) { this.hostId = hostId; return this; }
        public Builder totalAmount(BigDecimal amt) { this.totalAmount = amt; return this; }
        public Builder currency(Currency c) { this.currency = c; return this; }
        public Builder splitBreakdown(SplitBreakdown s) { this.splitBreakdown = s; return this; }
        public Builder cancellationPolicy(CancellationPolicy p) { this.cancellationPolicy = p; return this; }
        public Builder idempotencyKey(String key) { this.idempotencyKey = key; return this; }
        public Builder checkInTime(Instant t) { this.checkInTime = t; return this; }
        public Builder numberOfNights(int n) { this.numberOfNights = n; return this; }

        public Payment build() {
            Objects.requireNonNull(bookingId, "bookingId is required");
            Objects.requireNonNull(guestId, "guestId is required");
            Objects.requireNonNull(hostId, "hostId is required");
            Objects.requireNonNull(totalAmount, "totalAmount is required");
            Objects.requireNonNull(currency, "currency is required");
            Objects.requireNonNull(splitBreakdown, "splitBreakdown is required");
            Objects.requireNonNull(cancellationPolicy, "cancellationPolicy is required");
            Objects.requireNonNull(checkInTime, "checkInTime is required");
            if (totalAmount.compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("totalAmount must be positive");
            }
            if (numberOfNights <= 0) {
                throw new IllegalArgumentException("numberOfNights must be positive");
            }
            return new Payment(this);
        }
    }
}
```

### PaymentStateHandler.java

```java
import java.util.Set;

public interface PaymentStateHandler {
    PaymentState supports();
    PaymentState handle(Payment payment, PaymentEvent event);
    Set<PaymentEvent> allowedEvents();
}
```

### TransitionGuard.java

```java
public interface TransitionGuard {
    boolean canTransition(Payment payment, PaymentEvent event);
    String reason();
}
```

### StateChangeListener.java

```java
public interface StateChangeListener {
    void onStateChange(Payment payment, StateTransition transition);
}
```

### RefundCalculator.java

```java
import java.math.BigDecimal;
import java.time.Instant;

public interface RefundCalculator {
    BigDecimal calculateRefund(Payment payment, Instant cancellationTime);
}
```

### Concrete State Handlers

```java
import java.util.Set;

// ──────────────── CREATED ────────────────

public class CreatedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.CREATED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.AUTHORIZE, PaymentEvent.AUTHORIZE_DECLINED, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case AUTHORIZE -> PaymentState.AUTHORIZED;
            case AUTHORIZE_DECLINED -> PaymentState.AUTHORIZATION_DECLINED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── AUTHORIZED ────────────────

public class AuthorizedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.AUTHORIZED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.CAPTURE, PaymentEvent.VOID, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case CAPTURE -> PaymentState.CAPTURED;
            case VOID -> PaymentState.VOIDED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── CAPTURED ────────────────

public class CapturedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.CAPTURED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.INITIATE_PAYOUT, PaymentEvent.REQUEST_REFUND,
                PaymentEvent.PARTIAL_REFUND, PaymentEvent.FULL_REFUND,
                PaymentEvent.DISPUTE_OPEN, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case INITIATE_PAYOUT -> PaymentState.PAYOUT_INITIATED;
            case REQUEST_REFUND -> PaymentState.REFUND_PENDING;
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case FULL_REFUND -> PaymentState.REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── PAYOUT_INITIATED ────────────────

public class PayoutInitiatedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.PAYOUT_INITIATED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.SETTLE, PaymentEvent.FAIL, PaymentEvent.DISPUTE_OPEN);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case SETTLE -> PaymentState.SETTLED;
            case FAIL -> PaymentState.FAILED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── SETTLED ────────────────

public class SettledStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.SETTLED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.PARTIAL_REFUND, PaymentEvent.FULL_REFUND,
                PaymentEvent.DISPUTE_OPEN);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case FULL_REFUND -> PaymentState.REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── PARTIALLY_REFUNDED ────────────────

public class PartiallyRefundedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.PARTIALLY_REFUNDED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.FULL_REFUND, PaymentEvent.PARTIAL_REFUND,
                PaymentEvent.DISPUTE_OPEN);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case FULL_REFUND -> PaymentState.REFUNDED;
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── REFUND_PENDING ────────────────

public class RefundPendingStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.REFUND_PENDING; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.PARTIAL_REFUND, PaymentEvent.FULL_REFUND, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case FULL_REFUND -> PaymentState.REFUNDED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

// ──────────────── DISPUTED ────────────────

public class DisputedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() { return PaymentState.DISPUTED; }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.DISPUTE_RESOLVE, PaymentEvent.FULL_REFUND);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case DISPUTE_RESOLVE -> PaymentState.DISPUTE_RESOLVED;
            case FULL_REFUND -> PaymentState.REFUNDED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}
```

### Concrete Guards

```java
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

/**
 * Authorization expires after 7 days — cannot capture after that.
 */
public class AuthorizationExpiryGuard implements TransitionGuard {

    private static final Duration AUTH_VALIDITY = Duration.ofDays(7);

    @Override
    public boolean canTransition(Payment payment, PaymentEvent event) {
        if (event != PaymentEvent.CAPTURE) return true;
        if (payment.getCurrentState() != PaymentState.AUTHORIZED) return true;

        StateTransition authTransition = payment.getAuditTrail().stream()
                .filter(t -> t.event() == PaymentEvent.AUTHORIZE)
                .reduce((first, second) -> second)
                .orElse(null);

        if (authTransition == null) return false;

        return Duration.between(authTransition.timestamp(), Instant.now())
                       .compareTo(AUTH_VALIDITY) < 0;
    }

    @Override
    public String reason() {
        return "Authorization has expired (older than 7 days). Must re-authorize.";
    }
}

/**
 * Refund amount cannot exceed the original payment amount.
 */
public class RefundAmountGuard implements TransitionGuard {

    @Override
    public boolean canTransition(Payment payment, PaymentEvent event) {
        if (event != PaymentEvent.FULL_REFUND && event != PaymentEvent.PARTIAL_REFUND) {
            return true;
        }
        return payment.getRemainingRefundable().compareTo(BigDecimal.ZERO) > 0;
    }

    @Override
    public String reason() {
        return "Refund amount would exceed original payment — nothing remaining to refund.";
    }
}

/**
 * Airbnb-specific: Cancellation policy guard.
 * Determines if a void/refund is allowed based on the listing's cancellation policy
 * and timing relative to check-in.
 */
public class CancellationPolicyGuard implements TransitionGuard {

    @Override
    public boolean canTransition(Payment payment, PaymentEvent event) {
        if (event != PaymentEvent.VOID && event != PaymentEvent.REQUEST_REFUND) {
            return true;
        }

        // Calculate refund based on policy + timing
        BigDecimal refundAmount = payment.getCancellationPolicy()
                .calculateRefund(payment, Instant.now());

        // If policy says $0 refund, block the transition
        // (Support agent can override with FULL_REFUND directly — that skips this guard)
        return refundAmount.compareTo(BigDecimal.ZERO) > 0;
    }

    @Override
    public String reason() {
        return "Cancellation policy does not allow refund at this time. Contact support for override.";
    }
}

/**
 * Payout can only be initiated at least 24 hours after check-in.
 */
public class PayoutTimingGuard implements TransitionGuard {

    private static final Duration PAYOUT_DELAY = Duration.ofHours(24);

    @Override
    public boolean canTransition(Payment payment, PaymentEvent event) {
        if (event != PaymentEvent.INITIATE_PAYOUT) return true;

        Instant checkIn = payment.getCheckInTime();
        return Instant.now().isAfter(checkIn.plus(PAYOUT_DELAY));
    }

    @Override
    public String reason() {
        return "Host payout cannot be initiated until 24 hours after guest check-in.";
    }
}
```

### Concrete Listeners

```java
/**
 * Immutable audit log for every state transition — financial compliance.
 */
public class AuditLogListener implements StateChangeListener {

    @Override
    public void onStateChange(Payment payment, StateTransition transition) {
        // In production: write to immutable audit log table / event store
        System.out.printf("[AUDIT] Payment %s (Booking %s): %s → %s (event=%s, by=%s, at=%s)%n",
                payment.getId(),
                payment.getBookingId(),
                transition.fromState(),
                transition.toState(),
                transition.event(),
                transition.performedBy(),
                transition.timestamp()
        );
    }
}

/**
 * Notifies guest and host about payment lifecycle events.
 */
public class NotificationListener implements StateChangeListener {

    @Override
    public void onStateChange(Payment payment, StateTransition transition) {
        switch (transition.toState()) {
            case AUTHORIZED -> {
                notifyGuest(payment, "Your booking is confirmed! " +
                        payment.getTotalAmount() + " " + payment.getCurrency() + " has been authorized.");
                notifyHost(payment, "New booking confirmed! Payout of " +
                        payment.getSplitBreakdown().getHostPayout() + " " + payment.getCurrency() +
                        " will arrive 24h after check-in.");
            }
            case VOIDED ->
                notifyGuest(payment, "Your booking has been cancelled. Authorization has been released.");
            case CAPTURED ->
                notifyGuest(payment, "You've checked in! " + payment.getTotalAmount() +
                        " " + payment.getCurrency() + " has been charged.");
            case REFUNDED ->
                notifyGuest(payment, "Refund of " + payment.getRefundedAmount() +
                        " " + payment.getCurrency() + " has been processed.");
            case PARTIALLY_REFUNDED ->
                notifyGuest(payment, "Partial refund processed. Refunded so far: " +
                        payment.getRefundedAmount() + " " + payment.getCurrency());
            case SETTLED ->
                notifyHost(payment, "Payout of " + payment.getSplitBreakdown().getHostPayout() +
                        " " + payment.getCurrency() + " has been deposited to your account.");
            case DISPUTED ->
                notifyHost(payment, "A dispute has been filed on booking " +
                        payment.getBookingId() + ". We'll investigate.");
            default -> { /* no notification for terminal/internal states */ }
        }
    }

    private void notifyGuest(Payment payment, String message) {
        System.out.printf("[NOTIFY-GUEST %s] %s%n", payment.getGuestId(), message);
    }

    private void notifyHost(Payment payment, String message) {
        System.out.printf("[NOTIFY-HOST %s] %s%n", payment.getHostId(), message);
    }
}

/**
 * Updates the booking service status on payment state changes.
 */
public class BookingStatusListener implements StateChangeListener {

    @Override
    public void onStateChange(Payment payment, StateTransition transition) {
        switch (transition.toState()) {
            case AUTHORIZED ->
                System.out.printf("[BOOKING] Booking %s: status → CONFIRMED%n", payment.getBookingId());
            case VOIDED ->
                System.out.printf("[BOOKING] Booking %s: status → CANCELLED%n", payment.getBookingId());
            case CAPTURED ->
                System.out.printf("[BOOKING] Booking %s: status → CHECKED_IN%n", payment.getBookingId());
            case SETTLED ->
                System.out.printf("[BOOKING] Booking %s: status → COMPLETED%n", payment.getBookingId());
            case AUTHORIZATION_DECLINED ->
                System.out.printf("[BOOKING] Booking %s: status → PAYMENT_FAILED%n", payment.getBookingId());
            default -> { /* other states don't affect booking status */ }
        }
    }
}
```

### Custom Exceptions

```java
import java.util.Set;

public class InvalidTransitionException extends RuntimeException {

    private final PaymentState fromState;
    private final PaymentEvent event;
    private final Set<PaymentEvent> allowedEvents;

    public InvalidTransitionException(PaymentState fromState, PaymentEvent event,
                                      Set<PaymentEvent> allowedEvents) {
        super(String.format("Cannot apply event %s from state %s. Allowed events: %s",
                event, fromState, allowedEvents));
        this.fromState = fromState;
        this.event = event;
        this.allowedEvents = allowedEvents;
    }

    public PaymentState getFromState() { return fromState; }
    public PaymentEvent getEvent() { return event; }
    public Set<PaymentEvent> getAllowedEvents() { return allowedEvents; }
}

public class TransitionGuardException extends RuntimeException {

    private final String guardReason;

    public TransitionGuardException(String guardReason) {
        super("Transition blocked by guard: " + guardReason);
        this.guardReason = guardReason;
    }

    public String getGuardReason() { return guardReason; }
}
```

### PaymentStateMachine.java (Core Orchestrator)

```java
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

public class PaymentStateMachine {

    private final Map<PaymentState, PaymentStateHandler> handlers;
    private final List<TransitionGuard> guards;
    private final List<StateChangeListener> listeners;

    public PaymentStateMachine(List<PaymentStateHandler> handlerList,
                               List<TransitionGuard> guardList) {
        this.handlers = new EnumMap<>(PaymentState.class);
        for (PaymentStateHandler handler : handlerList) {
            this.handlers.put(handler.supports(), handler);
        }
        this.guards = new ArrayList<>(guardList);
        this.listeners = new CopyOnWriteArrayList<>();
    }

    /**
     * Applies an event to a payment. Core method of the state machine.
     *
     * 1. Idempotency check — if already processed, return as-is
     * 2. Find handler for current state
     * 3. Validate event is allowed for current state
     * 4. Run all guards — ALL must pass
     * 5. Execute transition
     * 6. Notify listeners
     */
    public Payment apply(Payment payment, PaymentEvent event) {
        return apply(payment, event, Map.of(), "SYSTEM");
    }

    public Payment apply(Payment payment, PaymentEvent event,
                         Map<String, String> metadata, String performedBy) {
        // 1. Idempotency check
        if (payment.hasProcessed(event)) {
            return payment;
        }

        // 2. Find handler
        PaymentState currentState = payment.getCurrentState();
        PaymentStateHandler handler = handlers.get(currentState);
        if (handler == null) {
            throw new InvalidTransitionException(currentState, event, Set.of());
        }

        // 3. Validate event is allowed
        if (!handler.allowedEvents().contains(event)) {
            throw new InvalidTransitionException(currentState, event, handler.allowedEvents());
        }

        // 4. Run guards — all must pass
        for (TransitionGuard guard : guards) {
            if (!guard.canTransition(payment, event)) {
                throw new TransitionGuardException(guard.reason());
            }
        }

        // 5. Execute transition
        PaymentState newState = handler.handle(payment, event);
        payment.transitionTo(newState, event, metadata, performedBy);

        // 6. Notify listeners (each in try-catch — one failing listener shouldn't block)
        StateTransition transition = payment.getAuditTrail().getLast();
        for (StateChangeListener listener : listeners) {
            try {
                listener.onStateChange(payment, transition);
            } catch (Exception e) {
                System.err.printf("[WARN] Listener %s failed: %s%n",
                        listener.getClass().getSimpleName(), e.getMessage());
            }
        }

        return payment;
    }

    public void registerListener(StateChangeListener listener) {
        this.listeners.add(listener);
    }

    public Set<PaymentEvent> getAllowedEvents(Payment payment) {
        PaymentStateHandler handler = handlers.get(payment.getCurrentState());
        return (handler != null) ? handler.allowedEvents() : Set.of();
    }
}
```

### Demo — Full Airbnb Booking Lifecycle

```java
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class AirbnbPaymentDemo {

    public static void main(String[] args) {

        // Wire up handlers
        List<PaymentStateHandler> handlers = List.of(
                new CreatedStateHandler(),
                new AuthorizedStateHandler(),
                new CapturedStateHandler(),
                new PayoutInitiatedStateHandler(),
                new SettledStateHandler(),
                new PartiallyRefundedStateHandler(),
                new RefundPendingStateHandler(),
                new DisputedStateHandler()
        );

        // Wire up guards
        List<TransitionGuard> guards = List.of(
                new AuthorizationExpiryGuard(),
                new RefundAmountGuard(),
                new CancellationPolicyGuard(),
                new PayoutTimingGuard()
        );

        // Create state machine
        PaymentStateMachine stateMachine = new PaymentStateMachine(handlers, guards);
        stateMachine.registerListener(new AuditLogListener());
        stateMachine.registerListener(new NotificationListener());
        stateMachine.registerListener(new BookingStatusListener());

        // ═══════════════════════════════════════════════
        // Scenario 1: Happy path — Book → Check-in → Payout
        // ═══════════════════════════════════════════════
        System.out.println("=== SCENARIO 1: Happy Path ===\n");

        Payment payment = new Payment.Builder()
                .bookingId(UUID.randomUUID())
                .guestId(UUID.randomUUID())
                .hostId(UUID.randomUUID())
                .totalAmount(new BigDecimal("1500.00"))
                .currency(Currency.USD)
                .splitBreakdown(new SplitBreakdown(
                        new BigDecimal("1200.00"),  // nightly
                        new BigDecimal("100.00"),   // cleaning
                        new BigDecimal("150.00"),   // service fee
                        new BigDecimal("50.00")     // taxes
                ))
                .cancellationPolicy(CancellationPolicy.FLEXIBLE)
                .checkInTime(Instant.now().minus(Duration.ofHours(48)))  // checked in 48h ago
                .numberOfNights(4)
                .idempotencyKey("idem-booking-001")
                .build();

        // Guest books → authorize
        stateMachine.apply(payment, PaymentEvent.AUTHORIZE,
                Map.of("psp_ref", "ch_stripe_123"), "BOOKING_SERVICE");
        System.out.println("State: " + payment.getCurrentState());

        // Guest checks in → capture
        stateMachine.apply(payment, PaymentEvent.CAPTURE,
                Map.of("psp_ref", "cap_stripe_456"), "BOOKING_SERVICE");
        System.out.println("State: " + payment.getCurrentState());

        // 24h after check-in → initiate host payout
        stateMachine.apply(payment, PaymentEvent.INITIATE_PAYOUT,
                Map.of("payout_ref", "po_stripe_789"), "PAYOUT_SCHEDULER");
        System.out.println("State: " + payment.getCurrentState());

        // Bank transfer completes → settle
        stateMachine.apply(payment, PaymentEvent.SETTLE,
                Map.of("settlement_batch", "BATCH-2026-03-11"), "PSP_WEBHOOK");
        System.out.println("State: " + payment.getCurrentState());

        System.out.println("Audit trail: " + payment.getAuditTrail().size() + " entries");

        // ═══════════════════════════════════════════════
        // Scenario 2: Idempotency test
        // ═══════════════════════════════════════════════
        System.out.println("\n=== SCENARIO 2: Idempotent Replay ===\n");

        stateMachine.apply(payment, PaymentEvent.SETTLE); // same event again — no-op
        System.out.println("State after replay: " + payment.getCurrentState()); // still SETTLED
        System.out.println("Audit trail still: " + payment.getAuditTrail().size() + " entries");

        // ═══════════════════════════════════════════════
        // Scenario 3: Invalid transition
        // ═══════════════════════════════════════════════
        System.out.println("\n=== SCENARIO 3: Invalid Transition ===\n");

        try {
            stateMachine.apply(payment, PaymentEvent.AUTHORIZE);
        } catch (InvalidTransitionException e) {
            System.out.println("Caught: " + e.getMessage());
        }

        // ═══════════════════════════════════════════════
        // Scenario 4: Cancellation → Void
        // ═══════════════════════════════════════════════
        System.out.println("\n=== SCENARIO 4: Pre-capture Cancellation (VOID) ===\n");

        Payment payment2 = new Payment.Builder()
                .bookingId(UUID.randomUUID())
                .guestId(UUID.randomUUID())
                .hostId(UUID.randomUUID())
                .totalAmount(new BigDecimal("800.00"))
                .currency(Currency.USD)
                .splitBreakdown(new SplitBreakdown(
                        new BigDecimal("600.00"),
                        new BigDecimal("50.00"),
                        new BigDecimal("100.00"),
                        new BigDecimal("50.00")
                ))
                .cancellationPolicy(CancellationPolicy.FLEXIBLE)
                .checkInTime(Instant.now().plus(Duration.ofDays(10)))  // 10 days from now
                .numberOfNights(3)
                .idempotencyKey("idem-booking-002")
                .build();

        stateMachine.apply(payment2, PaymentEvent.AUTHORIZE,
                Map.of("psp_ref", "ch_stripe_abc"), "BOOKING_SERVICE");
        System.out.println("State: " + payment2.getCurrentState()); // AUTHORIZED

        // Guest cancels 10 days before check-in (FLEXIBLE → full void)
        stateMachine.apply(payment2, PaymentEvent.VOID,
                Map.of("reason", "GUEST_CANCELLATION"), "BOOKING_SERVICE");
        System.out.println("State: " + payment2.getCurrentState()); // VOIDED
    }
}
```

---

## 12. Concurrency Considerations

### Problem: Two Events on the Same Payment Simultaneously

Example: PSP sends a CAPTURE callback while the guest initiates a VOID at the same moment. Both read `currentState = AUTHORIZED`, both pass validation, and one silently overwrites the other.

### Solution: Optimistic Locking

```java
// In the persistence layer (JPA/repository):
@Version
private long version;

// On save:
// UPDATE payments SET state = ?, version = version + 1
// WHERE id = ? AND version = ?
// If 0 rows affected → OptimisticLockException → retry or reject
```

The `version` field in `Payment` supports this. The database layer (outside LLD scope) uses optimistic locking:
- Read payment with `version = 3`
- Apply transition in-memory
- Write with `WHERE version = 3`
- If another thread already bumped to `version = 4`, the write fails → caller retries

### Why Optimistic Over Pessimistic?

- Payment state transitions are sequential by nature (one at a time per booking). Conflicts are rare.
- Pessimistic locking (`SELECT FOR UPDATE`) creates contention at Airbnb's scale (~275K bookings/day).
- Optimistic locking is costless in the common case (no conflict) and only retries in the rare conflict.

### Thread Safety in the State Machine

| Component | Thread Safe? | Why |
|---|---|---|
| `PaymentStateMachine` | Yes | Stateless — all state is in `Payment`. `handlers` map is immutable after construction. `guards` list is immutable after construction. |
| `listeners` list | Yes | `CopyOnWriteArrayList` — safe for concurrent iteration during notification + rare writes during registration. |
| `Payment.transitionTo()` | No (by design) | The `Payment` object itself is NOT thread-safe. Thread safety is enforced at the persistence layer (optimistic locking). Two threads should never be mutating the same `Payment` instance in memory. |
| Guard implementations | Yes | Stateless — read payment state, compute result, no shared mutable state. |

---

## 13. Edge Cases & Error Handling

| Edge Case | How It's Handled |
|---|---|
| **Duplicate event (idempotency)** | `hasProcessed()` checks if the last transition already processed this event → returns payment as-is, no side effects, no listener notifications |
| **Invalid transition (e.g., CAPTURE from CREATED)** | Handler's `allowedEvents()` rejects it → `InvalidTransitionException` with message listing valid events |
| **Expired authorization (>7 days)** | `AuthorizationExpiryGuard` blocks CAPTURE → `TransitionGuardException`. System must re-authorize. |
| **Refund exceeds payment amount** | `RefundAmountGuard` checks `getRemainingRefundable() > 0` → blocks if nothing remains |
| **Strict cancellation policy blocks void** | `CancellationPolicyGuard` calculates $0 refund → blocks VOID. Support agent can override with FULL_REFUND (different event path) |
| **Payout too early (<24h after check-in)** | `PayoutTimingGuard` blocks INITIATE_PAYOUT → must wait |
| **Concurrent state changes** | Optimistic locking (version field) → `OptimisticLockException` at DB layer → retry with fresh state |
| **Terminal state receives event** | Terminal states (SETTLED, REFUNDED, VOIDED, etc.) either have a limited `allowedEvents()` (SETTLED allows DISPUTE_OPEN) or no handler → `InvalidTransitionException` |
| **Listener throws exception** | Each listener call is wrapped in try-catch in the state machine. One failing listener doesn't block the transition or other listeners. Error is logged. |
| **Null/missing payment fields** | Builder validates all required fields at `build()` time → `NullPointerException` or `IllegalArgumentException` before the Payment is ever created |
| **Negative or zero amount** | Builder rejects `totalAmount <= 0` |
| **Partial refund → another partial → full** | Supported: `PARTIALLY_REFUNDED → PARTIAL_REFUND → PARTIALLY_REFUNDED` (loops on self, tracking cumulative refundedAmount). Then `PARTIALLY_REFUNDED → FULL_REFUND → REFUNDED`. `RefundAmountGuard` prevents over-refunding. |
| **Cancellation policy not set** | Builder requires `cancellationPolicy` → `NullPointerException` at build time |

---

## State Transition Matrix (Reference)

| From \ Event | AUTHORIZE | AUTH_DECLINED | CAPTURE | VOID | REQ_REFUND | PARTIAL_REFUND | FULL_REFUND | INIT_PAYOUT | SETTLE | DISPUTE_OPEN | DISPUTE_RESOLVE | FAIL |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **CREATED** | AUTHORIZED | AUTH_DECLINED | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | FAILED |
| **AUTHORIZED** | ✗ | ✗ | CAPTURED | VOIDED | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | FAILED |
| **CAPTURED** | ✗ | ✗ | ✗ | ✗ | REFUND_PEND | PARTIAL_REF | REFUNDED | PAYOUT_INIT | ✗ | DISPUTED | ✗ | FAILED |
| **PAYOUT_INIT** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | SETTLED | DISPUTED | ✗ | FAILED |
| **SETTLED** | ✗ | ✗ | ✗ | ✗ | ✗ | PARTIAL_REF | REFUNDED | ✗ | ✗ | DISPUTED | ✗ | ✗ |
| **REFUND_PEND** | ✗ | ✗ | ✗ | ✗ | ✗ | PARTIAL_REF | REFUNDED | ✗ | ✗ | ✗ | ✗ | FAILED |
| **PARTIAL_REF** | ✗ | ✗ | ✗ | ✗ | ✗ | PARTIAL_REF | REFUNDED | ✗ | ✗ | DISPUTED | ✗ | ✗ |
| **DISPUTED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | REFUNDED | ✗ | ✗ | ✗ | DISP_RESOLVED | ✗ |
| **AUTH_DECLINED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **VOIDED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **REFUNDED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **FAILED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **DISP_RESOLVED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |

---

## Appendix: Technology Choices

| Layer | Technology | Notes |
|---|---|---|
| Language | Java 21 | `record` for StateTransition, `switch` expressions in handlers, `List.getLast()` |
| DI | Spring Boot 3.x | Handlers, guards, listeners registered as Spring beans and auto-injected |
| Persistence | JPA + PostgreSQL | `@Version` for optimistic locking, `@Enumerated` for state/event columns |
| Audit Store | Append-only table / Event Store | `ledger_entries` table — INSERT only, never UPDATE/DELETE |
| Concurrency | Optimistic locking | Via JPA `@Version` — no explicit locks in Java code |
