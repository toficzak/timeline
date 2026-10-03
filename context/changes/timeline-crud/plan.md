# Timeline CRUD Implementation Plan

## Overview

Add the missing user-facing CRUD actions for timelines while preserving the existing local repository and guest flow. Users will create timelines, rename them, and delete them after confirmation; the list will reload from the repository after each successful mutation.

## Current State Analysis

`TimelineRepository` already exposes all four timeline operations (`lib/timeline/timeline_repository.dart:5-10`), and `LocalTimelineRepository` implements them against the Drift `timelines` table (`lib/timeline/local_timeline_repository.dart:16-54`). Repository tests already cover the happy-path CRUD and deterministic ordering (`test/timeline/local_timeline_repository_test.dart:25-49`).

`TimelineListScreen` currently performs read-only loading, empty, populated, and retryable-error rendering; it explicitly has no create action or navigation (`lib/timeline/timeline_list_screen.dart:6-8,46-86`). There are no existing form, dialog, or row-action patterns elsewhere in the app. The current database schema needs no change (`lib/data/app_database.dart:7-11,27-40`).

## Desired End State

From the shared local timeline list, a guest or signed-in user can create a timeline, edit its name, and delete it. Creation and editing trim the name and reject an empty result; duplicate names are allowed. Each row exposes Edit and Delete through an overflow menu, deletion requires confirmation, and successful mutations are followed by a fresh ordered read.

Operation failures remain in the current list context: create/update preserve the entered form text, delete leaves the row visible, and the user receives a clear error message. Existing read, auth, guest, local-data retention, and entry-storage behavior remains unchanged.

### Key Discoveries:

- The repository contract and local implementation already support timeline CRUD; the missing work is UI orchestration and validation (`lib/timeline/timeline_repository.dart:5-10`, `lib/timeline/local_timeline_repository.dart:16-54`).
- The list is injected through the app-owned repository interface and uses a reloadable `FutureBuilder` pattern (`lib/timeline/timeline_list_screen.dart:16-38`).
- The prior list slice intentionally excluded create, edit, delete, and navigation (`context/changes/signed-in-timeline-list/plan.md:15-34`).
- Local data is installation-scoped and available through guest mode; this slice must not add account ownership or cleanup on sign-out (`context/foundation/prd.md:76-85`).

## What We're NOT Doing

- No CRUD for timeline entries, photo picker, description editor, or entry detail view.
- No navigation into a selected timeline and no change to the S-02 entry-view slice.
- No backend, synchronization, cloud backup, account-owner column, roles, or sharing.
- No duplicate-name restriction, archive/undo model, schema migration, or new database table.
- No change to Google authentication or the existing guest access decision.

## Implementation Approach

Keep `TimelineListScreen` as the feature boundary and extend its existing asynchronous list state with mutation state. Add a shared create/edit form dialog, row overflow actions, and a confirmation dialog for deletion. Put the required-name normalization at the repository boundary so calls outside the UI obey the same invariant; surface the domain failure in the form/list without replacing the current data. After a successful repository mutation, reload through `listTimelines()` rather than maintaining a second in-memory source of truth.

## Critical Implementation Details

### Mutation and list state sequencing

Do not optimistically remove or rename rows. Disable the active mutation controls while the repository call is pending, keep the current list visible, and only start the replacement list read after the mutation succeeds. A failed create/update must leave the dialog open with its trimmed input available for correction or retry; a failed delete must leave the row available.

### Destructive action contract

The delete confirmation must name the selected timeline and explicitly warn that its associated entries are deleted by the existing repository cascade. There is no undo or archive operation in this slice.

## Phase 1: Timeline name contract and repository coverage

### Overview

Make the required-name rule explicit at the data boundary and extend repository tests around CRUD behavior and failure cases.

### Changes Required:

#### 1. Timeline repository validation

**File**: `lib/timeline/timeline_repository.dart`

**Intent**: Add a domain failure for a timeline name that is empty after trimming, so validation is shared by all callers rather than being UI-only.

**Contract**: `createTimeline` and `updateTimeline` accept the existing signatures, normalize leading/trailing whitespace, reject an empty normalized name, and return/store the normalized value. Duplicate normalized names remain valid.

#### 2. Local CRUD implementation

**File**: `lib/timeline/local_timeline_repository.dart`

**Intent**: Apply the name contract before database writes while preserving existing IDs, ordering, not-found failures, cascade behavior, and photo cleanup.

**Contract**: Invalid names produce the new repository failure without changing database rows; valid create/update operations persist the trimmed name and return a model containing that persisted value.

#### 3. Repository tests

**File**: `test/timeline/local_timeline_repository_test.dart`

**Intent**: Protect the new validation and the boundaries around independent timelines and missing IDs.

