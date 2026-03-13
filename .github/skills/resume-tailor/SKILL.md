---
name: resume-tailor
description: "Analyzes gaps between resume and JD, then suggests targeted resume improvements interactively. Reads the analysis doc's gap analysis, cross-references every resume bullet, and proposes exact rewrites. Updates the company-specific resume only with user-confirmed changes. Works for any role type."
argument-hint: "Company name (e.g., Airbnb)"
---

# Resume Tailor Skill

## Purpose

Deeply analyze the gap between a candidate's resume and a target company's JD, then interactively suggest **specific, actionable resume improvements** that maximize the chance of passing both ATS screening and human review. This skill is the difference between a generic resume and one that speaks directly to what the company is looking for.

## When to Use

- After company-setup is complete (analysis doc exists with gap analysis)
- User says "tailor my resume for [company]" or "improve my resume for [company]"
- User invokes `/resume-tailor`
- Before submitting an application to a specific company

## Prerequisites

Before running, the following must exist:
1. **Analysis doc** — `Companies/<Company>/<Company>-*-Analysis.md` (with Section 3: Resume vs JD Fit Analysis)
2. **Company-specific resume** — `Companies/<Company>/Resume-<Company>.md` (copied from base resume during company-setup)
3. **JD file** — `Companies/<Company>/<Company>-*-JD.md`

If any are missing, tell the user and suggest running company-setup first.

## Workflow

### Phase 1: Deep Gap Analysis

Read all three files (analysis doc, company resume, JD). For each gap identified in Section 3 of the analysis doc (both High-Risk and Medium-Risk), perform a **deep cross-reference**:

1. **Search the entire resume** for any bullet that could address this gap — even partially or indirectly
2. **Classify the gap type:**
   - **Missing Experience** — the candidate genuinely doesn't have this experience
   - **Hidden Experience** — the experience exists but isn't visible on the resume (buried, underframed, or missing keywords)
   - **Reframeable** — existing bullets can be reworded to better address this gap
   - **Keyword Gap** — the experience is there but JD-specific terminology is missing

3. **For each gap, prepare a suggestion** with:
   - What JD requirement it addresses
   - The gap type (from above)
   - The exact current resume text (if reframing)
   - The proposed change
   - Why this change helps (what signal it sends to the reviewer)

### Phase 2: ATS & Keyword Optimization

Beyond gaps, scan the full JD for **high-value keywords and phrases** that are absent from the resume:

1. **Technical keywords** — specific technologies, frameworks, methodologies mentioned in JD
2. **Domain keywords** — industry terms, business concepts (e.g., "payment processing", "compliance", "observability")
3. **Action verbs** — verbs the JD uses that signal seniority expectations (e.g., "architect", "drive", "lead", "influence")
4. **Soft skill signals** — collaboration styles the JD emphasizes (e.g., "cross-functional", "cross-geographical")

For each missing keyword, identify WHERE in the existing resume it could be naturally incorporated.

### Phase 3: Structural Improvements

Evaluate the resume structure relative to this specific role:

1. **Bullet ordering** — are the most relevant achievements at the top of each role section?
2. **Quantification** — do impact bullets have numbers? (users processed, latency reduced, team size, etc.)
3. **Relevance weighting** — should any section be expanded or condensed for this role?
4. **Professional summary** — does the opening paragraph align with what this company needs?

### Phase 4: Interactive Suggestion Walkthrough

Present suggestions to the user **one category at a time**, in priority order:

#### Category 1: High-Risk Gap Fixes (🔴)
> These gaps could cause rejection. Address them first.

For each suggestion:
```
🔴 Gap: [JD requirement]
📋 Type: [Missing / Hidden / Reframeable / Keyword Gap]
📍 Location: [Which section/bullet of the resume]

Current text:
> [exact current bullet, or "N/A — no existing bullet"]

Suggested change:
> [exact proposed new text]

💡 Why: [What signal this sends to the reviewer]

❓ Question: [Ask if the experience is real, if the framing is accurate, etc.]
```

