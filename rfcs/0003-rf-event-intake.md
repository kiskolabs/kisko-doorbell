# RFC 0003: RF event intake

- Type: Standards Track
- Status: Stable
- Created: 2026-09-30
- Author: Kisko Labs
- Relates: RFC 0002, RFC 0004

## Summary

kisko-doorbell runs `rtl_433` at 868.3 MHz, requests JSON for the supported doorbell protocols, and queues only JSON event lines for asynchronous identifier filtering and notification.

## Motivation

The receiver emits diagnostics and events on one stream. The service must preserve diagnostics for operators while ensuring that only structured events can reach the notification path.

## Guide-level explanation

Normal operation reads an attached RTL-SDR receiver. `--test` supplies `signals/g001_868.3M_250k.cu8` to `rtl_433`, so an operator can exercise the same decoding path without waiting for a transmitter.

## Reference-level explanation

The receiver command enables protocols 115 and 116, requests the `newmodel` metadata shape and JSON output, and tunes to 868300000 Hz. Test mode adds the bundled sample with `-r`; normal mode does not add a file input.

Each output line beginning with `{` is queued to `Kisko::Doorbell::MessageJob` with the configured decimal doorbell identifier, Slack values, and state path. Other lines are debug logs. A line containing `No supported devices found` is fatal and stops the run with failure.

The job parses each queued line as JSON. Invalid JSON produces a warning and no notification. A parsed event reaches Slack delivery only when its `id` equals the configured integer. Events from other identifiers remain debug information.

## Implementation notes

`Kisko::Doorbell::CLI#rtl_433_arguments` defines the receiver contract. `Kisko::Doorbell::CLI#run!` classifies output, and `Kisko::Doorbell::MessageJob#perform` parses and filters events.

## Security considerations

Receiver JSON and unmatched identifiers appear in debug logs. Operators must treat those logs as device data and limit access to them.

## Registrar

Frequency: 868300000 Hz. Protocol selectors: 115 and 116. Bundled signal: `signals/g001_868.3M_250k.cu8`. Event identifier: JSON field `id`.

## Drawbacks

The fixed frequency and protocol selection make deployment predictable for the current hardware but require a contract change for other receivers or regions.

## Rationale and alternatives

Line classification keeps `rtl_433` as the decoder instead of duplicating RF protocol handling in Ruby. Sending every decoded event to Slack would create unrelated notifications in shared RF space.

## Prior art

The `rtl_433` JSON output and recorded complex unsigned 8-bit sample input.

## Unresolved questions

A later RFC may make frequency and protocol selection configurable if another deployed doorbell requires it.
