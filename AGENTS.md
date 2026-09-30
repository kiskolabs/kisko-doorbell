<!-- pray:0 ignore-comments -->

# Agent context

Do not edit managed blocks in `AGENTS.md` or provisioned files under `.agents/`.
To change shared guidance, update `Prayfile` and run `pray install`.

<!-- pray:ae5d334a -->
## Additional instructions

### .agents/project.md

kisko-doorbell is a Ruby gem and command-line service. It reads doorbell RF events from `rtl_433` through an RTL-SDR receiver and posts matching events to Slack. The default branch is `master`.

Linear: https://linear.app/kisko/team/KIS/active
GitHub: https://github.com/kiskolabs/kisko-doorbell
Slack: #kisko-apps
Runtime errors go to Honeybadger through `HONEYBADGER_API_KEY`.

Link an existing Linear issue on the pull request when the user named one.

Evidence comes from git, specs, `rfcs/`, `usr/docs/`, pull requests, Linear, GitHub, Slack, and Honeybadger. Reads from those sources are allowed. Writes are not implied by listing them.

## External service writes

- Do not create, update, comment, post, or otherwise write to external services unless the turn names that destination and the write.
- Repository work does not authorize Linear, Slack, Honeybadger, or GitHub writes.
- Drafts stay in the reply or in `usr/docs/` until the user says to send them.

## Build and release

- CI is `.github/workflows/test.yml`; Trunk checks run from `.github/workflows/_trunk_check.yml`.
- Run `bundle exec rake` for specs and RuboCop.
- Do not run `gem push`, publish to RubyGems, or tag a release unless the user asks for that exact operation.

## Skills

- engineering-audit: packaged from amkisko/prayers
- dependency-audit: from dependency-policy
- changelog-update: packaged from amkisko/prayers
- claims-audit: packaged from amkisko/prayers
- rfc-process: packaged from amkisko/prayers

## Documentation

Shipped contracts live under `rfcs/`. Claim `rfcs/ids/NNNN` before writing an RFC and follow the rfc-process skill. Engineering traces live under `usr/docs/` per docs-conventions.

## Tests and source shape

RSpec tests live under `spec/`. Prefer production source files at 150 lines or fewer when cohesion allows. Files from 151 through 300 lines produce a LOC warning; production source files above 300 lines fail RuboCop.

## Jobs and configuration

Background Slack delivery uses SuckerPunch in `lib/kisko/doorbell/message_job.rb`. The Slack destination comes from the `--slack-channel` CLI option.

## Shared instructions
<!-- pray:ae5d334a -->

<!-- pray:9068e4a2 -->
- when fixing or refactoring code, add or update tests first to expose the current bug/regression path (or missing contract), then implement the fix, then run focused and broader checks, and do not ship behavior changes without proving before/after via specs;
- test only executable logic and user-facing behavior; tests should affect coverage metrics;
- avoid tests that only assert implementation details; avoid file/page content/ordering/regex assertions; avoid duplicating tests;
- user interface texts should never mention implementation technical details;
- prefer files around <=150 LOC when cohesion allows, but never split coherent logic purely to satisfy line count; split only when it improves ownership, readability, and reviewability;
- do not use abbreviations and short names for variables, methods, classes, etc. unless it is a very common abbreviation or short name;
- avoid explanatory comments, but allow intent comments for non-obvious constraints, invariants, concurrency edges, or external contract requirements;
- keep the idea that code reflects user experience, so readability, structure, and clarity are product qualities;
- pull request description should include answers to questions: what problem is solved, why it matters, how the solution works, and any relevant context; if the change is non-trivial, include reproduction steps or a changelog entry with intent;
- pull request checklist: changelog entry with intent or reproduction steps when relevant, test coverage, and quality checks done;
- follow docs-conventions for usr/docs trace filenames and layout;
- validation output must list exact commands run and observed results, and never claim tests pass unless they were executed and passed;
- ignore style-only dust unless it harms correctness, operability, maintainability, or auditability under realistic load.
<!-- pray:9068e4a2 -->

<!-- pray:781b7711 -->
## Credentials and Secrets

- Prefer a secret store or OS credential helper over embedding live secrets in config files, scripts, or documentation. Named managers (for example 1Password, Bitwarden, KeePassXC) are fine; the requirement is isolation, not a specific vendor.
- Config and project files may hold references (vault paths, item ids, redacted fingerprints). They must not hold live tokens, API keys, passwords, or client secrets.
- Do not pass secrets on command lines or in other process-visible arguments. Prefer secret-store lookup, short-lived credentials, or stdin/file descriptors that do not persist in shell history.
- Do not commit secrets, paste them into issues or pull requests, or write them to logs. Rotate anything that may have been exposed.

