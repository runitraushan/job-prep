# LLD Review Checklist

> Use this checklist to evaluate a Low-Level Design document for interview readiness.

| # | Section | What a Strong Answer Includes | Red Flags If Missing |
|---|---------|-------------------------------|----------------------|
| 1 | **Requirements Clarification** | Scope boundaries (included/excluded), functional requirements as bullets, stated assumptions | Jumped straight to classes → didn't scope the problem |
| 2 | **Use Cases / Actors** | All actors (User, Admin, System), key use cases per actor, helps drive the class design | No use cases → classes designed in a vacuum |
| 3 | **Core Entities / Classes** | Key objects with attributes + types, presented as table or list, captures domain correctly | Missing entities → incomplete domain model |
| 4 | **Class Diagram** | All classes with relationships (inheritance, composition, aggregation), cardinality (1:1, 1:N, N:M) | No relationships → just a bag of unconnected classes |
| 5 | **Interfaces & Abstractions** | Key interfaces/abstract classes, why each abstraction exists (justification), method signatures | No interfaces → tightly coupled, can't extend |
| 6 | **Design Patterns** | Which patterns + **why they solve this specific problem** (not textbook definition). Factory, Strategy, Observer, State, etc. | Patterns named but not justified → memorized, not understood |
| 7 | **SOLID Principles** | How each principle (S, O, L, I, D) applies with specific examples from the design | No SOLID discussion → misses Staff-level depth signal |
| 8 | **Sequence Diagram** | Step-by-step data flow for 2-3 key operations, shows method call chains between objects | No flow → unclear how objects interact at runtime |
| 9 | **Code Implementation** | Working, compilable Java code for all core classes. Real logic, not stubs. Clean naming, follows Java conventions | Stubs or pseudocode → didn't finish the design |
| 10 | **Edge Cases & Error Handling** | Specific invalid inputs, capacity limits, null handling, custom exceptions, concurrent access | No edge cases → only designed for the happy path |

## Optional Sections (Bonus Points)

| # | Section | When to Include |
|---|---------|-----------------|
| 11 | **Concurrency Handling** | When the problem involves shared state, multi-threading, or race conditions |
| 12 | **Enums & Constants** | When the domain has well-defined status codes, types, or configuration values |
| 13 | **Method Signatures** | Detailed Javadoc-style signatures with params, return types, exceptions |

## Scoring Guidance

- **Completeness 1:** Section completely missing
- **Completeness 2:** Mentioned but no substance (just class names, no attributes or methods)
- **Completeness 3:** Adequate — classes defined, basic relationships, some code
- **Completeness 4:** Good — clean design, patterns justified, working code, relationships clear
- **Completeness 5:** Excellent — production-quality design, all SOLID principles applied, edge cases covered, thread-safe where needed

## Staff-Level Expectations

At Staff Engineer level, interviewers specifically look for:
- **Why this pattern?** — not "I used Strategy" but "Strategy lets me swap algorithms without modifying the client, which matters here because..."
- **Trade-offs in class design** — "I chose composition over inheritance because..."
- **Extensibility signals** — "To add a new payment type, you only need to add one class that implements..."
- **Code quality** — meaningful names, no god classes, no 500-line methods, clear SRP
