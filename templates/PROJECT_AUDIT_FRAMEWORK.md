# Quality specializations — [Project Name]

> Extends `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`. Apply the global standard in full;
> the entries below add project-specific context where needed.
>
> Only include categories that need grounding for this stack. If a category applies without
> modification, omit it. A healthy project file is 30–80 lines.

---

## Category 1 — OOP & Design Patterns

[Optional: list the building blocks in use and their expected roles in this project.
Example: Entity, Value Object, Repository, Domain Event, Application Service — what they are, where they live.]

## Category 3 — Domain-Driven Design

[Optional: describe the layer structure and any tooling that enforces it.
Example: Domain ← Application ← Infrastructure ← Http, enforced by deptrac.]

## Category 4 — Testing

[Optional: list the test kinds in use and how they map to Cat 4 subcriteria.
Example:

```text
| Kind        | I/O  | Logging    | Network | Tag               | Runs in CI |
|-------------|------|------------|---------|-------------------|------------|
| Unit        | None | None       | None    | (default)         | Always     |
| Functional  | None | NullLogger | None    | (default)         | Always     |
| Integration | Real | Real       | Real    | @group integration| Excluded   |
```

]

## Category 7 — Tooling & Quality Standards

[Specify the quality gate command and what it runs.
Example:
Quality gate command: `composer qa` — runs in sequence:

1. `vendor/bin/phpstan analyse` — level 6
2. `vendor/bin/php-cs-fixer check` — PSR-12
3. `vendor/bin/deptrac analyse` — layer boundaries
4. `vendor/bin/phpunit` — unit + functional suites
]

## Category 8 — Application Security

[Optional: list security concerns that must be handled manually because no framework handles them automatically.
Example: security headers, CSRF, input sanitisation — implemented in custom Router/middleware.]
