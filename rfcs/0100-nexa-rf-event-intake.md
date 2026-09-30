# RFC 0100: Nexa RF event intake

- Type: Standards Track
- Status: Proposed
- Created: 2026-09-30
- Author: Kisko Labs
- Feedback until: 2026-10-14
- Relates: RFC 0003, RFC 0101
- Supersedes: RFC 0003

## Summary

kisko-doorbell will migrate RF intake from the deployed Honeywell contract in RFC 0003 to Nexa protocol 96 at 433.92 MHz. It will accept `ON` events from transmitter identifier `2810647` and reject the duplicate Proove decoding and non-press states.

## Motivation

The replacement indoor receiver is a Nexa LMLR-710 operating at 433.92 MHz. The installed unit is marked with date code `2106`, according to operator inspection. The LMLR-710 receives events from a separately paired System Nexa transmitter, so its receiver label does not identify the transmitter protocol or event identifier used by kisko-doorbell.

The current implementation enables Honeywell ActivLink protocols 115 and 116 at 868.3 MHz. A live capture of the replacement transmitter established the frequency, decoder, identifier, and press state needed to replace that contract.

## Guide-level explanation

An operator first stops the process that currently owns the RTL-SDR receiver. The operator then records several presses of the installed outdoor button:

```sh
rtl_433 -f 433.92M -M protocol -M level -F json -S all -T 60
```

The capture must include the emitted JSON and a replayable signal file. If rtl_433 reports `usb_claim_interface error -6`, the receiver is busy and no RF evidence was collected. The operator identifies and stops the process or driver holding the receiver before retrying.

The successful capture reports the same transmission through protocol 51 as `Proove` and protocol 96 as `Nexa`. Production enables only protocol 96 so one transmission does not enter the application through both decoders:

```sh
rtl_433 -R 96 -M newmodel -M protocol -F json -f 433920000 -s 250000
```

The application accepts an event only when `id` is `2810647` and `state` is `ON`. Test mode replays a captured 433.92 MHz fixture through the same decoder and event filter.

## Reference-level explanation

RFC 0003 remains the Stable RF intake contract until this RFC advances and its implementation ships.

The receiver command must select protocol 96, request the `newmodel` JSON shape and protocol metadata, tune live input to 433920000 Hz, and set the sample rate to 250000 samples per second. Protocol 51 must not be enabled because it decodes the same transmission a second time as `Proove`.

With `-M newmodel`, the captured press has `model` `Nexa-Security`, `id` 2810647, `state` `ON`, `channel` 3, `unit` 3, and `group` 1. The event filter must require the identifier and `ON` state before Slack delivery. Model, channel, unit, and group remain diagnostic fields rather than identity inputs.

Test mode must use the new fixture and exercise the same decoder and event-filter contract as live input. The implementation specs must assert the command arguments and representative matching and non-matching JSON events.

## Implementation notes

`Kisko::Doorbell::CLI#rtl_433_arguments` selects protocol 96 at 433920000 Hz and 250000 samples per second. Test mode selects `signals/g006_433.92M_250k.cu8`. `Kisko::Doorbell::MessageJob#perform` requires the configured decimal identifier and `ON` state. The focused specs cover the command, fixture selection, matching press, non-press state, and foreign identifier.

The installed rtl_433 binary is build `18.12-288-gfaee3a5`. The first discovery attempt on 2026-09-30 ended with `usb_claim_interface error -6` because the running kisko-doorbell service owned the receiver.

A second attempt after stopping the service captured repeated ASK transmissions around 433.92 MHz. Protocols 51 and 96 both reported `id` 2810647, `state` `ON`, `channel` 3, `unit` 3, and `group` 1.

Replaying all thirteen saved files with protocol 96 and `-M newmodel` identified `g006_433.92M_250k.cu8` as the smallest successful fixture. It is 524288 bytes, has SHA-256 `d4cea2d00e1b54f7269a07736f9668e6cd584572ec5cd05610c253dc9c508f2f`, and emits two identical `Nexa-Security` `ON` events for identifier 2810647.

The deployed service log also reports a 250000 sample-per-second rate for the existing 868.3 MHz command. Lowering the sample rate is therefore not available as a temperature reduction from the current deployed value.

## Security considerations

RF identifiers can distinguish installed transmitters. Store only the identifier needed for event filtering, and do not publish unrelated neighboring device events collected during discovery.

## Registrar

Live frequency: 433920000 Hz. Sample rate: 250000 samples per second. Protocol selector: 96. Event model: JSON `model` `Nexa-Security`. Event identifier: JSON `id` 2810647. Press state: JSON `state` `ON`. Captured diagnostics: `channel` 3, `unit` 3, `group` 1. Fixture: `signals/g006_433.92M_250k.cu8`.

## Drawbacks

Requiring an on-site capture delays implementation. Supporting both old and new hardware during migration may require explicit configuration instead of another fixed receiver command.

## Rationale and alternatives

The LMLR-710 is a receiver that can learn multiple System Nexa transmitters. The live capture, rather than the receiver brand alone, establishes protocol 96 and the event fields.

Protocol 51 also decodes the transmission, but enabling both demonstrated decoders emits two JSON events for each decoded packet. Protocol 96 identifies the event as Nexa and provides the required fields. Leaving protocols 115 and 116 unchanged would retain Honeywell decoders that did not report the captured Nexa transmission. Enabling every rtl_433 decoder in production would increase unrelated events and make the filtering contract depend on ambient RF traffic.

## Prior art

RFC 0003 specifies the existing fixed-frequency, fixed-decoder intake and its replay fixture. [Nexa documents the LMLR-710](https://nexa.se/smarta-hem/systemnexa/lmlr710) as a 433.92 MHz System Nexa receiver. [rtl_433 documents](https://github.com/merbanan/rtl_433/blob/master/docs/STARTING.md) saved signal capture, protocol metadata, and JSON output for decoder identification. [libusb defines error -6](https://github.com/libusb/libusb/blob/master/libusb/libusb.h) as `LIBUSB_ERROR_BUSY`.

## Unresolved questions

- Should CI install rtl_433 and replay the fixture as an integration check?
- What model is printed on the installed outdoor transmitter, if the marking is readable?
- Does migration need runtime configuration for coexistence with the old Honeywell hardware?
