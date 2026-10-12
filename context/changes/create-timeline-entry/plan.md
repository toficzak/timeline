# Create Timeline Entry Implementation Plan

## Overview

Add the first user-facing entry-creation flow to the timeline entries screen.
The form will show the current date and time, let the user optionally select a
photo from the real device gallery or use a persisted blank image as a camera
mock, collect an optional trimmed description, and save through the existing
local repository. After saving, the timeline reloads and renders the stored
photo when one exists.

## Current State Analysis

`TimelineEntriesScreen` already loads timeline-scoped entries and renders their
description and creation time, but it has no add action or photo rendering
(`lib/timeline/timeline_entries_screen.dart:21-103`). The timeline list already
navigates to this screen and supplies the shared `TimelineRepository`
(`lib/timeline/timeline_list_screen.dart:164-175`).

The repository and local storage already support the required persistence shape:
`TimelineRepository.createEntry` accepts an optional `File`,
`LocalTimelineRepository` imports it into the app-support photo directory, and
`TimelineEntry` stores a nullable relative `photoPath`
(`lib/timeline/timeline_repository.dart:11-22`,
`lib/timeline/local_timeline_repository.dart:59-87`,
`lib/timeline/timeline.dart:18-33`). The existing database has no missing field
for this feature, so no schema migration is required
(`lib/data/app_database.dart:13-40`).

The app has no image-picker dependency. Existing tests use injected repository
fakes and do not require platform channels, credentials, or real files
(`test/timeline/timeline_entries_test.dart:10-52`,
`test/timeline/timeline_list_test.dart:15-86`). The official `image_picker`
package supports the real gallery on Android and iOS; Android needs no extra
configuration, while iOS requires a photo-library usage description
(`https://pub.dev/packages/image_picker`).

## Desired End State

From a selected timeline, the user can open a new-entry form. The form presents
the current local date and time at the top, an empty or selected image preview,
separate Camera and Gallery buttons, an optional multiline description, and Save
and Cancel actions. Camera creates a blank placeholder file without opening the
native camera; Gallery opens the real device gallery. A photo is optional, so
Save works with neither source selected.

Successful Save creates one entry with the trimmed description, the captured
read-only creation time, and the selected photo when present. The form closes,
the entries screen reloads from the repository, and each stored photo is shown
above its entry metadata. Missing or unreadable photo files fall back to a
placeholder without hiding the date or description. Gallery, mock-file, and
repository failures remain in the form with the existing input preserved.

### Key Discoveries:

- Entry creation, optional photo storage, cleanup, and timeline scoping already
  exist; the missing work is UI orchestration and media selection.
- The current local photo store exposes import/delete but not a safe read-path
  resolver, so rendering saved photos needs an explicit repository/storage seam.
- The repository currently chooses `DateTime.now().toUtc()` internally; passing
  the form's captured timestamp keeps the displayed and persisted creation time
  consistent without making the date editable.
- Widget tests can inject a fake photo source and fake repository, keeping the
  real gallery plugin out of automated UI tests.

## What We're NOT Doing

- No real camera capture, camera permissions, video capture, image cropping, or
  multi-image selection.
- No editable date/time, backdating, date picker, or timezone-setting control.
- No entry edit/delete flow; existing repository methods remain unused by this
  form.
- No backend, synchronization, cloud backup, account ownership, AI comparison,
  or change to the installation-local data contract.
- No new database table or migration.
- No requirement that a photo be selected before Save.

## Implementation Approach

Keep `TimelineEntriesScreen` as the timeline boundary and add a dedicated
`TimelineEntryFormScreen` for creation. Inject an `EntryPhotoSource` abstraction
so the form never calls platform channels directly: the production adapter uses
`image_picker` for Gallery and generates a deterministic blank local image for
Camera, while tests provide files or null results. Extend the existing local
photo/repository seam with safe relative-path resolution for list rendering and
with an optional creation timestamp. Reuse the established FutureBuilder,
pending-control, inline-error, and reload-after-success patterns.

