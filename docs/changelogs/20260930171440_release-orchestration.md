# Release orchestration

## Decisions

Run releases from `usr/bin/release.rb` after the versioned source commit is clean and present on `origin/master`. Build the gem from that exact commit on the Raspberry Pi. Keep public gem publication outside this workflow.

Create and push the annotated version tag only after the automated target checks and the operator's physical doorbell test pass. Persist status and timestamps under `tmp/releases` so an interrupted release can resume without storing command output.

## Effects

The script runs the repository quality gates, including a full-tree Trunk check that remains effective on a clean release commit. It verifies the target's restricted Slack token-file setup, checks out the release commit, builds and installs the gem with dependency resolution enabled, restarts the systemd service, and verifies its version and process arguments. It stops before tagging when any step or the live confirmation fails.

Specs cover SSH target validation, resumable progress, failure-state redaction, live confirmation, and the deployment sequence. The script has not been run against the doorbell host in this change.

An attempted run reached the target preflight through `pi@doorbell` and stopped before checkout or installation. Follow-up coverage requires `--sudo` to protect token-file and process-argument checks for that non-root account, and preflight failures now identify the unmet prerequisite.

Release commands now stream sanitized standard output and standard error while retaining captured output for quiet validation commands. Gem installation uses RubyGems verbose mode so dependency downloads and native-extension builds remain visible during long Raspberry Pi operations.

RubyGems returned 404 for the unpublished `kisko-doorbell` package and then downloaded its full legacy specifications index before resolving dependencies. The target install now reads runtime requirements from the built gem, installs those named dependencies through RubyGems, and installs the doorbell package with `--local` after its dependency set is present.

The first automated checkout stopped because `/home/pi/kisko-doorbell` did not exist. The checkout step now clones the workstation's `origin` when the configured path is absent. It requires a writable parent and refuses an existing non-repository path.

## Next

- Commit and push the 0.5.1 release source.
- Run `usr/bin/release.rb --host pi@doorbell --sudo` from an interactive workstation.
- Rotate the previously exposed Slack token before completing the deployment.

## Source

- `usr/bin/release.rb`
- `spec/usr/bin/release_spec.rb`
- `README.md`
- `docs/issues/20260930162949_release-0-5-1.md`
