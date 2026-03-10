---
name: company-setup
description: "Sets up a complete interview prep workspace for a new company. Creates folder structure, processes JD, runs resume-vs-JD analysis, and generates a standardized analysis doc using templates. Use when adding a new company to the Job Prep workspace."
argument-hint: "Company name and role (e.g., Google Staff Backend Engineer)"
---

# Company Setup Skill

## Purpose

Scaffold a complete interview prep workspace for a new target company — including folder structure, JD intake, resume-vs-JD analysis, and a standardized analysis document — using bundled template files to ensure consistency across all companies.

## When to Use

- User says "set up prep for [company]" or "add [company] to my prep"
- User invokes `/company-setup`
- User wants to start interview prep for a new company

## Steps

### Step 1: Create Folder Structure

Create the company folder and subfolders:

```
Companies/{{COMPANY}}/
├── DSA/
├── System-Design/
├── Behavioral/
├── HLD/
├── LLD/
└── Machine-Coding/
```

### Step 2: Ask for JD

Ask the user to place the Job Description file inside the company folder as:
`Companies/{{COMPANY}}/{{COMPANY}}-{{ROLE}}-JD.md`

**Wait for the user to confirm the JD is ready before proceeding.** Do not generate or guess the JD.

### Step 3: Resume vs JD Analysis

Read the candidate's resume from `Runit_Kumar_Raushan_Resume_Improved.md` (workspace root) and the JD file. Compare them to identify:
- **Strong Synergies** — skills/experience that directly match JD requirements
- **High-Risk Gaps** — critical requirements missing from resume
- **Medium-Risk Gaps** — nice-to-have requirements not covered
- **Narrative Angles** — how to frame experience to cover gaps

This analysis becomes Section 3 of the analysis doc.

### Step 4: Create Analysis Doc

Use the template at [analysis-template.md](./assets/analysis-template.md) to create:
`Companies/{{COMPANY}}/{{COMPANY}}-{{ROLE}}-Analysis.md`

**Critical:** Follow the template structure exactly. Replace all `{{PLACEHOLDER}}` values with actual content based on the JD, resume analysis, and research. Do not invent new sections or skip existing ones.

### Step 5: Update Prep Tracker

Update the Prep Tracker table in `.github/copilot-instructions.md` by adding a new row:

```
| {{COMPANY}} | {{ROLE}} | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |
```

### Step 6: Remind About Next Steps

After creating the analysis doc, remind the user:
- Use `@interview-researcher` agent to collect specific interview questions into DSA/, System-Design/, and Behavioral/ folders
- The agent will use standardized templates from this skill: [DSA template](./assets/dsa-questions-template.md), [SD template](./assets/sd-questions-template.md), [Behavioral template](./assets/behavioral-questions-template.md)
- Use `/hld-solution` and `/lld-solution` prompts to generate design solutions

## Rules

- **Always use the template files** in `./assets/` — never generate analysis doc structure from memory
- Analysis doc covers topics at a HIGH LEVEL only (e.g., "Sliding Window", "Payment Gateway Design")
- Specific questions and problem files go in DSA/, System-Design/, Behavioral/ folders — handled by `@interview-researcher`, not this skill
- Do not proceed past Step 2 until the user confirms JD is ready
- Tailor all content to the Java/Spring Boot/Microservices ecosystem
- Include Staff-level focus: system thinking, leadership narratives, architectural decisions
