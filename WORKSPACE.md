# Job Prep 2026 — Workspace Guide

> **Single source of truth** for any AI assistant (Copilot, Claude, Gemini, etc.) working in this workspace.

---

## 1. Purpose

This workspace is dedicated to **company-wise job interview preparation** — supporting any role type, any experience level, and multiple users. Preparation covers all interview round types end-to-end.

---

## 2. Structure

```
Job Prep 2026/
├── WORKSPACE.md                              # This file — shared AI context
├── CLAUDE.md                                 # Claude Code context (references this file)
├── .github/copilot-instructions.md           # VS Code Copilot context (references this file)
├── Runit_Kumar_Raushan_Resume_Improved.md    # Base resume (never modified by skills)
├── Companies/
│   └── <CompanyName>/
│       ├── <CompanyName>-<Role>-JD.md        # Job Description (user provides)
│       ├── <CompanyName>-<Role>-Analysis.md  # Generated analysis doc
│       ├── Resume-<CompanyName>.md           # Company-specific resume (tailored from base)
│       └── <role-specific folders>/          # Determined by role profile (see below)
├── .github/
│   ├── skills/          # Portable skills (agentskills.io standard)
│   ├── agents/          # Agent personas with tool restrictions
│   ├── prompts/         # VS Code Copilot slash commands (thin wrappers)
│   └── hooks/           # Lifecycle hooks (scripts + configs)
```

### Lifecycle Hooks

Portable bash scripts in `.github/hooks/scripts/` that any AI tool can run:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `session-context.sh` | Session start | Reads prep tracker, outputs active company context |
| `progress-reminder.sh` | After creating a solution file | Reminds to update prep tracker |

Run manually: `bash .github/hooks/scripts/session-context.sh`

### Folder Structure per Company

Folders inside each company directory are **determined by the role profile** — not hardcoded. Examples:

| Role Type | Typical Folders |
|-----------|----------------|
| Backend | `DSA/`, `HLD/`, `LLD/`, `Behavioral/` — each with `Solutions/` and `Practice/` subfolders |
| Frontend | `DSA/`, `Component-Design/`, `Behavioral/` |
| Full-Stack | JD-driven — mix of Backend + Frontend folders |
| Data Science / ML | `ML-Algorithms/`, `ML-System-Design/`, `Behavioral/` |
| QA / SDET | `Test-Design/`, `Automation-Architecture/`, `Behavioral/` |
| DevOps / SRE | `DSA/`, `Infrastructure-Design/`, `Behavioral/` |

See [role-profiles.md](.github/skills/company-setup/assets/role-profiles.md) for full definitions.

---

## 3. How Prep Works

### Setting up a new company

1. Invoke the **company-setup** skill (or `/new-company-prep` in VS Code)
2. Provide: company name, role title, target level
3. The skill determines the role profile, creates appropriate folders, asks for JD
4. After JD is placed, generates a standardized analysis doc

### After setup

- Use **@interview-researcher** agent → researches and collects interview questions into the role-appropriate folders
- Use **hld-solution** / **lld-solution** / **dsa-solution** skills → generate practice solutions
- Use **@design-reviewer** agent → review design docs for completeness
- Use **design-review-checklists** skill → standalone checklist reference

---

## 4. Auto-Routing — Skills & Agents (MANDATORY)

> **Every user prompt MUST be checked against this routing table before responding.** Users should never need to type `@agent`, `/command`, or skill names — the AI must detect intent automatically and invoke the right skill or agent.

### How It Works

1. **On every user message**, match the intent against the routing table below.
2. If a match is found → **read the skill's `SKILL.md` or agent's `.agent.md`** and follow its instructions. Tell the user which skill/agent you're using (e.g., *"Using the `hld-solution` skill..."*).
3. If no match → respond normally using workspace context.

### Routing Table

