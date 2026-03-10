# LLD — Design a Payment State Machine

> **Company:** PayPal  
> **Level:** Staff Software Engineer — Backend  
> **Patterns:** State Pattern, Observer Pattern, Strategy Pattern  
> **Difficulty:** Medium-High  

---

## Assumptions

- We're designing the **core domain model** for a payment's lifecycle, not the full distributed system
- A payment moves through well-defined states: `CREATED → AUTHORIZED → CAPTURED → SETTLED → REFUNDED/DISPUTED`
- State transitions are triggered by external events (user actions, processor callbacks, cron jobs)
- Transitions must be **idempotent** — replaying the same event on the same state = no-op
- Concurrent transition attempts on the same payment must be handled safely
- Each transition is logged as an immutable audit event (compliance requirement for PayPal-scale fintech)

---

## 1. Requirements Clarification

**What are we designing?**

A payment state machine that models the full lifecycle of a payment transaction — from creation through settlement, including refund and dispute paths.

**Scope:**
- **Included:** State definitions, valid transitions, transition rules/guards, idempotency, audit logging, event notification, concurrent state change safety
- **Excluded:** Actual payment processor integration, database persistence layer, REST API layer, distributed coordination (those are HLD concerns)

**Functional Requirements:**
- Define all valid payment states and transitions between them
- Enforce that only valid transitions are allowed (e.g., can't go from CREATED directly to SETTLED)
- Each state can have entry/exit behavior (e.g., on entering AUTHORIZED, reserve funds)
- Transitions are idempotent — same event applied to same state produces same result without side effects
- Every transition is recorded as an immutable audit event
- Observers are notified on state changes (e.g., notification service, analytics)
- Support partial refunds (payment can be partially refunded, then fully refunded)

---

## 2. Use Cases / Actors

| Actor | Use Cases |
|---|---|
| **Customer** | Initiates payment (→ CREATED), requests refund (→ REFUND_REQUESTED), files dispute (→ DISPUTED) |
| **Merchant** | Authorizes payment (→ AUTHORIZED), captures payment (→ CAPTURED) |
| **Payment Processor** | Confirms authorization, confirms capture, confirms settlement, rejects payment |
| **Settlement System** | Settles captured payments nightly (→ SETTLED) |
| **Dispute System** | Opens dispute, resolves dispute (→ DISPUTE_RESOLVED) |
| **Admin** | Force-transitions (e.g., manual refund), views audit trail |

---

## 3. Core Entities

| Entity | Attributes | Types |
|---|---|---|
| **Payment** | id, amount, currency, currentState, createdAt, updatedAt, merchantId, customerId, idempotencyKey, version | UUID, BigDecimal, Currency, PaymentState, Instant, Instant, UUID, UUID, String, long |
| **PaymentState** (enum) | CREATED, AUTHORIZED, CAPTURED, SETTLED, REFUNDED, PARTIALLY_REFUNDED, DECLINED, CANCELLED, DISPUTED, DISPUTE_RESOLVED, FAILED | enum constants |
| **PaymentEvent** (enum) | AUTHORIZE, AUTHORIZE_DECLINED, CAPTURE, SETTLE, REFUND, PARTIAL_REFUND, CANCEL, DISPUTE_OPEN, DISPUTE_RESOLVE, FAIL | enum constants |
| **StateTransition** | fromState, toState, event, timestamp, metadata, performedBy | PaymentState, PaymentState, PaymentEvent, Instant, Map, String |
| **TransitionGuard** | — (interface) | boolean canTransition(Payment, PaymentEvent) |
| **StateAction** | — (interface) | void execute(Payment, StateTransition) |

---

## 4. Class Diagram

```
                            ┌─────────────────────────┐
                            │     «interface»          │
                            │   PaymentStateHandler    │
                            ├─────────────────────────┤
                            │ + handle(Payment,        │
                            │     PaymentEvent): void  │
                            │ + supports(): PaymentState│
                            └────────────┬────────────┘
                                         │
                     ┌───────────────────┼───────────────────┐
                     │                   │                   │
              ┌──────▼──────┐    ┌───────▼───────┐  ┌───────▼────────┐
              │ CreatedState │    │AuthorizedState│  │ CapturedState  │  ... (one per state)
              │   Handler    │    │   Handler     │  │   Handler      │
              └──────────────┘    └───────────────┘  └────────────────┘

  ┌──────────────────┐         ┌──────────────────────┐
  │    Payment        │◆───────│  List<StateTransition>│  (audit trail)
  ├──────────────────┤         └──────────────────────┘
  │ - id: UUID        │
  │ - amount: BigDec  │    1        1
  │ - currentState    │────────────────┐
  │ - version: long   │               │
  └──────────────────┘               │
                                      ▼
  ┌─────────────────────────────────────────────┐
  │           PaymentStateMachine                │
  ├─────────────────────────────────────────────┤
  │ - handlers: Map<PaymentState, Handler>       │
  │ - guards: List<TransitionGuard>              │
  │ - listeners: List<StateChangeListener>       │
  ├─────────────────────────────────────────────┤
  │ + apply(Payment, PaymentEvent): Payment      │
  │ + registerListener(StateChangeListener): void│
  └─────────────────────────────────────────────┘
           │                          │
           ▼                          ▼
  ┌──────────────────┐     ┌──────────────────────┐
  │ «interface»       │     │   «interface»         │
  │ TransitionGuard   │     │ StateChangeListener   │
  ├──────────────────┤     ├──────────────────────┤
  │ + canTransition() │     │ + onStateChange()     │
  └──────────────────┘     └──────────────────────┘
           │                          │
     ┌─────┴──────┐            ┌─────┴───────┐
     │AmountGuard  │            │AuditListener │
     │ExpiryGuard  │            │NotifyListener│
     └────────────┘            └─────────────┘
```

**Relationships:**
- `Payment` **has-a** list of `StateTransition` (composition, 1-to-many)
- `PaymentStateMachine` **has-many** `PaymentStateHandler` (aggregation, 1-to-many, one per state)
- `PaymentStateMachine` **has-many** `TransitionGuard` (aggregation, 1-to-many)
- `PaymentStateMachine` **has-many** `StateChangeListener` (aggregation, 1-to-many)
- Each `PaymentStateHandler` **implements** the state-specific logic for one `PaymentState`

---

## 5. Interfaces & Abstract Classes

### PaymentStateHandler (Strategy — one per state)

```java
/**
 * Each payment state has a handler that knows what events are valid
 * and how to transition. This replaces massive if-else/switch blocks
 * with polymorphism.
 */
public interface PaymentStateHandler {
    PaymentState supports();
    PaymentState handle(Payment payment, PaymentEvent event);
    Set<PaymentEvent> allowedEvents();
}
```

**Justification:** Without this, you'd have a giant switch statement with `(currentState, event)` pairs. Adding a new state means modifying a monolithic block. With this interface, each state is its own class — adding a new state = adding a new class. Open/Closed Principle.

### TransitionGuard (Chain of validations before transition)

```java
/**
 * Guards check preconditions before a transition is allowed.
 * e.g., "Can only capture if amount > 0 and authorization hasn't expired."
 * Multiple guards can be composed — ALL must pass.
 */
public interface TransitionGuard {
    boolean canTransition(Payment payment, PaymentEvent event);
    String reason();
}
```

**Justification:** Separates validation logic from transition logic. Guards are composable — add new business rules without modifying state handlers. Single Responsibility.

### StateChangeListener (Observer — decoupled reactions)

```java
/**
 * Observers get notified after a state change is committed.
 * Used for audit logging, notifications, analytics — without
 * coupling those concerns into the state machine itself.
 */
public interface StateChangeListener {
    void onStateChange(Payment payment, StateTransition transition);
}
```

**Justification:** The state machine shouldn't know about audit logs, notifications, or analytics. Observer pattern keeps these concerns decoupled. Adding a new side-effect = adding a new listener.

---

## 6. Method Signatures

```java
public class PaymentStateMachine {

    /**
     * Applies an event to a payment, triggering a state transition if valid.
     *
     * @param payment the current payment entity
     * @param event   the event to apply
     * @return the updated payment with new state
     * @throws InvalidTransitionException if the event is not valid for the current state
     * @throws TransitionGuardException   if a guard rejects the transition
     * @throws ConcurrentModificationException if optimistic lock fails (version mismatch)
     */
    public Payment apply(Payment payment, PaymentEvent event);

    /**
     * Registers a listener to be notified on state changes.
     *
     * @param listener the listener to register
     */
    public void registerListener(StateChangeListener listener);

    /**
     * Returns all events valid for the payment's current state.
     *
     * @param payment the payment to inspect
     * @return set of allowed events
     */
    public Set<PaymentEvent> getAllowedEvents(Payment payment);
}

public class Payment {

    /**
     * Transitions to a new state and records the transition in the audit trail.
     * Package-private — only the state machine should call this.
     *
     * @param newState   the target state
     * @param event      the triggering event
     * @param metadata   additional context (processor response code, admin notes, etc.)
     * @param performedBy who triggered (system, user ID, admin ID)
     */
    void transitionTo(PaymentState newState, PaymentEvent event,
                      Map<String, String> metadata, String performedBy);

    /**
     * Checks if this payment has already processed this idempotency key + event.
     *
     * @param event the event to check
     * @return true if this event was already applied (idempotent — skip)
     */
    public boolean hasProcessed(PaymentEvent event);

    /**
     * Returns the full audit trail of state transitions.
     *
     * @return unmodifiable list of transitions ordered by timestamp
     */
    public List<StateTransition> getAuditTrail();
}
```

---

## 7. Enums & Constants

```java
public enum PaymentState {
    CREATED("Payment initiated, awaiting authorization"),
    AUTHORIZED("Funds reserved with processor"),
    CAPTURED("Funds captured from customer's account"),
    SETTLED("Funds transferred to merchant"),
    REFUNDED("Full refund issued to customer"),
    PARTIALLY_REFUNDED("Partial refund issued"),
    DECLINED("Authorization declined by processor"),
    CANCELLED("Payment cancelled before capture"),
    DISPUTED("Customer filed a chargeback/dispute"),
    DISPUTE_RESOLVED("Dispute resolved (won or lost)"),
    FAILED("Terminal failure — unrecoverable");

    private final String description;

    PaymentState(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }

    public boolean isTerminal() {
        return this == SETTLED || this == REFUNDED || this == DECLINED
                || this == CANCELLED || this == FAILED || this == DISPUTE_RESOLVED;
    }
}

public enum PaymentEvent {
    AUTHORIZE,
    AUTHORIZE_DECLINED,
    CAPTURE,
    SETTLE,
    REFUND,
    PARTIAL_REFUND,
    CANCEL,
    DISPUTE_OPEN,
    DISPUTE_RESOLVE,
    FAIL
}

public enum Currency {
    USD, EUR, GBP, INR, AUD, CAD, JPY, SGD
}
```

---

## 8. Design Patterns

### 1. State Pattern

**Problem:** A payment behaves differently depending on its current state. A CREATED payment can be authorized or cancelled, but not settled. A CAPTURED payment can be settled or refunded, but not authorized.

**Naive approach:** A giant `switch(currentState)` with nested `switch(event)` — quickly becomes unmaintainable as states/events grow.

**Solution:** Each state is encapsulated in its own `PaymentStateHandler` class. The state machine delegates to the handler for the current state. Adding a new state is adding a new class — zero modification to existing code.

### 2. Observer Pattern

**Problem:** After a state transition, multiple things need to happen — audit log, send notification, update analytics, trigger downstream workflows. Putting all of this in the state machine couples unrelated concerns.

**Solution:** `StateChangeListener` interface. Listeners register with the state machine and get notified on every transition. The state machine doesn't know what listeners exist or what they do.

### 3. Strategy Pattern (via Guards)

**Problem:** Transition validation rules change independently from transition logic. "Authorization expires after 7 days" is a business rule that might change. "Can only capture if authorized amount >= capture amount" is another.

**Solution:** `TransitionGuard` as a strategy. Each guard encapsulates one rule. Guards are composed (all must pass). Adding a new business rule = adding a new guard class.

### 4. Builder Pattern (for Payment creation)

**Problem:** Payment has many fields, some optional (metadata, idempotencyKey). Telescoping constructors are unreadable.

**Solution:** Use a Builder for constructing Payment objects with clear, fluent syntax.

---

## 9. SOLID Principles

| Principle | Application |
|---|---|
| **S — Single Responsibility** | `PaymentStateHandler` handles transitions for ONE state only. `TransitionGuard` validates ONE rule. `StateChangeListener` handles ONE side-effect. The `Payment` entity only manages its own data and audit trail — it doesn't know about the state machine. |
| **O — Open/Closed** | Adding a new state (e.g., `ON_HOLD`) = new handler class. Adding a new guard = new guard class. Adding a new listener = new listener class. **Zero modification** to existing classes. The state machine is closed for modification, open for extension. |
| **L — Liskov Substitution** | All `PaymentStateHandler` implementations are interchangeable from the state machine's perspective. It calls `handler.handle(payment, event)` without knowing or caring which concrete handler it is. |
| **I — Interface Segregation** | `TransitionGuard` is a focused interface (one method: `canTransition`). `StateChangeListener` is a focused interface (one method: `onStateChange`). No client is forced to implement methods it doesn't need. |
| **D — Dependency Inversion** | `PaymentStateMachine` depends on abstractions (`PaymentStateHandler`, `TransitionGuard`, `StateChangeListener`) — not on concrete implementations. Concrete handlers/guards/listeners are injected (via constructor or registration), not hardcoded. |

---

## 10. Sequence Diagrams

### Flow 1: Authorize a Payment (Happy Path)

```
Customer              API Layer         PaymentStateMachine       CreatedStateHandler       Guards              Listeners
   │                     │                     │                        │                     │                    │
   │─── POST /pay ──────▶│                     │                        │                     │                    │
   │                     │── apply(payment,    │                        │                     │                    │
   │                     │   AUTHORIZE) ──────▶│                        │                     │                    │
   │                     │                     │── getHandler(CREATED)─▶│                     │                    │
   │                     │                     │                        │                     │                    │
   │                     │                     │── checkGuards() ──────────────────────────▶│                    │
   │                     │                     │                        │                     │── canTransition()  │
   │                     │                     │                        │                     │── returns true ───▶│
   │                     │                     │                        │                     │                    │
   │                     │                     │── handler.handle(payment, AUTHORIZE) ─────▶│                    │
   │                     │                     │                        │── returns AUTHORIZED │                    │
   │                     │                     │                        │                     │                    │
   │                     │                     │── payment.transitionTo(AUTHORIZED) ─────────────────────────────│
   │                     │                     │                        │                     │                    │
   │                     │                     │── notifyListeners(transition) ──────────────────────────────────▶│
   │                     │                     │                        │                     │  AuditListener:    │
   │                     │                     │                        │                     │  log transition    │
   │                     │                     │                        │                     │  NotifyListener:   │
   │                     │                     │                        │                     │  send notification │
   │                     │                     │                        │                     │                    │
   │                     │◀── updated payment ─│                        │                     │                    │
   │◀── 200 OK ─────────│                     │                        │                     │                    │
```

### Flow 2: Idempotent Replay (Same Event Arrives Twice)

```
Processor Callback     PaymentStateMachine         Payment
       │                      │                       │
       │── apply(payment,     │                       │
       │   AUTHORIZE) ──────▶│                       │
       │                      │── payment.hasProcessed(AUTHORIZE)? ──▶│
       │                      │                       │── checks last transition
       │                      │                       │── event=AUTHORIZE, state already AUTHORIZED
       │                      │◀── returns true ──────│
       │                      │                       │
       │◀── return payment    │  (no-op, no side      │
       │    as-is             │   effects, no          │
       │                      │   listeners fired)     │
```

### Flow 3: Invalid Transition (Capture on CREATED — skips AUTHORIZED)

```
Merchant               PaymentStateMachine       CreatedStateHandler
   │                          │                        │
   │── apply(payment,         │                        │
   │   CAPTURE) ─────────────▶│                        │
   │                          │── getHandler(CREATED)─▶│
   │                          │                        │── allowedEvents()
   │                          │                        │── returns {AUTHORIZE, CANCEL, FAIL}
   │                          │                        │── CAPTURE not in set
   │                          │                        │
   │◀── InvalidTransitionException("Cannot CAPTURE from CREATED. Allowed: [AUTHORIZE, CANCEL, FAIL]")
   │                          │                        │
```

---

## 11. Java Code

### Payment.java

```java
import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

public class Payment {

    private final UUID id;
    private final BigDecimal amount;
    private final Currency currency;
    private final UUID merchantId;
    private final UUID customerId;
    private final String idempotencyKey;
    private final Instant createdAt;

    private PaymentState currentState;
    private Instant updatedAt;
    private long version; // optimistic locking
    private BigDecimal refundedAmount;
    private final List<StateTransition> auditTrail;

    private Payment(Builder builder) {
        this.id = builder.id;
        this.amount = builder.amount;
        this.currency = builder.currency;
        this.merchantId = builder.merchantId;
        this.customerId = builder.customerId;
        this.idempotencyKey = builder.idempotencyKey;
        this.createdAt = Instant.now();
        this.updatedAt = this.createdAt;
        this.currentState = PaymentState.CREATED;
        this.version = 0;
        this.refundedAmount = BigDecimal.ZERO;
        this.auditTrail = new ArrayList<>();
    }

    // --- State transition (package-private) ---

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
        StateTransition last = auditTrail.get(auditTrail.size() - 1);
        return last.event() == event && last.toState() == this.currentState;
    }

    // --- Refund tracking ---

    public void addRefundedAmount(BigDecimal refund) {
        this.refundedAmount = this.refundedAmount.add(refund);
    }

    public BigDecimal getRemainingRefundable() {
        return this.amount.subtract(this.refundedAmount);
    }

    // --- Getters ---

    public UUID getId() { return id; }
    public BigDecimal getAmount() { return amount; }
    public Currency getCurrency() { return currency; }
    public UUID getMerchantId() { return merchantId; }
    public UUID getCustomerId() { return customerId; }
    public String getIdempotencyKey() { return idempotencyKey; }
    public PaymentState getCurrentState() { return currentState; }
    public Instant getCreatedAt() { return createdAt; }
    public Instant getUpdatedAt() { return updatedAt; }
    public long getVersion() { return version; }
    public BigDecimal getRefundedAmount() { return refundedAmount; }

    public List<StateTransition> getAuditTrail() {
        return Collections.unmodifiableList(auditTrail);
    }

    // --- Builder ---

    public static class Builder {
        private UUID id = UUID.randomUUID();
        private BigDecimal amount;
        private Currency currency;
        private UUID merchantId;
        private UUID customerId;
        private String idempotencyKey;

        public Builder amount(BigDecimal amount) { this.amount = amount; return this; }
        public Builder currency(Currency currency) { this.currency = currency; return this; }
        public Builder merchantId(UUID merchantId) { this.merchantId = merchantId; return this; }
        public Builder customerId(UUID customerId) { this.customerId = customerId; return this; }
        public Builder idempotencyKey(String key) { this.idempotencyKey = key; return this; }

        public Payment build() {
            Objects.requireNonNull(amount, "amount is required");
            Objects.requireNonNull(currency, "currency is required");
            Objects.requireNonNull(merchantId, "merchantId is required");
            Objects.requireNonNull(customerId, "customerId is required");
            if (amount.compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("amount must be positive");
            }
            return new Payment(this);
        }
    }
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

### Concrete State Handlers

```java
import java.util.Set;

public class CreatedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.CREATED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.AUTHORIZE, PaymentEvent.AUTHORIZE_DECLINED,
                      PaymentEvent.CANCEL, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case AUTHORIZE -> PaymentState.AUTHORIZED;
            case AUTHORIZE_DECLINED -> PaymentState.DECLINED;
            case CANCEL -> PaymentState.CANCELLED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

public class AuthorizedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.AUTHORIZED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.CAPTURE, PaymentEvent.CANCEL, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case CAPTURE -> PaymentState.CAPTURED;
            case CANCEL -> PaymentState.CANCELLED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

public class CapturedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.CAPTURED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.SETTLE, PaymentEvent.REFUND,
                      PaymentEvent.PARTIAL_REFUND, PaymentEvent.DISPUTE_OPEN, PaymentEvent.FAIL);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case SETTLE -> PaymentState.SETTLED;
            case REFUND -> PaymentState.REFUNDED;
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            case FAIL -> PaymentState.FAILED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