**Wait for user response before proceeding to the next suggestion.**

Possible user responses:
- ✅ "Yes, apply this" → apply the change to `Resume-<Company>.md`
- ❌ "No, skip this" → log as rejected, move on
- 🔄 "I have this experience but differently..." → user provides details, you rewrite and confirm again
- ❓ "Tell me more" → explain the reasoning in depth

#### Category 2: Medium-Risk Gap Fixes (🟡)
Same format as above, but for nice-to-have gaps.

#### Category 3: ATS & Keyword Optimization
Present keyword additions as a batch (not one by one):
```
📝 Keywords to weave in:
| Keyword/Phrase | Where to Add | Current Text → Suggested Text |
|---|---|---|
| "distributed systems" | Professional Summary | "scalable microservices" → "scalable distributed microservices" |
```

Ask user to confirm the batch or pick which ones to apply.

#### Category 4: Structural Improvements
Present as recommendations:
```
📐 Structural Suggestions:
1. [Suggestion] — [Why]
2. [Suggestion] — [Why]
```

### Phase 5: Apply & Log

After all suggestions are walked through:

1. **Apply confirmed changes** to `Companies/<Company>/Resume-<Company>.md`
2. **Append a Tailoring Log** to the analysis doc as a new section (after the last existing section):

```markdown
## 12. Resume Tailoring Log

> **Date:** {{DATE}}
> **Base Resume:** `../../<resume-filename>`
> **Tailored Resume:** `Resume-{{COMPANY}}.md`

### Changes Applied

| # | Gap/Area | Type | Change Summary | Status |
|---|---|---|---|---|
| 1 | [JD requirement] | Reframe | [Brief description] | ✅ Applied |
| 2 | [JD requirement] | Hidden Experience | [Brief description] | ✅ Applied |
| 3 | [JD requirement] | Missing Experience | [Brief description] | ❌ Rejected — not applicable |

### Keywords Added
- [list of keywords woven in]

### Structural Changes
- [list of structural changes made]

### Summary
- **X** suggestions applied out of **Y** total
- **High-risk gaps addressed:** X/Y
- **ATS keyword coverage improvement:** before → after (estimated)
```

3. **Show a final summary** to the user:

```
✅ Resume Tailoring Complete for <Company>

📄 Updated: Companies/<Company>/Resume-<Company>.md
📋 Log saved: Section 12 of analysis doc

Changes applied: X of Y suggestions
High-risk gaps addressed: X of Y
Keywords added: X

Your company-specific resume is ready for submission.
Base resume (workspace root) remains unchanged.
```

## Rules

- **NEVER fabricate experience.** Only add what the user explicitly confirms is true. If unsure, ask.
- **Always read the analysis doc first** — don't regenerate gap analysis from scratch. Build on what's already documented.
- **Be specific, not vague.** "Add monitoring experience" is useless. "Add 'Implemented CloudWatch dashboards for API latency monitoring across 6 microservices' under the Pepstudy section" is actionable.
- **One suggestion at a time for gaps.** Don't dump everything at once — interactive confirmation prevents overwhelm and ensures accuracy.
- **Keywords can be batched** — small wording tweaks don't need individual confirmation.
- **Preserve the candidate's authentic voice.** Rewrite to be better, not to sound like a different person.
- **Always explain WHY.** The candidate should understand what signal each change sends to the reviewer — this builds interview confidence too.
- **Log everything.** Future chats should see exactly what was suggested, applied, and rejected — no regeneration needed.
- **Never modify the base resume** at the workspace root. Only modify `Resume-<Company>.md`.
- **Professional summary is high-impact.** Always evaluate and suggest improvements to the opening paragraph — it's the first thing reviewers read.
- **Quantify wherever possible.** Push for numbers — users served, percentage improvements, team sizes, system scale. Numbers catch the eye.
