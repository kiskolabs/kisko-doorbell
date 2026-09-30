# Release orchestration

## Decisions

Run releases from `usr/bin/release.rb` after the versioned source commit is clean and present on `origin/master`. Build the gem from that exact commit on the Raspberry Pi. Keep public gem publication outside this workflow.

Create and push the annotated version tag only after the automated target checks and the operator's physical doorbell test pass. Persist status and timestamps under `tmp/releases` so an interrupted release can resume without storing command output.

## Effects

The script runs the repository quality gates, including a full-tree Trunk check that remains effective on a clean release commit. It verifies the target's restricted Slack token-file setup, checks out the release commit, builds and installs the gem with dependency resolution enabled, restarts the systemd service, and verifies its version and process arguments. It stops before tagging when any step or the live confirmation fails.

Specs cover SSH target validation, resumable progress, failure-state redaction, live confirmation, and the deployment sequence. The script has not been run against the doorbell host in this change.

An attempted run reached the target preflight through `pi@doorbell` and stopped before checkout or installation. Follow-up coverage requires `--sudo` to protect token-file and process-argument checks for that non-root account, and preflight failures now identify the unmet prerequisite.

## Next

- Commit and push the 0.5.1 release source.
- Run `usr/bin/release.rb --host pi@doorbell --sudo` from an interactive workstation.
- Rotate the previously exposed Slack token before completing the deployment.

## Source

- `usr/bin/release.rb`
- `spec/usr/bin/release_spec.rb`
- `README.md`
- `docs/issues/20260930162949_release-0-5-1.md`
