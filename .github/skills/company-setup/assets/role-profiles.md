# Role Profiles

> Central reference for the company-setup skill. Defines interview structure, folder layout, language, and content strategy per role type.
> Backend profile is fully detailed. Other profiles are structural — flesh them out when first needed.

---

## How to Use This File

1. When setting up a company, **match the JD to a role profile** below
2. Use the profile's **folder structure** to create company subfolders
3. Use the profile's **analysis sections** to know which template sections to fill vs skip
4. Use the profile's **question templates** to know which templates `@interview-researcher` should use
5. Use the profile's **level framing** to adapt the analysis doc's level-up section

If the JD doesn't fit neatly into one profile (e.g., "Backend-heavy Full-Stack"), pick the **closest profile** and note adaptations in the analysis doc.

---

## Profile: Backend Engineer

> **Status:** ✅ Fully detailed

### Interview Rounds (Typical)
| Round | Type | Present? |
|-------|------|----------|
| Online Assessment / Screening | DSA / MCQ | Common |
| Technical Coding | DSA / Live Coding | Almost always |
| System Design — HLD | Distributed systems | Senior+ |
| System Design — LLD | OOP / Class design | Senior+ |
| Behavioral | STAR format | Almost always |
| Hiring Manager | Culture fit, career | Common |

### Folder Structure
```
Companies/{{COMPANY}}/
├── DSA/
│   ├── Solutions/
│   └── Practice/
├── HLD/
│   ├── Solutions/
│   └── Practice/
├── LLD/
│   ├── Solutions/
│   └── Practice/
└── Behavioral/
```

> **Convention:** Questions files (`*-Questions.md`) stay at the folder root. Skill-generated reference solutions go in `Solutions/`. Self-written practice answers go in `Practice/`.

### Primary Language
Java

### Analysis Template Sections
| Section # | Section Name | Include? |
|-----------|-------------|----------|
| 1 | Role Overview | ✅ Always |
| 2 | JD Requirements Breakdown | ✅ Always |
| 3 | Resume vs JD Fit Analysis | ✅ Always |
| 4 | Interview Process & Rounds | ✅ Always |
| 5 | Technical Assessment Topics | ✅ → **DSA Topics & Patterns** |
| 6 | Design Topics | ✅ → **System Design Topics** (HLD + LLD) |
| 7 | Behavioral Focus Areas | ✅ Always |
| 8 | Level-Up Signals | ✅ → **{{CURRENT_LEVEL}} → {{TARGET_LEVEL}} Signals** |
| 9 | Prep Strategy & Priority Matrix | ✅ Always |
| 10 | Key Insights from Online Sources | ✅ Always |
| 11 | Prep Progress Tracker | ✅ Always |

### Question Templates
- DSA → [dsa-questions-template.md](./dsa-questions-template.md)
- HLD → [hld-questions-template.md](./hld-questions-template.md)
- LLD → [lld-questions-template.md](./lld-questions-template.md)
- Behavioral → [behavioral-questions-template.md](./behavioral-questions-template.md)

### Skills / Prompts Available
- `dsa-solution` — generate DSA solutions (Java)
- `hld-solution` — generate HLD solutions
- `lld-solution` — generate LLD solutions
- `design-review-checklists` — review HLD/LLD docs
- `@design-reviewer` — agent for design doc review
- `@interview-researcher` — research interview questions

### Level Framing Guidance
| Target Level | Emphasis |
|-------------|----------|
| Junior / Mid | Fundamentals, clean code, correct solutions, communication |
| Senior | System thinking, ownership, mentoring, depth in trade-offs |
| Staff / Principal | Architecture decisions, cross-team influence, vision, "Why Staff?" narratives |
| Lead / Manager | People leadership, org-wide impact, strategy |

---

## Profile: Frontend Engineer

> **Status:** 🔲 Structural placeholder — detail when first needed

### Interview Rounds (Typical)
| Round | Type | Present? |
|-------|------|----------|
| Online Assessment | DSA / JS coding | Common |
| Technical Coding | DOM, component logic | Almost always |
| Component Design | React/Vue architecture | Senior+ |
| System Design (Frontend) | Performance, state mgmt | Senior+ |
| Behavioral | STAR format | Almost always |

### Folder Structure
```
Companies/{{COMPANY}}/
├── DSA/
├── Component-Design/
├── Frontend-System-Design/
└── Behavioral/
```

### Primary Language
JavaScript / TypeScript

