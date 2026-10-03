# Open Timeline Entries — Implementation Plan

## Overview

Make timeline rows navigable and add a dedicated entries screen. The selected
timeline is passed by its existing model/id, entries are read through the
existing repository contract, and an empty timeline shows a clear empty state
without an unavailable add action.

## Current State Analysis

`TimelineListScreen` already loads and mutates timelines, but its `ListTile`
has no `onTap`; the trailing popup menu owns Edit and Delete
(`lib/timeline/timeline_list_screen.dart:156-190`). The repository already
provides `listEntries(int timelineId)` and the local implementation filters by
`timelineId` and orders by `createdAt`
(`lib/timeline/timeline_repository.dart:11-22`,
`lib/timeline/local_timeline_repository.dart:91-98`). `TimelineEntry` already
contains the owning `timelineId` (`lib/timeline/timeline.dart:18-33`).

The previous timeline-list slice intentionally excluded navigation and entry
display (`context/changes/signed-in-timeline-list/plan.md:15-33`), and the
timeline CRUD slice kept those concerns separate
(`context/changes/timeline-crud/plan.md:26-31`). This change now implements
the navigation boundary, but not entry CRUD or media presentation.

## Desired End State

Tapping anywhere on a timeline row outside its overflow menu opens a detail
screen for that timeline. The screen has a back affordance and displays the
timeline name, loading state, timeline-specific entries when present, an empty
state when none exist, and an actionable retry state when reading fails. The
empty state has no add-entry button because entry creation is out of scope.
Edit and Delete remain available from the row popup menu and do not navigate.

## Key Discoveries

- No schema or repository API change is required; `listEntries` already has
  the needed timeline-scoped contract.
- The local repository already prevents entries from other timelines appearing
  in the query and uses chronological ordering.
- The existing list screen and tests use injected repository interfaces and
  handwritten fakes, so navigation and read states can be tested without
  credentials, platform storage, or seeded device data.

## What We're NOT Doing

- No create, edit, or delete entry action.
- No photo picker, photo rendering, description editor, entry detail view, or
  AI comparison.
- No database migration, new table, backend, synchronization, or account
  ownership change.
- No change to timeline rename/delete behavior, guest access, authentication,
  or local-data retention.
- No add-entry CTA in the empty state.

## Implementation Approach

Add a focused `TimelineEntriesScreen` that receives the selected `Timeline` and
the shared `TimelineRepository`. It loads entries in `initState`, preserves the
selected timeline identity for the repository call, and mirrors the existing
loading/error/retry pattern without converting read failures into an empty
result. Add navigation from the timeline `ListTile` while leaving its popup
menu in the trailing slot. Extend the current fake repository and widget tests
for the new read contract and navigation regression.

## Critical Implementation Details

### Row interaction boundary

The row's main tap target opens entries; the `PopupMenuButton` remains an
independent trailing control. Edit and Delete must continue to invoke their
current dialogs rather than opening the entries screen.

### Timeline isolation

The entries screen must call `listEntries` with the selected timeline's id and
must not obtain entries through a global unfiltered list. Tests should include
different timeline ids so an accidental cross-timeline display is detectable.

## Phase 1: Entries list screen

### Overview

Create the dedicated read-only screen with all asynchronous states required by
the current MVP.

### Changes Required:

#### 1. Entries screen

**File**: `lib/timeline/timeline_entries_screen.dart` (new)

**Intent**: Provide the destination for a selected timeline and give users
clear feedback while its entries are loading, empty, available, or unavailable.

**Contract**: Accept a `Timeline` and `TimelineRepository`; call
`listEntries(timeline.id)`; show the timeline name in the app bar; expose a back
navigation affordance; show a loading indicator, a retryable read error, an
empty message with no add action, and chronological entry rows when data is
returned. Render only entries belonging to the selected timeline as supplied by
the repository contract.

#### 2. Entries widget tests

**File**: `test/timeline/timeline_entries_test.dart` (new)

**Intent**: Verify the screen independently of real Drift storage and mobile
credentials.

**Contract**: Tests cover loading, empty state, populated rendering, the
selected `timelineId`, read failure, retry, and back navigation. The empty
state must not expose a create/add-entry control.

### Success Criteria:

#### Automated Verification:

- Widget tests cover loading, empty, populated, error, retry, back navigation,
  and the exact timeline id passed to `listEntries`.
- Widget tests prove the empty state has no add-entry action.

#### Manual Verification:

- Opening a timeline shows its title, a loading state, then an empty message
  when the selected timeline has no entries.
- A read failure remains on the entries screen and can be retried.

## Phase 2: Timeline-row navigation

### Overview

Connect the existing timeline list to the new screen without disrupting row
actions or the shared guest/signed-in shell.

### Changes Required:

#### 1. Open selected timeline

**File**: `lib/timeline/timeline_list_screen.dart`

**Intent**: Make the normal row interaction open the entries list for the
selected timeline while preserving the existing overflow menu actions.

**Contract**: A tap outside the trailing popup menu pushes or presents
`TimelineEntriesScreen` with the tapped `Timeline`; Edit and Delete continue to
open their existing flows and do not trigger navigation. The selected id must
remain stable through navigation.