## Tracking and identification

- A redacted fingerprint above is a hash of a secret for config references. A device fingerprint is fields that combine to identify a person or device across sessions or observers.
- Identifiers, IP addresses, device marks, and combined attributes are personal data. They can unmask a person, a location, or a session secret. Emit them only when the feature they asked for this session needs them and they were shown that this product would.
- Silent analytics ids, leftover marks after logout, and canvas or hardware probes are security events. They can locate a person, stitch sessions, or leak a credential-shaped token.
<!-- pray:781b7711 -->

<!-- pray:bfe6ff38 -->
- `docs/` is for human-facing documentation: setup guides, architecture, migration notes, and operator material meant for users and contributors without agent context; use stable descriptive filenames;
- `usr/docs/` is for durable agent and engineering trace alongside other project-local operator surfaces under `usr/`; keep inference input (AGENTS.md, `.agents/`) separate from human docs;
- four timestamp trees, no README index, filename `YYYYMMDDHHMMSS_<kebab-case-title>.md`: `issues` (live work: contract, findings, open next; pitch, plan, and queue stay here), `changelogs` (what shipped), `meetings` (one sitting: who was there and what they agreed), `dependencies` (upstream defects from real work);
- issues, changelogs, and meetings make five things findable (use `##` headings or equivalent; omit empty sections): **Participants** (humans only; omit agents, tools, and binaries), **Decisions** (what was agreed), **Effects** (done, failed, recovered, rolled back), **Next** (todo, planned, open questions), **Source** (links upstream: meeting, issue, PR, commit, and downstream materializations); git history is the edit log; add an explicit note only when a later pass changes meaning (scope cut, rollback, decision reversed);
- mention software, tools, agents, or binaries in a note only when that detail is needed for execution or later analysis; put it under Decisions, Effects, or Source, not under Participants;
- never put local absolute paths or private material in `docs/` or `usr/docs/`: no home-directory or machine-specific filesystem paths, secrets, credentials, tokens, API keys, or personal private data; prefer repository-relative paths;
<!-- pray:bfe6ff38 -->

<!-- pray:edcc5f67 -->
## Dependency issues

When work surfaces a clearly visible bug or defect in a dependency (wrong behavior, broken API contract, regression between versions, or a fix already merged upstream but not released), say so in the task output and suggest a concrete fix path: upgrade, pin, patch, vendor, workaround, or upstream report.

Store evidence under `usr/docs/dependencies/#{YYYYMMDDHHMMSS}_<kebab-case-title>.md`; no README index in that tree. Each file should make these findable (use `##` headings or equivalent; omit empty sections): **Dependency** (name, version constraint, lockfile entry if any), **Symptom** (what breaks and where), **Evidence** (repro steps, logs, stack traces, links to issues or commits), **Suggested fix** (upgrade, pin, patch, workaround, or upstream report), **Next** (todo, planned, open questions), **Source** (links upstream: issue, PR, release note, commit, and downstream materializations in this repo). Git history is the edit log.

Do not open drive-by dependency hunts; record only issues encountered while doing the requested work and only when the defect is evident from behavior or published upstream facts, not speculation.

For proactive selection, alteration, and audit rules, use `dependency-policy` and the dependency-audit skill.
<!-- pray:edcc5f67 -->

<!-- pray:3ac5d6ce -->
## Dependency policy

Rules for adding, changing, or removing third-party packages. Apply across languages. Names vary by ecosystem; concepts do not.

Terminology:

- package manifest — declares intent (`gemspec`, `package.json`, `Cargo.toml`, `mix.exs`, etc.)
- lockfile — pins the resolved graph CI and developers install
- registry — published versions consumers resolve (`RubyGems`, `npm`, `crates.io`, `Hex`, etc.)
- hot path — code on the security, auth, crypto, IO, or request/response boundary users rely on

Stop until one of these applies before adding a dependency:

- stdlib or the framework for this tree already covers it;
- an installed transitive dependency already covers it without a second library for the same job;
- the feature needs a new package and tests will prove behavior.

Run the dependency-audit skill when adding, replacing, or removing a direct dependency; when asked for a dependency audit; before a release that changes hot-path packages; or after a published advisory names a package in the graph.