### Analysis Template Sections
| Section # | Section Name | Include? |
|-----------|-------------|----------|
| 5 | Technical Assessment Topics | ✅ → **Frontend Coding Topics** (DOM, async, closures, component logic) |
| 6 | Design Topics | ✅ → **Frontend Design Topics** (component architecture, state management, performance) |
| All others | Same as Backend | ✅ |

### Question Templates
- DSA → use backend DSA template, override language to JS/TS
- Component Design → TO BE CREATED when needed
- Behavioral → use standard behavioral template

### Skills Available
- `dsa-solution` — override language to JS/TS in the analysis doc
- Component design skills → TO BE CREATED when needed

---

## Profile: Full-Stack Engineer

> **Status:** 🔲 Structural placeholder — JD-driven (not fixed split)

### How to Handle
Full-Stack roles vary widely. **Analyze the JD** to determine:
- **Backend-heavy** → use Backend profile + add `Component-Design/` folder
- **Frontend-heavy** → use Frontend profile + add `HLD/` folder
- **Balanced** → combine both profiles, all folders

### Interview Rounds (Typical)
Combination of Backend and Frontend rounds. The JD and online research determine which rounds are emphasized.

### Folder Structure
JD-driven. Start with Backend folders, add Frontend folders based on JD requirements.

### Primary Language
JD-driven (Java + JavaScript/TypeScript typically)

### Analysis Template Sections
Sections 5 and 6 should cover both backend and frontend topics, weighted by JD emphasis.

---

## Profile: Data Science / ML Engineer

> **Status:** 🔲 Structural placeholder — detail when first needed

### Interview Rounds (Typical)
| Round | Type | Present? |
|-------|------|----------|
| Coding | Python, SQL, data manipulation | Almost always |
| ML Concepts | Algorithms, statistics, feature engineering | Almost always |
| ML System Design | Pipeline architecture, model serving | Senior+ |
| Case Study | Business problem → ML solution | Common |
| Behavioral | STAR format | Almost always |

### Folder Structure
```
Companies/{{COMPANY}}/
├── Coding/
├── ML-Concepts/
├── ML-System-Design/
├── Case-Study/
└── Behavioral/
```

### Primary Language
Python

### Analysis Template Sections
| Section # | Section Name | Include? |
|-----------|-------------|----------|
| 5 | Technical Assessment Topics | ✅ → **ML & Coding Topics** (algorithms, statistics, pandas, SQL) |
| 6 | Design Topics | ✅ → **ML System Design Topics** (pipelines, feature stores, model serving) |
| All others | Same structure | ✅ |

### Question Templates
- TO BE CREATED when first needed

---

## Profile: QA / SDET

> **Status:** 🔲 Structural placeholder — detail when first needed

### Interview Rounds (Typical)
| Round | Type | Present? |
|-------|------|----------|
| Coding | Automation scripts, basic DSA | Common |
| Test Design | Test strategy, test cases | Almost always |
| Automation Architecture | Framework design, CI/CD | Senior+ |
| Behavioral | STAR format | Almost always |

### Folder Structure
```
Companies/{{COMPANY}}/
├── Coding/
├── Test-Design/
├── Automation-Architecture/
└── Behavioral/
```

### Primary Language
Java / Python (JD-driven)

### Analysis Template Sections
| Section # | Section Name | Include? |
|-----------|-------------|----------|
| 5 | Technical Assessment Topics | ✅ → **Testing & Coding Topics** (automation, test patterns, basic DSA) |
| 6 | Design Topics | ✅ → **Test Architecture Topics** (framework design, CI/CD pipeline) |
| All others | Same structure | ✅ |

---

## Profile: DevOps / SRE

> **Status:** 🔲 Structural placeholder — detail when first needed

### Interview Rounds (Typical)
| Round | Type | Present? |
|-------|------|----------|
| Coding | Scripting, basic DSA | Common |
| Infrastructure Design | Cloud architecture, CI/CD | Almost always |
| Troubleshooting | Incident response, debugging | Senior+ |
| Behavioral | STAR format | Almost always |

### Folder Structure
```
Companies/{{COMPANY}}/
├── DSA/
├── Infrastructure-Design/
├── Troubleshooting/
└── Behavioral/
```

### Primary Language
Python / Go / Bash (JD-driven)

### Analysis Template Sections
| Section # | Section Name | Include? |
|-----------|-------------|----------|
| 5 | Technical Assessment Topics | ✅ → **Scripting & DSA Topics** |
| 6 | Design Topics | ✅ → **Infrastructure Design Topics** (cloud architecture, CI/CD, monitoring) |
| All others | Same structure | ✅ |
