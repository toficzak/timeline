# Local timeline data contract Implementation Plan

## Overview

Establish the first durable local data boundary for Timelines. The change adds a
Drift-backed SQLite database with timelines and entries, a private app-owned photo
file store, and a provider-independent repository contract that later timeline UI
features can consume.

The data is intentionally device-local in this phase: Google authentication gates
the app shell, but it does not become an owner key for local records. Signing out
disconnects the session and leaves the device's timelines and photos intact.

## Current State Analysis

- `pubspec.yaml:9-17` has no persistence or filesystem dependency beyond Flutter;
  the only runtime package is `google_sign_in`.
- `lib/main.dart:50-113` exposes only the authenticated placeholder shell; no
  timeline models, storage, repository or UI data flow exists.
- `lib/auth/auth_session.dart:3-8` provides a stable provider ID, but this change
  deliberately does not use it as a local-data owner key.
- `lib/auth/local_data_cleaner.dart:1-10` and the auth repositories provide a
  cleanup seam, but this device-local contract must not attach the timeline store
  to that seam or delete it on sign-out.
- The MVP requires multiple timelines, entries with a description and local photo,
  and offline local storage (`context/foundation/mvp-notes.md:9-28`). Cloud sync,
  cloud photo backup and a backend are explicitly out of scope
  (`context/foundation/prd.md:80-85`, `context/foundation/infrastructure.md:13-25`).
- No existing schema, migration convention or data tests are present.

## Desired End State

The app has a typed local data contract backed by SQLite. A timeline has a local
integer ID and name. An entry belongs to one timeline and has a local integer ID,
creation timestamp, description and an optional reference to one private local
photo. Foreign keys preserve the timeline-entry relationship.

Application code uses a provider-independent repository rather than Drift row
types. Photo imports copy files into an app-controlled directory and persist only
an app-relative path. The database opens from the app support area and has an
explicit schema version ready for future migrations.

The contract can be verified without Google credentials, network access or UI
implementation. The same local records remain available after an auth sign-out
and are visible to any subsequently authenticated account on that device, as
specified for this first local-only phase.

### Key Discoveries:

- Drift 2.35.0 provides typed SQLite tables, transactions, migrations and reactive
  queries; `drift_flutter` 0.3.1 opens a Flutter database in the app support area
  (official docs: `https://drift.simonbinder.eu/setup/`).
- `path_provider` 2.1.6 provides supported Android application directories; photo
  paths should be relative to the controlled photo directory rather than external
  gallery paths (`https://pub.dev/packages/path_provider`).
- The existing auth tests use handwritten fakes and `flutter_test`, so repository
  tests should use in-memory Drift executors and filesystem test doubles rather
  than real Google accounts or device paths.
- The chosen MVP contract is exactly two tables and one photo per entry at most;
  supporting photo galleries, sync metadata or account ownership would be a later
  migration.

## What We're NOT Doing

- No timeline or entry UI, navigation, camera/gallery picker or user-facing CRUD
  screens; those belong to later slices.
- No Google account ownership column, per-account filtering or account migration;
  the database is shared by the installed app on one device.
- No destructive local cleanup on sign-out; records and photo files remain.
- No cloud synchronization, backup, backend API, Firebase or server-side data
  model.
- No AI comparison fields, tags, reminders, sharing, collaboration or multi-photo
  entry model.
- No BLOB storage for photos; the database stores only a relative file reference.

## Implementation Approach

Use a small persistence module with three boundaries:

```text
timeline repository contract -> local timeline repository -> Drift AppDatabase
                                                |
                                                +-> private local photo store
auth gate/session ------------------------------+ (no owner relationship)
```

Drift owns schema, generated row types, foreign keys and migrations. The local
repository maps those rows into app-owned timeline/entry values and coordinates
database changes with photo-file replacement/deletion. The photo store owns the
app-relative path convention. Auth continues to control access to the shell, but
the local repository is not injected as an account cleaner.

## Critical Implementation Details

