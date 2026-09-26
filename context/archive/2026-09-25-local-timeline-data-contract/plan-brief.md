# Local timeline data contract — Plan Brief

> Full plan: `context/changes/local-timeline-data-contract/plan.md`

## What & Why

This plan establishes the first durable local data layer for Timelines: named
timelines, entries with creation time and description, and one optional local
photo per entry. It unblocks the readable timeline slices without introducing a
backend, synchronization or cloud photo storage.

## Starting Point

The Flutter app currently has Google/mock authentication and a private placeholder
shell, but no data models, database, file store or repository. The auth session has
a stable Google ID, but the first data phase intentionally treats the installation
as one local data space rather than assigning records to an account.

## Desired End State

Drift-backed SQLite stores two tables: `timelines` and `entries`. Entries reference
their timeline, contain a creation timestamp and description, and may reference
one photo copied into the app's private data directory. A repository hides Drift
and file-system details from future UI code, and data survives sign-out.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Database | Drift + SQLite | Typed relational storage and explicit migrations fit the timeline-entry relationship. |
| Schema | `timelines` + `entries` | The minimal two-table model covers the first local flow without future-feature fields. |
| Entry time | Creation timestamp only | The first version needs ordering and day grouping without user-editable historical dates. |
| Photos | Zero or one per entry, copied privately | App-controlled files are more reliable than external gallery paths and avoid BLOB growth. |
| Ownership | No account/provider column | This phase is explicitly device-local; Google login does not partition local data. |
| Sign-out | Preserve local data | Sign-out disconnects auth only; it does not delete the device journal. |
| Synchronization | None | The MVP and infrastructure decision keep data local and offline. |

## Scope

**In scope:**

- Drift dependencies, generated database code and schema version 1.
- Timeline/entry data values and repository CRUD contract.
- Private photo copying, relative path references and lifecycle cleanup.
- In-memory tests, auth sign-out regression coverage and Android build verification.
- Documentation of device-local retention and data-loss limitations.

**Out of scope:**

- Timeline UI, navigation, camera/gallery picker and user-facing CRUD screens.
- Per-account data isolation, cloud sync, backup, backend or Firebase.
- Multiple photos, AI metadata, sharing and collaboration.

## Architecture / Approach

Future UI code calls an app-owned timeline repository. The repository maps values to
Drift's SQLite database and coordinates the database rows with an injected private
photo store. Auth remains a shell gate only; it does not provide the local store's
owner key and is not connected to destructive cleanup.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Drift database and schema | Dependencies, generated code and versioned two-table SQLite schema | Generator/configuration or foreign-key mistakes block all later work. |
| 2. Timeline repository and photo files | Provider-independent CRUD contract and reliable private photo lifecycle | Database/file failure ordering could leave orphaned records or files. |
| 3. Integration and verification | Auth retention policy, documentation and full automated/build checks | Existing F-01 cleanup expectations must not delete device-local data. |

**Prerequisites:** Flutter/Android tooling; no Google credentials or backend access.
**Estimated effort:** Approximately 2–3 focused implementation sessions.

## Open Risks & Assumptions

- Local data can be lost when the app is uninstalled or the device is replaced;
  backup is intentionally not part of this change.
- Sharing one local database across authenticated accounts is acceptable only for
  the first single-device MVP and must be revisited before multi-user use.
- Photo imports need a later UI/picker integration; this plan defines the storage
  seam without selecting a camera/gallery package.

## Success Criteria (Summary)

- A typed local repository can create, read, update and delete timelines and entries
  with one optional private photo per entry.
- Data and photos survive process restart and auth sign-out on the same device.
- `flutter analyze`, `flutter test`, Drift generation and the Android debug build
  pass without network, account credentials or storage permissions.
