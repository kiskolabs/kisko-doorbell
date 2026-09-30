## Additional instructions

### .agents/project.md

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
- Before release, run `bundle exec rake`, `trunk check`, `RBENV_VERSION=3.4.6 pray verify --strict`, and `bundle exec rake build`. Inspect the built gem for required signal fixtures.
- Deployment is manual. Install the built gem on the doorbell host, update its configured doorbell identifier, restart the service, inspect its logs, and verify live presses before tagging or publishing.
- Keep credentials out of command lines, release notes, logs, and built artifacts. Rotate an exposed credential before deployment.
- Tag and push only after deployment validation. Run `bundle exec rake release` only when the intended gem server and authentication are configured and the user explicitly requested publication.
- Do not run `gem push`, publish to RubyGems, or tag a release unless the user asks for that exact operation.

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

## Shared instructions
