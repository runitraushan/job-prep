# Copilot Customization — Decision Guide

> When to use which feature. Detailed comparison with real-world SDLC scenarios.

---

## The Decision Framework

### Step-by-Step Decision Flow

```
Step 1: Is this a ONE-TIME task or an ONGOING RULE?
   → Ongoing rule → INSTRUCTION (.instructions.md)
   → One-time task → Go to Step 2

Step 2: Does it need a SPECIALIZED PERSONA or TOOL RESTRICTIONS?
   → Yes → CUSTOM AGENT (.agent.md)
   → No → Go to Step 3

Step 3: Does it need BUNDLED FILES (templates, scripts, reference docs)?
   → Yes → SKILL (SKILL.md)
   → No → Go to Step 4

Step 4: Does it need GUARANTEED ENFORCEMENT (must always happen, no exceptions)?
   → Yes → HOOK (.json)
   → No → ✅ PROMPT (.prompt.md)
```

---

## Feature Deep Dive — SDLC Mapping

### Instructions = Coding Standards & Linting Rules

**SDLC Parallel:** Think of how your team maintains a `checkstyle.xml` or `.eslintrc` config file. It doesn't run once — it **continuously applies** to every file you write. You don't need to remember to invoke it. It's always there, enforcing rules silently.

Instructions work the same way. They're the **coding standards document** of Copilot.

**When to use:**
- Team coding conventions (naming, formatting, patterns)
- Project-specific rules ("always use constructor injection in Spring, never field injection")
- File-type rules ("every Java file must have package-level Javadoc")
- Behavioral defaults ("explain things simply", "use analogies")

**SDLC Examples:**

| Scenario | Instruction File | `applyTo` |
|---|---|---|
| Spring Boot coding standards | `spring-boot-conventions.instructions.md` | `"**/*.java"` |
| API response format must always include `status`, `data`, `error` | `api-response-format.instructions.md` | `"**/controller/**"` |
| All Kafka consumers must have DLQ configured | `kafka-conventions.instructions.md` | `"**/consumer/**"` |
| YAML config files must have comments explaining each property | `yaml-docs.instructions.md` | `"**/*.yml"` |
| Communication style — explain simply, use analogies | `communication-style.instructions.md` | `"**"` (always) |

**Why not a Prompt?** You'd have to type `/java-style` every time you start writing a Java file. You'll forget. And when you forget, the rules don't apply. Instructions are **passive enforcement** — like a linting config that runs without you thinking about it.

---

### Prompts = CI/CD Pipeline Templates

**SDLC Parallel:** Think of how Jenkins or GitHub Actions provides pipeline templates. You pick a template ("Java CI with Maven", "Deploy to AWS ECS"), it generates the config, and you customize it. You invoke it **when you need it**, not constantly.

Prompts work the same way. They're **on-demand task generators**.

**When to use:**
- Generating boilerplate for a specific task
- One-time scaffolding (new service, new module, new design doc)
- Document generation (HLD, LLD, postmortem, RFC)
- Repetitive but not continuous tasks (every new service needs scaffolding, but not every chat)

**SDLC Examples:**

| Scenario | Prompt File | Invocation |
|---|---|---|
| Create a new Spring Boot microservice | `new-microservice.prompt.md` | `/new-microservice Payment-Service` |
| Generate API spec from requirements | `write-api-spec.prompt.md` | `/write-api-spec` |
| Create DB migration with rollback | `create-migration.prompt.md` | `/create-migration add-users-table` |
| Write PR description from changed files | `pr-description.prompt.md` | `/pr-description` |
| Generate HLD for a system | `hld-solution.prompt.md` | `/hld-solution Design URL Shortener` |
| Create incident postmortem doc | `incident-postmortem.prompt.md` | `/incident-postmortem` |

**Why not an Instruction?** These are task-specific. You don't want "how to write an HLD" loaded into context when you're debugging a NullPointerException. Prompts load **only when invoked**, keeping context clean.

**Why not a Skill?** Prompts are just text instructions. If you need to bundle template files, scripts, or reference docs with the task, use a Skill instead.

---

### Custom Agents = Specialized QA / Security Reviewers

