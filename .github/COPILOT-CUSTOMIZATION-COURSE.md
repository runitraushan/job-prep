# Copilot Customization — Interactive Course Plan

> A 6-phase hands-on course to master Prompts, Custom Agents, Skills, and Hooks.
> Tailored for a Senior/Staff Engineer working with Java/Spring Boot Microservices in a large team.

---

## Course Settings

| Setting | Value |
|---|---|
| **Pace** | Medium (~30-45 min per phase) |
| **Stack** | Java/Spring Boot Microservices |
| **Hands-on Workspace** | Job Prep 2026 (current workspace) |
| **Style** | Interactive — ask questions, take input, learn by doing |
| **Learning Order** | Prompts → Agents → Skills → Hooks → Combined → Enterprise |

---

## Phase 1: Prompts — "Recipe Cards" (~30 min)

**Goal:** Create reusable slash commands for common tasks.

**Status:** ✅ Complete

### Steps

| # | Step | Type | Duration | Status |
|---|------|------|----------|--------|
| 1 | Prompt anatomy — frontmatter fields (description, agent, model, tools, argument-hint), body content, context references | Theory | 10 min | ✅ |
| 2 | Walk through how `/create-instructions` works internally | Live Demo | 5 min | ✅ |
| 3 | Create `/new-company-prep` prompt — auto-scaffolds company folder + analysis template | Hands-on | 10 min | ✅ |
| 4 | Create `/lld-solution` and `/hld-solution` prompts — generates design solutions in company folder | Hands-on | 10 min | ✅ |
| 5 | Cover `agent`, `tools`, `model`, `argument-hint` fields in detail | Advanced | 5 min | ✅ |
| 6 | When your team should use prompts. Onboarding, PR descriptions, boilerplate, workflows | Team Discussion | 5 min | ✅ |
| 7 | When NOT to use — vs Instructions, vs Skills, vs Agents | Comparison | 3 min | ✅ |
| 8 | Invoke both prompts and verify they work | Checkpoint | 5 min | ✅ |

### Files to Create
- [x] `.github/prompts/new-company-prep.prompt.md`
- [x] `.github/prompts/lld-solution.prompt.md`
- [x] `.github/prompts/hld-solution.prompt.md`

---

## Phase 2: Custom Agents — "Specialists" (~30 min)

**Goal:** Create specialized personas with restricted tools and focused behavior.

**Status:** ✅ Complete

### Steps

| # | Step | Type | Duration | Status |
|---|------|------|----------|--------|
| 1 | Agent anatomy — description, tools (aliases), model, user-invocable, subagent concept, handoffs | Theory | 10 min | ✅ |
| 2 | Why tool restriction matters — safety + focus. Tool aliases explained | Concept | 5 min | ✅ |
| 3 | Create a "Design Reviewer" agent — read-only, reviews system design docs, flags missing sections | Hands-on | 10 min | ✅ |
| 4 | Create an "Interview Researcher" agent — researches interview questions from online sources, organizes into DSA/SD/Behavioral folders, iterates conversationally | Hands-on | 10 min | ✅ |
| 5 | Subagent orchestration — parent → child agents, `user-invocable: false`, `disable-model-invocation` | Advanced | 5 min | ✅ |
| 6 | Team use cases — code reviewer, security audit, documentation, onboarding guide agents | Team Discussion | 5 min | ✅ |
| 7 | When NOT to use — vs Prompts, vs Skills, vs Instructions | Comparison | 3 min | ✅ |
| 8 | Invoke agents and verify they work | Checkpoint | 5 min | ✅ |

### Files Created
- [x] `.github/agents/design-reviewer.agent.md`
- [x] `.github/agents/interview-researcher.agent.md`
- DSA Coach agent skipped (user preference)

---

## Phase 3: Skills — "Full Toolkits" (~40 min)

**Goal:** Build template-driven skills that compose with agents for consistent, repeatable output.

**Status:** 🔄 In Progress

### Steps

| # | Step | Type | Duration | Status |
|---|------|------|----------|--------|
| 1 | Skill anatomy — folder structure, SKILL.md, frontmatter, progressive 3-level loading | Theory | 10 min | ✅ |
| 2 | Skill vs Prompt — when the task outgrows instructions-only (decision framework) | Concept | 5 min | ✅ |
| 3 | Build `company-setup` skill — SKILL.md + 4 template assets (analysis, DSA, SD, behavioral). Replaces `/new-company-prep` prompt with template-driven consistency | Hands-on | 15 min | ⬜ |
| 4 | Build `dsa-solution` skill — example-driven approach with reference solution + complexity cheatsheet | Hands-on | 10 min | ⬜ |
| 5 | Build `design-review-checklists` skill — externalize HLD/LLD checklists from @design-reviewer agent, update agent to reference skill | Hands-on | 10 min | ⬜ |
| 6 | Advanced: naming rules, discovery keywords, `disable-model-invocation`, personal vs project skills, `chat.agentSkillsLocations` | Deep-dive | 5 min | ⬜ |
| 7 | Checkpoint: Invoke `/company-setup` for a new company (e.g., Stripe) and verify template consistency | Checkpoint | 5 min | ⬜ |

