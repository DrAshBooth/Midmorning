# Design

See `openspec/changes/v1-programme/design.md`, "The programme engine is a
pure function with stored openings as input" and "Pure seams the packages
expose". This change makes no design decision `v1-programme` does not
already state; its own narrower choices are in `proposal.md`, "Decisions
this change makes".

## Why the engine resolves all seven stages in one call

Stage 3's fallback counts from the record day stage 2 opened; stage 4's
fallback counts from the record day stage 3 opened; stages 5 and 7 count
weeks from the record day stage 2 opened. Each later stage's gate needs an
earlier stage's resolved opening day, stored or computed, so `Programme.state`
resolves stage 1 through 7 in order inside one function and returns the
whole `ProgrammeState`, rather than seven separate entry points that would
each need the others' results passed back in.

## Why a day key is a plain, comparable string

A record-day key ("2026-09-24") never carries a time zone; `RecordDay` in
`Record` already fixes it at save from the entry's own offset. Because the
format is a zero-padded ISO date, two keys compare correctly with plain
string comparison, so most of the engine's counting (recorded days, planned
days, weeks) never touches `Calendar` at all. Only two operations need it:
adding whole days to a key, and finding the wall-clock moment a key's day
starts or ends, both in `DayKeyMath.swift`.