## Critical Implementation Details

### Source and persistence sequencing

The form must keep the selected source `File` as temporary input until
`createEntry` succeeds; only the repository imports it into durable app-support
storage. The mock camera file is treated exactly like a gallery file so its
entry remains visually consistent after the form closes. Gallery cancellation
is not an error and leaves the current form unchanged.

### Saved-photo failure behavior

Photo-path resolution must validate relative paths through the existing local
storage boundary. If a stored file is missing or cannot be decoded, render a
stable placeholder/error state for that image while retaining the entry's date
and optional description.

## Phase 1: Media and persistence contracts

### Overview

Add the dependency and testable media boundary, make the mock camera produce a
durable input file, and expose the timestamp/photo-path contracts needed by the
form and saved-entry renderer.

### Changes Required:

#### 1. Gallery and mock-camera adapter

**File**: `pubspec.yaml`

**Intent**: Add the official `image_picker` dependency needed for real gallery
selection while keeping native camera capture out of scope.

**Contract**: The dependency must support the current Flutter/Dart SDK; use
`image_picker: ^1.2.4` unless dependency resolution selects a compatible newer
stable version.

**File**: `lib/timeline/entry_photo_source.dart` (new)

**Intent**: Isolate gallery and mock-camera behavior from the form so widget
tests do not depend on platform channels.

**Contract**: Define an `EntryPhotoSource` seam with an asynchronous gallery
operation returning a nullable `File` (`null` means user cancellation) and a
camera operation returning a blank placeholder `File`. The production adapter
converts `image_picker` gallery `XFile` results to `File` and never invokes
`ImageSource.camera`; failures propagate for inline form handling.

#### 2. Mock image and platform setup

**File**: `lib/timeline/entry_photo_source.dart` (production implementation)

**Intent**: Make the Camera action behave as a completed capture without opening
  camera UI or requiring camera permissions.

**Contract**: Generate or materialize a deterministic blank image in a temporary
  location, return it as a `File`, and let `LocalTimelineRepository` import it
  into durable photo storage during Save. Do not store a temporary path in the
  database.

**File**: `ios/Runner/Info.plist`

**Intent**: Declare the reason for real photo-library selection on iOS while
  preserving the platform scaffold for future mobile testing.

**Contract**: Add `NSPhotoLibraryUsageDescription` with user-facing copy about
  selecting a timeline photo. Do not add camera or microphone usage strings for
  this change because no native camera/video operation is performed.

#### 3. Timestamp and photo-resolution boundary

**File**: `lib/timeline/timeline_repository.dart`,
`lib/timeline/local_timeline_repository.dart`,
`lib/timeline/local_photo_store.dart`

**Intent**: Keep the form's displayed creation time equal to the value persisted
  in the existing UTC field, and give the list a safe way to resolve stored local
  photo paths.

**Contract**: Extend `createEntry` with an optional named `DateTime? createdAt`
  that defaults to the current UTC time and is normalized to UTC. Add a
  repository/storage read-path method that resolves a validated relative
  `photoPath` to a local `File`; existing import/delete path-safety rules remain
  in force. No database schema or migration changes are allowed.

#### 4. Contract coverage

**File**: `test/timeline/local_timeline_repository_test.dart`,
`test/data/app_database_test.dart`

**Intent**: Protect timestamp preservation, optional photos, relative-path
  resolution, and existing cleanup behavior while extending the seam.

**Contract**: Tests prove an explicit timestamp is stored as UTC, no-photo
  creation still returns a null path, imported photos remain relative, path
  traversal is rejected, and existing entry/timeline cleanup behavior remains
  unchanged.

### Success Criteria:

#### Automated Verification:

- Repository and database tests cover explicit UTC timestamp persistence,
  optional photos, path resolution, traversal rejection, and existing cleanup.
- The production photo-source contract and fake-compatible interfaces compile
  without invoking platform channels in tests.

#### Manual Verification:

