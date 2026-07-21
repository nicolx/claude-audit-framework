---
description: Quarterly competency review — assess skill progress, update user_profile.md, and set the next review date.
allowed-tools: [Read, Bash]
---

> **Execution constraints:** Run entirely in this conversation. Do NOT spawn subagents.

## Purpose

Assess whether competencies in `~/.claude/context/user_profile.md` have changed since the last review — improvements, regressions, or new skills acquired. Update the profile and set the next review date.

## Step 1 — Read the current profile

Read `~/.claude/context/user_profile.md` in full. Note:
- All `Base *` competencies (priority targets)
- All `Operativo` competencies (candidates for promotion)
- The current `next_review_date`

## Step 2 — Conduct the assessment

Ask the following questions **one section at a time**, waiting for the user's answer before moving to the next.

### Section A — Base * competencies (priority)

For each `Base *` entry, ask two concrete questions that test actual knowledge — not self-perception. Examples:

**Docker:**
- Can you write a Dockerfile for a PHP application from memory?
- Can you use Docker Compose to wire a PHP app with a database service?

**TypeScript:**
- Can you type a function with generics and union types without looking them up?
- Have you written TypeScript in a real project, even small?

**Functional programming:**
- Can you use map, filter, and reduce without looking them up in PHP or JS?
- Have you applied immutability or pure function principles in a recent project?

**Redis:**
- Can you configure Redis as a Symfony cache backend independently?
- Do you understand TTL and cache invalidation strategies?

**OpenAPI / Swagger:**
- Can you write a basic OpenAPI YAML spec for a REST endpoint from scratch?
- Have you used Swagger UI or a similar tool to document an API?

For each: if both answers are confidently yes → propose promotion to `Operativo`.
If one yes, one no → keep `Base *` but note progress.
If both no → keep `Base *`, note no change.

### Section B — Operativo competencies (verify level + promotion candidates)

For each `Operativo` entry, ask one or two concrete questions that test actual knowledge — not self-perception. The goal is twofold: confirm the skill is still at Operativo level (no regression to Base), and assess whether it has matured to Fluente.

Examples by area:
- **DDD**: Can you design a bounded context and identify its aggregate roots for a domain you haven't seen before, without guidance?
- **Behat**: Can you write a full feature file with background, scenario outline, and custom step definitions independently?
- **Cloud**: Can you provision, configure, and connect cloud services (compute, storage, networking) for a new project without following a tutorial?
- **jQuery**: Can you handle DOM manipulation, AJAX, and event delegation without looking things up?

If answers show deep, automatic command → propose promotion to `Fluente`.
If answers show competence with occasional hesitation → keep `Operativo`.
If answers reveal significant gaps → propose demotion to `Base`.

### Section C — Currency check for Fluente and Operativo

Skills can become outdated even when actively used. For each `Fluente` and `Operativo` entry, ask one question that probes current best practices — not just whether the skill exists, but whether the knowledge is up to date.

Examples:
- **PHP / Symfony**: Are you using PHP 8 features (enums, fibers, readonly properties, named arguments) naturally in new code?
- **Design Patterns**: Beyond GoF classics, are you familiar with patterns that have emerged in DDD and distributed systems contexts?
- **CI/CD**: Are your pipelines using current practices (matrix builds, reusable workflows, OIDC-based secrets, environment protection rules)?
- **REST/API design**: Do you apply current standards for versioning, error responses (RFC 9457 Problem Details), and hypermedia where appropriate?
- **SQL**: Are you comfortable with window functions, CTEs, and lateral joins in practice?

If the knowledge is current and confidently applied → level confirmed.
If the area has evolved and the user hasn't kept up → flag the specific gap; do not change the level automatically, but note it as a learning target.
If the skill is clearly rusty or the knowledge is outdated across the board → propose demotion one level.

### Section D — New competencies acquired

Ask: "Have you worked with any technology or technique not in the current profile? Anything new since the last review?"

Add any new entries at the appropriate level.

### Section E — Trend radar

This section is Claude's responsibility, not the user's. Based on the current state of the industry and the user's existing profile, identify:

1. **Technologies gaining significant adoption** that are adjacent to the user's existing strengths — not novelties, but tools or patterns that are becoming standard in contexts where the user already operates (microservices, backend, API design, PHP ecosystem, cloud-native).

2. **Patterns or practices** that have moved from "emerging" to "expected" in professional contexts since the last review.

3. **Trains worth considering** — where the user's current `*` gaps have changed in urgency or relevance given industry movement.

For each candidate, state explicitly:
- Why it's relevant to the user's specific profile (not generically)
- Whether it builds depth on existing strengths or opens a new direction
- A clear recommendation: worth adding as `Base *`, watch-and-wait, or not relevant given the focus preference

Then ask the user: "Do you want to add any of these to your profile?"

Do not add anything without explicit confirmation. This section is advisory, not automatic.

## Step 3 — Propose updates

Present a summary of proposed changes:
- Promotions: Base * → Operativo, Operativo → Fluente
- Regressions: Fluente → Operativo (if any)
- New entries

Ask the user to confirm before writing.

## Step 4 — Update the profile

Apply confirmed changes to `~/.claude/context/user_profile.md`.
Update `next_review_date` to today + 3 months.
