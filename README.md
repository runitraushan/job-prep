# Job Prep 2026

An **AI-powered interview preparation framework** that uses VS Code Copilot agents and skills to build structured, company-specific prep workspaces. Instead of scattered notes and random LeetCode grinding, this project gives you a repeatable system — from JD analysis to mock practice — all driven by AI assistants that understand your resume, target role, and gaps.

## What Problem Does This Solve?

Interview prep is chaotic. You have a JD, a resume, dozens of topics, and no clear plan. This framework automates the boring parts:

1. **Analyze the JD** against your resume — identify exact gaps
2. **Scaffold a prep workspace** with the right folder structure for your role type
3. **Collect interview questions** from online sources (Glassdoor, LeetCode, Blind)
4. **Generate solutions** — DSA, system design (HLD), OOP design (LLD) — all in interview-ready format
5. **Practice interactively** with a coaching agent that reviews your answers section-by-section
6. **Tailor your resume** with specific, JD-aligned rewrites

## Supported Role Types

| Role | Prep Folders | Primary Language |
|------|-------------|-----------------|
| **Backend** | DSA, HLD, LLD, Behavioral | Java |
| **Frontend** | DSA, Component-Design, Behavioral | TypeScript |
| **Full-Stack** | JD-driven mix of Backend + Frontend | JD-dependent |
| **Data Science / ML** | Coding, ML-Concepts, ML-System-Design, Case-Study, Behavioral | Python |
| **QA / SDET** | Test-Design, Automation-Architecture, Behavioral | Java/Python |
| **DevOps / SRE** | DSA, Infrastructure-Design, Behavioral | Python/Go |

## Project Structure

```
Job Prep 2026/
├── README.md                          # You are here
├── WORKSPACE.md                       # Shared AI context — single source of truth
├── CLAUDE.md                          # Claude Code specific instructions
├── Resume/
│   └── <YourName>_Resume.md           # Your base resume (never modified by skills)
│
├── Companies/
│   └── <CompanyName>/
│       ├── <Company>-<Role>-JD.md     # Job description
│       ├── <Company>-<Role>-Analysis.md  # AI-generated gap analysis
│       ├── Resume-<Company>.md        # Tailored resume copy
│       └── <role-specific folders>/   # DSA/, HLD/, LLD/, ML-Concepts/, etc.
│           ├── Solutions/             # AI-generated or self-written answers
│           └── Practice/              # Interactive practice session files
│
└── .github/
    ├── skills/                        # Portable AI skills (see below)
    ├── agents/                        # Agent personas (see below)
    ├── prompts/                       # VS Code slash command wrappers
    └── hooks/                         # Lifecycle scripts (session context, progress reminders)
```

## Quick Start

### Prerequisites

- **VS Code** with GitHub Copilot (Chat + Agents)
- A resume in markdown format placed at `Resume/<YourName>_Resume.md`
- A job description (text or markdown) for your target company

### 1. Set Up a New Company

In VS Code Copilot Chat, type:

```
/new-company-prep Google Staff Backend Engineer
```

Or invoke the skill directly:

```
Use the company-setup skill to set up prep for Google, Staff Backend Engineer
```

This will:
- Detect the role type (Backend, Frontend, DS/ML, etc.)
- Create the company folder with the right subfolder structure
- Ask you to paste the JD
- Generate a comprehensive analysis doc (JD breakdown, resume gaps, prep strategy, interview rounds)

### 2. Collect Interview Questions

```
@interview-researcher Research questions for Google Staff Backend Engineer
```

The agent searches Glassdoor, LeetCode, Blind, and other sources, then organizes questions into your prep folders (DSA-Questions.md, HLD-Questions.md, etc.).

### 3. Generate Solutions

```
Use the hld-solution skill to solve "Design a URL Shortener" for Google
```

```
Use the dsa-solution skill to solve "Merge Intervals" for Google
```

```
Use the lld-solution skill to solve "Design a Parking Lot" for Google
```

Solutions are saved in the appropriate `Solutions/` folder with a consistent, interview-ready format.

### 4. Practice Interactively

```
@design-coach Practice Payment Processing System HLD for Google
```

The coach walks you through one section at a time — explains what's expected, waits for your answer, rates it (1-5 stars), gives feedback, and saves everything to a practice file.

### 5. Review Your Design Docs

```
@design-reviewer Review my HLD for Payment Processing System
```

Gets a structured review with section-by-section completeness scores, critical gaps, and improvement suggestions.

### 6. Tailor Your Resume

```
Use the resume-tailor skill for Google
```

