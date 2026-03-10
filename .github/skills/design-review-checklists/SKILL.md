---
name: design-review-checklists
description: "Provides HLD and LLD review checklists for system design interview prep. Use when reviewing a design document for completeness, or while writing a design to self-check coverage. Can be used standalone or by the @design-reviewer agent."
user-invocable: true
---

# Design Review Checklists

## Purpose

Provides structured checklists for reviewing High-Level Design (HLD) and Low-Level Design (LLD) documents. These checklists define what a strong system design answer looks like at a Staff Engineer level.

## How to Use

### Standalone (Self-Check While Writing)
Invoke `/design-review-checklists` while writing a design doc to verify you haven't missed critical sections.

### With @design-reviewer Agent
The `@design-reviewer` agent references these checklists automatically when reviewing your design documents.

## Checklists

- **HLD Review:** See [hld-checklist.md](./hld-checklist.md) — 15 sections covering functional requirements through failure scenarios
- **LLD Review:** See [lld-checklist.md](./lld-checklist.md) — 10 sections covering requirements through edge cases

## Review Output Format

When using these checklists to review a document, produce:

### Section Coverage

| Section | Present? | Completeness (1-5) | Notes |
|---------|----------|---------------------|-------|
| Section name | ✅/❌ | ⭐ rating | Specific feedback |

### Critical Gaps (Interviewer would notice)
- Sections that are missing or very weak

### Areas to Strengthen
- Sections present but need more depth

### Strong Points
- What's done well

### Interview Readiness: X/10
- 1-3: Not ready — major gaps
- 4-6: Needs work — key sections missing
- 7-8: Good — minor improvements needed
- 9-10: Interview ready

### Top 3 Improvements
Specific, actionable steps to improve the document.