### Files to Create
- [ ] `.github/skills/company-setup/SKILL.md`
- [ ] `.github/skills/company-setup/assets/analysis-template.md`
- [ ] `.github/skills/company-setup/assets/dsa-questions-template.md`
- [ ] `.github/skills/company-setup/assets/sd-questions-template.md`
- [ ] `.github/skills/company-setup/assets/behavioral-questions-template.md`
- [ ] `.github/skills/dsa-solution/SKILL.md`
- [ ] `.github/skills/dsa-solution/examples/sample-solution.md`
- [ ] `.github/skills/dsa-solution/references/complexity-cheatsheet.md`
- [ ] `.github/skills/design-review-checklists/SKILL.md`
- [ ] `.github/skills/design-review-checklists/hld-checklist.md`
- [ ] `.github/skills/design-review-checklists/lld-checklist.md`

---

## Phase 4: Hooks — "Security Guards" (~30 min)

**Goal:** Automate enforcement at lifecycle events with shell scripts.

**Status:** ⬜ Not Started

### Steps

| # | Step | Type | Duration | Status |
|---|------|------|----------|--------|
| 1 | Hook events (SessionStart, PreToolUse, PostToolUse, etc.), input/output contract, exit codes | Theory | 10 min | ⬜ |
| 2 | Deterministic enforcement vs guidance — hooks vs instructions | Concept | 5 min | ⬜ |
| 3 | Create a session-start hook that injects workspace context as a system message | Hands-on | 10 min | ⬜ |
| 4 | Create a pre-tool hook that asks for confirmation before file deletions | Hands-on | 10 min | ⬜ |
| 5 | Team use cases — auto-format on edit, block force-push, inject team context, validate PR descriptions | Team Discussion | 5 min | ⬜ |
| 6 | When NOT to use — vs Instructions (guidance is enough), when hooks add unnecessary friction | Comparison | 3 min | ⬜ |
| 7 | Trigger both hooks and verify they work | Checkpoint | 5 min | ⬜ |

### Files to Create
- [ ] `.github/hooks/session-context.json`
- [ ] `.github/hooks/safe-delete.json`
- [ ] `.github/hooks/scripts/session-context.sh`
- [ ] `.github/hooks/scripts/safe-delete.sh`

---

## Phase 5: Putting It All Together (~20 min)

**Goal:** See all 4 features working as one cohesive system.

**Status:** ⬜ Not Started

### Steps

| # | Step | Type | Duration | Status |
|---|------|------|----------|--------|
| 1 | Architecture review — review all customizations created, see how they connect | Review | 5 min | ⬜ |
| 2 | Walk-through — "A new engineer joins your team. What happens?" (hook → instructions → agent → prompt → skill) | Scenario | 10 min | ⬜ |
| 3 | Decision exercise — Given 5 scenarios, pick the right customization type | Exercise | 5 min | ⬜ |
| 4 | Best practices summary — dos and don'ts for each type, common pitfalls | Summary | 5 min | ⬜ |

---

## Phase 6: Enterprise Patterns (Discussion, ~15 min)

**Goal:** How to scale these in a large team.

**Status:** ⬜ Not Started

### Topics

| # | Topic | Status |
|---|-------|--------|
| 1 | Version control — `.github/` is committed, team shares customizations | ⬜ |
| 2 | User-level vs workspace-level separation | ⬜ |
| 3 | Monorepo patterns — different `AGENTS.md` per service folder | ⬜ |
| 4 | Governance — who owns/reviews customization files? PR reviews for agents/hooks | ⬜ |
| 5 | Context window management — avoiding instruction bloat | ⬜ |
| 6 | Security — hook scripts, tool restrictions, preventing misuse | ⬜ |

---

## Progress Tracker

| Phase | Topic | Status |
|-------|-------|--------|
| 1 | Prompts | ✅ Complete |
| 2 | Custom Agents | ✅ Complete |
| 3 | Skills | ⬜ Not Started |
| 4 | Hooks | ⬜ Not Started |
| 5 | Combined Workflow | ⬜ Not Started |
| 6 | Enterprise Patterns | ⬜ Not Started |

---

_Last Updated: 7 March 2026_