| User Intent (detect from prompt) | Route To | Type |
|---|---|---|
| Setting up prep for a new company, new JD, new role | `company-setup` | Skill |
| Tailoring resume, resume gaps, resume improvements for a company | `resume-tailor` | Skill |
| Solve a DSA / coding / algorithm problem | `dsa-solution` | Skill |
| Solve an HLD / system design / high-level design problem | `hld-solution` | Skill |
| Solve an LLD / OOP design / low-level design / class design problem | `lld-solution` | Skill |
| Review a design doc, check design completeness | `@design-reviewer` | Agent |
| Practice HLD/LLD interactively, mock design interview | `@design-coach` | Agent |
| Research interview questions for a company, find questions online | `@interview-researcher` | Agent |
| HLD/LLD checklist, design review checklist | `design-review-checklists` | Skill |

### Intent Detection Hints

- **Keywords** like "design", "system design", "HLD" → `hld-solution` skill
- **Keywords** like "LLD", "class design", "OOP", "low-level" → `lld-solution` skill
- **Keywords** like "DSA", "leetcode", "algorithm", "coding problem", "solve" + problem name → `dsa-solution` skill
- **Keywords** like "new company", "prepare for X", "JD", "job description" → `company-setup` skill
- **Keywords** like "resume", "tailor", "gap analysis" → `resume-tailor` skill
- **Keywords** like "review my design", "check my HLD/LLD" → `@design-reviewer` agent
- **Keywords** like "practice", "mock", "coach me", "let's do HLD/LLD" → `@design-coach` agent
- **Keywords** like "find questions", "research questions", "glassdoor", "interview questions for X" → `@interview-researcher` agent
- If ambiguous between skill and agent (e.g., "HLD for payment system" vs "practice HLD for payment system"), prefer **skill** for generation, **agent** for interactive practice.

---

## 5. Behavior Guidelines (All Tools)

### Always Do
- **Auto-route**: Check the routing table (§4) on every user message before doing anything else
- **Use the role's primary language** for code solutions (default: Java for backend roles). Check the company's analysis doc for role-specific language.
- **Include complexity analysis** for every DSA/coding solution
- **Discuss trade-offs** in design rounds — never name-drop technologies without justification
- **Tailor to the role profile** — don't assume every role has DSA or system design rounds
- **Track progress** using todo lists for multi-step tasks

### Never Do
- Don't skip complexity analysis for coding problems
- Don't provide design solutions without discussing trade-offs
- Don't create unnecessary files — only what's needed for prep
- Don't assume backend/Java unless the role profile says so
- Don't require users to type `@agent` or `/skill` — auto-detect intent

---

## 6. Level Context

This workspace supports **any experience level**, not just senior→staff. When generating content:

- Read the company's analysis doc for the specific `{{CURRENT_LEVEL}} → {{TARGET_LEVEL}}`
- Adapt depth, scope, and framing to the target level
- For level-up scenarios, emphasize what differentiates the target level from current

| Level | Focus |
|-------|-------|
| Fresher / Junior | Fundamentals, clean code, communication |
| Mid | Problem-solving depth, ownership narratives |
| Senior | System thinking, technical leadership |
| Staff / Principal | Architecture, cross-team influence, vision |
| Lead / Manager | People leadership, org impact, strategy |

---

## 7. Available Skills (Portable — works in Copilot, Claude, Gemini)

| Skill | Purpose | Scope |
|-------|---------|-------|
| `company-setup` | Scaffold prep workspace for a new company | All roles |
| `resume-tailor` | Tailor company-specific resume based on gap analysis | All roles |
| `dsa-solution` | Generate DSA solution with code + analysis | Backend roles |
| `hld-solution` | Generate HLD / system design solution | Backend / Full-Stack |
| `lld-solution` | Generate LLD / OOP design solution | Backend / Full-Stack |
| `design-review-checklists` | HLD/LLD review checklists | Backend system design |

## 8. Available Agents

| Agent | Purpose | Tools |
|-------|---------|-------|
| `@design-reviewer` | Reviews design docs for completeness (read-only) | read, search |
| `@design-coach` | Interactive section-by-section HLD/LLD practice with instant feedback | read, search, edit |
| `@interview-researcher` | Researches interview questions from online sources | read, search, edit, web |

---

## 9. Prep Tracker

| Company | Role | Analysis | Questions | Solutions | Behavioral | Status |
|---|---|---|---|---|---|---|
| PayPal | Staff Backend Engineer | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |
| Airbnb | Senior SE, Payments | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |
| Soft Suave | AIML Engineer | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |

---

_Last Updated: 11 March 2026_
