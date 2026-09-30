<!-- pray:0 ignore-comments -->

# Agent context

Do not edit managed blocks in `AGENTS.md` or provisioned files under `.agents/`.
To change shared guidance, update `Prayfile` and run `pray install`.

<!-- pray:ae5d334a -->
## Additional instructions

kisko-doorbell is a Ruby gem and command-line service. It reads doorbell RF events from `rtl_433` through an RTL-SDR receiver and posts matching events to Slack. The default branch is `master`.

Linear: https://linear.app/kisko/team/KIS/active
GitHub: https://github.com/kiskolabs/kisko-doorbell
Slack: #kisko-apps
Runtime errors go to Honeybadger through `HONEYBADGER_API_KEY`.

Link an existing Linear issue on the pull request when the user named one.

Evidence comes from git, specs, `rfcs/`, `docs/`, pull requests, Linear, GitHub, Slack, and Honeybadger. Reads from those sources are allowed. Writes are not implied by listing them.

## External service writes

- Do not create, update, comment, post, or otherwise write to external services unless the turn names that destination and the write.
- Repository work does not authorize Linear, Slack, Honeybadger, or GitHub writes.
- Drafts stay in the reply or in `docs/` until the user says to send them.

## Build and release

- CI is `.github/workflows/test.yml`; Trunk checks run from `.github/workflows/_trunk_check.yml`.
- Run `bundle exec rake` for specs and RuboCop.
- Keep user-visible pending changes under `## Unreleased` in `CHANGELOG.md`. Move them to a versioned heading with the release date when cutting the release.
- Use a new version for changed gem contents. Update `lib/kisko/doorbell/version.rb` before building; never replace an existing version with different bytes.
- Commit every file intended for the gem before building because the gemspec packages files returned by `git ls-files`.
- Before release, run `bundle exec rake`, `trunk check --all`, `RBENV_VERSION=3.4.6 pray verify --strict`, and `bundle exec rake build`. Inspect the built gem for required signal fixtures.
- Deployment is operator-triggered through `usr/bin/release.rb`. The script deploys the exact pushed `master` commit, builds and installs the gem on the doorbell host, restarts and verifies the service, requires a confirmed live press, and only then creates and pushes the version tag.
- Keep credentials out of command lines, release notes, logs, and built artifacts. Rotate an exposed credential before deployment.
- Run `bundle exec rake release` only when the intended gem server and authentication are configured and the user explicitly requested publication.
- Do not run `gem push` or publish to RubyGems unless the user asks for that exact operation.

## Skills

- engineering-audit: packaged from amkisko/prayers
- dependency-audit: from dependency-policy
- changelog-update: packaged from amkisko/prayers
- claims-audit: packaged from amkisko/prayers
- rfc-process: packaged from amkisko/prayers

## Documentation

Shipped contracts live under `rfcs/`. Claim `rfcs/ids/NNNN` before writing an RFC and follow the rfc-process skill. This repository keeps engineering traces under `docs/changelogs`, `docs/issues`, `docs/meetings`, and `docs/dependencies`.

## Tests and source shape

RSpec tests live under `spec/`. Prefer production source files at 150 lines or fewer when cohesion allows. Files from 151 through 300 lines produce a LOC warning; production source files above 300 lines fail RuboCop.

## Jobs and configuration

Background Slack delivery uses SuckerPunch in `lib/kisko/doorbell/message_job.rb`. The Slack destination comes from the `--slack-channel` CLI option.
<!-- pray:ae5d334a -->

<!-- pray:9068e4a2 -->
- when fixing or refactoring code, add or update tests first to expose the current bug/regression path (or missing contract), then implement the fix, then run focused and broader checks, and do not ship behavior changes without proving before/after via specs;
- test only executable logic and user-facing behavior; tests should affect coverage metrics;
- avoid tests that only assert implementation details; avoid file/page content/ordering/regex assertions; avoid duplicating tests;
- user interface texts should never mention implementation technical details;
- prefer files around <=150 LOC when cohesion allows; split only when it improves ownership, readability, and reviewability;
- do not use abbreviations or short names unless they are very common;
- avoid explanatory comments, but allow intent comments for non-obvious constraints, invariants, concurrency edges, or external contract requirements;
- readability, structure, and clarity are product qualities;
- pull request description answers what problem is solved, why it matters, how the solution works, and relevant context; non-trivial changes include reproduction steps or a changelog entry with intent;
- pull request checklist: changelog entry with intent or reproduction steps when relevant, test coverage, and quality checks done;
- follow docs-conventions for docs timestamp-tree filenames and layout;
- report completed actions only with observed evidence; validation output must list exact commands run and observed results;
- ignore style-only dust unless it harms correctness, operability, maintainability, or auditability under realistic load;
- sibling files and executable checks beat shared defaults; mixed styles stay a split until a path boundary explains both;
- fix the cause of a race, not a retry around it; prefer positive names; compute at write when a read cannot paginate; do not change production design only so tests can reach it;
- if process state and local cache files are both cleared, name what must be rebuilt and from which durable source;
- side effects read committed state from a cursor; they are not steps of the write;
- on a store or network hot path, name the expensive unit and keep a before-and-after budget;
- after changing a published number, identifier, or contract field, search dependents and mark them stale or update them.
<!-- pray:9068e4a2 -->