**SDLC Parallel:** In a mature team, you have specialized roles — a **security reviewer** who only looks at auth and encryption, a **DBA** who reviews SQL migrations, a **tech lead** who reviews architecture decisions. Each specialist has a specific scope and specific tools they use.

Custom Agents work the same way. They're **specialized reviewers or workers with restricted access**.

**When to use:**
- Read-only review workflows (code review, design review, security audit)
- Specialized personas that need different behavior than the default Copilot
- Workflows where you want to **limit** what Copilot can do (safety)
- Subagent orchestration — a parent agent that delegates to specialist children

**SDLC Examples:**

| Scenario | Agent File | Tools Allowed |
|---|---|---|
| Code reviewer — reads code, flags issues, doesn't modify | `code-reviewer.agent.md` | `[read, search]` |
| Security auditor — checks for OWASP Top 10, insecure patterns | `security-auditor.agent.md` | `[read, search]` |
| DBA reviewer — reviews migrations, checks indexes, query plans | `dba-reviewer.agent.md` | `[read, search]` |
| DSA coach — guides you to solution without giving answer | `dsa-coach.agent.md` | `[]` (conversational only) |
| On-call helper — reads logs, suggests fixes, can't deploy | `oncall-helper.agent.md` | `[read, search, web]` |
| Full-stack dev — can read, edit, search, run commands | Default agent | All tools |

**Why not a Prompt?** Two key reasons: **(1) Persona** — An agent has a persistent personality. A code reviewer agent always behaves like a reviewer throughout the conversation. A prompt is a one-shot task — it doesn't maintain a persona across back-and-forth. **(2) Tool restriction** — Agents can be locked down. A reviewer that can only `[read, search]` physically cannot modify your code. A prompt can suggest restrictions in text, but it's not enforced.

**Why not an Instruction?** Instructions tell Copilot **how to behave generally**. Agents tell Copilot **to become a specific character** with specific limitations. You don't want a security auditor persona active when you're writing README docs.

---

### Skills = Runbooks & Playbooks

**SDLC Parallel:** Think of an **operational runbook** for deploying to production. It's not just instructions — it includes scripts (`deploy.sh`, `rollback.sh`), templates (PR template, release notes template), reference docs (architecture diagram, config reference), and step-by-step procedures. Everything is bundled in one place.

Skills work the same way. They're **self-contained toolkits with everything needed to complete a multi-step workflow**.

**When to use:**
- Multi-step procedures that need bundled assets (templates, scripts, configs)
- Workflows where the task references external files (not just generates from scratch)
- Repeatable operations that need to be consistent every time
- Complex procedures where a simple prompt would be insufficient

**SDLC Examples:**

| Scenario | Skill Folder | What's Bundled |
|---|---|---|
| New microservice setup | `new-service/` | SKILL.md + Dockerfile template + CI template + helm chart template |
| Database migration workflow | `db-migration/` | SKILL.md + migration template + rollback checklist + validation script |
| Incident response | `incident-response/` | SKILL.md + postmortem template + severity matrix + escalation docs |
| Release process | `release-process/` | SKILL.md + changelog template + release checklist + rollback script |
| Onboarding new dev | `onboarding/` | SKILL.md + setup scripts + architecture reference + key contacts |

**Skill structure example:**
```
.github/skills/new-service/
├── SKILL.md                          # Main instructions + procedure
├── assets/
│   ├── Dockerfile.template           # Docker template
│   ├── application.yml.template      # Spring Boot config template
│   └── ci-pipeline.yml.template      # CI/CD template
├── scripts/
│   └── init-service.sh               # Setup script
└── references/
    └── architecture-standards.md     # Team's architecture guidelines
```

**Why not a Prompt?** A prompt is **just text**. It can describe "create a Dockerfile" but can't bundle a Dockerfile template. A skill carries the actual template file — Copilot reads it and uses it, ensuring consistency. Think of it as: Prompt = recipe card (words only). Skill = meal kit (recipe + pre-measured ingredients).

**Why not an Agent?** Agents are about **persona and tool restriction**. Skills are about **procedure and bundled assets**. If you need both (a specific persona AND bundled assets), you can reference a skill from within an agent.

---

### Hooks = CI Gates & Git Hooks

**SDLC Parallel:** Think of **pre-commit hooks** (lint check before commit), **CI gate checks** (tests must pass before merge), or **deployment gates** (approval required before prod deploy). These don't rely on humans remembering — they **automatically enforce** policies at specific lifecycle events.

