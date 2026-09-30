# Project tooling and RFC baseline

## Decisions

Use Prayfile as the source for shared agent guidance and keep project-specific guidance in `.agents/project.md`. Provision dependency-audit, engineering-audit, changelog-update, claims-audit, and rfc-process as project-local skills.

Document the shipped command-line, RF intake, and Slack delivery contracts as Stable RFCs. Reserve later proposal numbers from 0100.

Run Ruby 3.4 in `.github/workflows/test.yml`. Run specs and RuboCop through the default Rake task. Treat 151 through 300 production-source lines as a visible warning and more than 300 as a RuboCop failure.

Use Trunk for RuboCop, workflow, YAML, Markdown, shell, secret, and dependency checks. Ignore generated Pray inputs where a linter would otherwise require changes to provisioned files.

## Effects

Removed `.github/workflows/ruby.yml` and the obsolete Travis configuration, then added the supported test workflow. Pinned checkout, Ruby setup, and Trunk actions by commit. Limited Dependabot and pull request labels to ecosystems and paths that exist in this gem.

Added `.pray` and Trunk generated-state ignore rules. `pray verify --strict` reports no drift.

Added RuboCop configuration and executable specs for both LOC thresholds. `bundle exec rake` completes with three examples, no failures, no RuboCop offenses, and a warning for the existing 154-line CLI.

Updated the Ruby 3.4 test dependencies and the vulnerable transitive runtime lock entries. `bundler-audit check --update` reports no vulnerabilities and `trunk check --all --no-progress` reports no issues.

The gem builds as `pkg/kisko-doorbell-0.5.0.gem` after excluding deleted tracked paths from package contents.

## Source

- `Prayfile`
- `.agents/project.md`
- `rfcs/README.md`
- `.github/workflows/test.yml`
- `.github/workflows/_trunk_check.yml`
- `.rubocop.yml`
- `.trunk/trunk.yaml`
- `Gemfile.lock`
