---
description: First-time developer profile setup for claude-audit-framework
allowed-tools: [Read, Write, Bash]
---

> **Execution constraints:** Run entirely in this conversation. Do NOT spawn subagents.

## Purpose

Create a developer profile at `~/.claude/context/user_profile.md`. This profile calibrates all recommendations from `claude-audit-framework` to your skill level — across every project that uses this framework.

**The profile lives on your machine, not in the project repo.** It is personal and never committed.

---

## Step 1 — Check for existing profile

```bash
cat ~/.claude/context/user_profile.md 2>/dev/null && echo "---PROFILE_EXISTS---" || echo "---PROFILE_MISSING---"
```

**If `PROFILE_EXISTS`:** Tell the developer:
> A profile already exists. To update it after skill changes, run `/competency-review` instead.
> Do you want to overwrite the existing profile from scratch? (yes / no)

If they say no, stop here. If yes, continue.

**If `PROFILE_MISSING`:** Continue immediately.

---

## Step 2 — Introduction

Tell the developer:

> "I'm going to ask you a few questions about your technical background. Answer honestly — this isn't a test, there are no wrong answers. The goal is to ensure that when I recommend solutions, I pitch them at the right level for you.
>
> For each area, I'll use three levels:
>
> - **Fluente** — you're comfortable, can reason about edge cases, rarely need to look things up
> - **Operativo** — you work independently but look things up occasionally; you know the concepts
> - **Base** — you understand the basics but would need guidance or examples for real tasks
>
> Entries you mark as priority learning targets get a `*` — when a task requires one of those, I'll flag it and we'll address it together rather than work around it."

---

## Step 3 — Assessment (one section at a time, wait for answers)

### Section A — Role

Ask:

1. "What is your primary role? (e.g., backend developer, fullstack, frontend, DevOps, architect, tech lead)"
2. "What language or stack do you spend most of your time in?"

### Section B — Languages

Ask: "For each of the following languages, what level are you at? Skip any you haven't used."

Languages to cover: PHP, JavaScript, TypeScript, Python, HTML/CSS, Bash/Shell, Java, Go, Kotlin, Swift, other languages they mention.

For any language rated Base, ask: "Is this a gap you're actively trying to fill? If so, I'll mark it as `*`."

### Section C — Paradigms & principles

Ask: "How would you rate yourself in these areas?"

- OOP (Object-Oriented Programming)
- Clean Code / SOLID principles
- Design Patterns (GoF and beyond)
- Domain-Driven Design (DDD)
- Functional programming

### Section D — Frameworks & libraries

Ask: "Which frameworks or libraries do you use regularly, and at what level?"

Suggest: Symfony, Laravel, React, Vue, Angular, Node.js/Express, Django, FastAPI, Spring/Spring Boot, other.

### Section E — Architecture & system design

Ask: "In architecture and system design:"

- REST / API design
- Event-driven systems / Message queues (RabbitMQ, Kafka, etc.)
- Microservices
- Modular Monolith
- CQRS / Event Sourcing
- Saga / Outbox / Circuit Breaker patterns
- Architecture Decision Records (ADRs)
- OpenAPI / Swagger

### Section F — Data

Ask: "On the data side:"

- SQL (basic queries, CRUD)
- SQL advanced (window functions, CTEs, lateral joins, query optimization)
- ORM usage (Doctrine, Eloquent, Hibernate, etc.)
- Performance & profiling (N+1, query analysis, memory)
- NoSQL (MongoDB, DynamoDB, etc.)
- Redis / caching

### Section G — Testing

Ask: "On testing:"

- Unit testing (PHPUnit, Jest, pytest, JUnit, etc.)
- BDD / acceptance testing (Behat, Cucumber, etc.)
- Integration testing
- Test-Driven Development (TDD) as a practice

### Section H — Infrastructure & DevOps

Ask: "On infrastructure:"

- Git (branching strategies, advanced workflows)
- CI/CD (GitHub Actions, GitLab CI, etc.)
- Docker / containerization
- Cloud platforms (AWS, GCP, Azure)
- Linux / CLI
- Observability tooling (Prometheus, Grafana, Datadog, etc.)

### Section I — Priority learning targets

Ask: "Looking at everything we've covered — are there specific areas not already marked as `*` where you're actively trying to level up?"

Add `*` to those entries.

---

## Step 4 — Propose the profile

Present the complete profile in this format and ask for confirmation:

```markdown
# User profile — [Name / Role]

> Read this before proposing technical solutions, architectural choices, or implementation strategies.
> Calibrate every proposal to the competency levels below.

## Competency levels

- **Fluente** — propose advanced patterns freely; skip basic explanations; use domain terms without glossing.
- **Operativo** — use in proposals but explain non-obvious choices; avoid advanced patterns without rationale.
- **Base** — avoid as a primary technology; prefer alternatives where available; when unavoidable, use simple patterns and explain clearly.

## On Base competencies marked with *

Entries marked with `*` are gaps the user intends to fill. When a task genuinely requires one of these competencies, do not work around it — stop, flag it explicitly, and address the gap together before proceeding.

## On tasks that combine multiple levels

Proceed freely through the Fluente and Operativo parts of a task without interruption. When the task crosses into **Base** or **Base `*`** territory, signal it explicitly before continuing:

> ⚠ Entering Base territory — [competency]. Proceeding with a simple approach; flag if you want to go deeper or address the gap now.

---

## Languages

| Language | Level |
|---|---|
[table rows from assessment]

## Paradigms

| Paradigm | Level |
|---|---|
[table rows]

## Techniques & principles

| Technique | Level |
|---|---|
[table rows]

## Frameworks & libraries

| Framework | Level |
|---|---|
[table rows]

## Data

| Area | Level |
|---|---|
[table rows]

## Architecture & design

| Area | Level |
|---|---|
[table rows]

## Testing

| Tool / approach | Level |
|---|---|
[table rows]

## Infrastructure & DevOps

| Area | Level |
|---|---|
[table rows]

---

## Review schedule

| Field | Value |
|---|---|
| Cadence | Quarterly |
| Next review | [today + 3 months] |
| Command | `/competency-review` |
```

Ask: "Does this look right? Any corrections before I save it?"

---

## Step 5 — Save the profile

After confirmation:

```bash
mkdir -p ~/.claude/context
```

Write the confirmed profile content to `~/.claude/context/user_profile.md`.

Confirm:
> "Profile saved to `~/.claude/context/user_profile.md`. From now on, all recommendations in any project using `claude-audit-framework` will be calibrated to your skill level. Run `/competency-review` in 3 months to update it."
