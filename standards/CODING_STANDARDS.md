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

The root is *where* the fix goes, not how much of it arrives at once. A fix that generalises across
forty call sites is still delivered in steps — principle 11 for the shape, principle 24 for the
sequence. "Fix at the root" never licenses one change that touches everything the root touches.

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

---

## 14. Check what already exists before building it

Before writing a capability, find out whether the framework, the standard library, or a dependency
already in the project provides it. Hand-rolled versions of solved problems are the most expensive
code in a codebase: they carry no upstream fixes, no documentation, and no other maintainers.

The inverse is equally true. A dependency added for something the standard library does in five
lines is a supply-chain liability, a version to track, and an upgrade to schedule.

**Check that it is still alive, not just that it fits.** A dependency is a commitment to someone
else's maintenance, so before adding one, look at when it last released, whether the repository is
archived, and what it constrains — a package that pins an old runtime version does not just age, it
freezes everything else. Solving today's problem with a dependency that stopped moving in 2021 buys
a rewrite later at a worse moment.

**What good looks like:**

- The framework's own abstraction used for cache, queue, HTTP client, validation, serialisation
- A dependency added when it owns a genuinely hard problem — crypto, parsing, protocol handling
- A new dependency whose maintenance was checked before adding it: recent releases, not archived,
  and no constraint that blocks the runtime or another dependency the project needs to move
- A short note in the ADR or commit when a native mechanism was deliberately *not* used

**Signals of drift:**

- A custom router, container, validator, or ORM alongside a framework that ships all four
- A dependency whose entire use is one function that the standard library also has
- A dependency added without looking at its release history, or one whose constraint on the runtime
  was discovered at the next upgrade rather than at the moment it was chosen
- Reimplementation because the native mechanism "did not quite fit", with no record of how

---

## 15. Validate at the boundary, trust inside

Every value that enters the process from outside is untrusted: HTTP requests, CLI arguments, queue
messages, webhook payloads, deserialised documents, deep links, environment variables. Validate at
the entry point and convert to a type that carries the guarantee — then code inside the boundary can
stop asking.

This is principle 5 applied to the outside world: the reason to validate at the edge is so that
`EmailAddress` means a valid email everywhere it appears, instead of every consumer re-checking.

**What good looks like:**

- One validation site per entry point, producing typed values, not sanitised strings
- Output encoded at the moment of rendering, for the specific context (HTML, SQL, shell, JSON)
- Authorisation checked on the operation being performed, not only on the route that reached it
- Secrets read from configuration or environment, never literals, and never written to logs
- State-changing requests carrying CSRF protection where the framework provides it

**Signals of drift:**

- The same `if (!isset($x))` guard repeated in controller, service, and repository
- String concatenation into SQL, HTML, or a shell command anywhere
- A route protected by middleware while the underlying operation can also be reached unprotected
- A credential, token, or key visible in source, in a fixture, or in a log line

---

## 16. Observability is part of the feature, not added afterwards

A feature that cannot be diagnosed in production is unfinished. The person reading the logs is not
the person who wrote the code, and they are reading at three in the morning with no access to the
developer's assumptions.

**What good looks like:**

- Every failure path emits one structured record with the identifiers needed to trace it
- Context as fields, not prose: `order_id`, `user_id`, `duration_ms` — never a sentence to be grepped
- Log levels that mean something: `error` for something a human must act on, not for expected outcomes
- Degradation that is visible — a fallback path says it took the fallback
- Long-running or scheduled work with bounded output and a retention rule

**Signals of drift:**

- A caught exception with no record of it, or a record with no identifier
- Log messages assembled by string interpolation into a single free-text field
- Secrets, tokens, or personal data inside log payloads
- Everything at `info`, or everything at `error`
- A process that writes unbounded output to a file nothing rotates

---

## 17. Use test doubles at the boundary, real objects inside

Double what the unit does not own: the network, the clock, the filesystem, a third-party service.
Use the real thing for what it does own: its own value objects, entities, and domain logic. A test
that mocks the code under test asserts only that the mock was configured.

**What good looks like:**

- In-memory implementations of repository interfaces, reused across the suite
- Real value objects and entities constructed in tests, never mocked
- Time, randomness, and IDs injected so a test can fix them
- One test name stating one behaviour: what it does, under which condition, with what outcome