<!-- pray:781b7711 -->
## Credentials and Secrets

- Prefer a secret store or OS credential helper over embedding live secrets in config files, scripts, or documentation. Named managers (for example 1Password, Bitwarden, KeePassXC) are fine; the requirement is isolation, not a specific vendor.
- Config and project files may hold references (vault paths, item ids, redacted fingerprints). They must not hold live tokens, API keys, passwords, or client secrets. The same prohibition applies to skill files, prompt templates, and MCP environment settings.
- Do not pass secrets on command lines or in other process-visible arguments. Prefer secret-store lookup, short-lived credentials, or stdin/file descriptors that do not persist in shell history.
- Do not commit secrets, paste them into issues or pull requests, or write them to logs. Rotate anything that may have been exposed.
- if a live secret, credential, or confidential trace appears in this session, treat it as a security event: tell the person, do not quote the value, and do not send it to another third party; the inference provider already saw what reached this session

## Tracking and identification

- A redacted fingerprint above is a hash of a secret for config references. A device fingerprint is fields that combine to identify a person or device across sessions or observers.
- Identifiers, IP addresses, device marks, and combined attributes are personal data. They can unmask a person, a location, or a session secret. Emit them only when the feature they asked for this session needs them and they were shown that this product would.
- Silent analytics ids, leftover marks after logout, and canvas or hardware probes are security events. They can locate a person, stitch sessions, or leak a credential-shaped token.

## Ownership and destinations

- Lookups go through an ownership set; request parameters pick which row; fail closed when access cannot be proven.
- Treat user-supplied URLs as untrusted; rate-limit authentication and abuse-prone endpoints.
- An invalid or expired credential gets a protocol-level failure status. A hop's own credential is never the caller's. Modes that relax access controls must remain disabled when their configuration is missing or invalid.

Related: `engineering-audit` security mode asks whether a parameter establishes access and whether a worker skipped policy.
<!-- pray:781b7711 -->

<!-- pray:bfe6ff38 -->
- `docs/` holds maintained explanations and working records; use stable descriptive filenames for guides; placement does not imply polish or currency;
- keep inference input (AGENTS.md, `.agents/`) separate from `docs/`; conventions that matter fail a command;
- `usr/` is the workshop for working tools and operational material;
- `usr/migrate/` holds console-first scripts that must run before new code is on the process; later schema migrate is schema-only and idempotent;
- four `docs/` timestamp trees, no README index, filename `YYYYMMDDHHMMSS_<kebab-case-title>.md`: `issues` (live work: contract, findings, open next; pitch, plan, and queue stay here), `changelogs` (what shipped), `meetings` (one sitting: who was there and what they agreed), `dependencies` (upstream defects from real work);
- issues, changelogs, and meetings make five things findable (use `##` headings or equivalent; omit empty sections): **Participants** (humans only; omit agents, tools, and binaries), **Decisions** (what was agreed), **Effects** (done, failed, recovered, rolled back), **Next** (todo, planned, open questions), **Source** (links upstream: meeting, issue, PR, commit, and downstream materializations); git history is the edit log; add an explicit note only when a later pass changes meaning (scope cut, rollback, decision reversed);
- mention software, tools, agents, or binaries in a note only when that detail is needed for execution or later analysis; put it under Decisions, Effects, or Source, not under Participants;
- never put local absolute paths or private material in `docs/` or under `usr/`: no home-directory or machine-specific filesystem paths, secrets, credentials, tokens, API keys, or personal private data; prefer repository-relative paths;
- one home per fact; link, do not duplicate; goal and acceptance live apart from operating rules; when a decision changes shape, supersede it in place; name what the product does not do next to what it does;
<!-- pray:bfe6ff38 -->

<!-- pray:edcc5f67 -->
## Dependency issues