public class SettledStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.SETTLED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.REFUND, PaymentEvent.PARTIAL_REFUND,
                      PaymentEvent.DISPUTE_OPEN);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case REFUND -> PaymentState.REFUNDED;
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

public class PartiallyRefundedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.PARTIALLY_REFUNDED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.REFUND, PaymentEvent.PARTIAL_REFUND, PaymentEvent.DISPUTE_OPEN);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case REFUND -> PaymentState.REFUNDED;
            case PARTIAL_REFUND -> PaymentState.PARTIALLY_REFUNDED;
            case DISPUTE_OPEN -> PaymentState.DISPUTED;
            default -> throw new InvalidTransitionException(
                    payment.getCurrentState(), event, allowedEvents());
        };
    }
}

public class DisputedStateHandler implements PaymentStateHandler {

    @Override
    public PaymentState supports() {
        return PaymentState.DISPUTED;
    }

    @Override
    public Set<PaymentEvent> allowedEvents() {
        return Set.of(PaymentEvent.DISPUTE_RESOLVE, PaymentEvent.REFUND);
    }

    @Override
    public PaymentState handle(Payment payment, PaymentEvent event) {
        return switch (event) {
            case DISPUTE_RESOLVE -> PaymentState.DISPUTE_RESOLVED;
            case REFUND -> PaymentState.REFUNDED;
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
        if (event != PaymentEvent.CAPTURE) {
            return true; // this guard only applies to capture
        }
        if (payment.getCurrentState() != PaymentState.AUTHORIZED) {
            return true;
        }
        StateTransition authTransition = payment.getAuditTrail().stream()
                .filter(t -> t.event() == PaymentEvent.AUTHORIZE)
                .reduce((first, second) -> second) // last AUTHORIZE transition
                .orElse(null);

        if (authTransition == null) {
            return false;
        }
        return Duration.between(authTransition.timestamp(), Instant.now())
                       .compareTo(AUTH_VALIDITY) < 0;
    }

    @Override
    public String reason() {
        return "Authorization has expired (older than 7 days)";
    }
}

/**
 * Refund amount cannot exceed the original payment amount.
 */
public class RefundAmountGuard implements TransitionGuard {