**Signals of drift:**

- A mock of a value object, a DTO, or an entity
- Assertions on how many times a collaborator was called, when the outcome is what matters
- A unit test that cannot run without a database, a network, or a real clock
- `testItWorks()`, or one test asserting six unrelated things

---

## 18. A deprecation is a deadline

A deprecation warning means: *this will break in a future version, and you have until then.*
Suppressing the notice does not extend the deadline — it deletes the reminder.

When you touch code that emits a deprecation warning, fix the call site. When you cannot, record
why and by when, somewhere a person will see it again.

**What good looks like:**

- Deprecated calls resolved as they are encountered, in the change that touches them
- A suppression that carries the reason and the removal deadline, if one is unavoidable
- Upgrades taken in their own change, separate from feature work

**Signals of drift:**

- A suppression added to make a quality gate green
- `ignoreErrors`, `@ts-ignore`, `noqa`, or `filterwarnings` entries with no expiry and no author
- A dependency pinned below its current major for reasons nobody can now reconstruct

---

## 19. History is part of the deliverable

The commit log is read far more often than it is written, and almost always by someone trying to
understand *why* a line exists. A change whose reasoning lives only in a chat log is a change that
will be undone by accident.

**What good looks like:**

- One logical change per commit — a refactor and a behaviour change are two commits
- A subject line saying what changed, and a body saying why, when the why is not obvious
- The project's existing convention followed exactly, whatever it is
- Anything that would need explaining in a review explained in the commit instead

**Signals of drift:**

- "fix", "wip", "update", or a file list as a commit subject
- A single commit spanning a refactor, a feature, and a formatting pass
- Reasoning that exists only in the pull request description, which outlives nothing

---

## 20. Code speaks English, the domain speaks its own language, the product speaks the user's

Write code in English: identifiers, comments, test names, developer-facing messages, technical
documentation. English is the language of the standard library, the framework, the error messages,
and of whoever joins the project next.

Keep a domain term in its original language when the English word would not name the same thing.
Apply this test, and note that it is asked **inside one bounded context**, not of the repository as
a whole:

> In this context, does the English word name the same thing?
>
> Yes → use English. It names something broader, narrower, or different → keep the original term.

Because the test is context-local, one concept can correctly carry two names. In a generic payments
core, `Invoice` is right — there the thing really is a generic accounting record. In a module
implementing Italian e-invoicing law, `FatturaElettronica` is right — there the thing is the
document the law defines, and `Invoice` would name a superset. Do not "unify" the two: that
distinction is why the contexts are separate.

**Declare before you use.** Every term kept in its original language belongs in the **Domain
language** section of the project's `.claude/CODING_STANDARDS.md`, with its context and the reason
it is not translated. Before inventing a non-English identifier, read that section:

- The term is declared for the context you are working in → use it.
- The term is declared for a *different* context → you are at a boundary. Use this context's own
  vocabulary and translate explicitly; do not import the other context's term.
- The term is not declared and translating it loses nothing → use English.
- The term is not declared and translating it *would* lose legal or business precision → say so and
  propose adding it. Never use an undeclared term silently, and never translate a term that should
  not be translated.

**Translate at the seam, explicitly.** Where two contexts meet, the translation is an object with a
name — a mapper that takes an `Invoice` and returns a `FatturaElettronica`. Half-translated
identifiers are the symptom of a seam where that object is missing.

**Keep the domain's grammar.** The point of not translating is precision, and precision includes the
domain's own word forms: *FatturaElettronica* is the document, *FatturazioneElettronica* is the
process. A module may be named for the process, an entity may not. A compound the domain does not
use loses exactly what a translation would have lost.

**User-facing text is a different question, and it has its own rule: wrap it when you write it.**
Every string a person will read — a label, a PDF heading, an email body, a line of CLI output, a
validation message that reaches a screen — goes into the project's translation catalog in the same
change that introduces it. Not "for now", not "until we need a second language": a hardcoded string
is cheap to add and expensive to find later, and the ones never found are what make a product
untranslatable.

Author the text in English. English is the source and the fallback, so a locale missing a key still
renders something a reader can act on. Terms declared in the **Domain language** section stay whole
inside the text — the English catalog says `FatturaElettronica`, because that is the name of the
thing, not a word awaiting translation.