#### 2. Navigation regression coverage

**File**: `test/timeline/timeline_list_test.dart`

**Intent**: Protect the new row affordance and existing CRUD interactions.

**Contract**: Tests prove a row tap opens the selected timeline's entries
screen, that its name is shown, and that the row popup still exposes Edit and
Delete without opening the detail screen.

### Success Criteria:

#### Automated Verification:

- Widget tests prove tapping a timeline opens the entries screen with the
  correct timeline identity.
- Existing timeline create, edit, delete, empty-list, loading, retry, guest,
  and signed-in tests remain passing.

#### Manual Verification:

- A user can tap a timeline row, see its entries screen, and return with the
  back affordance to the same timeline list.
- Opening the row menu still permits Edit and Delete without accidental
  navigation.

## Phase 3: Integration and regression verification

### Overview

Run the complete test and analysis suite and record that the feature remains a
read-only, local MVP change.

### Changes Required:

#### 1. Verification record

**File**: `context/changes/open-readable-timeline/verification.md` (new during
implementation)

**Intent**: Record reproducible checks for timeline navigation, empty/error
states, existing actions, and the Android-targeted build.

**Contract**: Name commands and results accurately; do not claim device,
emulator, or Google-credential verification that was not available.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes.
- `flutter test` passes, including repository, entries-screen, timeline-list,
  auth, retention, and database tests.
- `flutter build apk --debug` completes successfully.

#### Manual Verification:

- On Android or an emulator, a timeline opens its empty entries screen and
  back navigation returns to the timeline list.
- Existing timeline CRUD actions still work from the list, and no unavailable
  add-entry action is shown.

## Testing Strategy

### Unit Tests:

- No new repository or database unit behavior is required; the existing
  `listEntries` implementation and timeline-scoped query remain the source of
  truth.

### Widget Tests:

- Use the existing handwritten `FakeTimelineRepository` pattern, extending it
  with configurable `listEntries` responses and recorded timeline ids.
- Cover every entries-screen state and the list-to-detail interaction while
  retaining current timeline CRUD regression coverage.

### Manual Testing Steps:

1. Start with a clean local store and create a timeline using the existing
   timeline action.
2. Tap the timeline row and confirm the title, empty message, and back action.
3. Open the row overflow menu and confirm Edit/Delete still work without
   navigating.
4. Simulate an entries read failure, choose retry, and confirm the screen
   recovers or remains actionable.

## Performance Considerations

The MVP targets a small local dataset. One repository read per opened timeline
and a standard Flutter list are sufficient; no cache, pagination, reactive
stream, or backend is needed.

## Migration Notes

No schema migration is required. Existing entries are read through the current
`timelineId` relationship, and no stored data is changed.

## References

- `context/foundation/prd.md:43-64,76-85`
- `context/foundation/mvp-notes.md:9-28`
- `context/foundation/roadmap.md:40-48,114-155`
- `context/changes/signed-in-timeline-list/plan.md:15-33,87-123`
- `context/changes/timeline-crud/plan.md:26-31,139-179`
- `lib/timeline/timeline_list_screen.dart:156-190`
- `lib/timeline/timeline_repository.dart:11-22`
- `lib/timeline/local_timeline_repository.dart:91-98`
- `lib/timeline/timeline.dart:18-33`
- `lib/data/app_database.dart:13-24`
- `test/timeline/timeline_list_test.dart:14-78,263-408`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append — <commit sha> when a step lands. Do not rename step titles.

### Phase 1: Entries list screen

#### Automated

- [x] 1.1 Widget tests cover loading, empty, populated, error, retry, back navigation, and the exact timeline id passed to `listEntries`. — 713cd0a
- [x] 1.2 Widget tests prove the empty state has no add-entry action. — 713cd0a

#### Manual

- [x] 1.3 Opening a timeline shows its title, a loading state, then an empty message when the selected timeline has no entries.
- [x] 1.4 A read failure remains on the entries screen and can be retried.

### Phase 2: Timeline-row navigation

#### Automated

- [x] 2.1 Widget tests prove tapping a timeline opens the entries screen with the correct timeline identity.
- [x] 2.2 Existing timeline create, edit, delete, empty-list, loading, retry, guest, and signed-in tests remain passing.

#### Manual

- [x] 2.3 A user can tap a timeline row, see its entries screen, and return with the back affordance to the same timeline list.
- [x] 2.4 Opening the row menu still permits Edit and Delete without accidental navigation.

### Phase 3: Integration and regression verification

#### Automated

- [ ] 3.1 `flutter analyze` passes.
- [ ] 3.2 `flutter test` passes, including repository, entries-screen, timeline-list, auth, retention, and database tests.
- [ ] 3.3 `flutter build apk --debug` completes successfully.

#### Manual

- [ ] 3.4 On Android or an emulator, a timeline opens its empty entries screen and back navigation returns to the timeline list.
- [ ] 3.5 Existing timeline CRUD actions still work from the list, and no unavailable add-entry action is shown.