When work surfaces a clearly visible bug or defect in a dependency (wrong behavior, broken API contract, regression between versions, or a fix already merged upstream but not released), say so in the task output and suggest a concrete fix path: upgrade, pin, patch, vendor, workaround, or upstream report.

Store evidence under `docs/dependencies/#{YYYYMMDDHHMMSS}_<kebab-case-title>.md`; no README index in that tree. Each file should make these findable (use `##` headings or equivalent; omit empty sections): **Dependency** (name, version constraint, lockfile entry if any), **Symptom** (what breaks and where), **Evidence** (repro steps, logs, stack traces, links to issues or commits), **Suggested fix** (upgrade, pin, patch, workaround, or upstream report), **Next** (todo, planned, open questions), **Source** (links upstream: issue, PR, release note, commit, and downstream materializations in this repo). Git history is the edit log.

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

Run dependency-audit for direct dependency changes, graph audits, releases with hot-path package changes, and plausible dependency vulnerability or exploitation signals found during ordinary work. Keep the evidence and assessment in the live-work or dependency record.

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

Review for marketing language, invented objections, empty contrasts, stray em dashes, and paragraph flow; keep notes and metadata honest and plain.
- docs timestamp trees: plain prose readable without a rendered preview. No markdown tables, bold, italic, or other styling. Prioritize factual accuracy over presentation.
- Ease, lexical diversity, coherence, mechanics, and claim integrity are separate constructs. Automated matches, readability grades, similarity, and model preference are review prompts; preserve meaning, necessary negation, scope, and uncertainty when editing.
- Keep agency on the person who acts. Tools and process nouns do mechanical work.
- Technical names, APIs, CLI verbs, RFC titles, identifiers, and UI copy use instrument and protocol words: check-in, last-seen, probe, monitor, expected tick. Body and organism metaphors such as heartbeat, pulse, and organ stay out of contracts and code. HTTP `/health` remains the liveness probe until a later RFC.
- One sentence holds one beat. Consecutive short sentences that only restated the same beat are a punchline stack.
- For material external claims, quotations, dates, or research summaries, use the claims-audit skill.
- signed comments on a public tracker speak as the account holder to the named person; chat stays in chat
- cite only what a public reader can open and check; confidential traces, unique working locators, and unverifiable session evidence stay in chat; do not expose source material that is not already public, and do not post source material without the person's consent
- greeting names the person, then a short body, a close, and the name from the tracker identity; first person when that person did the work
- one primary commit, pull request, or release link; comment when asked; do not close, assign, or reopen unless asked

Related: `security` forbids secrets in issues and owns the session notice when confidential material hits inference.
<!-- pray:ca94e22d -->

<!-- pray:d893ab3d -->
## Claims and testimony

Treat checkable facts, quotations, dates, quantities, and causal statements as claims. Treat author memory and clearly framed interpretation as testimony.

- Inventing scenes, sources, numbers, or quotations is out of scope.
- A link or citation in the text is not verification. The cited passage must support the claim's scope, date, population, and causal strength.
- If a material external claim cannot be checked in this run, mark it unverifiable rather than rounding it to certainty.
- Keep statement, domain, and quantifiers on a formal claim. Freeze quantities from the producing artifact. A later file does not prove an earlier check.
- Run the claims-audit skill when asked to verify, fact-check, or research checkable claims, or when prose under edit states material external facts, quotations, dates, or research summaries.

Related: `writing-prose` covers voice and quality constructs; `engineering-audit` covers code and pipeline behavior; `derivation-audit` covers symbolic derivation when a consumer asks for that job.
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
- compatibility aliases, shims, and legacy input shapes that remain accepted even though the change should remove them
<!-- pray:08c294fb -->

<!-- pray:2543c1cc -->
## Checks before publish (engineering)

- verify the change is wanted; discuss first for unconfirmed larger features
- describe what problem is solved and why it matters
- include tests
- add screenshots or screen recordings for UI changes
- keep one pull request to one concern
- understand any AI-assisted code you submit
- review generated changes before requesting revisions; write review replies from the author's own understanding
<!-- pray:2543c1cc -->

<!-- pray:48e8a6b3 -->
## Collaboration workflow

- record durable project value in the live-work queue, including improvements to shared guidance or a skill;
- keep only decision-bearing material; omit generic notes, copied chat, and filler;
- use the lightest trace that preserves context; design-only work needs no branch unless implementation starts;
- follow docs-conventions for `docs/` and `usr/`; when encoding how this tree writes, use infer-conventions.
<!-- pray:48e8a6b3 -->