Related: `dependency-issues` records upstream defects found during real work; `minimal-implementation` covers YAGNI before adding deps; `engineering-audit` covers code and pipeline review.
<!-- pray:3ac5d6ce -->

<!-- pray:26f3566a -->
## Branch naming

Use kebab-case after the prefix.

Prefixes:

- `feature/<title>` — new capability
- `patch/<title>` — bugfix or chore
- `trunk/<title>` — release candidate or integration work before `main`
- `plan/<title>` — exploration or ideation

Examples:

- `feature/user-access-control`
- `patch/fix-translation`
- `trunk/2026w15`
- `trunk/2026-august-pack`
- `plan/auth-redesign-notes`
- `plan/2026-q2-roadmap`
<!-- pray:26f3566a -->

<!-- pray:ca94e22d -->
## Writing and changelog prose checks

Read once for marketing odor, once for negation-led sentences, once for stray em dashes, and once for paragraphs that break on clause instead of on scene; keep live notes and metadata honest and plain.
- repo trace under usr/docs: plain prose readable without a rendered preview. No markdown tables, bold, italic, or other styling. Prioritize factual accuracy over presentation.
- Ease, lexical diversity, coherence, mechanics, and claim integrity are separate constructs. Automated matches, readability grades, similarity, and model preference are review prompts; rewrite for meaning.
- Keep agency on the person who acts. Tools and process nouns do mechanical work.
- Technical names, APIs, CLI verbs, RFC titles, identifiers, and UI copy use instrument and protocol words: check-in, last-seen, probe, monitor, expected tick. Body and organism metaphors such as heartbeat, pulse, and organ stay out of contracts and code. HTTP `/health` remains the liveness probe until a later RFC.
- One sentence holds one beat. Consecutive short sentences that only restated the same beat are a punchline stack.
- For material external claims, quotations, dates, or research summaries, use the claims-audit skill.
<!-- pray:ca94e22d -->

<!-- pray:d893ab3d -->
## Claims and testimony

Treat checkable facts, quotations, dates, quantities, and causal statements as claims. Treat author memory and clearly framed interpretation as testimony.

- Inventing scenes, sources, numbers, or quotations is out of scope.
- A link or citation in the text is not verification. The cited passage must support the claim's scope, date, population, and causal strength.
- If a material external claim cannot be checked in this run, mark it unverifiable rather than rounding it to certainty.
- Run the claims-audit skill when asked to verify, fact-check, or research checkable claims, or when prose under edit states material external facts, quotations, dates, or research summaries.

Related: `writing-prose` covers voice and quality constructs; `engineering-audit` covers code and pipeline behavior.
<!-- pray:d893ab3d -->

<!-- pray:b1ea9b07 -->
## RFC process

Significant user-facing contract changes start as an RFC. Skip a bugfix, typo, or refactor that leaves those contracts in place.

Claim `rfcs/ids/NNNN` before writing `rfcs/NNNN-slug.md`. Copy `rfcs/0000-template.md`. Omit unused header fields and empty sections. Implementation PRs cite `RFC-NNNN`. Numbering bands, isolation, and extra product tests live in `rfcs/README.md`. Follow the rfc-process skill. Product RFCs specify a design. Version numbers belong in changelogs. Keep existing RFC numbers. RFC titles, registrar names, and identifiers use instrument and protocol words; body and organism metaphors stay out of contracts and code.
<!-- pray:b1ea9b07 -->

<!-- pray:08c294fb -->
## Likely rejected changes

- features whose complexity outweighs user value
- giant refactors
- non-trivial changes without tests
- style-only rewrites without behavior change
- AI-generated-looking code the author does not understand
<!-- pray:08c294fb -->

<!-- pray:2543c1cc -->
## Checks before publish (engineering)

- verify the change is wanted; discuss first for unconfirmed larger features
- describe what problem is solved and why it matters
- include tests
- add screenshots or screen recordings for UI changes
- keep one pull request to one concern
- understand any AI-assisted code you submit
<!-- pray:2543c1cc -->

<!-- pray:48e8a6b3 -->
## Collaboration workflow

- agent-assisted work with ongoing project value must leave a trace in the repo;
- store only specific, decision-bearing, high-signal material; do not commit generic notes, copied chat logs, or filler;
- use the lightest process that preserves traceability; design-only work does not need branch ceremony unless implementation work starts;
- follow docs-conventions for docs/ versus usr/docs/ layout.
<!-- pray:48e8a6b3 -->