**Contract**: Tests cover trimmed create/update names, blank and whitespace-only rejection, duplicate-name acceptance, update/delete of a missing timeline, and that CRUD on one timeline does not alter another timeline or its entries.

### Success Criteria:

#### Automated Verification:

- Repository tests prove trimming, required-name rejection, duplicate-name acceptance, and missing-timeline failures.
- Existing entry, photo cleanup, cascade, auth, and local-retention tests continue to pass.

#### Manual Verification:

- No manual verification is requested for this phase; the repository contract is fully executable through automated tests.

---

## Phase 2: Create and edit form

### Overview

Add a reusable timeline name form for creating and renaming timelines, including validation, pending state, cancellation, and operation errors.

### Changes Required:

#### 1. Timeline name form UI

**File**: `lib/timeline/timeline_name_dialog.dart` (new)

**Intent**: Encapsulate the shared create/edit form so both operations use the same label, validation, focus, and error behavior.

**Contract**: Accept optional initial timeline data and an operation callback; trim before submission, reject an empty value inline, disable submission while pending, return the saved `Timeline` on success, and keep the dialog open with entered text plus an actionable error on failure.

#### 2. Create and edit integration

**File**: `lib/timeline/timeline_list_screen.dart`

**Intent**: Add a clearly discoverable Create action and connect each row’s Edit action to the shared form without introducing timeline navigation.

**Contract**: Create is available for an empty and populated list; edit opens with the current name; cancel leaves storage and visible list unchanged; successful create/update closes the dialog and triggers a fresh list read.

#### 3. Widget fakes and form tests

**File**: `test/timeline/timeline_list_test.dart`

**Intent**: Extend the handwritten repository fake and widget coverage to exercise form state without credentials, platform storage, or a real database.

**Contract**: Tests cover opening create/edit, inline blank validation, successful create/update, cancellation, pending disabled controls, repository errors with preserved input, and refreshed list content.

### Success Criteria:

#### Automated Verification:

- Widget tests cover create and edit dialogs, validation, cancellation, pending state, operation errors, and successful list refresh.
- Existing loading, empty, populated, retry, signed-in, and guest list tests remain passing.

#### Manual Verification:

- A human can create a timeline from both an empty and populated list, rename it, cancel either form, and see the result without leaving the list.
- A failed save keeps the form open and retains the typed name rather than silently discarding it.

---

## Phase 3: Row actions and confirmed deletion

### Overview

Add the per-row overflow menu and destructive-action confirmation, then connect deletion to the same repository/reload/error lifecycle.

### Changes Required:

#### 1. Timeline row actions

**File**: `lib/timeline/timeline_list_screen.dart`

**Intent**: Expose Edit and Delete from an overflow menu so rows remain readable and are not confused with navigation targets.

**Contract**: Each row identifies its timeline and offers Edit and Delete; the menu action must not open a detail screen. Delete opens a confirmation dialog naming the timeline and warning about child entries.

#### 2. Delete lifecycle and tests

**File**: `lib/timeline/timeline_list_screen.dart`

**Intent**: Execute deletion only after confirmation, prevent duplicate submissions, report failures in the list context, and reload after success.

**Contract**: Cancel leaves the row untouched; confirmed success removes it after the fresh repository read; failure leaves it visible and displays an actionable error. The UI does not add undo or archive semantics.

**File**: `test/timeline/timeline_list_test.dart`

**Intent**: Verify the complete row-action and deletion interaction contract.

**Contract**: Tests cover menu discoverability, confirmation copy, cancel, successful delete, pending controls, repository failure, and preservation of unrelated rows.

### Success Criteria:

#### Automated Verification:

- Widget tests prove delete is not executed before confirmation and that cancel, success, failure, and pending states behave as specified.
- Tests prove the list is re-read after every successful mutation and retains deterministic ordering.

#### Manual Verification:

- A human can distinguish Edit from Delete, cancel a delete safely, and see the warning that associated entries are removed.
- A confirmed delete removes only the selected timeline; a failed delete leaves it visible with an error message.

---

## Phase 4: Integration, regression, and Android delivery

### Overview

Run the complete automated suite and verify the CRUD flow on the target Android path without expanding product scope.

### Changes Required:

#### 1. Regression and verification record

**File**: `context/changes/timeline-crud/verification.md` (new during implementation)

**Intent**: Record reproducible checks for local CRUD, guest/signed-in presentation, error handling, and Android delivery.

**Contract**: The record names the commands run, their results, and the manual scenarios completed; it must not claim Google credentials or device verification that was not available.

#### 2. App-level regression coverage

**File**: `test/timeline/timeline_list_test.dart`, `test/auth/auth_gate_test.dart`

