# Open and Readable Timeline Implementation Plan

## Overview

Extend the local timeline list so a user can open a selected timeline, read its entries grouped by local calendar day, and add a text-only entry. This implements S-02 while preserving the repository/data contract from F-02 and leaving photo media to S-03.

## Current State Analysis

`TimelineListScreen` loads and displays timeline names but intentionally renders non-interactive `ListTile`s (`lib/timeline/timeline_list_screen.dart:77-86`). `_PrivateShell` embeds that screen for both signed-in and guest access (`lib/main.dart:155-204`). There is no Navigator route or detail screen.

The app-owned `TimelineRepository` already exposes `listEntries(timelineId)` and `createEntry` (`lib/timeline/timeline_repository.dart:5-22`). `LocalTimelineRepository` validates the timeline, orders entries by ascending UTC `createdAt`, and maps rows to `TimelineEntry` values (`lib/timeline/local_timeline_repository.dart:57-96`). Entries have an optional `photoPath`, but photo selection and rendering are explicitly deferred to S-03.

Existing widget tests use injected handwritten repository fakes, and auth tests exercise the shared list shell (`test/timeline/timeline_list_test.dart:14-54`, `test/auth/auth_gate_test.dart:37-80`). No database migration or seed path is required; fixed historical dates will be used only in tests to prove day grouping.

## Desired End State

After this change, tapping a timeline opens a detail page with the timeline name, an AppBar back action, and an asynchronously loaded entry list. Entries are shown oldest-first under headings derived from their local calendar day; the page distinguishes loading, no entries, read failure with retry, and successful content.

The page always exposes a FAB for adding an entry. The form accepts an optional description, creates through `TimelineRepository.createEntry`, preserves entered text if saving fails, and returns to the refreshed detail page after success. Signed-in and guest access both use the same navigation and repository path.

### Key Discoveries:

- The existing repository API already supports all required read/create operations; no new storage API is required (`lib/timeline/timeline_repository.dart:11-16`).
- Local entries are already ordered by `createdAt`, so presentation can preserve that order while adding local-day sections (`lib/timeline/local_timeline_repository.dart:89-96`).
- The data contract keeps local rows across sign-out and intentionally excludes account ownership or cleanup (`docs/local-timeline-data-contract.md:22-29`).
- S-01 deliberately deferred opening rows to S-02 (`context/changes/signed-in-timeline-list/plan.md:15-26`).

## What We're NOT Doing

- No photo picker, permissions, photo import, path resolution, or image rendering; those remain S-03.
- No timeline creation, rename, deletion, entry editing, or entry deletion UI.
- No production seed/debug data path or API for supplying historical entry dates.
- No schema migration, backend, synchronization, account-specific filtering, or auth contract changes.
- No global state manager; detail loading and form state remain local to the relevant screens.

## Implementation Approach

Add a focused `TimelineDetailScreen` that receives a `TimelineRepository` and selected `Timeline`, loads entries, derives local-day groups, and owns retry/error state. Extend `TimelineListScreen` with an optional item-tap callback; `_PrivateShell` supplies a callback that pushes the detail page using a `MaterialPageRoute`. Keep list state outside the detail route so AppBar back returns to the existing list.

Add a small entry form reachable from a detail-page FAB. The form accepts an optional description, calls `createEntry`, reports save failures without clearing the controller, and lets the detail screen reload after success. Tests use repository fakes with fixed `DateTime` values spanning local days; production persistence remains unchanged.

## Critical Implementation Details

### User experience spec

Use `createdAt.toLocal()` for the displayed calendar day, but retain repository order oldest-first. The empty detail state must still show the add FAB, and a successful save must return to the detail list rather than leaving the user on a stale form.

### State sequencing

A failed save must leave the form route and its text controller intact so retry does not lose input. Only a successful repository result should pop the form and trigger a fresh `listEntries` read; a read failure remains inside the detail page and must not sign the user out.

## Phase 1: Entry detail presentation

### Overview

Create the read-only detail screen and its deterministic state presentation before wiring navigation or creation.

### Changes Required:

#### 1. Timeline detail screen

**File**: `lib/timeline/timeline_detail_screen.dart` (new)

**Intent**: Encapsulate loading and presenting entries for one selected timeline, including local-day headings and loading, empty, populated, error, and retry states.