    @Override
    public boolean canTransition(Payment payment, PaymentEvent event) {
        if (event != PaymentEvent.REFUND && event != PaymentEvent.PARTIAL_REFUND) {
            return true;
        }
        return payment.getRemainingRefundable().compareTo(BigDecimal.ZERO) > 0;
    }

    @Override
    public String reason() {
        return "Refund amount would exceed original payment amount";
    }
}
```

### Concrete Listeners

```java
import java.time.Instant;

public class AuditLogListener implements StateChangeListener {

    @Override
    public void onStateChange(Payment payment, StateTransition transition) {
        // In production: write to an immutable audit log table / event store
        System.out.printf("[AUDIT] Payment %s: %s → %s (event=%s, by=%s, at=%s)%n",
                payment.getId(),
                transition.fromState(),
                transition.toState(),
                transition.event(),
                transition.performedBy(),
                transition.timestamp()
        );
    }
}

public class NotificationListener implements StateChangeListener {

    @Override
    public void onStateChange(Payment payment, StateTransition transition) {
        // In production: publish to notification service via Kafka
        switch (transition.toState()) {
            case AUTHORIZED -> notifyMerchant(payment, "Payment authorized — ready to capture");
            case CAPTURED -> notifyCustomer(payment, "Payment of " + payment.getAmount() + " " + payment.getCurrency() + " captured");
            case REFUNDED -> notifyCustomer(payment, "Refund processed for " + payment.getAmount() + " " + payment.getCurrency());
            case DECLINED -> notifyCustomer(payment, "Payment was declined");
            case DISPUTED -> notifyMerchant(payment, "Dispute filed on payment " + payment.getId());
            default -> { /* no notification for other states */ }
        }
    }

