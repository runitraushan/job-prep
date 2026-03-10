---
description: "Generate a complete Low-Level Design (LLD) solution for a given problem. Creates file in the company's System-Design folder."
agent: "agent"
argument-hint: "Company name and LLD problem (e.g., PayPal Design a Parking Lot System)"
---

Generate a comprehensive Low-Level Design (LLD) solution. The user will provide the company name and the design problem.

## Output

Create the solution file at: `Companies/<CompanyName>/System-Design/LLD-<ProblemName>.md`
Use kebab-case for the filename (e.g., `LLD-Parking-Lot.md`, `LLD-Elevator-System.md`).

## Solution Structure

The solution MUST cover all the following sections in order:

### 1. Requirements Clarification
- What exactly are we designing?
- Scope boundaries — what's included and excluded
- Functional requirements as bullet points

### 2. Use Cases / Actors
- Who interacts with the system (User, Admin, System, etc.)
- Key use cases for each actor

### 3. Core Entities
- Key objects/classes with their attributes and data types
- Present as a table: Entity | Attributes | Types

### 4. Class Diagram
- All classes with their relationships (inheritance, composition, aggregation)
- Show cardinality (1-to-1, 1-to-many, many-to-many)
- Use text-based diagram or structured description

### 5. Interfaces & Abstract Classes
- Key abstractions and contracts
- Why this abstraction exists (justification)

### 6. Method Signatures
- All public methods with:
  - Method name
  - Parameters with types
  - Return type
  - Exceptions thrown
- Present as code blocks with Javadoc-style comments

### 7. Enums & Constants
- Status codes, types, configuration values
- Present as Java enum definitions

### 8. Design Patterns
- Which patterns are used and **why**
- How they solve the specific problem (not just textbook definition)
- Examples: Factory, Strategy, Observer, Singleton, Builder, etc.

### 9. SOLID Principles
- How each principle (S, O, L, I, D) is applied in this design
- Specific examples from the classes above

### 10. Sequence Diagram
- Data flow for 2-3 key operations
- Describe as step-by-step numbered flow (text-based)

### 11. Java Code
- Complete implementation of all core classes
- Include interfaces, abstract classes, concrete classes
- Working, compilable Java code
- Use meaningful variable names and follow Java conventions

### 12. Concurrency Considerations
- Thread safety concerns (if applicable)
- Locks, synchronized blocks, or concurrent data structures used
- Race conditions and how they're handled
- Skip this section if concurrency is not relevant to the problem

### 13. Edge Cases & Error Handling
- What can go wrong?
- How does the system handle invalid inputs, capacity limits, null values?
- Custom exceptions if needed

## Rules
- Use **Java** for all code
- Explain design decisions — **why**, not just what
- Keep the solution at Staff Engineer level — show depth and trade-off thinking
- If the problem is ambiguous, state your assumptions clearly at the top
