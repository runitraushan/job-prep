# Copilot Customization — Cheat Sheet

> Quick reference for all VS Code Copilot customization features, syntax, and usage.

---

## All Available Features

| # | Feature | What It Does | Analogy |
|---|---------|-------------|---------|
| 1 | **Workspace Instructions** | Always-on rules for this project | Welcome sign on the office door |
| 2 | **File Instructions** | Rules loaded based on file type or task | Labeled toolbox — only opens when needed |
| 3 | **Prompts** | Reusable task templates (slash commands) | Recipe card — pick and run |
| 4 | **Custom Agents** | Specialized personas with restricted tools | Expert you call for a specific job |
| 5 | **Skills** | Multi-step workflows with bundled scripts/templates | Full toolkit with manual |
| 6 | **Hooks** | Automatic shell commands at lifecycle events | Security guard — checks things before/after |

---

## 1. Workspace Instructions (`copilot-instructions.md`)

**What:** Project-wide rules that Copilot always follows in this workspace.

**Location:** `.github/copilot-instructions.md`

**Syntax:** Plain markdown, no frontmatter needed.

```markdown
# Project Guidelines

## Code Style
- Use Java for all DSA solutions
- Follow STAR format for behavioral prep

## Architecture
- Microservices-first approach
```

**When loaded:** Every single chat in this workspace — automatically.

**Invoke:** No action needed. It's always active.

---

## 2. File Instructions (`.instructions.md`)

**What:** Rules that load based on file type, folder, or task relevance.

**Location:**
- Workspace: `.github/instructions/*.instructions.md`
- User (all workspaces): `~/Library/Application Support/Code/User/prompts/*.instructions.md`

**Syntax:**

```yaml
---
description: "Use when: writing Java DSA solutions. Covers coding style and complexity analysis."
applyTo: "**/*.java"
---

# Java DSA Rules

- Always include time & space complexity
- Use meaningful variable names
```

**Key fields:**
| Field | Required? | What It Does |
|-------|-----------|-------------|
| `description` | Recommended | Helps Copilot decide when to load (keyword matching) |
| `applyTo` | Optional | Auto-load for matching files (`"**"` = always, `"**/*.java"` = Java only) |

**When loaded:**
- If `applyTo` is set → when working with matching files
- If only `description` is set → when Copilot detects task relevance
- Both can be set together

**Invoke:** Automatic. Or manually via `Add Context` → `Instructions` in chat.

---

## 3. Prompts (`.prompt.md`)

**What:** One-click task templates. Like shortcuts for common tasks.

**Location:**
- Workspace: `.github/prompts/*.prompt.md`
- User (all workspaces): `~/Library/Application Support/Code/User/prompts/*.prompt.md`

**Syntax:**

```yaml
---
description: "Set up a new company folder with standard prep structure"
agent: "agent"
---

Create a new company prep folder under Companies/ with:
- Analysis doc template
- DSA, HLD, LLD, Behavioral subfolders
```

**Key fields:**
| Field | Required? | What It Does |
|-------|-----------|-------------|
| `description` | Recommended | Shown in the prompt picker |
| `agent` | Optional | Which mode to run in: `agent`, `ask`, `plan`, or a custom agent name |
| `model` | Optional | Force a specific AI model |
| `tools` | Optional | Restrict which tools the prompt can use |
| `argument-hint` | Optional | Hint text shown in chat input after selecting |

**How to invoke:**
```
Method 1: Type "/" in chat → pick from list
Method 2: Command Palette → "Chat: Run Prompt..."
Method 3: Open the .prompt.md file → click play button
```

**Example — if file is named `new-company-prep.prompt.md`:**
```
Type: /new-company-prep
```

---

## 4. Custom Agents (`.agent.md`)

**What:** Specialized personas with their own tools, rules, and personality. Like hiring a specialist.

**Location:**
- Workspace: `.github/agents/*.agent.md`
- User (all workspaces): `~/Library/Application Support/Code/User/agents/*.agent.md`

**Syntax:**

