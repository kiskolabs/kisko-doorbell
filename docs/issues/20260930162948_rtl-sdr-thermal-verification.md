# RTL-SDR thermal verification

## Decisions

Keep the receiver continuously available. Do not duty-cycle RF intake because a press during a powered-off interval would be lost.

Measure case temperature, ambient temperature, and actual USB voltage and current before changing RF settings. Change one physical or receiver setting per run and require twenty decoded events from twenty live presses after 60 minutes.

Try separation from Raspberry Pi heat, free airflow, and verification of the unused bias tee before adding a separately powered fan or replacing the receiver.

## Effects

RFC 0101 defines the measurement fields, sequence, reception gate, safety constraints, and cited manufacturer comparison bands. No gain, sample-rate, duty-cycle, or bias-tee command change has been made without measurements from the installed hardware.

The installed rtl_433 build cannot use the newer explicit RTL-SDR bias-tee setting. The current production arguments do not request bias-tee power, but the persistent device and driver state still needs verification.

## Next

- Record the baseline measurements at 0, 5, 15, 30, and 60 minutes.
- Record receiver provenance and whether its bias tee is forced on.
- Separate the dongle from the Pi and repeat the run.
- Add airflow only if passive placement does not resolve excess temperature or current.
- Replace the receiver if abnormal heat, current, or USB disconnections persist.

## Source

- `rfcs/0101-rtl-sdr-thermal-operation.md`
- `rfcs/0100-nexa-rf-event-intake.md`
