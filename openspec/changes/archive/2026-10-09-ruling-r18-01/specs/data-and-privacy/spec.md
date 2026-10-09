## MODIFIED Requirements

### Requirement: Launch safety

The app MUST write a launch marker file at start. The marker MUST hold the count of launches in a row that ended before the app cleared the marker. On a launch that is not in safe mode, the app MUST clear the marker after Today appears. The marker MUST live outside the store directory. When two or more launches in a row end before the app clears the marker, the app MUST enter safe mode at the next launch. So safe mode starts at the third launch. Safe mode continues at each later launch until Today appears in safe mode. Ash set this threshold on 26 September 2026. The app MUST choose safe mode from the count in the launch marker before it opens the store.

In safe mode the app MUST skip the Erasure read, the import, the Reconciler and the scheduler. In safe mode the app MUST open `Record.store` and `Local.store` read-only. In safe mode the app MUST NOT write to either store. This rule does not stop Delete-all or "Delete from this device". Both delete the store directory, and offline Delete-all then keeps its instruction in a new `Local.store`. In safe mode the app MUST NOT let a schema migration write to the store. Ash ruled on 26 September 2026 that safe mode reads the record for Export and writes nothing. When the read-only open succeeds, the app MUST show Today with Export and Get support.

The app MUST add one to the launch failure count in `Local.store` each time it finds an uncleared marker. In safe mode the app MUST keep that failure in the launch marker instead. When Today appears in safe mode, the app MUST clear the count of launches in the marker and keep that failure. The next launch that opens the store for writing MUST add each kept failure to the count in `Local.store`. In safe mode the app MUST also keep each MetricKit crash count in the launch marker, not in `Local.store`. The next launch that opens the store for writing MUST add each kept crash to the crash count in `Local.store`.

When the container throws for any reason other than unavailable protected data, the app MUST show one page. The page MUST read "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything". "Try again" MUST open the container again. "Delete everything" MUST open the Delete-all confirmation. The app MUST NOT delete the store without the person's confirmation.

In safe mode the app MUST open the store at the schema version that the store holds. A store that needs a schema migration cannot open read-only with the current schema version. So in safe mode the app MUST first read the schema version that the metadata of each store file names. `Record.store` and `Local.store` migrate one at a time, so the two files can hold different versions after a launch that stopped between them. The app MUST then open each file read-only with the `VersionedSchema` of its own version from `RecordMigrationPlan.schemas`, and with no migration plan. No migration step runs, and no store file changes. When that open succeeds, the app shows Today with Export and Get support, as above. Today then appears in safe mode, so the next launch is not in safe mode. That launch MUST run the migration. When no `VersionedSchema` in the app agrees with the metadata of a file, the open throws, and the app MUST show the page above. The app holds one schema version now, `RecordSchemaV1`. So a test MUST prove this rule with a second schema version that only the test holds. Ash ruled this on 7 October 2026 (r15-01) and, for two files at different versions, on 8 October 2026 (r18-01).

#### Scenario: Third launch with an uncleared marker
- **WHEN** the app ends before Today appears on two launches in a row and the person opens it a third time
- **THEN** the app shows Today with Export and Get support, imports nothing and schedules nothing

#### Scenario: One uncleared marker
- **WHEN** the app ends before Today appears on one launch and the person opens it again
- **THEN** the app does not enter safe mode

#### Scenario: Safe mode reads only
- **WHEN** the app enters safe mode and the person makes an export
- **THEN** the PDF holds the record, and `Record.store` and `Local.store` hold no new or changed row

#### Scenario: Safe mode with a pending migration
- **WHEN** the store is at an earlier schema version than the app and the app enters safe mode
- **THEN** the app opens the store read-only with the store's own schema version and no migration plan, shows Today with Export and Get support, and the store files are unchanged

#### Scenario: Export from a store that needs a migration
- **WHEN** the store is at an earlier schema version than the app, the app enters safe mode and the person makes an export
- **THEN** the PDF holds the record, and no store file changes

#### Scenario: Migration after safe mode
- **WHEN** Today appears in safe mode with a store at an earlier schema version, and the person opens the app again
- **THEN** that launch is not in safe mode, the app runs the migration, and Today shows every entry

#### Scenario: Store at an unknown schema version
- **WHEN** the store's metadata names a schema version that the app does not hold and the app enters safe mode
- **THEN** the open throws, the store files are unchanged, and the app shows "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything"

#### Scenario: Safe mode continues
- **WHEN** the app enters safe mode, ends before Today appears, and the person opens it again
- **THEN** the app enters safe mode again

#### Scenario: Marker cleared
- **WHEN** Today appears on a launch that is not in safe mode
- **THEN** the app clears the marker, and the next launch runs the Erasure read, the import, the Reconciler and the scheduler

#### Scenario: Launch failures counted
- **WHEN** the app finds an uncleared marker at a launch that does not enter safe mode
- **THEN** the launch failure count in `Local.store` rises by one and the Diagnostics page shows the new count

#### Scenario: Launch failure in safe mode
- **WHEN** the app enters safe mode, Today appears, and the person opens the app again
- **THEN** the safe mode launch writes nothing to `Local.store`, the launch marker keeps its failure, and the next launch adds that failure to the launch failure count in `Local.store`

#### Scenario: Crash count in safe mode
- **WHEN** MetricKit delivers a crash diagnostic at a launch in safe mode
- **THEN** the launch marker keeps the crash, `Local.store` does not change, and the next launch that opens the store for writing adds one to the crash count in `Local.store`

#### Scenario: Store fails to open
- **WHEN** the container throws an error that is not about protected data
- **THEN** the app shows "Midmorning cannot open your record on this device." with Get support, "Try again" and "Delete everything", and the store files are unchanged

#### Scenario: Try again
- **WHEN** the person taps "Try again" and the container opens
- **THEN** the app shows Today

#### Scenario: A migration that stopped after one file
- **WHEN** a launch stopped after the migration of one store file, so `Record.store` and `Local.store` hold different schema versions, and the app enters safe mode
- **THEN** the app opens each file read-only at its own version, Today shows with Export, and no store file changes