**Contract**: Accept a `TimelineRepository` and `Timeline`; call `listEntries(timeline.id)`; preserve ascending entry order; group by `entry.createdAt.toLocal()` calendar date; show entry descriptions without photo UI; expose a retry action after read failure. The screen must be usable with an empty entry list.

#### 2. Detail presentation tests

**File**: `test/timeline/timeline_detail_test.dart` (new)

**Intent**: Verify the detail screen independently from authentication, platform storage, and real database state.

**Contract**: Use a handwritten fake repository with fixed entries from at least two local days. Assert loading, headings, descriptions, empty state, read error, retry, and ascending order; assert no photo picker or timeline-creation action is introduced.

### Success Criteria:

#### Automated Verification:

- Detail widget tests pass for loading, populated multi-day, empty, read-error, retry, and ascending-order states.
- `flutter analyze` passes after adding the detail screen and tests.

#### Manual Verification:

- Opening a populated detail screen shows readable entries under distinct local-day headings, with the oldest day first.
- An empty timeline clearly says it has no entries and still presents the add-entry action area.

**Implementation Note**: After automated verification, pause for human confirmation of the detail presentation before proceeding.

---

## Phase 2: Navigation and text entry

### Overview

Connect list rows to the detail route and add the optional-description entry form while preserving recovery behavior.

### Changes Required:

#### 1. List-to-detail navigation

**File**: `lib/timeline/timeline_list_screen.dart`

**Intent**: Make each timeline row actionable without coupling the list to authentication or storage details.

**Contract**: Accept an optional `ValueChanged<Timeline>` callback and invoke it for the selected row; existing list tests and empty/error behavior remain valid when no callback is supplied.

#### 2. Shared shell route wiring

**File**: `lib/main.dart`

**Intent**: Push the selected timeline detail page from both signed-in and guest shells using the injected repository.

**Contract**: Use a standard `MaterialPageRoute`; pass the selected timeline and same `TimelineRepository`; preserve auth controls, guest identity behavior, and AppBar back navigation. Do not add account filtering or sign-out side effects.

#### 3. Text entry form

**File**: `lib/timeline/timeline_entry_form.dart` (new) or the detail feature module

**Intent**: Let the user create a local entry with an optional description from the detail-page FAB.

**Contract**: Call `createEntry(timelineId: ..., description: ...)` with no photo; allow an empty description; show loading while saving; on failure display a retryable message while retaining the entered text; on success return a result that causes the detail screen to reload. The form must not introduce a date input or photo picker.

#### 4. Navigation and creation tests

**File**: `test/timeline/timeline_detail_test.dart`, `test/timeline/timeline_list_test.dart`, and `test/auth/auth_gate_test.dart`

**Intent**: Protect row navigation, FAB/form behavior, optional descriptions, save failure retention, and the shared signed-in/guest route.

**Contract**: Fakes must record selected timeline ids, create calls, and list-entry reloads. Tests must verify AppBar back returns to the list, empty timelines can open the form, successful save refreshes content, failed save keeps the form text, and guest/sign-in presentation remains unchanged.

### Success Criteria:

#### Automated Verification:

- Widget tests cover list-row navigation, AppBar back, FAB/form submission with an empty and non-empty description, save failure with retained input, and successful reload.
- Existing auth, timeline-list, repository, and database tests continue to pass.

#### Manual Verification:

- From both guest and signed-in shells, tapping a timeline opens its detail page and system/AppBar back returns to the list.
- The FAB opens the form on an empty and populated timeline; saving an optional-description entry returns to a refreshed detail list.
- A forced save failure leaves the entered description visible and does not sign the user out.

**Implementation Note**: After automated verification, pause for human confirmation of navigation and text-entry behavior before proceeding.

---

## Phase 3: Integration and delivery verification

### Overview

Run the complete regression suite and verify the new flow on the Android target without adding seed data or photo scope.

### Changes Required:

#### 1. Integration coverage and verification record

**File**: `context/changes/open-readable-timeline/verification.md` (new during implementation if the workflow requires a verification log)

**Intent**: Record reproducible automated and emulator checks for opening, reading, creating, retrying, and returning from a timeline.

**Contract**: The record names the commands and mock-auth/emulator conditions used; it must distinguish text-only S-02 verification from photo work deferred to S-03.

### Success Criteria:

#### Automated Verification:

