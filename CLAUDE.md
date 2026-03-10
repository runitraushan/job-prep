# Claude Code Instructions — Job Prep 2026

> For shared context (purpose, structure, behavior guidelines), see [WORKSPACE.md](./WORKSPACE.md).

## Skills

All reusable skills are in `.github/skills/`. Each skill has a `SKILL.md` with instructions and bundled assets:

- `company-setup` — scaffold prep workspace for a new company
- `dsa-solution` — generate DSA solution (backend roles, Java)
- `hld-solution` — generate HLD / system design solution (backend/full-stack)
- `lld-solution` — generate LLD / OOP design solution (backend/full-stack)
- `design-review-checklists` — HLD/LLD review checklists (backend)

## Agents

Agent definitions are in `.github/agents/`:

- `design-reviewer` — read-only design doc reviewer
- `interview-researcher` — researches interview questions from online sources

## Default Candidate

See `Runit_Kumar_Raushan_Resume_Improved.md` at workspace root. Each company's analysis doc specifies the actual role, level, and stack.

## Key Rules

- Follow [WORKSPACE.md](./WORKSPACE.md) § Behavior Guidelines
- Use the role's primary language (default: Java for backend)
- Always check the company's analysis doc for role-specific context before generating content
- Don't assume every role has DSA or system design rounds — check the role profile