Where the project declares more than one locale, a feature is not done until its keys exist in every
declared catalog. And keep the catalog out of the domain: the domain names the fact, the layer that
speaks to a person chooses the sentence.

**What good looks like:**

- `final class Fattura` next to `final class OrderRepository`, `Fattura` declared and scoped
- `Invoice` in the payments core, `FatturaElettronica` in the Italian module, a named mapper between
- A declared row that reads like a decision, not a dictionary entry: the reason is what makes it one
- Domain terms whole and in the domain's own grammar; ASCII-only identifiers
- Comments and test names in English even about domain terms:
  `it_rejects_a_fattura_without_a_partita_iva()`
- Every user-facing string added to the catalog in the change that introduced it, in every declared
  locale, with named placeholders rather than concatenated fragments

**Signals of drift:**

- General vocabulary in the local language where English names the same thing: `getUtenti()`, `$elencoProdotti`
- Half-translated names, especially at a boundary: `UserFattura`, `getFatturaList()`, `IsPagato`
- A declared term used outside its context — the concept crossed a boundary that should have
  translated it
- One term spelled several ways: declaring a term commits you to one spelling
- Comments in the local language inside otherwise English code
- A declared list that has grown to cover every local word: an amnesty for not renaming, not a glossary
- A user-facing string written straight into a template, a PDF builder or a mail body
- One surface translated and the rest — emails, PDFs, CLI output — left hardcoded
- A feature merged with its English keys only, the other declared locales left to a later ticket
- A translation key stored on a domain object: the domain has learned how it will be displayed

---

## 21. Know the cost of your data access

Every read from a database has a cost that scales with something. Know what that something is
before the code ships, because the query you cannot see costing anything is the one you will pay for
at volume — and the bill arrives in production, on the day the table gets big.

The rule is not "optimise early". It is: **be able to say how this query behaves at a hundred times
the current row count.** If the answer is "it issues one query per row" or "it loads the whole
table", that is not a performance concern to revisit later, it is a defect now.

**Never issue a query inside a loop.** If you are iterating a collection and each element needs
related data, fetch it before the loop, in one query, and index it in memory. This is the N+1, and
it is written by accident every time: the loop is in one file and the lazily loaded association is
declared in another, and each is correct on its own.

**Every collection read is bounded.** Pagination, or an explicit limit. `findAll()` against a table
that grows is a latency and memory incident scheduled for whenever the data arrives.

**Aggregate where the data is.** `COUNT(*)` in SQL, not `count($repository->findAll())`. Sum, filter,
and group in the query — moving a million rows into the application to reduce them to one number
pays the transfer cost for nothing.

**An index is part of the change that needs it.** A new `WHERE` or `ORDER BY` on a growing table
ships with its index, in the same change, not in a later performance ticket. And check the plan at
realistic volume: `EXPLAIN` at two hundred rows will happily tell you a sequential scan is fine.

**What good looks like:**

- One query before the loop, indexed by id, and the loop reads from memory
- Repository methods that cannot return an unbounded set — the limit is in the signature
- A migration that adds both the query path and the index it depends on
- A test asserting the query *count* for a route, so a later refactor cannot quietly reintroduce an N+1

**Signals of drift:**

- An ORM call or query inside `foreach` / `for` / `map`
- `findAll()`, `all()`, `.objects.all()` with no limit, on anything that grows
- An entity loaded in full to read one column, or to check whether it exists
- Counting, summing or filtering in application code over a set that came from the database
- "We will add the index when it becomes a problem" — it is already a problem, just not yet a
  noticeable one

---

## 22. Documentation is part of the change that invalidated it

When a change makes a written statement false, correcting the statement belongs to that change — not
to a follow-up ticket, not to a documentation sprint. The only moment anyone reliably knows which
documents a change has just falsified is the moment they are making it.

This is narrower than "write documentation", and that is the point. You renamed the make target, so
rename it in the README. You raised the analyser level, so the file that names the old level names
the new one. You moved a directory, so the documents citing the old path cite the new one. Nothing
here asks for prose that did not exist before.

**Two audiences, and the quieter one matters more.** A stale README is read by a person who hits the
wrong command, notices, and goes to look at the code. A stale `CLAUDE.md` or `.claude/*` file is
loaded into every session and applied as fact, by a reader who never questions it and never reads it
end to end. Drift there does not surface; it compounds.

