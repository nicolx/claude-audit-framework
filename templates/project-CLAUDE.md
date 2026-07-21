@.claude/framework/CLAUDE.md

# [Project Name] — [Short description]

## Purpose

[What this project does and why it exists.]

## Architecture

- **Language:** [PHP 8.x / TypeScript / Python / etc.]
- **Pattern:** [DDD / MVC / layered / etc.]
- **Framework:** [Symfony / Laravel / none / etc.]
- **External dependencies:** [APIs, services, databases]

## Quality gate

```bash
[command to run the full quality suite, e.g. composer qa / make qa / npm run qa]
```

After completing a change, ask the user whether they want to run the quality gate before proceeding. Run it only if the user confirms.

## Key conventions

- [List any conventions specific to this project's stack]
- [e.g. PHPStan level, style guide, layer rules, test types in use]

## Quality evaluation

Apply `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md` (global standard) extended by `PROJECT_AUDIT_FRAMEWORK.md` in this directory (project-specific specializations).
