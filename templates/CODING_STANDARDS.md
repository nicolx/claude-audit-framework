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
> below are the declared exceptions — domain vocabulary the English word would not name correctly.
>
> **The test:** *in this context, does the English word name the same thing?* Yes → use English.
> It names something broader, narrower, or different → the term belongs here.
>
> A term earns a place only if translating it loses legal, regulatory or business precision.
> General vocabulary does not qualify: if `utenti` means `users`, use `users`. Adding a row is a
> deliberate decision, never a way to avoid a rename.
>
> **Delete this section entirely if the codebase is uniformly English.** 2.8 scores full marks with
> no section when there is nothing to declare, and an empty table beats a table of habits.

| Term | Context | Meaning | Why it is not translated |
|---|---|---|---|
| [FatturaElettronica] | [billing] | [Italian e-invoice as defined by fiscal law] | [`Invoice` names a superset: a generic accounting record with no statutory format] |
| [Cedolino] | [payroll] | [Italian statutory payslip] | [`Payslip` names a broader document with no legally defined format] |
| [PartitaIva] | [all] | [Italian VAT registration number] | [`VatNumber` is close but not equivalent — format and validation are defined nationally] |

**The Context column is the rule, not decoration.** A term is correct **inside** its context and a
boundary leak **outside** it. Where a concept crosses contexts it gets each context's own name —
`Invoice` in a generic payments core, `FatturaElettronica` in the Italian billing module — with an
explicit mapper at the seam. Those are not duplicates to unify: the distinction is why the contexts
are separate. Use `all` only when the codebase genuinely has one context, or when the term really
does apply everywhere.

**Keep the domain's grammar.** *FatturaElettronica* is the document, *FatturazioneElettronica* is the
process: a module may be named for the process, an entity may not. And one term, one spelling —
declaring `FatturaElettronica` rules out `fattura_elettronica` and `FattElettr` elsewhere.

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
