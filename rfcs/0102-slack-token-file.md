# RFC 0102: Slack token file

- Type: Standards Track
- Status: Proposed
- Created: 2026-09-30
- Author: Kisko Labs
- Feedback until: 2026-10-14
- Relates: RFC 0002

## Summary

The `kisko-doorbell` executable will read its Slack token from a restricted file so supervised deployments do not expose the credential in process arguments. The existing `--slack-token` option remains available during migration.

## Motivation

RFC 0002 records the shipped command-line token input. A process argument is visible in process listings and is commonly copied into a systemd unit, so it does not provide adequate isolation for a long-lived Slack credential.

The deployed host's support for native service-manager credentials has not been established. A plain restricted file works without making this release depend on that unverified capability or placing the token itself in an environment variable.

## Guide-level explanation

Create a root-owned token file that contains only the Slack token and a trailing newline:

```sh
sudo install -d -m 700 /etc/kisko-doorbell
sudoedit /etc/kisko-doorbell/slack-token
sudo chmod 600 /etc/kisko-doorbell/slack-token
```

Pass the path, not the token, to the service:

```text
kisko-doorbell --slack-token-file=/etc/kisko-doorbell/slack-token --slack-channel=#general --doorbell-id=2810647
```

The `KISKO_DOORBELL_SLACK_TOKEN_FILE` environment variable may provide the path when the command line should contain only stable application arguments.

## Reference-level explanation

The executable accepts `--slack-token-file=PATH`. It also reads the initial path from `KISKO_DOORBELL_SLACK_TOKEN_FILE`; an explicit option replaces that environment-provided path.

When `--slack-token` and a token-file path are both present, the direct token argument takes precedence for backward compatibility. Otherwise the prerequisite check reads the file, removes surrounding whitespace, and requires a non-empty token and Slack channel.

A missing or unreadable file fails the Slack prerequisite, logs the path and operating-system error without token content, and causes the existing startup-failure exit status 99. A successful check logs the channel and credential source, never a token or token prefix.

The process reads the file before starting rtl_433 and retains the value in memory. Changing the file requires a service restart.

## Implementation notes

`exe/kisko-doorbell` parses the option and environment variable. `Kisko::Doorbell::CLI#slack_token` reads the file, and `Kisko::Doorbell::CLI#check_slack` handles missing input and file errors. The CLI specs cover successful file loading and an unreadable path.

## Security considerations

The token file must be readable only by the service account. The application does not place token contents in its command line or logs, but the running process necessarily holds the token in memory. Operators must rotate any token previously exposed through process arguments before deployment.

## Registrar

Option: `--slack-token-file=PATH`. Environment variable: `KISKO_DOORBELL_SLACK_TOKEN_FILE`.

## Drawbacks

The token remains on the host filesystem and a compromised service account can read it. Operators must manage ownership, permissions, rotation, and service restarts.

## Rationale and alternatives

Passing the token itself through an environment variable removes it from normal process listings but still places the secret in the process environment. A token file permits standard Unix ownership and mode controls and works on the deployed host.

Removing `--slack-token` immediately would break the Stable RFC 0002 interface. Keeping it during migration preserves compatibility while the production unit moves to the file input.

Native systemd credentials provide stronger lifecycle isolation on supported releases. The deployed host version has not been established, so requiring that feature would make this release depend on an unverified operating-system upgrade.

## Prior art

RFC 0002 records the existing direct token option. This RFC preserves that interface during migration while adding the restricted-file input.

## Unresolved questions

- When can the direct `--slack-token` option be deprecated and removed?
- Does a future host upgrade allow migration to native systemd credentials?