Reads the gap analysis, cross-references every resume bullet against the JD, and proposes exact rewrites interactively. Only updates the company-specific resume copy (never your base resume).

---

## Skills

Skills are portable, reusable instructions that any AI assistant (Copilot, Claude, Gemini) can follow. Each lives in `.github/skills/<name>/SKILL.md`.

| Skill | What It Does | Invocation |
|-------|-------------|------------|
| **company-setup** | Scaffolds a complete prep workspace for a new company. Detects role type, creates folders, processes JD, generates analysis doc with gap analysis and prep strategy. | `/new-company-prep` or ask for "company setup" |
| **dsa-solution** | Generates a DSA solution with brute-force → optimized approach, complexity analysis, Java/Python code, dry run, and edge cases. Links to LeetCode problems. | `/dsa-solution` or "solve [problem] for [company]" |
| **hld-solution** | Generates a 17-section HLD solution: requirements, estimation, API design, data model, architecture, caching, queues, sharding, replication, monitoring, trade-offs, failure scenarios. | `/hld-solution` or "design [system] for [company]" |
| **lld-solution** | Generates a 13-section LLD solution: requirements, use cases, class diagram, interfaces, design patterns, SOLID principles, sequence diagram, code, concurrency, edge cases. | `/lld-solution` or "design [component] for [company]" |
| **resume-tailor** | Analyzes resume-vs-JD gaps and proposes specific bullet rewrites. Interactive — only applies changes you confirm. Works with any role type. | "Tailor resume for [company]" |
| **design-review-checklists** | Provides HLD (15 sections) and LLD (10 sections) review checklists. Used standalone for self-review or automatically by the @design-reviewer agent. | "Show HLD/LLD checklist" |

## Agents

Agents are AI personas with specific expertise and restricted tool access. Invoke them with `@agent-name` in VS Code Copilot Chat.

| Agent | What It Does | Tools | Mode |
|-------|-------------|-------|------|
| **@design-coach** | Interactive practice coach. Presents one design section at a time, waits for your answer, reviews it with a star rating and feedback, saves progress to a practice file. Covers all HLD/LLD sections. | read, search, edit | Interactive |
| **@design-reviewer** | Reviews HLD/LLD documents for completeness. Supports both structured (template-generated) and free-form (self-written) answers. Rates each section, flags critical gaps. **Read-only — never modifies files.** | read, search | Read-only |
| **@interview-researcher** | Researches interview questions from Glassdoor, LeetCode, Blind, AmbitionBox, and GeeksforGeeks. Organizes questions by round type into your prep folders. Includes LeetCode links for DSA problems. | read, search, edit, web | Research |

## Slash Commands (VS Code)

Thin wrappers in `.github/prompts/` that delegate to skills:

| Command | Delegates To |
|---------|-------------|
| `/new-company-prep` | `company-setup` skill |
| `/hld-solution` | `hld-solution` skill |
| `/lld-solution` | `lld-solution` skill |

## Lifecycle Hooks

Bash scripts that provide session context and progress reminders:

| Hook | When It Runs | What It Does |
|------|-------------|-------------|
| `session-context.sh` | Session start | Reads prep tracker, outputs active company context |
| `progress-reminder.sh` | After creating a solution file | Reminds to update the prep tracker in WORKSPACE.md |

Run manually: `bash .github/hooks/scripts/session-context.sh`

## Multi-User Support

This framework isn't locked to one person. To use it for a different candidate:

1. Place your resume (markdown) at `Resume/<YourName>_Resume.md`
2. Update the candidate profile table in `.github/copilot-instructions.md` § 1 with your details (name, role, stack, resume path)
3. When running `company-setup`, provide your role details — the skill will ask
4. Each company's analysis doc stores the specific candidate profile, role, and level
5. The default profile in `.github/copilot-instructions.md` is just a starting point — company-level docs override it

## Prep Tracker

Track progress across all companies in [WORKSPACE.md](WORKSPACE.md#8-prep-tracker):

| Company | Role | Analysis | Questions | Solutions | Behavioral | Status |
|---------|------|----------|-----------|-----------|------------|--------|
| _(Add companies here as you set them up)_ | — | — | — | — | — | — |

## Typical Workflow

```
1. company-setup          → Scaffold folders + analysis doc
2. @interview-researcher  → Collect real interview questions
3. dsa/hld/lld-solution   → Generate solutions for collected questions
4. @design-coach          → Practice designs interactively
5. @design-reviewer       → Get feedback on your practice answers
6. resume-tailor          → Tailor resume before applying
```

---

## License

This is a personal interview prep workspace. The framework (skills, agents, templates) can be adapted for your own use.
