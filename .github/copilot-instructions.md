# Copilot Instructions — Job Prep 2026

> **Purpose:** VS Code Copilot-specific behavior for this workspace. For shared context (purpose, structure, behavior guidelines), see [WORKSPACE.md](../WORKSPACE.md).

---

## 1. Default Candidate Profile

> This is the default profile. Each company's analysis doc may override these for different candidates/roles.
> **Update this table** with your own details before starting prep.

| Field | Details |
|---|---|
| **Current Role** | _(e.g., Senior Software Engineer)_ |
| **Target Role** | _(e.g., Staff Software Engineer)_ |
| **Experience** | _(e.g., 8+ years in Backend Engineering)_ |
| **Core Stack** | _(e.g., Java, Spring Boot, Microservices)_ |
| **Key Skills** | _(e.g., REST APIs, Distributed Systems, System Design)_ |
| **Resume** | `Resume/<YourName>_Resume.md` (in `Resume/` folder) |

> **Multi-user note:** Other users should update this table and the resume path. This default profile is not mandatory — the company-setup skill will ask for role details.

---

## 2. Copilot-Specific Guidelines

### Auto-Routing (MANDATORY)
On every user message, **check [WORKSPACE.md § 4 — Auto-Routing](../WORKSPACE.md#4-auto-routing--skills--agents)** to detect if the request matches a skill or agent. If it does, read the skill's `SKILL.md` or invoke the agent — the user should never need to type `@agent` or `/command`.

### Mode Recommendations
- **Plan mode** for strategizing, research, and analysis
- **Agent mode** for execution, file creation, and multi-step tasks

### VS Code Slash Commands (Optional shortcuts)
These are optional convenience shortcuts — auto-routing handles everything even without them:
- `/new-company-prep` → uses `company-setup` skill
- `/hld-solution` → uses `hld-solution` skill
- `/lld-solution` → uses `lld-solution` skill

### Track Progress
- Use todo lists for multi-step tasks
- Update the Prep Tracker in [WORKSPACE.md](../WORKSPACE.md) after completing milestones

---

## 3. Companies — Prep Tracker

See [WORKSPACE.md § Prep Tracker](../WORKSPACE.md#8-prep-tracker) for the unified tracker.

---

## 4. Resume

Base resume: `Resume/<YourName>_Resume.md` (in `Resume/` folder) — used for initial analysis, never modified by skills.
Company-specific resumes: `Companies/<Company>/Resume-<Company>.md` — tailored versions created during company setup.

---

_Last Updated: 14 March 2026_
