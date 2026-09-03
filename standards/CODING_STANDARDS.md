# Coding Standards

> Governs how Claude Code writes and proposes code — in any language, at any scale.
> Applied before every implementation decision, not on demand.
> Sister document to `PROJECT_AUDIT_FRAMEWORK.md`: these principles define what good
> looks like; the framework measures how close existing code comes to them.

---

## Project-level specializations (optional)

For projects where these global principles need grounding in a specific technology
stack, create a `CODING_STANDARDS.md` in the project's `.claude/` directory. Claude Code
reads it alongside this global document — it extends it, it does not replace it.
`scripts/init-project.sh` scaffolds it from `templates/CODING_STANDARDS.md` automatically.

### When to create one

Create it when at least one of the following is true:

- The project uses a language or framework with idiomatic conventions that refine
  how a global principle is applied (e.g., how dependency injection is wired, which
  error type hierarchy to use, how interfaces are named)
- The project has established naming or structural patterns that all new code must
  follow for consistency
- A global principle needs a concrete translation for this stack (e.g., "make invalid
  states unrepresentable" → "use Value Objects validated in the constructor, not
  request DTOs validated in the controller")

### What to put in it

- Language-specific idioms that implement a global principle
- Project naming conventions (file structure, class suffixes, method prefixes)
- Framework constraints that affect design decisions
- Patterns already established in the codebase that new code must mirror

### What not to put in it

- The global principles restated in different words
- Rules that apply to all languages and projects — those belong here
- Aspirational conventions not yet present in the existing codebase

### Ignore files

No changes to any ignore file are needed. The project `CODING_STANDARDS.md`
should be committed to version control and must remain readable by Claude Code —
do not add it to `.claudeignore`.

---

## 1. Express intent through structure, not comments

Code communicates through names, types, and shape — not through comments that
explain what the code does. A comment that describes WHAT the code does is a
signal that the code itself is not clear enough.

**What good looks like:**

- A name that communicates purpose completely: `findTopCoinsByMarketCap()`, not `getData()`
- A type that makes the concept unambiguous: `UserId`, not `int $id`
- A method body that reads like a sentence

**Signals of drift:**

- Inline comments explaining what a single line does
- Variable names like `data`, `result`, `temp`, `item`
- Function names containing "and", "or", "also"

---

## 2. Introduce abstractions at the right moment

Abstract when you have concrete examples that justify it, not before. An abstraction
created for one use case is usually the wrong shape and locks future code into a
premature contract.

**What good looks like:**

- A shared utility extracted after the same logic appears independently in multiple places
- An interface introduced when a second implementation is needed or testability requires it
- A concept named when the domain genuinely uses that name

**Signals of drift:**

- An interface with one implementation and no second on the horizon
- A helper class created "in case it's needed later"
- A class hierarchy deeper than two levels without a clear domain reason

> The right moment to abstract is determined by the actual complexity of the problem
> (see section 7), not by counting occurrences. Complexity justifies abstraction;
> occurrences alone do not.

---

## 3. One concern per unit

Every function, class, and module has one reason to change. This applies at every
level of granularity.

**What good looks like:**

- A function that does one thing completely
- A class whose name describes exactly what it is responsible for
- Module boundaries that coincide with domain or responsibility boundaries

**Signals of drift:**

- Method names containing conjunctions: "fetchAndFormat", "validateAndSave"
- A class with public methods that belong to two unrelated concerns
- A change to one feature requires touching a file that conceptually belongs to another

---

## 4. Depend on abstractions, not implementations

When a unit needs a collaborator, it should depend on what the collaborator does,
not on how it does it. This is what makes units replaceable and independently testable.

**What good looks like:**

- Constructor parameters typed as interfaces or abstract contracts
- No direct instantiation of concrete dependencies inside domain or application logic
- Test doubles that implement the same interface as the real dependency

**Signals of drift:**

- Business logic importing infrastructure classes directly
- `new ConcreteClass()` inside a method that is not a factory
- Units that cannot be tested without a real network, database, or filesystem

---

## 5. Make invalid states unrepresentable

If a concept has invariants, encode them in a type that enforces them at
construction time. Validation scattered across multiple call sites means the
invariant is not owned by the concept itself.

**What good looks like:**

- Domain primitives wrapped in types that validate on construction and throw on violation
- Return types that cannot represent error states — use exceptions, not nulls as sentinels
- A constructor that makes it impossible to create an object in an invalid state

**Signals of drift:**

- The same validation logic repeated in multiple callers
- Null used to represent "not found", "invalid", or "not yet set"
- Primitive types carrying domain constraints that are enforced elsewhere

---

## 6. Prefer explicit over implicit

Hidden behavior, magic defaults, and side effects not obvious from the name make
the system harder to reason about. Explicit is better than clever.

**What good looks like:**

- Dependencies declared and injected, not discovered at runtime
- A function whose output depends only on its inputs where possible
- Side effects named in the function signature or clearly communicated

**Signals of drift:**

- Global state or singletons accessed directly from business logic
- Functions that change external state without it being evident from their name
- Behavior that varies based on context read implicitly inside domain logic

---

## 7. Architecture follows the problem

No architectural style is universally correct. The right structure makes the
problem simpler to reason about — it does not impose complexity for its own sake.

Apply patterns proportional to actual complexity. DDD in particular carries real
overhead: aggregates, bounded contexts, domain events, and layered separation are
justified when the domain has genuine complexity. On a project that is just getting
started, or one with a single coherent domain and simple rules, this machinery is
overkill — a straightforward layered structure or even a flat script is correct.
DDD starts earning its cost when the domain grows to the point where multiple
bounded contexts need to be distinguished, or when different parts of the system
have meaningfully different models of the same concept.

**What good looks like:**

- The chosen structure can be explained in one sentence and matches the domain's complexity
- Layers and boundaries exist because they enforce a meaningful constraint
- Patterns are applied because they solve a specific problem in this context

**Signals of drift:**

- Abstractions and layers that add no constraint — everything passes through unchanged
- Patterns applied by default or reflex rather than because they address a real tension
- A simple problem solved with machinery designed for a complex one

---

## 8. Distinguish failure modes

Not all errors are the same, and conflating them produces code that is either
too defensive or too brittle. Every failure belongs to one of three categories,
each handled differently.

**Domain failures** — expected, part of the business model. A coin that does not
exist, a payment that exceeds the balance, an invalid identifier. These are not
bugs: they are outcomes the domain acknowledges. Express them as typed exceptions
the caller can catch and handle explicitly.

**Infrastructure failures** — unexpected at the domain level: network timeouts,
disk full, external service down. These originate outside the application boundary.
Catch them at the boundary, wrap them in a domain-level exception if the domain
cares, and let them propagate if it does not.

**Programming errors** — wrong assumptions, null dereferences, out-of-bounds
access. These are bugs. Do not catch them: let them propagate to a top-level
handler that logs and reports. Catching programming errors hides bugs.

**What good looks like:**

- Typed exceptions that communicate which category a failure belongs to
- Infrastructure catch blocks at the boundary, not scattered through domain logic
- No empty catch blocks; no catch-all that swallows all three categories silently

**Signals of drift:**

- `catch (Exception e) {}` or equivalent — the silent swallow
- Domain logic checking for null where a typed exception would be clearer
- The same generic exception type used for both domain and infrastructure failures

---

## 9. Fix at the root, not at the surface

When something is wrong, identify why it is possible before deciding how to fix it.
A patch that prevents the specific symptom while leaving the root cause intact will
produce the next symptom.

**What good looks like:**

- A fix that makes the wrong thing structurally impossible, not just this instance harder
- A change that generalises correctly across all current call sites
- An improvement that makes the next similar requirement cheaper, not more complicated

**Signals of drift:**

- Special cases accumulating around a central function
- The same guard condition repeated in multiple callers
- A fix that works for the reported scenario but does not address the underlying cause

---

## 10. Agree on expected behaviour before writing code

Before writing any non-trivial implementation, Claude Code must verify that the
expected behaviour is understood and agreed. A test is the most precise form of
this agreement — it specifies inputs, outputs, and edge cases in a way that prose
cannot. The user defines what the code must do; Claude implements it.

Before starting, Claude Code will ask — or explicitly state its assumptions about:

- What the unit receives and what it must return
- The edge cases and failure paths that matter
- Whether existing tests already cover the behaviour or new ones are needed

This is not TDD as a ritual. It is the discipline of separating specification from
implementation, which produces better interfaces regardless of who writes what.

If the expected behaviour is unclear or the specification is incomplete, Claude Code
asks at most one specific question before proceeding — not a list of questions, not
an implementation built on silent assumptions. One focused question unblocks the
conversation; a questionnaire stalls it.

**What good looks like:**

- Expected inputs, outputs, and failure cases agreed before any code is written
- Tests that document contracts (what the unit promises) not implementation (how it works)
- A failing test or a stated behavioural spec as the starting point for any new feature

**Signals of drift:**

- Writing an implementation and then writing tests to match it (testing the code, not the contract)
- Tests that assert internal state rather than observable behaviour
- Proceeding with implementation when the expected output for an edge case is unclear

---

## 11. Refactor in two passes, never one

When refactoring existing code, never remove the old implementation in the same
step that introduces the new one. The two must coexist long enough to verify that
outputs are identical.

**The protocol:**

**Pass 1 — Secure the legacy.** Before touching anything, add tests that capture
the current observable behaviour of the code being replaced. These tests do not
need to be elegant — their purpose is to act as a safety net that will fail if
the new implementation diverges.

**Pass 2 — Refactor alongside.** Introduce the new implementation without removing
the old. Run both and compare outputs. Only when all tests pass and the outputs
are verified to be identical in all relevant cases is it safe to remove the
legacy code.

This protocol applies to any significant change: extracting a service, replacing
an algorithm, migrating a data format, introducing a new layer. The cost of
running old and new in parallel is always less than the cost of a silent regression.

**What good looks like:**

- Legacy tests written before any refactoring begins
- Old and new implementations coexisting through at least one verification cycle
- Legacy code removed only after explicit confirmation that outputs match

**Signals of drift:**

- Deleting the old implementation in the same commit that introduces the new one
- Relying on "it looks correct" without a mechanical comparison of outputs
- Refactoring and adding new behaviour in the same pass

---

## 12. Start simple, earn complexity

Every project starts as a modular monolith — or simpler. Architecture expands only when complexity justifies it, not in anticipation of it.

The first commit must be the simplest thing that solves the problem. A working POC with clear boundaries is more valuable than a well-architected skeleton with no behaviour. Design quality and architectural sophistication are earned through iteration, not imposed at inception.

**The progression:**

1. **POC / MVP** — solve the problem with the simplest structure that works. No layers, no patterns unless they emerge naturally. Validate the idea.
2. **Modular monolith** — when the codebase grows, introduce boundaries within the monolith. Each module owns its data and logic. Boundaries are enforced by convention or tooling, not by network calls.
3. **Distributed services** — only when a module needs to scale, deploy, or evolve independently of the others, and when the operational cost of distribution is justified by the benefit.

This is not an excuse to write bad code at step 1 — Clean Code and SOLID apply from the first line. It is an excuse to defer architectural decisions until you have enough information to make them correctly.

**What good looks like:**

- The architecture at any stage can be explained in one sentence
- Moving from step N to step N+1 is a refactoring, not a rewrite
- The team can answer "why are we at this stage?" for every module

**Signals of drift:**

- A project at day 1 with service boundaries, message brokers, and separate deployments
- Abstractions designed for scale that the system may never reach
- "We'll need this later" as justification for architectural complexity today

---

## 13. Document architectural decisions with ADRs

An Architecture Decision Record (ADR) is a short document that captures a significant architectural decision — the context that prompted it, the alternatives considered, and the rationale for the chosen approach. It lives in the repository alongside the code it affects.

**When to write one:**
Write an ADR when a decision is hard to reverse, would not be obvious to a future reader of the code alone, or involves a genuine trade-off between reasonable alternatives. Routine implementation choices do not need an ADR.

**Format:**

```text
# ADR-NNN: Title

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-NNN

## Context
What situation or problem prompted this decision? What constraints apply?

## Decision
What was decided? State it plainly.

## Consequences
What becomes easier? What becomes harder? What does this commit us to?

## Alternatives considered
What else was evaluated and why was it not chosen?
```

**Where it lives:** `/docs/adr/` at the project root, one file per decision, numbered sequentially (`0001-use-ddd-layered-architecture.md`).

**What good looks like:**

- An ADR exists for every structural decision a new contributor would ask "why?" about
- Each ADR is one page maximum — if longer, the decision is not clear enough yet
- Superseded ADRs are marked as such, never deleted — the history is as valuable as the current state

**Signals of drift:**

- Architecture that cannot be explained without a long conversation
- Decisions reversed without recording why the original choice was wrong
- "We've always done it this way" as the only available explanation for a structural choice
