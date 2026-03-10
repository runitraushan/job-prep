# Copilot Instructions — Job Prep 2026

> **Purpose:** This file serves as persistent context and guidelines for GitHub Copilot across this workspace. Always refer to this file, follow the guidelines, and keep it updated as new information becomes available.

---

## 1. Candidate Profile

| Field | Details |
|---|---|
| **Current Role** | Senior Software Engineer |
| **Target Role** | Staff Software Engineer |
| **Experience** | 10+ years in Backend Engineering |
| **Core Stack** | Java, Spring Boot, Microservices |
| **Key Skills** | Java EE (JMS, JPA, Servlets), Spring MVC, Hibernate, REST APIs, Cloud-Native Architecture, Distributed Systems |
| **Resume** | _Not yet shared — update this section when resume is provided_ |

---

## 2. Workspace Purpose

This workspace is dedicated to **company-wise job interview preparation** for Staff Software Engineer roles at top tech companies. Preparation covers all interview round types end-to-end.

---

## 3. Workspace Structure

```
Job Prep 2026/
├── Runit_Kumar_Raushan_Resume_Improved.md   # Resume (primary)
├── Companies/
│   └── <CompanyName>/
│       ├── <CompanyName>-<Role>-JD.md         # Job Description (user provides)
│       ├── <CompanyName>-<Role>-Analysis.md   # Generated from JD
│       ├── DSA/                     # DSA + Machine Coding
│       ├── System-Design/           # HLD + LLD
│       └── Behavioral/              # STAR format
```

Use `/new-company-prep` to set up a new company. Full workflow is in `.github/prompts/new-company-prep.prompt.md`.

---

## 4. Copilot Behavior Guidelines

### Always Do
- **Use Java** as the primary language for all DSA and coding solutions unless specified otherwise
- **Include time & space complexity** analysis for every DSA solution
- **Discuss trade-offs** in design rounds (consistency vs availability, SQL vs NoSQL, sync vs async, etc.)
- **Tailor solutions** to the Java/Spring Boot/Microservices ecosystem
- **Track progress** using todo lists for multi-step tasks
- **Suggest Plan mode** for strategizing/research, **Agent mode** for execution

### Never Do
- Don't skip complexity analysis for DSA problems
- Don't provide design solutions without discussing trade-offs
- Don't create unnecessary files — only what's needed for prep

---

## 5. Level-Up Context: Senior → Staff

Since the candidate is targeting a **level-up from Senior SE to Staff SE**, Copilot should emphasize:

- **System-level thinking** over component-level thinking
- **Leadership narratives** — leading without authority, mentoring, driving technical direction
- **Architectural decisions** — why, not just how
- **Cross-functional influence** — working with product, driving roadmaps
- **Scope expansion** — demonstrating impact beyond immediate team
- **Engineering excellence** — setting standards, improving processes, reducing toil

In behavioral prep, always prepare "Why Staff?" narratives backed by concrete examples.

---

## 6. Companies — Prep Tracker

| Company | Role | Analysis | DSA | System Design | Behavioral | Status |
|---|---|---|---|---|---|---|
| PayPal | Staff SE — Backend | ✅ | Not Started | Not Started | Not Started | 🔄 In Progress |

---

## 7. Resume

Primary resume: `Runit_Kumar_Raushan_Resume_Improved.md` (root of workspace)

---

_Last Updated: 7 March 2026_