The database and photo file lifecycle must be coordinated: create or update the
database row only when the referenced photo has been copied successfully, remove
the previous file only after its replacement is durable, and make delete/orphan
cleanup idempotent. Drift's generated file is build output and must be regenerated
with `build_runner`, never hand-edited.

## Phase 1: Drift database and schema

### Overview

Add the persistence dependencies and define the versioned SQLite schema for the
device-local timeline contract. Make the database openable in production code and
replaceable with an in-memory executor in tests.

### Changes Required:

#### 1. Persistence dependencies and generator configuration

**File**: `pubspec.yaml`, `pubspec.lock`

**Intent**: Add the current compatible Drift, Flutter database helper, filesystem
path and code-generation dependencies needed for typed SQLite persistence.

**Contract**: Runtime dependencies include `drift`, `drift_flutter` and
`path_provider`; development dependencies include `drift_dev` and `build_runner`.
The lockfile is generated by `flutter pub get`; no hand-edits are made to it.

#### 2. Database schema and connection

**Files**: `lib/data/app_database.dart`, generated `lib/data/app_database.g.dart`

**Intent**: Define the minimal relational schema and a named on-device database
that later repositories can use.

**Contract**:

- `Timelines` has an auto-incrementing integer `id` and required `name`.
- `Entries` has an auto-incrementing integer `id`, required `timelineId` foreign
  key to `Timelines` with cascade semantics, required `createdAt`, required
  `description` (empty text is allowed), and nullable `photoPath`.
- Schema version is `1`; the connection uses the app support directory and has a
  constructor accepting an injected `QueryExecutor` for tests.
- Generated code is produced by `dart run build_runner build
  --delete-conflicting-outputs` and is kept consistent with the source schema.

### Success Criteria:

#### Automated Verification:

- `flutter pub get` resolves Drift and generator dependencies.
- `dart run build_runner build --delete-conflicting-outputs` completes and produces
  the database companion code.
- `flutter analyze` passes with the database source and generated code.
- A schema smoke test opens an in-memory database, creates a timeline and entry,
  and verifies the foreign-key relationship and stored creation timestamp.

#### Manual Verification:

- A debug Android build launches with the new database dependency and creates its
  database under the app-controlled support/data area without requesting network
  or storage permissions.

**Implementation Note**: After automated verification passes, pause for human
confirmation that the schema and local-only boundary are correct before proceeding.

---

## Phase 2: Timeline repository and photo files

### Overview

Expose a stable app-owned data contract and implement local CRUD for timelines and
entries, including the one-photo-per-entry file lifecycle. Keep Drift-generated
types and filesystem details behind the repository boundary.

### Changes Required:

#### 1. Domain values and repository contract

**Files**: `lib/timeline/timeline.dart`, `lib/timeline/timeline_repository.dart`

**Intent**: Define the provider-independent values and operations that S-01/S-02
can consume without depending on SQLite or file paths.

**Contract**: Expose immutable timeline and entry values with local IDs; entries
carry `createdAt`, `description` and nullable photo reference. Repository
operations support creating, listing, updating and deleting timelines, plus
creating, listing, updating and deleting entries under a timeline. Entry creation
uses the current time for `createdAt`; the first contract does not accept a
user-supplied historical date. Invalid or missing timeline references produce a
typed repository failure rather than silently creating orphan entries.

#### 2. Local photo store

**File**: `lib/timeline/local_photo_store.dart`

**Intent**: Own copying and deletion of entry photos inside an app-controlled
directory while keeping database values portable.

**Contract**: Importing a source file copies it below a private application data
directory and returns an app-relative path. The store can delete a path
idempotently, rejects paths that escape its root, and does not expose absolute
device paths through the repository contract. It must be injectable so tests do
not depend on platform channels or a real device directory.

#### 3. Local repository and lifecycle coordination

**File**: `lib/timeline/local_timeline_repository.dart`

**Intent**: Map app-owned operations to Drift and coordinate record changes with
photo copies, replacements and removals.

