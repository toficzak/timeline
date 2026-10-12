# Create Timeline Entry — Plan Brief

> Full plan: `context/changes/create-timeline-entry/plan.md`

## What & Why

The app can open timelines and persist entries, but users cannot create one. This change adds a form for a current moment with an optional description and photo, using the real gallery and a safe camera mock while native camera capture is deferred.

## Starting Point

`TimelineEntriesScreen` displays descriptions and creation times, and `TimelineRepository.createEntry` already accepts optional `File` photos. The local schema/storage support one relative photo path, but there is no picker, form, add action, or saved-photo rendering.

## Desired End State

Add opens a form with localized current date/time, image preview, separate Camera/Gallery buttons, optional multiline description, and Save/Cancel. Gallery opens the device gallery; Camera creates and persists a blank placeholder. Save works without a photo, returns to the timeline, reloads it, and displays saved local images above their metadata.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Gallery behavior | Real device gallery | It delivers the requested usable gallery path while camera capture remains deferred. |
| Camera behavior | Persisted blank placeholder | The mocked source behaves like a completed photo selection and remains visible after reload. |
| Photo requirement | Optional | The user explicitly chose to allow saving a text-only entry. |
| Date/time | Current, read-only | It matches the existing creation-time model without adding backdating UX. |
| Description | Trimmed, optional, multiline | It preserves the existing repository contract and avoids an arbitrary limit. |
| Source controls | Separate Camera and Gallery buttons | Both choices stay discoverable and can replace/remove an existing selection. |
| Success flow | Return and refresh | Existing screens reload from the repository after successful mutations. |
| Failure flow | Inline error, preserve form | Users can retry without losing text or selected media. |
| Saved media | Render in timeline list | The photo workflow gives visible confirmation after the form closes. |
| Architecture | Injected photo-source adapter | Widget tests remain independent of platform channels and real devices. |

## Scope

**In scope:**

- Form from empty/populated timeline screens; real `image_picker` gallery and persisted blank Camera mock.
- Optional photo, trimmed description, current timestamp, preserved errors, list refresh, saved-photo rendering, tests, analysis, and Android checks.

**Out of scope:**

- Native camera capture/permissions, video, cropping, or multi-image support; editable dates/backdating; entry edit/delete; AI; backend/sync/backup; account ownership; or schema migration.

## Architecture / Approach

`TimelineEntriesScreen` owns navigation and refresh. A dedicated form receives the selected timeline, repository, and injected `EntryPhotoSource`; production uses `image_picker` only for Gallery and generates the Camera placeholder. The repository imports selected files and resolves validated relative paths for rendering. Fakes keep form tests independent of platform channels.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Media contracts | Picker adapter, mock file, timestamp and path-resolution seams | Temporary picker files must never become database paths. |
| 2. New-entry form | Date/image/source/description form with save, cancel, and errors | Optional media and platform failures must preserve form state. |
| 3. Refresh/rendering | Add navigation, reload, and saved-photo list display | Missing local files must not hide entry metadata. |
| 4. Verification | Full tests, analysis, APK, and Android smoke checks | Real gallery verification depends on a device/emulator. |

**Prerequisites:** Existing local timeline flow and Flutter toolchain. Android device/emulator is needed only for native-gallery verification; automated tests need no credentials or device.

**Estimated effort:** ~3–4 focused implementation sessions across 4 phases.

## Open Risks & Assumptions

- Picker paths may be temporary; the repository copies them before the form is discarded. Picker lost-data recovery must not turn a missing result into an entry.
- Local photos remain installation-scoped; no backup is added. If Android hardware is unavailable, widget/repository checks are the fallback.

## Success Criteria (Summary)

- Users can save with no image, a gallery image, or the mock Camera image, plus an optional trimmed description.
- The form preserves input through errors, refreshes after save, renders saved photos, and falls back without hiding metadata when images are missing.
- Existing local/auth flows, tests, analysis, and Android debug build remain intact.
