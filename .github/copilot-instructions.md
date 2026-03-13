# Copilot Instructions — Job Prep 2026

> **Purpose:** VS Code Copilot-specific behavior for this workspace. For shared context (purpose, structure, behavior guidelines), see [WORKSPACE.md](../WORKSPACE.md).

---

## 1. Default Candidate Profile

> This is the default profile. Each company's analysis doc may override these for different candidates/roles.

| Field | Details |
|---|---|
| **Current Role** | Senior Software Engineer |
| **Target Role** | Staff Software Engineer |
| **Experience** | 10+ years in Backend Engineering |
| **Core Stack** | Java, Spring Boot, Microservices |
| **Key Skills** | Java EE (JMS, JPA, Servlets), Spring MVC, Hibernate, REST APIs, Cloud-Native Architecture, Distributed Systems |
| **Resume** | `Runit_Kumar_Raushan_Resume_Improved.md` (workspace root) |

> **Multi-user note:** Other users should update the resume path and profile in their company's analysis doc. This default profile is not mandatory — the company-setup skill will ask for role details.

---

## 2. Copilot-Specific Guidelines

### Mode Recommendations
- **Plan mode** for strategizing, research, and analysis
- **Agent mode** for execution, file creation, and multi-step tasks

### VS Code Slash Commands (Thin Wrappers)
These prompts delegate to portable skills:
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

Base resume: `Runit_Kumar_Raushan_Resume_Improved.md` (root of workspace) — used for initial analysis, never modified by skills.
Company-specific resumes: `Companies/<Company>/Resume-<Company>.md` — tailored versions created during company setup.

---

_Last Updated: 11 March 2026_
