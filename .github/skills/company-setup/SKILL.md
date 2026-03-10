---
name: company-setup
description: "Sets up a complete interview prep workspace for a new company. Creates folder structure, processes JD, runs resume-vs-JD analysis, and generates a standardized analysis doc using templates. Supports any role type and experience level."
argument-hint: "Company name, role, and level (e.g., Google Staff Backend Engineer)"
---

# Company Setup Skill

## Purpose

Scaffold a complete interview prep workspace for a new target company — including folder structure, JD intake, resume-vs-JD analysis, and a standardized analysis document — using bundled template files to ensure consistency across all companies. Supports any role type (Backend, Frontend, Full-Stack, DS/ML, QA/SDET, DevOps/SRE) and any experience level.

## When to Use

- User says "set up prep for [company]" or "add [company] to my prep"
- User invokes `/company-setup`
- User wants to start interview prep for a new company

## Steps

### Step 0: Detect Role Profile

Read the [role-profiles.md](./assets/role-profiles.md) file. From the user's input (company name, role title, level), determine:
1. **Role type** — match to one of the defined profiles (Backend, Frontend, Full-Stack, DS/ML, QA/SDET, DevOps/SRE)
2. **Current level → Target level** (e.g., Senior → Staff)
3. **Primary language** — from the role profile (or ask user if unclear)
4. **Folder structure** — from the role profile's folder list

If the role doesn't clearly match a profile, ask the user to clarify. For Full-Stack roles, analyze the JD later (Step 3) to determine frontend/backend weightage.

### Step 1: Create Folder Structure

Create the company folder and **role-specific subfolders** from the matched role profile:

```
Companies/{{COMPANY}}/
└── <folders from role profile>
```

For example, a Backend role creates `DSA/`, `HLD/`, `LLD/`, `Machine-Coding/`, `Behavioral/`, while a Frontend role creates `DSA/`, `Component-Design/`, `Behavioral/`.

### Step 2: Ask for JD

Ask the user to place the Job Description file inside the company folder as:
`Companies/{{COMPANY}}/{{COMPANY}}-{{ROLE}}-JD.md`

**Wait for the user to confirm the JD is ready before proceeding.** Do not generate or guess the JD.

### Step 3: Resume vs JD Analysis

Read the candidate's resume (check `WORKSPACE.md` for the configured resume path, default: `Runit_Kumar_Raushan_Resume_Improved.md`) and the JD file. Compare them to identify:
- **Strong Synergies** — skills/experience that directly match JD requirements
- **High-Risk Gaps** — critical requirements missing from resume
- **Medium-Risk Gaps** — nice-to-have requirements not covered
- **Narrative Angles** — how to frame experience to cover gaps

This analysis becomes Section 3 of the analysis doc.

### Step 4: Create Analysis Doc

Use the template at [analysis-template.md](./assets/analysis-template.md) to create:
`Companies/{{COMPANY}}/{{COMPANY}}-{{ROLE}}-Analysis.md`

**Critical:** Follow the template structure exactly. Replace all `{{PLACEHOLDER}}` values — including `{{ROLE_PROFILE}}`, `{{PRIMARY_LANGUAGE}}`, `{{CURRENT_LEVEL}}`, `{{TARGET_LEVEL}}` — with actual content based on the detected role profile, JD, resume analysis, and research. Do not invent new sections or skip existing ones.

Use the role profile's **analysis template section mappings** to know which sections are relevant for this role.

### Step 5: Update Prep Tracker

Update the Prep Tracker table in `WORKSPACE.md` (Section 8) by adding a new row:

```
| {{COMPANY}} | {{ROLE}} | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |
```

### Step 6: Remind About Next Steps

After creating the analysis doc, remind the user:
- Use `@interview-researcher` agent to collect specific interview questions into the role-appropriate folders
- The agent will use standardized templates from this skill: [DSA template](./assets/dsa-questions-template.md), [SD template](./assets/sd-questions-template.md), [Behavioral template](./assets/behavioral-questions-template.md)
- Use the **hld-solution**, **lld-solution**, or **dsa-solution** skills to generate practice solutions

## Rules

- **Always use the template files** in `./assets/` — never generate analysis doc structure from memory
- **Always detect the role profile first** (Step 0) — folder structure and content depend on it
- Analysis doc covers topics at a HIGH LEVEL only (e.g., "Sliding Window", "Payment Gateway Design")
- Specific questions and problem files go in role-appropriate folders — handled by `@interview-researcher`, not this skill
- Do not proceed past Step 2 until the user confirms JD is ready
- Use the **role's primary language** for any code references — do not hardcode Java
- Adapt level framing based on `{{CURRENT_LEVEL}} → {{TARGET_LEVEL}}` from role profile guidance
