# RFC 0101: RTL-SDR thermal operation

- Type: Standards Track
- Status: Proposed
- Created: 2026-09-30
- Author: Kisko Labs
- Feedback until: 2026-10-14
- Relates: RFC 0100

## Summary

kisko-doorbell will keep the RTL-SDR receiver continuously available while controlling avoidable heat through placement, airflow, and a disabled unused bias tee. An operator will measure case-temperature rise and actual USB current before and after each change. The application will not duty-cycle reception or change RF gain without proving that the doorbell still decodes reliably.

## Motivation

The installed receiver is marked `rtl-sdr.com`, `RTL2832U`, `R820T2`, `TCXO`, `BIAS T`, and `HF`, which is consistent with an RTL-SDR Blog V3. The marking does not prove that the unit is genuine. The metal case becomes hot during continuous reception, but there is no case-temperature or current measurement yet to distinguish intended heat transfer from excess power or a faulty unit.

The doorbell transmission is brief and asynchronous. Turning the receiver off between expected events would reduce heat by creating periods in which a visitor cannot ring the software doorbell.

## Guide-level explanation

Keep the aluminium enclosure installed and exposed to room air. Do not put the dongle inside the Raspberry Pi enclosure or against its processor, power supply, or another heat source. Use a short USB extension when needed to separate those heat sources, and keep the receiver out of direct sunlight.

Measure rather than judge by touch. Attach a contact probe to the centre of the metal case with electrically insulating tape. Place a second probe in the same air volume without touching the Pi, dongle, wall, or sunlight. Put an inline USB voltage and current meter between the Pi and receiver. USB descriptor values such as `MaxPower` are not measurements.

Let the disconnected receiver and both probes reach the same room temperature. Start the service and record this comma-separated data at 0, 5, 15, 30, and 60 minutes:

```text
elapsed_minutes,ambient_c,case_c,case_rise_c,usb_v,usb_a,disconnects,decoded_presses
0,,,,,,,
5,,,,,,,
15,,,,,,,
30,,,,,,,
60,,,,,,,
```

At 60 minutes, ring the installed button twenty times at normal range and record how many events decode. Repeat the run after each physical or receiver-setting change. Keep the service's startup log with the measurement so the frequency, sample rate, gain mode, tuner identity, and USB failures remain attributable.

The manufacturer says a genuine V3 case normally reaches about 20 to 25 degrees Celsius above ambient because the metal enclosure transfers heat away from the chips. It also describes 0.28 to 0.30 amperes as normal USB current and associates higher current with abnormal heat and random disconnections in a small set of older faulty units. These figures are comparison bands, not general safety ratings for an unidentified or counterfeit receiver.

For the current passive antenna, the bias tee is unnecessary. The production rtl_433 arguments do not request it, but a persistent EEPROM setting or driver can still turn it on. Stop the service and use the manufacturer's driver procedure to confirm the forced-bias setting before changing EEPROM. An operator qualified to probe RF connectors may also check for DC voltage at the disconnected antenna port without shorting it. Record the result. Do not power a fan from the antenna port.

Apply changes in this order, repeating the 60-minute run each time:

1. Separate the dongle from the Pi and other heat sources, expose the case to free air, and remove direct sunlight.
2. Confirm that the unused bias tee is not forced on.
3. If case rise or current remains outside the manufacturer's comparison bands, try gentle airflow across the metal case from a separately powered fan.
4. Replace the receiver if excess current, rising temperature, or USB disconnections persist.

The receiver remains at 433920000 Hz and 250000 samples per second. The deployed service already used 250000 samples per second, so that value is not a new thermal reduction. Automatic gain remains in place until a measured fixed-gain trial both lowers heat or current beyond instrument resolution and decodes all twenty test presses.

## Reference-level explanation

Continuous RF intake is required. A thermal control must not intentionally create deaf intervals unless a later RFC defines the resulting availability loss.

The measurement record must include receiver markings, ambient temperature, case temperature, measured USB voltage and current, elapsed time, USB disconnect count, rtl_433 startup settings, and live press results. Raspberry Pi processor temperature is diagnostic context only and must not be reported as receiver temperature.

The first run uses the RFC 0100 production command with automatic tuner gain. A changed layout, fan, bias setting, gain, sample rate, receiver, or power source starts a new run. One change per run keeps cause and effect distinguishable.

A proposed RF-setting change passes the reception gate only when the saved RFC 0100 fixture still decodes and twenty of twenty live presses decode after 60 minutes. A setting that misses a press is rejected even if it lowers temperature. A result outside the manufacturer's temperature-rise or current bands requires investigation; it does not by itself identify the cause.

The installed rtl_433 build predates its RTL-SDR `biastee` setting, so kisko-doorbell must not add an unsupported command argument. A later rtl_433 upgrade may explicitly request `biastee=0` only after replay and live-hardware tests confirm the command and protocol contract.

## Security considerations

Do not include Slack credentials or unrelated received RF identifiers in a measurement record. Stop and disconnect USB power before changing wiring. Treat the antenna connector as potentially energised until bias-tee state is known.

## Registrar

Thermal record fields: `elapsed_minutes`, `ambient_c`, `case_c`, `case_rise_c`, `usb_v`, `usb_a`, `disconnects`, and `decoded_presses`. Reception gate: twenty decoded events from twenty live presses after 60 minutes.

## Drawbacks

The procedure needs two temperature probes and an inline USB meter. It takes at least one hour per configuration. Continuous availability prevents software duty cycling, and added airflow introduces another powered component.

## Rationale and alternatives

The metal enclosure is part of the receiver's passive cooling path, so a hot case can indicate working heat transfer rather than a hot chip. Removing or insulating it works against that design. A lower sample rate is unavailable because 250000 samples per second is already the rtl_433 default at 433.92 MHz and the deployed rate.

Power cycling would cool the receiver but necessarily loses events while it is off. Changing gain without measuring current and reception assumes a thermal benefit that has not been established. Raspberry Pi processor temperature and USB descriptor current are easy to collect but do not measure the receiver quantities in question.

A dedicated low-power 433.92 MHz receiver connected to a GPIO could reduce heat and power, but it replaces the rtl_433 decoding boundary and needs a separate RFC, implementation, interference test, and electrical design.

## Prior art

The [RTL-SDR Blog V3 guide](https://www.rtl-sdr.com/rtl-sdr-blog-v-3-dongles-user-guide/) describes the enclosure's thermal role, expected temperature rise and current, sunlight guidance, bias-tee control, and an older high-current failure mode. The [V3 datasheet](https://www.rtl-sdr.com/wp-content/uploads/2018/02/RTL-SDR-Blog-V3-Datasheet.pdf) describes the aluminium enclosure as a heatsink. The [rtl_433 starting guide](https://github.com/merbanan/rtl_433/blob/master/docs/STARTING.md) documents the 250000 sample-per-second default at 433.92 MHz and current tuner settings. The [rtl_433 changelog](https://github.com/merbanan/rtl_433/blob/master/CHANGELOG.md) records RTL-SDR bias-tee control as a later addition than the installed build.

## Unresolved questions

- Is the installed receiver a genuine RTL-SDR Blog V3?
- What temperature rise and USB current does the baseline 60-minute run measure?
- Is the bias tee forced on in EEPROM or by the installed driver?
- Do separation and free airflow bring the receiver into the manufacturer's comparison bands?
- Is a fan or replacement receiver needed after passive changes?
