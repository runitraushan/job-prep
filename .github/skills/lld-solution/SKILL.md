---
name: lld-solution
description: "Generates a complete Low-Level Design (LLD) / OOP design solution for interview prep. Covers 13 sections: requirements, use cases, class diagram, interfaces, design patterns, SOLID principles, sequence diagram, Java code, concurrency, edge cases. Use when solving an LLD problem for backend or full-stack roles."
argument-hint: "Company name and LLD problem (e.g., PayPal Design a Parking Lot System)"
---

# LLD Solution Skill

## Purpose

Generate a comprehensive, interview-ready Low-Level Design (LLD) solution. The solution follows a strict 13-section format optimized for Staff Engineer interview prep — covering OOP design, patterns, SOLID principles, and working code.

## When to Use

- User wants to solve an LLD / OOP design problem
- User says "design [component] for [company] prep"
- User invokes `/lld-solution`

## Output

Create the solution file at: `Companies/<CompanyName>/LLD/Solutions/LLD-<ProblemName>.md`
Use kebab-case for the filename (e.g., `LLD-Parking-Lot.md`, `LLD-Elevator-System.md`).

## Solution Format

Follow the **exact structure** from the [sample LLD solution](./examples/sample-lld.md). Every solution MUST cover all the following sections in order:

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
- Present as enum definitions in the role's primary language

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

### 11. Code Implementation
- Complete implementation of all core classes
- Include interfaces, abstract classes, concrete classes
- Working, compilable code in the role's primary language
- Use meaningful variable names and follow language conventions

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

- Check the company's analysis doc for the role's **primary language** — use that for all code (default: Java)
- Explain design decisions — **why**, not just what
- Keep the solution at the **target level** from the analysis doc — show appropriate depth and trade-off thinking
- If the problem is ambiguous, state your assumptions clearly at the top