Hooks work the same way. They're **deterministic automation that runs at specific points in Copilot's lifecycle**.

**When to use:**
- Policy enforcement that must NEVER be skipped
- Automatic validation before/after Copilot uses a tool
- Injecting runtime context (environment variables, team config)
- Blocking dangerous operations (file deletions, force pushes)
- Auto-formatting after file edits

**SDLC Examples:**

| Scenario | Hook Event | What It Does |
|---|---|---|
| Block `rm -rf` commands | `PreToolUse` | Checks if terminal command contains dangerous patterns, blocks it |
| Auto-format Java code after edit | `PostToolUse` | Runs `google-java-format` on edited files |
| Inject team context at start | `SessionStart` | Adds current sprint goals, on-call info, active incidents |
| Require confirmation before DB changes | `PreToolUse` | Prompts for approval when migration files are being modified |
| Log all file edits for audit | `PostToolUse` | Records what files were changed, by whom, when |

**Why not an Instruction?** Instructions are **guidance** — Copilot *should* follow them, but they're not enforced. A hook is **enforcement** — it literally intercepts the action and can block it. Like the difference between a "Please don't run in the hallway" sign (instruction) vs a speed bump (hook).

**Why not a Prompt?** Prompts are on-demand. Hooks are automatic. You don't invoke a hook — it runs at the lifecycle event, whether you want it to or not. That's the point.

---

## Comparison Matrix

| Dimension | Instruction | Prompt | Agent | Skill | Hook |
|---|---|---|---|---|---|
| **SDLC Analog** | Linting config | CI template | QA reviewer | Runbook/Playbook | Git hook / CI gate |
| **Active** | Always (or per file type) | Only when invoked | Only when selected | Only when invoked | Always at lifecycle events |
| **Invocation** | Automatic | `/command-name` | Agent picker | `/skill-name` | Automatic |
| **Tool Restriction** | ❌ No | ⚠️ Optional | ✅ Yes (core feature) | ❌ No | N/A |
| **Bundled Assets** | ❌ No | ❌ No | ❌ No | ✅ Yes (scripts, templates) | ❌ No (shell script only) |
| **Persona** | ❌ No | ❌ No | ✅ Yes | ❌ No | ❌ No |
| **Enforcement** | Guidance only | Guidance only | Guidance only | Guidance only | ✅ Deterministic |
| **Context Cost** | Loaded into context | Loaded on invoke | Loaded on select | Progressive loading | No context cost |
| **Version Controlled** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |

---

## Overlap & Hybrid Patterns

Sometimes features work together. These are common patterns in production teams:

| Pattern | What Happens |
|---|---|
| **Prompt references Instruction** | Prompt says "Follow the rules in `java-conventions.instructions.md`" — combines task template with ongoing rules |
| **Agent invokes Prompt** | Security auditor agent runs `/check-dependencies` prompt as part of its review |
| **Skill references Agent** | Onboarding skill delegates "review architecture" step to a read-only `architecture-reviewer` agent |
| **Hook + Instruction** | Instruction says "use 4-space indentation". Hook runs formatter after every edit to guarantee it. Belt AND suspenders. |
| **Prompt triggers Skill** | `/deploy-to-staging` prompt loads the `deployment` skill for the full runbook procedure |

---

## Anti-Patterns — Common Mistakes

| Mistake | Why It's Wrong | Fix |
|---|---|---|
| Putting ongoing rules in a Prompt | Rules only apply when you remember to invoke | Move to Instruction |
| Using default agent when review needs to be read-only | Copilot might accidentally modify files during review | Create Agent with `tools: [read, search]` |
| Writing long procedure steps in a Prompt when they need templates | Template quality is inconsistent without a source file | Convert to Skill with bundled templates |
| Using Instruction for something that MUST happen | Instructions are guidance — agent might not follow | Add a Hook for enforcement |
| Creating an Agent when you just need a one-shot task | Overkill — agent persona is unnecessary for simple generation | Use a Prompt |
| Bundling everything into one mega-Skill | Hard to maintain, loads too much context | Split into focused Skills, one per workflow |

---

_Last Updated: 7 March 2026_
