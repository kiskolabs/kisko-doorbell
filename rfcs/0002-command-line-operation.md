# RFC 0002: Command-line operation

- Type: Standards Track
- Status: Stable
- Created: 2026-09-30
- Author: Kisko Labs
- Relates: RFC 0003, RFC 0004

## Summary

The `kisko-doorbell` executable accepts the doorbell identifier, Slack credentials, Slack destination, and an optional recorded-signal mode, validates its runtime prerequisites, and reports distinct startup and runtime failures through exit status.

## Motivation

Operators need one repeatable command for selecting a physical transmitter and Slack destination. Supervisors need exit codes that distinguish invalid startup configuration from a receiver failure after startup.

## Guide-level explanation

```text
kisko-doorbell --doorbell-id=123456 --slack-token=TOKEN --slack-channel=#general
kisko-doorbell --test --doorbell-id=123456 --slack-token=TOKEN --slack-channel=#general
```

`--help` prints the option list. `--version` prints `kisko-doorbell vVERSION`. Test mode reads the bundled sample signal instead of an attached receiver.

## Reference-level explanation

The executable accepts `-d` or `--doorbell-id`, `-c` or `--slack-channel`, `-t` or `--slack-token`, and `-T` or `--[no-]test`. The doorbell identifier is a decimal integer.

Before starting intake, the process checks for the `rtl_433` executable, executes `rtl_433 -V`, requires both Slack values, requires a doorbell identifier, and resolves its YAML state path. A failed prerequisite exits 99. A completed intake run exits 0. A receiver error, missing device report, or rescued runtime exception exits 1. SIGINT exits 130.

Logs include the selected Slack channel and an abbreviated token. The full Slack token must not be logged.

## Implementation notes

`exe/kisko-doorbell` owns option parsing and process exit status. `Kisko::Doorbell::CLI` owns prerequisite checks and receiver execution.

## Security considerations

The Slack token is a command-line input in the shipped interface. Process listings and service definitions may expose command-line secrets, so operators must restrict host access. Logs show only the first eleven token characters followed by an ellipsis.

## Registrar

Executable: `kisko-doorbell`. Options: `--doorbell-id`, `--slack-channel`, `--slack-token`, `--test`, `--help`, and `--version`. Exit statuses: 0, 1, 99, and 130.

## Drawbacks

Command-line credentials are easy to configure but harder to isolate than credentials read from a secret store or file descriptor.

## Rationale and alternatives

A single executable works with systemd and keeps the receiver lifecycle in one process. Environment-only configuration was not part of the shipped interface.

## Prior art

Ruby `OptionParser` command-line applications and supervised Unix services.

## Unresolved questions

A later RFC may replace command-line token input with a secret-store reference while preserving the existing option during migration.
