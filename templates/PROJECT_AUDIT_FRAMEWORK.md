# Quality specializations — [Project Name]

> Extends `.claude/framework/standards/PROJECT_AUDIT_FRAMEWORK.md`. Apply the global standard in full;
> the entries below add project-specific context where needed.
>
> Only include categories that need grounding for this stack. If a category applies without
> modification, omit it. A healthy project file is 30–80 lines.

---

## Category 0 — Product Strategy & Delivery Documentation

[Optional but the most useful entry in this file: name where the product documentation lives and the
exact status vocabulary in use, so 0.2, 0.4 and 0.5 are scored against this project's convention
rather than the standard's example.
Example:

| Field | Value |
|---|---|
| Documentation home | `docs/` — `docs/product/` specs, `docs/adr/` decisions, `docs/design/` mockups |
| Spec format | `docs/product/NNN-slug.md`, YAML frontmatter |
| Status vocabulary | `todo`, `in-progress`, `implemented`, `superseded`, `abandoned` |
| Per-requirement status | `- [ ]` / `- [x]` under `## Acceptance criteria` |
| Outstanding work | `grep -rl 'status: todo' docs/product/` |
| Spec threshold | anything beyond a bugfix or a one-file change |

]

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

## Database access for query analysis

[Required by precondition 4. Subcriteria 7.9 and 9.8 cannot be answered from configuration, so
declare how to reach a database with representative volume — or state that none is available and
accept that both are capped at 8.

The grant should allow **schema and statistics, not rows**: `information_schema`, index inventory,
`EXPLAIN`, row counts, and the engine's own statement statistics. Query analysis needs none of the
application's data, so the grant should not permit reading it.

Example:

| Field | Value |
|---|---|
| Command | `make db-analyse` (wraps `psql "$AUDIT_DB_URL"`) |
| Environment | staging, restored nightly from an anonymised production dump |
| Volume | representative — ~2M rows in `orders`, ~400k in `invoices` |
| Grant | `audit_ro`: `USAGE` on schema, `SELECT` on `information_schema` and `pg_catalog`, `pg_read_all_stats`; **no** `SELECT` on application tables |
| Credentials | `AUDIT_DB_URL` in the developer's environment; never in the repo |
| Out of bounds | production, `EXPLAIN ANALYZE`, any statement that is not a read of schema or statistics |

If no such database exists: "Not available — 7.9 and 9.8 are scored from configuration only."]

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

## Production access

