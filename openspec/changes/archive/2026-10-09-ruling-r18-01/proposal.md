## Why

Ash ruled on 8 October 2026 (Midmorning Decisions page, r18-01) that safe mode opens each store file at its own schema version when a migration stopped after one of the two files. Commit 93e2c7e built it. The data-and-privacy text still names one version for the whole store.

## What Changes

- data-and-privacy "Launch safety": safe mode reads the schema version of each store file and opens each file read-only at its own version. A new scenario covers two files at different versions.

## Impact

- Spec text only. The code already does this (mm-ue6).
