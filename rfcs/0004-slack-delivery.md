# RFC 0004: Slack delivery

- Type: Standards Track
- Status: Stable
- Created: 2026-09-30
- Author: Kisko Labs
- Relates: RFC 0002, RFC 0003

## Summary

Matching doorbell events post a randomly selected message to the configured Slack channel. A local YAML store suppresses notifications within five seconds and selects an urgent message when the prior notification is at most two minutes old.

## Motivation

One physical press may decode more than once, while repeated presses after a short wait can mean that a visitor is still waiting. Slack delivery needs to suppress immediate duplicates without hiding that second situation.

## Guide-level explanation

The first matching event posts one message from the normal catalog with the `:bellhop_bell:` icon. Another event within five seconds does not post. A later event within two minutes uses the urgent catalog and begins with `<!here>, `. After two minutes, delivery returns to the normal catalog.

## Reference-level explanation

`Kisko::Doorbell::MessageJob` creates a Slack Web client from the configured token and calls `chat_postMessage` with the configured channel, selected text, and `:bellhop_bell:` icon.

The process-wide state path is `kisko-doorbell.yaml` under the operating system temporary directory. Delivery runs inside an exclusive `YAML::Store` transaction. If `last_message_sent_at` exists and is no more than five seconds old, the job returns without posting. Otherwise it selects a normal message when the timestamp is absent or older than 120 seconds, and an urgent message for a newer timestamp. Slack urgent messages prefix the selected text with `<!here>, `.

After a successful Slack response, the job records the message under `body` and the timestamp under `last_message_sent_at`. The current implementation reads `last_message_body` when avoiding a repeated choice, so consecutive normal messages are not guaranteed to differ. Slack or job exceptions flow through the configured SuckerPunch exception handler to Honeybadger.

## Implementation notes

`Kisko::Doorbell::MessageJob` owns filtering, catalogs, throttling, state, and Slack delivery. `Kisko::Doorbell::CLI#initialize` configures SuckerPunch logging and Honeybadger exception reporting.

## Security considerations

The YAML file contains timestamps and message text but no Slack token. The file lives in a shared temporary directory, so the store must not acquire credentials or other sensitive fields without a later security design.

## Registrar

State file: `kisko-doorbell.yaml`. Written state fields: `last_message_sent_at` and `body`. Read compatibility field: `last_message_body`. Slack mention: `<!here>`. Slack icon: `:bellhop_bell:`.

## Drawbacks

Local temporary state is not shared across processes or hosts and may disappear after a restart. `<!here>` can notify many Slack members when repeated presses arrive within two minutes.

## Rationale and alternatives

The YAML transaction provides a small cross-thread critical section without another service. Sending every decoded press would create bursts; suppressing all repeats for two minutes would conceal a visitor who is still waiting.

## Prior art

Slack Web API `chat.postMessage` and file-backed process coordination.

## Unresolved questions

A later RFC may define durable or multi-host throttling if the receiver service runs with more than one process.
