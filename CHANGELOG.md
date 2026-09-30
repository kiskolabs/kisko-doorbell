# CHANGELOG

## 0.5.1 (2026-09-30)

- Receive Nexa doorbell events at 433.92 MHz with the bundled replay signal.
- Notify Slack only for `ON` events from the configured transmitter.
- Read the Slack token from a restricted file instead of exposing it in process arguments.
- Add an operating procedure for measuring RTL-SDR temperature and current before applying cooling changes.
- Release tagged builds to the Raspberry Pi with resumable checks and a required live doorbell confirmation.