**Contract**: The repository uses one `AppDatabase` and one `LocalPhotoStore`.
Creating an entry with a photo stores the row's relative path only after a copy
has succeeded; replacing an image does not delete the old file until the new
reference is durable. Deleting an entry removes its database row and associated
file, while repeated cleanup is safe. Deleting a timeline removes its entries and
their photo files through the repository boundary. The repository is device-local
and is never passed to `LocalDataCleaner`.

### Success Criteria:

#### Automated Verification:

- Repository tests cover timeline CRUD and entry CRUD using an in-memory Drift
  database.
- Repository tests verify one-entry-to-one-optional-photo behavior, relative path
  storage, replacement cleanup, deletion cleanup and failure cleanup after a copy
  error.
- Tests verify entries cannot be read or created under a missing timeline and that
  deleting a timeline leaves no child entries.
- `flutter analyze` passes with the repository and photo-store contracts.

#### Manual Verification:

- A developer can exercise the repository against a debug database, restart the
  app process, and observe that timeline and entry records remain available while
  the stored photo remains in the app-controlled directory.

**Implementation Note**: After automated verification passes, pause for human
confirmation that the two-table contract and photo retention behavior match the
intended local MVP before proceeding.

---

## Phase 3: Integration and verification

### Overview

Make the local-only policy explicit at the auth boundary, add regression coverage
for persistence across sign-out, document the contract for the next timeline
features and run the complete repository verification path.

### Changes Required:

#### 1. Auth boundary integration

**Files**: `lib/auth/auth_factory.dart`, `lib/auth/google_auth_repository.dart`,
`lib/auth/mock_auth_repository.dart`, `lib/auth/local_data_cleaner.dart` and
affected auth tests

**Intent**: Preserve the existing Google/mock session gate while ensuring neither
auth implementation treats the device-local timeline database as account-owned
data or deletes it during sign-out.

**Contract**: The timeline repository is not supplied as a
`LocalDataCleaner`. Sign-out clears the active auth session but leaves the local
database and photo directory untouched. Existing cleanup seams may remain as
no-op/compatibility seams for future account-scoped stores, but this change must
not connect them to the device-local timeline repository. Tests update the old
clear-on-logout expectation to assert local data survives auth disconnect.

#### 2. Contract documentation and test fixtures

**Files**: `docs/local-timeline-data-contract.md`, `test/data/`,
`test/timeline/` and any focused auth regression tests

**Intent**: Document the schema, local file policy, data retention after sign-out,
known data-loss-on-uninstall limitation and the seams used by later UI work.

**Contract**: Documentation states that records are device-local, shared across
authenticated accounts on that installation, not synchronized or backed up by
the app, and represented by two tables with at most one photo per entry. Test
fixtures use in-memory databases and fake photo stores; no credentials, network,
platform gallery or real user files are required.

#### 3. Generated integration and repository checks

**Files**: generated plugin/dependency outputs as produced by Flutter, if changed

**Intent**: Confirm that the persistence dependencies work with the Android target
and that generated artifacts are reproducible from source configuration.

**Contract**: No generated Dart or Android file is hand-edited. The repository
must pass its normal analyzer, tests and debug Android build after generation.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes.
- `flutter test` passes with database, repository, photo-store and auth regression
  tests.
- `dart run build_runner build --delete-conflicting-outputs` is reproducible with
  no uncommitted generated drift afterward.
- `flutter build apk --debug` completes with the existing final Android
  application ID.
- A persistence regression test proves that signing out does not delete or hide
  the device-local timeline data from the repository.

#### Manual Verification:

- In documented mock mode, a developer can authenticate, create/read local data
  through the repository verification path, sign out, authenticate again and
  confirm that the same device-local data remains.
- The documentation accurately communicates that uninstalling or replacing the
  device can lose local records and photos.

**Implementation Note**: This phase is complete only after human confirmation
that the local-only retention policy is intentional; Google account ownership and
cloud synchronization remain later decisions.

---

## Testing Strategy

### Unit Tests:

- Test schema creation, foreign keys, required fields and schema version behavior
  with an in-memory Drift executor.
