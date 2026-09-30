# Runtime dependency advisories found by Trunk

## Dependency

`Gemfile.lock` held concurrent-ruby 1.1.7, Faraday 1.0.1, and websocket-driver 0.7.3. They are transitive runtime dependencies used through SuckerPunch and slack-ruby-client.

## Symptom

`trunk check --all` reported nine published advisories, including high-severity findings for concurrent-ruby, Faraday, and websocket-driver. The Trunk workflow could not pass with that lockfile.

## Evidence

OSV Scanner reported GHSA-wv3x-4vxv-whpp, GHSA-h8w8-99g7-qmvj, and GHSA-6wx8-w4f5-wwcr for concurrent-ruby 1.1.7; GHSA-98m9-hrrm-r99r and GHSA-33mh-2634-fwr2 for Faraday 1.0.1; and GHSA-2x63-gw47-w4mm, GHSA-8j3g-f24p-4mpw, GHSA-ghhp-3qvg-889p, and GHSA-33ph-fccm-39pj for websocket-driver 0.7.3.

After the targeted update, `trunk check --all --no-progress` completed with no issues. `bundler-audit check --update` updated ruby-advisory-db to commit cb6460a5876f3bf6ef908718457bfa9dd4ca9c06 and reported no vulnerabilities.

## Suggested fix

Keep concurrent-ruby at 1.3.8 or newer, Faraday at 1.10.6 or a compatible patched major, and websocket-driver at 0.8.2 or newer. The current lockfile also moves slack-ruby-client from 0.15.0 to 0.17.0 within its existing `~> 0.14` manifest constraint.

## Next

Keep OSV Scanner enabled in Trunk and review grouped Bundler updates from Dependabot.

## Source

- https://github.com/advisories/GHSA-wv3x-4vxv-whpp
- https://github.com/advisories/GHSA-h8w8-99g7-qmvj
- https://github.com/advisories/GHSA-6wx8-w4f5-wwcr
- https://github.com/advisories/GHSA-98m9-hrrm-r99r
- https://github.com/advisories/GHSA-33mh-2634-fwr2
- https://github.com/advisories/GHSA-2x63-gw47-w4mm
- https://github.com/advisories/GHSA-8j3g-f24p-4mpw
- https://github.com/advisories/GHSA-ghhp-3qvg-889p
- https://github.com/advisories/GHSA-33ph-fccm-39pj
- `Gemfile.lock`