- No manual verification is requested for this phase; the contracts are
  executable through repository tests and static analysis.

---

## Phase 2: New-entry form

### Overview

Create the form with the agreed layout and interaction states, including real
gallery selection, the mock Camera action, optional image/description handling,
and preserved input on recoverable failures.

### Changes Required:

#### 1. Entry form screen

**File**: `lib/timeline/timeline_entry_form_screen.dart` (new)

**Intent**: Provide a focused creation form for one selected timeline and keep
  all creation state local to the form.

**Contract**: Accept a `Timeline`, `TimelineRepository`, and `EntryPhotoSource`.
  Capture a read-only `DateTime` when the form opens; display it as localized
  date and time at the top. Below it show an empty or selected image preview,
  separate Camera and Gallery buttons, an optional Remove photo action, and a
  multiline description field below the image controls. Trim the description;
  an empty result is valid. Save passes the selected `File?`, trimmed text, and
  captured timestamp to `createEntry`; Cancel returns without a repository call.

#### 2. Form state and errors

**File**: `lib/timeline/timeline_entry_form_screen.dart`

**Intent**: Match existing mutation-dialog behavior for pending operations and
  recoverable failures.

**Contract**: Disable relevant controls while selecting or saving, prevent
  duplicate submissions, treat gallery cancellation as a no-op, and show a
  readable inline error while retaining the description, selected preview, and
  ability to retry. Successful Save returns the created entry to the caller.

#### 3. Form widget tests

**File**: `test/timeline/timeline_entry_form_test.dart` (new)

**Intent**: Verify form behavior without a real gallery, device, database, or
  credentials.

**Contract**: Use fake repository/photo-source implementations to cover the
  displayed current timestamp, separate source actions, mock/gallery files,
  gallery cancellation, optional no-photo Save, trimmed optional description,
  Cancel, pending disabled controls, successful return, and source/save errors
  with preserved input.

### Success Criteria:

#### Automated Verification:

- Form widget tests cover both source actions, cancellation, optional no-photo
  save, description trimming, pending controls, success, and error recovery.
- The form passes the selected timeline id, captured timestamp, trimmed
  description, and selected file/null to the repository fake.

#### Manual Verification:

- Opening the form shows date/time first, then the image area/source controls,
  then the optional description field and Save/Cancel actions.
- Camera shows the blank placeholder without opening native camera UI; Gallery
  opens the device gallery, and a cancelled selection leaves the form unchanged.
- Save works with no image and with either selected source; a failed selection or
  save leaves the form open with the entered description intact.

---

## Phase 3: Navigation, refresh, and saved-photo rendering

### Overview

Expose the form from the entries screen, reload after a successful save, and
  display locally stored photos without breaking existing empty/read/error states.

### Changes Required:

#### 1. Open and refresh the creation flow

**File**: `lib/timeline/timeline_entries_screen.dart`

**Intent**: Make entry creation available from both empty and populated timeline
  states and keep the repository-backed list as the source of truth.

**Contract**: Expose one Add entry action, open
  `TimelineEntryFormScreen` with the selected timeline, shared repository, and
  photo source, and call `listEntries` again only after a successful returned
  entry. Cancel returns without changing the list. Existing loading, empty, and
  retryable-error behavior remains intact.

#### 2. Wire the photo source through app boundaries

**File**: `lib/main.dart`, `lib/timeline/timeline_list_screen.dart`

**Intent**: Construct the production photo-source adapter once and pass it to
  the entries screen without exposing plugin details to unrelated screens.

**Contract**: The shared local repository and photo source remain stable while
  navigating from the timeline list; tests can continue to inject fakes. Guest,
  signed-in, sign-out, and local-retention behavior must not change.

#### 3. Render saved entry photos

**File**: `lib/timeline/timeline_entries_screen.dart`

**Intent**: Make successful photo selection visible after returning to the
  timeline and fulfill the saved-local-photo viewing requirement.