- Test repository CRUD, ordering by `createdAt`, invalid timeline references and
  cascade deletion.
- Test photo import, relative-path validation, replacement, deletion and cleanup
  after failed persistence operations with a fake photo store.
- Test auth sign-out regression so the local repository/data remains intact and no
  provider ID is introduced into the local schema.

### Integration Tests:

- Run the repository against the real Drift native executor in a debug Android
  build to verify app support directory placement and SQLite initialization.
- Keep Google provider interaction out of persistence tests; existing auth fakes
  remain sufficient for the gate.

### Manual Testing Steps:

1. Run the documented mock-auth command and open the app on Android.
2. Use the repository verification path to create one timeline and one entry with
   a local photo.
3. Restart the app process and verify the record and photo remain available.
4. Sign out and sign in again, then verify the same device-local data remains.
5. Confirm no network or storage permission is required for the local contract.

## Performance Considerations

The MVP scale is small, so ordinary indexed SQLite queries are sufficient. Add an
index for `Entries.timelineId` and `Entries.createdAt`, avoid loading photo bytes
through SQLite, and keep photo files outside the database. No background sync or
polling is introduced.

## Migration Notes

The initial schema is version 1 and there is no existing timeline data to migrate.
Future schema changes must increment the Drift schema version and include an
explicit migration; future account ownership or synchronization must be a separate
decision and migration rather than being inferred from the current local schema.

## References

- `context/foundation/roadmap.md:85-97`
- `context/foundation/prd.md:51-68,76-85`
- `context/foundation/mvp-notes.md:9-28`
- `context/foundation/infrastructure.md:13-25,31-33,48-54`
- `lib/auth/auth_session.dart:3-8`
- `lib/auth/local_data_cleaner.dart:1-10`
- `lib/auth/google_auth_repository.dart:78-90`
- `lib/main.dart:50-113`
- Drift setup: `https://drift.simonbinder.eu/setup/`
- Drift package: `https://pub.dev/packages/drift`
- Drift Flutter package: `https://pub.dev/packages/drift_flutter`
- Path provider: `https://pub.dev/packages/path_provider`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Drift database and schema

#### Automated

- [x] 1.1 `flutter pub get` resolves Drift and generator dependencies.
- [x] 1.2 `dart run build_runner build --delete-conflicting-outputs` completes and produces the database companion code.
- [x] 1.3 `flutter analyze` passes with the database source and generated code.
- [x] 1.4 A schema smoke test opens an in-memory database and verifies the foreign-key relationship and stored creation timestamp.

#### Manual

- [x] 1.5 A debug Android build launches with the database dependency and creates its database under the app-controlled support/data area without network or storage permissions.

### Phase 2: Timeline repository and photo files

#### Automated

- [ ] 2.1 Repository tests cover timeline and entry CRUD using an in-memory Drift database.
- [ ] 2.2 Repository tests verify optional single-photo behavior, relative path storage, replacement cleanup, deletion cleanup and copy-error cleanup.
- [ ] 2.3 Tests verify missing timeline references are rejected and deleting a timeline leaves no child entries.
- [ ] 2.4 `flutter analyze` passes with the repository and photo-store contracts.

#### Manual

- [ ] 2.5 A debug repository verification confirms records and a stored photo remain after restarting the app process.

### Phase 3: Integration and verification

#### Automated

- [ ] 3.1 Auth integration leaves the device-local database and photo directory intact after sign-out, covered by regression tests.
- [ ] 3.2 `flutter analyze` passes.
- [ ] 3.3 `flutter test` passes with database, repository, photo-store and auth regression tests.
- [ ] 3.4 `dart run build_runner build --delete-conflicting-outputs` is reproducible with no generated drift.
- [ ] 3.5 `flutter build apk --debug` completes with the final Android application ID.

#### Manual

- [ ] 3.6 Mock-auth sign-out/sign-in confirms the same device-local data remains available.
- [ ] 3.7 Documentation confirms local data loss on uninstall/device replacement and the absence of sync or account ownership.