**Intent**: Ensure the new actions do not alter guest entry, signed-in presentation, sign-out, or local-data retention behavior.

**Contract**: Both access modes expose the same local CRUD capability; sign-out still changes authentication state only and does not delete local timelines.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes.
- `flutter test` passes, including repository, list widget, auth, retention, and database tests.
- `flutter build apk --debug` completes successfully.

#### Manual Verification:

- On Android or an emulator, guest mode can create, rename, and delete a local timeline, including canceling a delete.
- The same local CRUD flow is available after mock or configured Google sign-in; signing out preserves local timelines for guest re-entry.

---

## Testing Strategy

### Unit Tests:

- Validate normalization and required-name failures at the repository boundary.
- Verify timeline CRUD, missing IDs, duplicate names, ordering, isolation between timelines, and preservation of existing entry/photo cascade behavior.

### Integration Tests:

- Exercise the list screen with a handwritten repository fake for create, edit, delete, reload, errors, cancellation, and pending states.
- Exercise `AuthGate` in guest and signed-in modes to ensure the shared repository capability and sign-out retention remain intact.

### Manual Testing Steps:

1. Start with an empty local store and create a timeline with surrounding whitespace; verify the displayed/stored name is trimmed.
2. Try an empty and whitespace-only name in create and edit; verify inline validation prevents submission.
3. Create two timelines, rename one, and confirm the other is unchanged.
4. Open Delete, cancel it, then confirm it and verify the warning and removal.
5. Force or simulate create/update/delete failures and verify the form/list retains usable state.
6. Repeat the smoke flow as signed-in and guest, sign out, re-enter as guest, and verify local rows remain.

## Performance Considerations

The MVP targets a small local dataset. A single list query after each mutation is sufficient; no cache, pagination, reactive Drift stream, debounce, or backend is needed.

## Migration Notes

No schema migration is required. Existing timeline names remain valid unless they are edited; no data is renamed or deduplicated automatically. The installation-local/shared-across-accounts behavior is preserved.

## References

- `context/foundation/prd.md:43-64,76-85`
- `context/foundation/mvp-notes.md:9-28`
- `context/foundation/roadmap.md:40-47,113-154`
- `context/changes/signed-in-timeline-list/plan.md:15-34,87-123`
- `lib/timeline/timeline_repository.dart:5-47`
- `lib/timeline/local_timeline_repository.dart:16-54`
- `lib/timeline/timeline_list_screen.dart:6-86`
- `test/timeline/local_timeline_repository_test.dart:25-49`
- `test/timeline/timeline_list_test.dart:76-217`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append — <commit sha> when a step lands. Do not rename step titles.

### Phase 1: Timeline name contract and repository coverage

#### Automated

- [x] 1.1 Repository tests prove trimming, required-name rejection, duplicate-name acceptance, and missing-timeline failures. — bb0260a
- [x] 1.2 Existing entry, photo cleanup, cascade, auth, and local-retention tests continue to pass. — bb0260a

#### Manual

- [x] 1.3 No manual verification is requested for this phase; the repository contract is fully executable through automated tests. — bb0260a

### Phase 2: Create and edit form

#### Automated

- [x] 2.1 Widget tests cover create and edit dialogs, validation, cancellation, pending state, operation errors, and successful list refresh. — f24e06c
- [x] 2.2 Existing loading, empty, populated, retry, signed-in, and guest list tests remain passing. — f24e06c

#### Manual

- [x] 2.3 A human can create a timeline from both an empty and populated list, rename it, cancel either form, and see the result without leaving the list. — f24e06c
- [x] 2.4 A failed save keeps the form open and retains the typed name rather than silently discarding it. — f24e06c

### Phase 3: Row actions and confirmed deletion

#### Automated

- [x] 3.1 Widget tests prove delete is not executed before confirmation and that cancel, success, failure, and pending states behave as specified.
- [x] 3.2 Tests prove the list is re-read after every successful mutation and retains deterministic ordering.

#### Manual

- [x] 3.3 A human can distinguish Edit from Delete, cancel a delete safely, and see the warning that associated entries are removed.
- [x] 3.4 A confirmed delete removes only the selected timeline; a failed delete leaves it visible with an error message.

### Phase 4: Integration, regression, and Android delivery

#### Automated

- [ ] 4.1 `flutter analyze` passes.
- [ ] 4.2 `flutter test` passes, including repository, list widget, auth, retention, and database tests.
- [ ] 4.3 `flutter build apk --debug` completes successfully.

#### Manual

- [ ] 4.4 On Android or an emulator, guest mode can create, rename, and delete a local timeline, including canceling a delete.
- [ ] 4.5 The same local CRUD flow is available after mock or configured Google sign-in; signing out preserves local timelines for guest re-entry.