**Contract**: When `photoPath` is present, resolve it through the repository
  storage seam and render the local image above the entry's localized date/time
  and optional description. When the path is null, show metadata without an
  image; when the file is missing or unreadable, show a stable placeholder and
  retain the metadata. Empty descriptions must not create a misleading blank
  title.

#### 4. Entries-screen regression tests

**File**: `test/timeline/timeline_entries_test.dart`,
`test/timeline/timeline_list_test.dart`

**Intent**: Extend existing screen coverage for the new add action and preserve
  timeline isolation/navigation behavior.

**Contract**: Tests cover Add from empty and populated states, successful
  refresh, Cancel without refresh, saved photo rendering/fallback, optional
  description rendering, existing chronological filtering, retry behavior, and
  navigation back to the timeline list.

### Success Criteria:

#### Automated Verification:

- Entries-screen tests prove Add opens the form for the selected timeline and a
  successful result triggers exactly one fresh list read.
- Widget tests cover saved-image rendering, no-photo entries, unreadable-photo
  fallback, optional descriptions, cancel behavior, and existing read states.
- Existing timeline-list, auth, guest, retention, and navigation tests remain
  passing.

#### Manual Verification:

- A user can open Add from an empty or populated timeline, cancel it, or save;
  successful save returns to the list with the new entry visible.
- A gallery image and the mock camera placeholder remain visible on the list
  after navigation/reload; an entry saved without a photo remains readable.
- Existing timeline navigation, sign-out, guest access, and timeline CRUD still
  behave as before.

---

## Phase 4: Integration and delivery verification

### Overview

Run the complete automated suite and record the Android-targeted verification
without claiming unavailable hardware or native camera support.

### Changes Required:

#### 1. Verification record

**File**: `context/changes/create-timeline-entry/verification.md` (new during
implementation)

**Intent**: Record reproducible checks for entry creation, media states, local
photo persistence, regression coverage, and the Android build.

**Contract**: Name commands and actual results accurately; distinguish widget
and repository verification from real gallery/manual Android verification, and
do not claim camera capture was tested or implemented.

### Success Criteria:

#### Automated Verification:

- `flutter pub get` completes after the dependency change.
- `flutter analyze` passes.
- `flutter test` passes, including repository, form, entries-screen, timeline,
  auth, retention, and database tests.
- `flutter build apk --debug` completes successfully.

#### Manual Verification:

- On an available Android device or emulator, a user can open a timeline, save
  entries with no photo, a gallery photo, and the mocked Camera photo, and see
  each result in the list.
- Gallery cancellation and a simulated gallery/save failure preserve the form;
  no native camera screen or camera permission prompt appears.

## Testing Strategy

### Unit Tests:

- Verify optional UTC timestamp handling, photo import/relative-path resolution,
  traversal protection, and existing entry/photo cleanup.
- Test the photo-source adapter boundary with fake files and null cancellation;
  keep platform-channel behavior behind injected implementations.

### Widget Tests:

- Use the existing handwritten `TimelineRepository` fake pattern and add a fake
  `EntryPhotoSource` that records Gallery/Camera calls and returns deterministic
  files.
- Cover form state transitions, source replacement/removal, description
  normalization, save/cancel/error behavior, entries refresh, and image fallback.

### Manual Testing Steps:

1. Open a timeline with no entries and confirm Add is available.
2. Open the form and verify the order: date/time, image area/source controls,
   description, Save/Cancel.
3. Save with no image and an empty description; confirm the entry remains
   readable.
4. Choose Camera and confirm a blank preview is shown without native camera UI;
   save and verify the placeholder remains after returning to the list.
5. Choose Gallery, select an image, replace/remove it if needed, save, and
   verify the selected image remains visible after list reload.
6. Cancel gallery selection and the form; confirm no entry or refresh occurs.
7. Exercise a gallery/source error and a repository save error; confirm input is
   preserved and retry remains possible.

## Performance Considerations

The MVP targets small local datasets. One repository reload after a successful
save and one local image widget per entry are sufficient; no cache, pagination,
thumbnail service, image upload, or backend is needed. The durable photo store
continues to own copied files, so temporary picker files are not database
references.