    private void notifyCustomer(Payment payment, String message) {
        System.out.printf("[NOTIFY-CUSTOMER %s] %s%n", payment.getCustomerId(), message);
    }

    private void notifyMerchant(Payment payment, String message) {
        System.out.printf("[NOTIFY-MERCHANT %s] %s%n", payment.getMerchantId(), message);
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
        this.listeners = new CopyOnWriteArrayList<>(); // thread-safe for listener registration
    }

    /**
     * Applies an event to a payment. Core method of the state machine.
     *
     * Steps:
     * 1. Idempotency check — if already processed, return as-is
     * 2. Find handler for current state
     * 3. Validate event is allowed for current state
     * 4. Run all guards — all must pass
     * 5. Execute transition
     * 6. Notify listeners
     */
    public Payment apply(Payment payment, PaymentEvent event) {
        return apply(payment, event, Map.of(), "SYSTEM");
    }

    public Payment apply(Payment payment, PaymentEvent event,
                         Map<String, String> metadata, String performedBy) {
        // 1. Idempotency — same event on same state = no-op
        if (payment.hasProcessed(event)) {
            return payment;
        }

        // 2. Get handler for current state
        PaymentState currentState = payment.getCurrentState();
        PaymentStateHandler handler = handlers.get(currentState);
        if (handler == null) {
            throw new InvalidTransitionException(currentState, event, Set.of());
        }

        // 3. Check event is allowed
        if (!handler.allowedEvents().contains(event)) {
            throw new InvalidTransitionException(currentState, event, handler.allowedEvents());
        }

        // 4. Run guards
        for (TransitionGuard guard : guards) {
            if (!guard.canTransition(payment, event)) {
                throw new TransitionGuardException(guard.reason());
            }
        }

        // 5. Execute transition
        PaymentState newState = handler.handle(payment, event);
        payment.transitionTo(newState, event, metadata, performedBy);

        // 6. Notify listeners
        StateTransition transition = payment.getAuditTrail()
                .get(payment.getAuditTrail().size() - 1);
        for (StateChangeListener listener : listeners) {
            listener.onStateChange(payment, transition);
        }

        return payment;
    }

