---
description: "Set up a new company interview prep workspace with folder structure, analysis doc, and research-based question collection"
agent: "agent"
argument-hint: "Company name and role (e.g., Google Staff Backend Engineer)"
---

Set up a complete interview prep workspace for a new company. The user will provide the company name and target role.

## Steps

### Step 1: Create Folder Structure

Create the company folder and subfolders:

```
Companies/<CompanyName>/
├── DSA/                    ← DSA + Machine Coding questions (separate files if needed)
├── System-Design/          ← HLD + LLD (separate files if they can be bifurcated)
└── Behavioral/             ← STAR format behavioral prep
```

### Step 2: Ask for JD

Ask the user to place the Job Description file inside the company folder as:
`Companies/<CompanyName>/<CompanyName>-<Role>-JD.md`

Wait for the user to confirm the JD is ready before proceeding.

### Step 3: Resume vs JD Analysis

Read the candidate's resume from [Resume](../../Runit_Kumar_Raushan_Resume_Improved.md) and compare it with the JD:
- **Synergies** — Highlight skills, experience, and projects from the resume that directly align with JD requirements
- **Gaps** — Identify skills or experience the JD requires that are missing or weak in the resume
- **Prep Recommendations** — Suggest what the candidate needs to learn or prepare to bridge the gaps

Include this analysis as a section in the analysis doc.

### Step 4: Create Analysis Doc

Once the JD is available, create `Companies/<CompanyName>/<CompanyName>-<Role>-Analysis.md` based on the JD.

Use the structure from [PayPal analysis](../../Companies/PayPal/PayPal-Staff-Backend-Engineer-Analysis.md) as reference template. The analysis doc MUST include:

1. **Role Overview** — What the company expects from this role
2. **JD Requirements Breakdown** — Must-have vs nice-to-have, mapped to prep areas
3. **Interview Process & Rounds** — How many rounds, what kind (DSA, LLD, HLD, System Design, Behavioral, etc.)
4. **DSA Topics & Patterns** — Key topics and patterns to focus on
5. **System Design Topics** — HLD and LLD topics relevant to this role
6. **Behavioral Focus Areas** — Key themes for STAR stories
7. **Senior → Staff Level-Up Signals** — What differentiates Staff from Senior at this company
8. **Prep Strategy & Priority Matrix** — What to prep first, time allocation
9. **Key Insights from Online Sources** — Glassdoor, AmbitionBox, LeetCode, Blind, etc.
10. **Prep Progress Tracker** — Checklist to track completion

### Step 5: Update Prep Tracker

Update the Prep Tracker table in [copilot-instructions.md](../../.github/copilot-instructions.md) by adding a new row for this company with all columns set to "Not Started".

## Rules

- Follow the exact folder structure defined above (simplified: DSA, System-Design, Behavioral)
- Analysis doc should be created ONLY after JD is provided by the user
- The analysis doc covers topics/patterns at a HIGH LEVEL only (e.g., "Sliding Window", "Payment Gateway Design"). Specific questions and concrete problem files go in DSA/, System-Design/, Behavioral/ folders — but that's handled separately by the Interview Researcher agent, not this prompt.
- After creating the analysis doc, remind the user they can use the `@interview-researcher` agent to collect specific questions into the prep folders