```yaml
---
description: "Use for reviewing system design docs. Checks for missing trade-offs and capacity estimates."
tools: [read, search]
---

You are a system design reviewer. Your job is to review design documents and flag:
- Missing trade-offs
- Missing capacity estimation
- Unclear API contracts

## Constraints
- DO NOT modify any files
- ONLY provide review comments
```

**Key fields:**
| Field | Required? | What It Does |
|-------|-----------|-------------|
| `description` | Required | How Copilot discovers and describes this agent |
| `tools` | Optional | Restrict what tools this agent can use |
| `model` | Optional | Force a specific AI model |
| `user-invocable` | Optional | `false` = hidden from picker, only usable as subagent |

**Tool aliases:**
| Alias | Means |
|-------|-------|
| `execute` | Run terminal commands |
| `read` | Read files |
| `edit` | Edit files |
| `search` | Search files/text |
| `web` | Fetch URLs, web search |
| `agent` | Can call other agents |
| `todo` | Manage task lists |

**How to invoke:**
```
In chat → click the agent selector (dropdown) → pick your custom agent
```

---

## 5. Skills (`SKILL.md`)

**What:** Multi-step workflows with bundled scripts, templates, and reference docs. Like a full instruction manual with tools included.

**Location:**
```
.github/skills/<skill-name>/
├── SKILL.md           # Required — main instructions
├── scripts/           # Optional — executable scripts
├── references/        # Optional — docs loaded as needed
└── assets/            # Optional — templates, boilerplate
```

**Syntax (SKILL.md):**

```yaml
---
name: company-setup
description: "Set up a new company prep workspace with folders, templates, and analysis doc."
---

# Company Setup

## When to Use
- Starting prep for a new company

## Procedure
1. Create company folder under Companies/
2. Run [setup script](./scripts/setup.sh)
3. Generate analysis doc from [template](./assets/analysis-template.md)
```

**Key rules:**
- Folder name MUST match the `name` field
- `name`: lowercase, hyphens only (e.g., `company-setup`)

**How to invoke:**
```
Type "/" in chat → appears alongside prompts in the list
```

---

## 6. Hooks (`.json`)

**What:** Shell commands that run automatically at specific lifecycle events. For enforcing rules deterministically (not just guidance).

**Location:** `.github/hooks/*.json`

**Syntax:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./scripts/validate.sh",
        "timeout": 15
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "./scripts/format.sh"
      }
    ]
  }
}
```

**Available events:**
| Event | When It Runs |
|-------|-------------|
| `SessionStart` | First prompt of a new chat |
| `UserPromptSubmit` | User sends a message |
| `PreToolUse` | Before Copilot uses a tool |
| `PostToolUse` | After Copilot uses a tool |
| `Stop` | Chat session ends |

**When to use:** Only when you need **guaranteed enforcement** — like blocking dangerous commands or auto-formatting. For most cases, instructions are enough.

---

## Quick Comparison

| Feature | Always Active? | How to Trigger | Best For |
|---------|---------------|----------------|----------|
| Workspace Instructions | ✅ Yes | Automatic | Project-wide rules |
| File Instructions | Depends on `applyTo` | Automatic or manual | File-type-specific rules |
| Prompts | ❌ No | `/command-name` | One-off tasks |
| Custom Agents | ❌ No | Agent picker | Specialized workflows |
| Skills | ❌ No | `/skill-name` | Multi-step workflows |
| Hooks | ✅ Yes | Automatic on events | Enforcement & automation |

---

## Folder Structure — Complete

```
.github/
├── copilot-instructions.md              # Workspace instructions (always on)
├── instructions/
│   ├── java-coding.instructions.md      # File-specific instructions
│   └── markdown-docs.instructions.md
├── prompts/
│   ├── new-company-prep.prompt.md       # Slash commands
│   └── dsa-solution.prompt.md
├── agents/
│   ├── design-reviewer.agent.md         # Custom agents
│   └── code-reviewer.agent.md
├── skills/
│   └── company-setup/                   # Skills (folder per skill)
│       ├── SKILL.md
│       ├── scripts/
│       └── assets/
└── hooks/
    └── pre-tool-validation.json         # Lifecycle hooks
```

---

_Last Updated: 7 March 2026_