[Declares what 9.9 is scored against, and bounds what a session may do with it. List every production
signal the project has and the path that reaches it; mark explicitly which of those paths Claude may
use. Read-only is the default — a mutating path belongs here only if the team means it to be used,
and only named action by named action.

Example:

| Field | Value |
|---|---|
| Logs | `make prod-logs SINCE=1h` — wraps `ssh observer@app-1 journalctl -u app`; account has no shell and no write |
| Metrics | Grafana `https://grafana.example.com`, dashboard `app / oncall` — viewer role, SSO |
| Errors | Sentry org `acme`, project `app` — MCP server `sentry`, read-scoped token |
| Health | `make prod-health` — `/healthz` on every instance |
| Agent path | the `make` targets above, allow-listed in `.claude/settings.json`. No interactive shell |
| Credentials | `PROD_OBSERVER_KEY`, `SENTRY_TOKEN` in the operator's environment; never in the repo |
| Mutating actions | none allow-listed — `make prod-restart` and `make prod-rollback` are run by a person |
| Out of bounds | a shell on production, anything that writes, and reading application data out of the logs |

If there is none: "Not available — no production path is open to a session; 9.9 is scored on what a
person can reach."]

## Team census

[Who writes, who reviews, who releases, and who consumes a version of this project. Required by
precondition 5, and read by the proportionality rule at the top of Category 10 — it is what decides
whether 10.12, 10.13 and 10.14 are in play at all. `/team-census` drafts it from the git history and
asks only for what the history cannot know.

This is not a competency profile. That one is `~/.claude/context/user_profile.md`, lives on each
developer's machine and is never committed; this one belongs to the project and is.

Record what is true today rather than the org chart, and keep the evidence row — a census nobody can
check against the log is a claim.

Count people, not identities: a bot, an agent or a shared account is somebody's work, and that
somebody is the contributor. An identity nobody could resolve gets a row of its own rather than
being left out of the count — precondition 5 keeps the subcriteria it would have excused in play.

Example — one developer, deployed continuously:

| Field | Value |
|---|---|
| Contributors | 1 — the maintainer: writes, deploys, operates |
| Evidence | `git shortlog -sne --since='12 months ago' --no-merges HEAD` — 1 author, 312 commits |
| Review | none — no second writer. The reviewable-change rules apply to the commit (10.11) |
| May merge to `main` | the maintainer |
| Releases | no release step — `main` deploys on green |
| Consumes a version | nobody; rollback names a commit |
| Census date | 2026-10-11 |
| next_review_date | 2027-04-11 |

Example — nine developers, published package:

| Field | Value |
|---|---|
| Contributors | 9 — 5 backend, 2 frontend, 1 SRE, 1 tech lead |
| Evidence | `git shortlog -sne --since='12 months ago' --no-merges HEAD` — 11 authors; 2 left in March |
| Review | pull request, 1 approval, `CODEOWNERS` routes by directory |
| May merge to `main` | anyone with an approval — branch protection enforces it |
| Releases | `release-please` on merge; the tech lead cuts anything out of band |
| Consumes a version | 4 internal services pin the published package; the changelog has readers |
| Census date | 2026-10-11 |
| next_review_date | 2027-04-11 |

If there is none: "Not declared — the team shape is read from the git history, and a subcriteria
whose condition the history cannot settle is scored rather than marked N/A."]

## Delivery convention

[Declares what a finished change carries in this project, and what a session may do unattended.
Scored by 10.15, and read by every session before its first commit.

The shape is the team's: a solo repository and a twelve-person one have different right answers and
neither is a higher score. What is scored is that it is written, that the mechanical half is checked
by a machine, and that the session's authority is enumerated rather than inferred.

Example — solo project, trunk-based:

| Field | Value |
|---|---|
| Branch policy | straight to `main`, no pull request |
| Done means | committed, pushed, CI green |
| Rides with a user-visible change | an entry under `## [Unreleased]` in `CHANGELOG.md` |
| Release | `make release` — bumps `VERSION`, moves the Unreleased block, tags `vX.Y.Z` |
| Checked by | CI job `version-changelog`: fails when `VERSION` and the newest changelog entry disagree, or when the README pins a version other than the current one |
| Session may | commit, push `main` |
| Session may not | tag, publish, force-push, rewrite history |

Example — team of nine:

| Field | Value |
|---|---|
| Branch policy | `feat/*` cut from `main`, pull request required, squash merge |
| Done means | pull request open, green, one approval, squashed |
| Rides with a user-visible change | the Conventional Commit footer `release-please` reads, and the spec's status marker moved (0.5) |
| Release | automated — `release-please` opens the release pull request and tags on merge |
| Checked by | `commitlint`, the `changelog` job, branch protection on `main` |
| Session may | commit, push `feat/*`, open and update its own pull request |
| Session may not | merge a pull request, push `main`, tag, release |

If there is none: "Not declared — a session prepares changes and asks before committing; 10.15 is
scored on what the history shows."]

## Disaster recovery drill

[What `/dr-drill` is allowed to do, and the committed script it runs. Without this section the
command refuses to start — a restore improvised against an undeclared target is the accident it was
meant to rehearse for.

Example:

| Field | Value |
|---|---|
| Drill script | `ops/dr-drill.sh` — committed; the command runs it, never its own steps |
| Source | the most recent artefact in `s3://acme-backups/prod/` — **read only**, never rotated or deleted by a drill |
| Target | a `docker compose` stack created by the script and destroyed at the end. Disposable; named `dr-drill-*`; shares nothing with production |
| Assertions | row counts within 2% of the recorded source counts, canary row `settings.dr_canary` present, uploads manifest checksum, app boots and `/healthz` returns 200, `make smoke` passes |
| Personal data | the script anonymises on restore — production personal data never lands in an environment protected less than production |
| Receipts | `docs/ops/dr-drills/YYYY-MM-DD.md`, committed |
| RPO / RTO | 1 hour / 4 hours — what the drill's backup age and duration are compared against |
| Scheduled by | nightly CI job `dr-drill`, failure alerts `#oncall`; the command is for re-running it by hand |

If there is none: "Not declared — no drill target exists, and 9.10 is scored from configuration and
the runbook alone."]