**Prefer a claim something can check.** When you write a factual statement in a document, choose the
form a machine could verify: name the command (`composer qa`) rather than describing it ("run the
quality suite"), cite the path rather than the concept. A checkable claim is one a CI job can keep
honest; an unverifiable one relies on someone remembering, which is how it got stale the first time.

**What good looks like:**

- The commit that renames a thing renames it everywhere it is named
- A documentation change that is a *correction*, sitting in the same commit as the cause
- Factual claims written as paths and commands, so a checker can resolve them
- An instruction file for the AI whose statements about tooling can be compared to the tooling

**Signals of drift:**

- A doc fix as a separate follow-up commit, days later, by whoever noticed
- "Update the docs" as a recurring backlog item — the backlog is the symptom
- A document describing a directory layout, command or tool version that no longer exists
- Prose where a path or command would have done, so nothing can check it

---

## 23. A spec is delivered when its status says so

The documents that describe planned work carry a status marker — `todo`, `in-progress`,
`implemented`, `superseded`, `abandoned` — and the whole value of that marker is that it can be
trusted. Moving it belongs to the change that made it wrong, for the same reason principle 22 puts a
doc correction there: the moment you finish the work is the last moment anyone reliably knows which
document just became out of date.

This is principle 22 applied to a different kind of claim. Principle 22 governs what a document says
about the **system** — the command, the path, the analyser level. This one governs what it says about
**itself**: whether the thing it describes exists yet.

**Before you build**, look for the document that already describes the work. If one exists, it is the
specification — read it before proposing an approach, and if you are about to build something it
contradicts, that contradiction is the finding, not a detail to route around. If the work is more
than a fix and no document describes it, say so: the spec is worth writing first, marked `todo`, and
it is cheaper to disagree about a page than about a branch.

**When asked to document an existing codebase**, say what reconstruction can and cannot produce
before starting. Reading the code and writing down what it does yields a description, not a
specification: it agrees with the implementation by construction, so it can never catch the
implementation being wrong — which is the only reason a spec is worth reviewing. What is worth
writing from an existing codebase is what does not come out of it: the product context, and the
decisions that still constrain the code. Both live in people's heads. The specs start at the next
piece of work, not at the last one.

**When you finish**, move the marker in the same change, and make the claim checkable — a spec marked
`implemented` should name the module or the test that implements it, so somebody other than its
author can verify it. Where a spec is only half delivered, mark the requirements individually rather
than moving the whole document; `in-progress` that does not say which half is a status nobody can
act on.

**What good looks like:**

- The pull request that ships the feature contains the status change, in the same diff as the code
- `implemented` accompanied by what implements it — a path, a test name, a merge reference
- A partial delivery marked per requirement, so the remaining work is still listable
- A spec written before the work when the work is large enough to be worth disagreeing about
- Superseded documents kept and marked, pointing at what replaced them

**Signals of drift:**

- Every document says `todo`, including the ones running in production
- A "documentation pass" that sweeps a batch of statuses to `implemented` before a review
- `in-progress` with no date and no owner, indistinguishable from abandoned
- Work started with no reference to the document that describes it, then diverging from it silently
- A batch of specs generated from the code to fill a documentation gap — every one of them
  `implemented`, every one of them accurate, none of them able to disagree with anything
- A status moved by someone who was not in the change, days later, from the changelog

---

## 24. Cut the work into steps that ship

Anything larger than a fix is decomposed before it is written, and the decomposition is agreed on its
own — a separate exchange, before the first line of code. The list of steps is the cheapest thing in
the change to disagree about, and the last one that costs nothing to throw away.

**What a step is.** One change to the implementation, the one test that proves it, and a state the
system can be released and observed in. All three, in every step. A line item missing any of them is
a wish with a number in front of it, and it will be discovered to be unfinishable somewhere in the
middle of the next one.

**Where to cut.** By behaviour, never by layer. A step that delivers all the entities, then one that
delivers all the repositories, then one that delivers the controllers, produces nothing observable
until the third — which makes it one step that has been counted three times, with the comfort of
progress and none of the evidence. Cut so that each step changes something a test can see.

**What to do first.** Open on the assumption most likely to be wrong, at the smallest cost that
settles it. State it the way an A3 does, on one page: the problem, where the system is now, where it
has to get to, the single countermeasure being tried first, and how its effect will be checked. The
plan that begins with the easiest file reaches the hard question in week three, with a branch behind
it that cannot be thrown away.

**When the end state replaces something that exists**, the sequence is the subject of principles 11
and 12: old and new coexist, verified against each other, and the legacy goes last. There is no step
that is the cutover.

**When the request itself is the destination.** *"Rewrite the importer"*, *"migrate everything to the
new client"*, *"do it all in one go"* — these name where to end up, not what to do first. Answer with
the route: the steps, which one is first, and what its test will be. Agreement on a destination is
not agreement on a route, and must not be read as one. If the developer, having seen the sequence,
still wants the single cutover, that is their call — build it, and say plainly which part of it
nobody will be able to verify until the end.

**What good looks like:**

- A numbered plan agreed before implementation starts, each step naming its change, its test, and
  what is released once it lands
- A first step that lands within a day and settles the question the rest of the plan rests on
- Each step merged on its own and revertible on its own, leaving the system working in between
- A replacement that passed through a period where both implementations were live

**Signals of drift:**

- A plan that describes the end state and no intermediate state
- *"I'll do the whole refactor and run the tests at the end"*
- Steps that cannot be released: a step that leaves the build red, or whose only verification is the
  step after it
- A sequence that was stated and then collapsed into one pass because it looked small from inside
- Scope added to a step because it was adjacent to what was already open

---

## 25. A change is delivered, not finished

Code that works and sits in a working tree has not been delivered; it has been written. The step of
principle 24 ends in the state the project calls *done*, and what that state is is the project's to
declare — committed and pushed on a solo repository, a reviewed pull request on a team, a tagged
release where something downstream pins a version.

**Read the declaration before the first commit of the session**, not after the work. It is the
*Delivery convention* block of the project's `.claude/PROJECT_AUDIT_FRAMEWORK.md`, and it says what a
finished change carries and which actions a session may take unattended.

**Where it permits an action, take it without asking.** The declaration *is* the authorization, and
asking again at each step is the friction the team removed by writing it down. Report what was done
in one line — the commit, the branch, the pull request — so the action is visible rather than silent.

**Where it does not cover an action, stop at the last one it permits** and say what remains, naming
the command the developer would run. Never infer an adjacent permission: committing does not imply
pushing, pushing a feature branch does not imply pushing `main`, and neither implies a tag, a
release, or a published artifact. An agent's authority here is narrower than the team's by design.

**Where there is no declaration**, prepare the change and ask, as before — and say once that the
block is missing. A session that starts committing because nobody wrote down that it should not is
the failure this principle is most likely to cause if read carelessly.

**What rides along with the change.** The documents it invalidated are part of it, not a follow-up:
principle 22 for what a document says about the system, 23 for what it says about itself, and — where
the change is a release — the version, the changelog entry, and the install or upgrade steps that
name a version, in the same commit. A changelog written afterwards from the log records what the
commits said, which is the one thing a reader could already get from the commits.

**What good looks like:**

- Every session ends with the work in the state the declaration calls done, or with one line saying
  which permitted action was the last one and what remains
- Version, changelog and install instructions in the same commit as the change that made them wrong
- A session that pushed says so, naming the ref it pushed to

**Signals of drift:**

- Work left uncommitted at the end of a session that nobody asked to leave uncommitted
- *"Shall I commit this?"* asked every time in a project that already declared the answer
- `docs: update changelog` as its own commit, two days after the feature
- A tag created without the version bump that justifies it, or a version bump never tagged
- A push to a ref the declaration does not name, or a permission inferred from an adjacent one

---

## 26. Every bug fix leaves a test behind

A bug is not only broken code. It is also a gap in the suite, which is what let the code break
unobserved for as long as it did. Changing the code closes the first half. The test that would have
caught it closes the second, and that is the half deciding whether the same defect can arrive twice.

**The protocol:**

1. **Reproduce it as a failing test, before the fix.** The test must fail on the current code and
   fail *for the reported reason* — not on a setup error, not on an assertion the bug never violated.
   A test written after the fix and never seen red proves only that it agrees with the code sitting
   in front of it.
2. **Write it at the lowest level that reproduces the defect.** A wrong rounding rule gets a unit
   test on the calculation, not an end-to-end run through checkout. The level that reproduces the bug
   is the level that will localise the next one.
3. **Aim it at the root, not at the report.** Principle 9 decides where the fix goes; this decides
   what pins it there. Where the root was a shared function and the report was one of its forty call
   sites, the test belongs on the function — and the reported input stays in it as a case, because
   that is the one a human confirmed.
4. **Name the defect in the test.** The issue id, the ticket, or one line above it saying what broke.
   A regression test is the one test whose reason to exist is not visible in the code it covers, and
   the reader who cannot see the reason is the one who deletes it.

**Then it stays.** It is removed only when the behaviour it pins is deliberately changed, in the same
commit as that change, with the change stated. Nothing else is a reason:

- **Not that it is red.** A red regression test is either a returned defect or a decided change of
  behaviour. Both are answered in the production code or in the commit message, never by deleting
  the test
- **Not that it is old.** The defect is not less reachable because the fix is two years old; the code
  around it has been rewritten twice since
- **Not that a broader test covers it.** *"The integration suite covers that"* holds until the
  integration suite is restructured by someone who never knew it was load-bearing
- **Not that it is slow or awkward.** Make it faster at the level it is on. Raising its level or
  dropping it trades a defect you have already paid for against a few seconds of CI

**What good looks like:**

- The fix commit contains the test, and the test fails on that commit's parent
- A regression test that says what it is for, in its name or in one line above it
- A behaviour change that retires a regression test doing so explicitly, in the commit that changes
  the behaviour

**Signals of drift:**

- A fix commit touching only production code, with the test as a follow-up that never arrives
- A regression test that still passes when the fix is reverted
- Regression tests skipped, quarantined, or excluded from the default run
- The same defect twice in the history — the strongest signal there is, and the only retroactive
  one: whatever the first fix left behind, it was not a test

---

## 27. Cleanup runs on a trigger, not on a reminder

A repository accumulates. Every merge leaves a branch behind, every branch deleted upstream leaves a
remote-tracking ref on a dozen clones, every build writes output next to the source, every release
leaves a draft, a cache, an artifact. None of it is a defect on the day it appears — which is exactly
why it is still there a year later. Nothing about it ever becomes urgent, so nothing about it ever
gets done.

The habit people reach for is the tidy-up: an afternoon of deleting branches, once the list has
become unusable. It works, once. What it never becomes is a property of the repository, because what
it runs on is somebody noticing — and noticing is the first thing the accumulation consumes.

**Two triggers, and between them they cover all of it.**

**1. The change removes what the change created.** The branch is deleted by the merge that consumed
it — the host does this with one setting, so the correct form of the rule is *turn it on once*, not
*remember every time*. The scratch file, the fixture copied in to reproduce something, the one-off
script: out in the commit that stops needing them. Whatever the build produces is in the ignore file
the day the build first produces it, and the check for that is one command — `git status` on a clean
checkout after a full build and test run. If it lists anything, somebody will eventually commit it.

**2. What no single change can reach runs on a schedule.** Remote-tracking refs for branches deleted
upstream — `fetch.prune`, configured rather than typed by hand. Branches with no commit for months.
CI caches, artifact retention, pre-release tags, draft releases. A job, on a trigger it does not
share with anyone's memory, that reports what it removed somewhere with a reader.

**The line automation does not cross.** Cleanup that destroys work is worse than the mess it removes,
and this is the one place where conservative beats thorough:

- **Nothing unmerged.** A branch holding commits that are not in the mainline is somebody's
  unfinished work, whatever its date says. Age is evidence about attention, never about value
- **Nothing that rewrites published history.** A 200MB fixture committed two years ago is a cost
  every clone keeps paying, and removing it is a coordinated migration with a date and a notice —
  never a line in a cleanup job
- **No tags, no releases.** They are the answer to *what was running in March*; that question gets
  asked years later
- **Nothing silently, and nothing without a dry run.** A job whose output nobody reads is the same
  thing as a job nobody can audit after it removes the wrong branch

**What good looks like:**

- The branch is gone when the pull request closes, and no one deleted it
- Residue from a change leaves in the change: the fixture, the scratch script, the temporary flag
- A new clone of a five-year-old repository is small, and `git status` is clean after a full build
- The retention rule is written where the job is defined — *merged remote branches older than 90
  days are deleted, unmerged ones are reported and never touched* — so the job can be read for what
  it will do rather than watched for what it did

**Signals of drift:**

- A branch list long enough that nobody scans it, in which the three live branches are indistinguishable
  from the fifty merged ones
- `git fetch` printing refs for branches that stopped existing months ago, on every machine, forever
- `.gitignore` entries that each arrived one commit after the file they ignore was committed by mistake
- The cleanup lives in one developer's shell aliases: it works, and it leaves when they do
- Tidying scheduled as a task — *clean up branches* on a board, moved forward every sprint. The task
  is the admission that nothing runs

---

## Traceability — where each principle is measured

These principles are the write-time half of the framework; `PROJECT_AUDIT_FRAMEWORK.md` is the
measurement half. The mapping below is the only place the two documents cross-reference each other:
a principle is defined here and nowhere else, a criterion is defined there and nowhere else.

The table exists to make gaps visible. A criterion with no principle behind it is a quality that
can only be found in an audit, never written correctly the first time.

| # | Principle | Measured by |
|---|---|---|
| 1 | Express intent through structure | 2.1, 2.5 |
| 2 | Introduce abstractions at the right moment | 1.3, 1.5, 2.6 |
| 3 | One concern per unit | 1.2, 2.2 |
| 4 | Depend on abstractions | 1.4, 3.5 |
| 5 | Make invalid states unrepresentable | 1.1, 3.3 |
| 6 | Prefer explicit over implicit | 1.4, 3.2, 5.3 |
| 7 | Architecture follows the problem | 3.1, 6.7 |
| 8 | Distinguish failure modes | 2.4, 5.5, 9.5 |
| 9 | Fix at the root | 2.6, 2.7 |
| 10 | Agree on expected behaviour first | 4.2, 4.5 |
| 11 | Refactor in two passes | 4.3, 10.9 |
| 12 | Start simple, earn complexity | 6.7, 10.9 |
| 13 | Document decisions with ADRs | 0.7 |
| 14 | Check what already exists | 6.2, 6.4, 6.8, 6.9 |
| 15 | Validate at the boundary | 8.1, 8.2, 8.3, 8.4, 8.6, 8.7 |
| 16 | Observability is part of the feature | 9.1, 9.2, 9.4, 9.6 |
| 17 | Test doubles at the boundary | 4.4, 4.6 |
| 18 | A deprecation is a deadline | 7.8 |
| 19 | History is part of the deliverable | 10.11, 10.14 |
| 20 | Code speaks English, the domain speaks its own language, the product speaks the user's | 2.8, 2.9, 2.10 |
| 21 | Know the cost of your data access | 7.9, 9.8 |
| 22 | Documentation is part of the change that invalidated it | 7.10 |
| 23 | A spec is delivered when its status says so | 0.3, 0.4, 0.5 |
| 24 | Cut the work into steps that ship | 0.8, 10.9 |
| 25 | A change is delivered, not finished | 10.14, 10.15 |
| 26 | Every bug fix leaves a test behind | 4.7 |
| 27 | Cleanup runs on a trigger, not on a reminder | 10.16 |

### Criteria with no write-time principle, and why

Not every criterion can have one. These are measured in an audit and cannot be governed while
writing a feature — stating which, and why, keeps the table above honest instead of padded.

| Criteria | Why it is audit-only |
|---|---|
| 0.1, 0.2, 0.6 | The documentation home, the product context and the design artifacts are established once as project structure and then maintained; principle 23 governs what happens inside them per change |
| 4.1 coverage level | An outcome of principles 10 and 17, not a separate instruction |
| 7.1–7.7 tooling | Project infrastructure: configured once, not written per change |
| 8.5 security headers | Configuration of the framework or web server, not of a feature |
| 9.3 health endpoint, 9.7 data lifecycle | Built once as operational surface, then maintained |
| 9.9 operational access, 9.10 disaster recovery | Access paths, credentials and backups are established by whoever operates the system; no change to a feature can open one or restore one |
| 10.1–10.8, 10.10, 10.12, 10.13 | Pipeline, environment, and repository setup — outside any single change |
| 5.1, 5.2, 5.4, 5.6, 5.7 | Principles 3, 4, 6 and 8 applied to JS. Stack-specific rules belong in the project's own `.claude/CODING_STANDARDS.md`, not in a language-agnostic document |