    public void registerListener(StateChangeListener listener) {
        this.listeners.add(listener);
    }

    public Set<PaymentEvent> getAllowedEvents(Payment payment) {
        PaymentStateHandler handler = handlers.get(payment.getCurrentState());
        if (handler == null) {
            return Set.of();
        }
        return handler.allowedEvents();
    }
}
```

### Putting It All Together — Demo

```java
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class PaymentStateMachineDemo {

    public static void main(String[] args) {

        // Wire up handlers (in production: Spring @Bean or DI container)
        List<PaymentStateHandler> handlers = List.of(
                new CreatedStateHandler(),
                new AuthorizedStateHandler(),
                new CapturedStateHandler(),
                new SettledStateHandler(),
                new PartiallyRefundedStateHandler(),
                new DisputedStateHandler()
        );

        // Wire up guards
        List<TransitionGuard> guards = List.of(
                new AuthorizationExpiryGuard(),
                new RefundAmountGuard()
        );

        // Create state machine
        PaymentStateMachine stateMachine = new PaymentStateMachine(handlers, guards);
        stateMachine.registerListener(new AuditLogListener());
        stateMachine.registerListener(new NotificationListener());

        // Create a payment
        Payment payment = new Payment.Builder()
                .amount(new BigDecimal("150.00"))
                .currency(Currency.USD)
                .merchantId(UUID.randomUUID())
                .customerId(UUID.randomUUID())
                .idempotencyKey("idem-123")
                .build();

        System.out.println("=== Happy Path: CREATED → AUTHORIZED → CAPTURED → SETTLED ===\n");

        stateMachine.apply(payment, PaymentEvent.AUTHORIZE,
                Map.of("processor_ref", "AUTH-9876"), "PAYMENT_PROCESSOR");

        stateMachine.apply(payment, PaymentEvent.CAPTURE,
                Map.of("processor_ref", "CAP-5432"), "MERCHANT_API");

        stateMachine.apply(payment, PaymentEvent.SETTLE,
                Map.of("settlement_batch", "BATCH-2026-03-09"), "SETTLEMENT_CRON");

        System.out.println("\nFinal state: " + payment.getCurrentState());
        System.out.println("Audit trail size: " + payment.getAuditTrail().size());

        // --- Idempotency demo ---
        System.out.println("\n=== Idempotency: Replaying SETTLE on already-SETTLED payment ===\n");
        stateMachine.apply(payment, PaymentEvent.SETTLE); // should be no-op
        System.out.println("State after replay: " + payment.getCurrentState()); // still SETTLED

        // --- Invalid transition demo ---
        System.out.println("\n=== Invalid Transition: Try AUTHORIZE on SETTLED payment ===\n");
        try {
            stateMachine.apply(payment, PaymentEvent.AUTHORIZE);
        } catch (InvalidTransitionException e) {
            System.out.println("Caught: " + e.getMessage());
        }
    }
}
```

---

## 12. Concurrency Considerations

### Problem: Two Threads Trying to Transition the Same Payment

Imagine two processor callbacks arrive simultaneously: one trying to CAPTURE and another trying to CANCEL the same AUTHORIZED payment. Without protection, both could read `currentState = AUTHORIZED`, both pass validation, and one overwrites the other.

### Solution: Optimistic Locking

```java
// In the persistence layer (JPA / repository):
@Version
private long version;

// On save:
// UPDATE payments SET state = ?, version = version + 1
// WHERE id = ? AND version = ?
// If 0 rows affected → ConcurrentModificationException → retry
```

The `version` field on `Payment` supports this. The database layer (not shown — LLD scope is the domain model) uses optimistic locking:
- Read payment with `version = 5`
- Apply transition in-memory
- Write back with `WHERE version = 5`
- If another thread already incremented to `version = 6`, the write fails → caller retries or rejects

### Why Optimistic Over Pessimistic Locking?

- Payments are high-throughput at PayPal. Pessimistic locks (SELECT FOR UPDATE) create contention.
- Conflicts are rare — most payments have one transition at a time (sequential lifecycle).
- Optimistic locking is cheaper in the common case and only pays the retry cost in the rare conflict case.

### Thread Safety in the State Machine

- `PaymentStateMachine` itself is **stateless** — all state lives in the `Payment` object. Safe to share across threads.
- `handlers` map is initialized once in constructor, never modified. Safe for concurrent reads.
- `listeners` list uses `CopyOnWriteArrayList` — safe for concurrent iteration + rare writes (listener registration).
- `guards` list is initialized once in constructor. Immutable after construction.

---

## 13. Edge Cases & Error Handling

| Edge Case | How It's Handled |
|---|---|
| **Duplicate event (idempotency)** | `hasProcessed()` checks if the last transition already processed this event → returns payment as-is, no side effects |
| **Invalid transition** | Handler's `allowedEvents()` rejects it → `InvalidTransitionException` with clear message listing valid events |
| **Expired authorization** | `AuthorizationExpiryGuard` blocks CAPTURE if >7 days since AUTHORIZE → `TransitionGuardException` |
| **Refund exceeds payment amount** | `RefundAmountGuard` checks `getRemainingRefundable()` → blocks if ≤ 0 |
| **Concurrent state change** | Optimistic locking (version field) → `ConcurrentModificationException` at DB layer → caller retries |
| **Terminal state receives event** | Terminal states (SETTLED, REFUNDED, DECLINED, etc.) have limited or empty `allowedEvents()`. SETTLED allows REFUND/DISPUTE but not AUTHORIZE. Fully terminal states (FAILED, CANCELLED) have no handler → exception |
| **Null/missing payment fields** | Builder validates required fields (`amount`, `currency`, `merchantId`, `customerId`) at build time → `NullPointerException` or `IllegalArgumentException` |
| **Negative amount** | Builder rejects `amount <= 0` |
| **Unknown state (no handler)** | `apply()` checks `handlers.get(currentState)` → null → `InvalidTransitionException` |
| **Listener throws exception** | Currently propagates up. In production, wrap each listener call in try-catch and log — one failing listener shouldn't block the transition. Consider `CompletableFuture.runAsync()` for non-critical listeners. |
| **Partial refund → full refund** | Supported: `PARTIALLY_REFUNDED` → `REFUND` transitions to `REFUNDED`. Track `refundedAmount` to prevent over-refunding. |

---

## State Transition Matrix (Reference)

| From \ Event | AUTHORIZE | AUTH_DECLINED | CAPTURE | SETTLE | REFUND | PARTIAL_REFUND | CANCEL | DISPUTE_OPEN | DISPUTE_RESOLVE | FAIL |
|---|---|---|---|---|---|---|---|---|---|---|
| **CREATED** | AUTHORIZED | DECLINED | ✗ | ✗ | ✗ | ✗ | CANCELLED | ✗ | ✗ | FAILED |
| **AUTHORIZED** | ✗ | ✗ | CAPTURED | ✗ | ✗ | ✗ | CANCELLED | ✗ | ✗ | FAILED |
| **CAPTURED** | ✗ | ✗ | ✗ | SETTLED | REFUNDED | PARTIAL_REF | ✗ | DISPUTED | ✗ | FAILED |
| **SETTLED** | ✗ | ✗ | ✗ | ✗ | REFUNDED | PARTIAL_REF | ✗ | DISPUTED | ✗ | ✗ |
| **PARTIAL_REF** | ✗ | ✗ | ✗ | ✗ | REFUNDED | PARTIAL_REF | ✗ | DISPUTED | ✗ | ✗ |
| **DISPUTED** | ✗ | ✗ | ✗ | ✗ | REFUNDED | ✗ | ✗ | ✗ | DISPUTE_RESOLVED | ✗ |
| **REFUNDED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **DECLINED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **CANCELLED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **FAILED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| **DISP_RESOLVED** | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
