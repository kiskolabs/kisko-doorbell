# RFC 0001: kisko-doorbell RFC process

- Type: Procedural
- Status: Stable
- Created: 2026-09-30
- Author: Kisko Labs

## Summary

Significant command-line, RF intake, notification, and persistent-state contracts start as numbered RFCs under `rfcs/`.

## Motivation

kisko-doorbell shipped its operator and notification behavior before it had numbered contracts. RFCs keep later changes reviewable without turning setup notes or source code into the only description of expected behavior.

## Guide-level explanation

Read this file and `rfcs/README.md`. Claim `rfcs/ids/NNNN` with one kebab-case slug before adding `rfcs/NNNN-slug.md`. Copy `rfcs/0000-template.md`, remove unused optional sections, and open a pull request titled `rfc: NNNN short title`. An implementation pull request cites `RFC-NNNN`.

## Reference-level explanation

0001 is this process. 0002 through 0099 record contracts that shipped before the process. 0100 through 0999 hold later proposals.

Isolation is off. RFCs may name repository paths a reviewer can open. The required header fields are Type, Status, Created, and Author. Summary, Motivation, Guide-level explanation, and Unresolved questions are required sections. Product RFCs also define the reference contract, drawbacks, rationale and alternatives, and prior art.

Types are Standards Track, Informational, Historical, and Procedural. Statuses are Draft, Experimental, Proposed, Stable, Final, Deferred, Rejected, Superseded, and Obsolete. Already-shipped behavior is Stable when an RFC specifies it.

An RFC number remains claimed even when its document is rejected or retired. Two pull requests that claim the same `ids/NNNN` path conflict in git; the later author takes another free number.

The repository does not add RFC-only tests. RFC review compares the implementation and available executable specs with the stated contract. An implementation that changes a contract must add or update specs for that behavior.

## Drawbacks

Authors pay a numbering and review cost before changing a contract. A bug fix that restores specified behavior does not require another RFC.

## Rationale and alternatives

The README teaches installation and daily use, but it does not provide stable numbers for contract decisions. Source-only documentation makes reviewers infer intended behavior from implementation details.

## Prior art

amkisko/rfc-process 1.2.0 and the RFC trees in other Kisko repositories.

## Unresolved questions

Later procedural RFCs may divide the proposal band if this small tree grows enough to need separate command-line and notification ranges.