## Migration Notes

No database migration is required. Existing entries with null or valid relative
photo paths remain readable. Existing entries with missing files must render the
defined placeholder rather than fail the entire list. The optional timestamp
parameter is backward-compatible for existing repository callers.

## References

- `context/foundation/prd.md:28-38,51-85`
- `context/foundation/mvp-notes.md:9-28`
- `context/foundation/roadmap.md:34-48,129-155`
- `docs/local-timeline-data-contract.md:3-20,35-44`
- `lib/timeline/timeline.dart:18-58`
- `lib/timeline/timeline_repository.dart:11-22`
- `lib/timeline/local_timeline_repository.dart:59-182`
- `lib/timeline/local_photo_store.dart:8-69`
- `lib/timeline/timeline_entries_screen.dart:21-103`
- `lib/timeline/timeline_list_screen.dart:164-175`
- `test/timeline/timeline_entries_test.dart:10-213`
- `test/timeline/timeline_list_test.dart:15-86,322-346`
- `test/timeline/local_timeline_repository_test.dart:123-226`
- `https://pub.dev/packages/image_picker`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append — <commit sha> when a step lands. Do not rename step titles.

### Phase 1: Media and persistence contracts

#### Automated

- [x] 1.1 Repository and database tests cover explicit UTC timestamp persistence, optional photos, path resolution, traversal rejection, and existing cleanup.
- [x] 1.2 The production photo-source contract and fake-compatible interfaces compile without invoking platform channels in tests.

#### Manual

- [x] 1.3 No manual verification is requested for this phase; the contracts are executable through repository tests and static analysis.

### Phase 2: New-entry form

#### Automated

- [x] 2.1 Form widget tests cover both source actions, cancellation, optional no-photo save, description trimming, pending controls, success, and error recovery.
- [x] 2.2 The form passes the selected timeline id, captured timestamp, trimmed description, and selected file/null to the repository fake.

#### Manual

- [ ] 2.3 Opening the form shows date/time first, then the image area/source controls, then the optional description field and Save/Cancel actions.
- [ ] 2.4 Camera shows the blank placeholder without opening native camera UI; Gallery opens the device gallery, and a cancelled selection leaves the form unchanged.
- [ ] 2.5 Save works with no image and with either selected source; a failed selection or save leaves the form open with the entered description intact.

### Phase 3: Navigation, refresh, and saved-photo rendering

#### Automated

- [ ] 3.1 Entries-screen tests prove Add opens the form for the selected timeline and a successful result triggers exactly one fresh list read.
- [ ] 3.2 Widget tests cover saved-image rendering, no-photo entries, unreadable-photo fallback, optional descriptions, cancel behavior, and existing read states.
- [ ] 3.3 Existing timeline-list, auth, guest, retention, and navigation tests remain passing.

#### Manual

- [ ] 3.4 A user can open Add from an empty or populated timeline, cancel it, or save; successful save returns to the list with the new entry visible.
- [ ] 3.5 A gallery image and the mock camera placeholder remain visible on the list after navigation/reload; an entry saved without a photo remains readable.
- [ ] 3.6 Existing timeline navigation, sign-out, guest access, and timeline CRUD still behave as before.

### Phase 4: Integration and delivery verification

#### Automated

- [ ] 4.1 `flutter pub get` completes after the dependency change.
- [ ] 4.2 `flutter analyze` passes.
- [ ] 4.3 `flutter test` passes, including repository, form, entries-screen, timeline, auth, retention, and database tests.
- [ ] 4.4 `flutter build apk --debug` completes successfully.

#### Manual

- [ ] 4.5 On an available Android device or emulator, a user can open a timeline, save entries with no photo, a gallery photo, and the mocked Camera photo, and see each result in the list.
- [ ] 4.6 Gallery cancellation and a simulated gallery/save failure preserve the form; no native camera screen or camera permission prompt appears.
