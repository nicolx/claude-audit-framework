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