- `flutter test` passes, including auth, database, repository, list, and detail/form widget tests.
- `flutter analyze` passes with no new warnings.
- `flutter build apk --debug` completes successfully.

#### Manual Verification:

- On the Android emulator with mock auth, a user can enter as guest, open a local timeline, see its entries grouped by day, return to the list, and create a text-only entry.
- Signed-in presentation follows the same route and preserves the session email; sign-out still returns to the access choices without deleting local entries.
- Empty, read-error/retry, and save-error/retained-form behavior are distinguishable; no photo UI is presented.

**Implementation Note**: This is the final phase; after manual verification, close the change and record the final verification result.

## Testing Strategy

### Unit Tests:

- Use fixed `TimelineEntry` values spanning local calendar days to verify grouping and chronological order.
- Verify repository calls receive the selected timeline id and optional description.
- Verify read retry, save failure retention, and successful reload transitions.

### Integration Tests:

- Exercise `AuthGate` with signed-in and guest fakes through list → detail → back.
- Run existing in-memory Drift tests unchanged to protect the local contract.

### Manual Testing Steps:

1. Launch with `AUTH_MODE=mock`, enter as guest, and open an existing local timeline.
2. Confirm entries are readable, grouped by local day, oldest-first, and returnable through AppBar/system back.
3. On an empty timeline, open the FAB form, submit both an empty description and a non-empty description, and confirm the detail list refreshes.
4. Force read and save failures using the test/fake path; confirm retry and retained form input without auth changes.
5. Sign in/sign out in mock mode and confirm the same local timeline remains available; confirm no photo picker or photo rendering is part of S-02.

## Performance Considerations

The MVP targets small local data volume. One repository read per detail entry and a standard grouped list are sufficient; no caching, pagination, stream, or database migration is required.

## Migration Notes

No schema migration is required. Existing timelines with no entries render the empty state, and existing entries are grouped at presentation time using their stored timestamps.

## References

- `context/foundation/roadmap.md:36-47,128-140`
- `context/foundation/prd.md:28-41,51-64`
- `context/foundation/mvp-notes.md:19-28`
- `context/changes/signed-in-timeline-list/plan.md:15-26,87-123`
- `docs/local-timeline-data-contract.md:22-29`
- `lib/main.dart:155-204`
- `lib/timeline/timeline_repository.dart:5-22`
- `lib/timeline/local_timeline_repository.dart:57-96`
- `lib/timeline/timeline.dart:18-57`
- `test/timeline/timeline_list_test.dart:14-54`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append — <commit sha> when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Entry detail presentation

#### Automated

- [x] 1.1 Detail widget tests pass for loading, populated multi-day, empty, read-error, retry, and ascending-order states.
- [x] 1.2 `flutter analyze` passes after adding the detail screen and tests.

#### Manual

- [x] 1.3 Opening a populated detail screen shows readable entries under distinct local-day headings, with the oldest day first.
- [x] 1.4 An empty timeline clearly says it has no entries and still presents the add-entry action area.

### Phase 2: Navigation and text entry

#### Automated

- [ ] 2.1 Widget tests cover list-row navigation, AppBar back, FAB/form submission with an empty and non-empty description, save failure with retained input, and successful reload.
- [ ] 2.2 Existing auth, timeline-list, repository, and database tests continue to pass.

#### Manual

- [ ] 2.3 From both guest and signed-in shells, tapping a timeline opens its detail page and system/AppBar back returns to the list.
- [ ] 2.4 The FAB opens the form on an empty and populated timeline; saving an optional-description entry returns to a refreshed detail list.
- [ ] 2.5 A forced save failure leaves the entered description visible and does not sign the user out.

### Phase 3: Integration and delivery verification

#### Automated

- [ ] 3.1 `flutter test` passes, including auth, database, repository, list, and detail/form widget tests.
- [ ] 3.2 `flutter analyze` passes with no new warnings.
- [ ] 3.3 `flutter build apk --debug` completes successfully.

#### Manual

- [ ] 3.4 On the Android emulator with mock auth, a user can enter as guest, open a local timeline, see its entries grouped by day, return to the list, and create a text-only entry.
- [ ] 3.5 Signed-in presentation follows the same route and preserves the session email; sign-out still returns to the access choices without deleting local entries.
- [ ] 3.6 Empty, read-error/retry, and save-error/retained-form behavior are distinguishable; no photo UI is presented.
