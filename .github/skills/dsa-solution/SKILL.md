---
name: dsa-solution
description: "Generates a complete DSA solution for interview prep with code, complexity analysis, approach explanation, and edge cases. Primarily for coding interview roles (Backend, Full-Stack, DevOps). Uses the role's primary language (default: Java)."
argument-hint: "Company name and problem (e.g., PayPal Merge Intervals)"
---

# DSA Solution Skill

## Purpose

Generate a complete, interview-ready DSA solution for a given problem. The solution follows a strict format optimized for Staff Engineer interview prep — covering approach, complexity, code, dry run, and edge cases.

## When to Use

- User wants to practice/solve a DSA problem
- User says "solve [problem] for [company] prep"
- User invokes `/dsa-solution`

## Output

Create the solution file at: `Companies/<CompanyName>/DSA/Solutions/<ProblemName>.md`
Use kebab-case for the filename (e.g., `Merge-Intervals.md`, `LRU-Cache.md`).

## Solution Format

Follow the **exact structure** from the [sample solution](./examples/sample-solution.md). Every solution MUST include these sections in order:

1. **Problem Statement** — Concise description + constraints + examples. Include a `**LeetCode:**` line with direct link if the problem maps to a LeetCode problem (e.g., `[#56. Merge Intervals](https://leetcode.com/problems/merge-intervals/)`). If only a similar problem exists, note it as `Similar: [#Number. Name](url)`.
2. **Approach** — Brute force first, then optimized. Explain the intuition. Why does this approach work?
3. **Complexity Analysis** — Time AND space for each approach. Use the [complexity cheatsheet](./references/complexity-cheatsheet.md) for common patterns
4. **Java Code** — Clean, compilable, interview-ready. Include comments for non-obvious logic only
5. **Dry Run** — Walk through one example step by step, showing how variables change
6. **Edge Cases** — What inputs break naive solutions? How does this code handle them?
7. **Related Problems** — Similar problems to practice the same pattern
8. **Interview Tips** — What to say out loud during the interview

## Rules

- **Use the role's primary language** for all code (check the company's analysis doc; default: Java for backend roles)
- Brute force first → optimized. Interviewers want to see you can improve
- Complexity analysis is MANDATORY — never skip it
- Code must be compilable and correct — test it mentally before writing
- Use meaningful variable names. No `i, j, k` for anything beyond loop counters
- Include `// Time: O(...), Space: O(...)` comment at the top of each method
- Edge cases must be specific: "empty array", "single element", not just "edge cases"
- Reference the [complexity cheatsheet](./references/complexity-cheatsheet.md) when pattern-matching complexity
