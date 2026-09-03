# Coding Standards — [Project Name]

> Extends `.claude/framework/standards/CODING_STANDARDS.md`. Apply the global standards in full;
> the entries below add [language/framework]-specific conventions where the global
> principles need concrete grounding in this stack.
>
> Only include rules that refine a global principle for this specific stack.
> Do not restate global rules in different words.

---

## Language — [PHP 8.x / TypeScript / Python / etc.]

[List language-specific idioms that implement a global principle.
Example for PHP:

- Constructor promotion — prefer `public function __construct(private readonly Type $prop)`
- Readonly properties — all Value Object and Entity properties are `readonly`
- Named arguments — use for constructors with 3+ parameters
- Match expressions — prefer over `switch` when returning a value
- Enums — for fixed sets of domain values that need type safety
]

## Typing

[Describe type strictness requirements for this stack.
Example:

- No `mixed` anywhere in `src/` — every parameter, property, and return type explicitly annotated
- Array shapes annotated: `@param array{key: Type}`, `@return list<Type>`, `@return array<string, Type>`
]

## Domain language

> Required by principle 20 and scored as subcriteria 2.8. Code is written in English; the terms
> below are the declared exceptions — domain vocabulary whose meaning translation would destroy.
>
> A term earns a place here only if translating it loses legal, regulatory or business precision.
> General vocabulary does not qualify: if `utenti` would be understood as `users`, use `users`.
> Adding a term is a decision to make deliberately, not a way to avoid a rename.
>
> **Delete this section entirely if the codebase is uniformly English.** An empty glossary is
> better than a table of habits, and 2.8 scores full marks with no section when there is nothing
> to declare.

| Term | Meaning | Why it is not translated |
|---|---|---|
| [Fattura] | [Italian invoice under fiscal law] | [Legally distinct from a generic invoice; "Invoice" would not name the same artefact] |
| [Cedolino] | [Italian payslip] | [Statutory document with a defined format; no faithful English equivalent] |

Applies to identifiers, comments, test names, and developer-facing messages. It does **not** apply
to user-facing text — labels, emails and end-user messages belong to the product's language and are
an internationalisation concern.

## Naming conventions

| Concept | Convention | Example |
|---|---|---|
| [Class] | [PascalCase] | [ExampleClass] |
| [Interface] | [PascalCase + Interface suffix] | [ExampleInterface] |
| [Method] | [camelCase, verb phrase] | [findById()] |

## [Framework]-specific conventions

[Add any patterns established in the codebase that new code must mirror.
Example: Exception static factory methods: `CoinNotFoundException::forId($id)` — no `new Exception("string")` at call sites.
]

## Style

[Reference the style tool and ruleset.
Example: PSR-12 enforced by PHP-CS-Fixer. Run `composer cs:fix` to auto-correct. Do not manually format code.
]
