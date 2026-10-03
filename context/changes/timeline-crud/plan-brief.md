# Timeline CRUD — Plan Brief

> Full plan: `context/changes/timeline-crud/plan.md`

## What & Why

The app can already store, list, rename, and delete timelines through its local repository, but users currently see a read-only list. This change exposes the missing create, rename, and delete workflow so the first usable timeline can be managed from the mobile UI.

## Starting Point

`TimelineListScreen` handles loading, empty, populated, and retry states, while `LocalTimelineRepository` already implements timeline CRUD and deterministic ordering. There are no form, confirmation-dialog, or row-action patterns yet, and the schema requires no change.

## Desired End State

Guest and signed-in users can create a timeline, rename it, and delete it from the shared local list. Names are trimmed and required, duplicate names are allowed, deletion is confirmed, and every successful mutation reloads the list from storage.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Slice scope | Timeline entity only | Entry CRUD and detail navigation belong to later work and would make this slice unnecessarily broad. |
| Write access | Guest and signed-in users | It preserves the existing local installation contract and keeps the MVP flow testable without credentials. |
| Name rule | Trim and require non-empty; allow duplicates | It prevents unusable names without adding uniqueness policy or schema changes. |
| Row actions | Overflow menu with Edit/Delete | It keeps rows readable and avoids implying that a row opens a detail view. |
| Delete behavior | Confirmation dialog naming the timeline and child-entry consequence | The repository deletion cascades to entries, so accidental deletion must be explicit. |
| Mutation errors | Message while preserving form/list state | Users can correct or retry without losing entered data or hiding existing rows. |
| Refresh strategy | Re-read after success | The repository remains the single source of truth and ordering stays deterministic. |
| Verification | Repository tests, widget tests, and Android/manual smoke test | The feature crosses data, UI interaction, and the mobile delivery boundary. |

## Scope

**In scope:**

- Repository-level normalized-name validation and failure contract.
- Create and edit dialogs with pending, validation, cancellation, and error states.
- Create action, per-row Edit/Delete menu, confirmed deletion, and reload after success.
- Regression tests, `flutter analyze`, `flutter test`, debug APK build, and manual Android verification.

**Out of scope:**

- Entry CRUD, photos, descriptions, timeline detail navigation, and AI comparison.
- Backend, sync, cloud backup, account ownership, roles, sharing, and archive/undo.

## Architecture / Approach

`TimelineListScreen` remains the feature boundary and uses the existing `TimelineRepository`. A shared name-dialog component handles create/edit; list-level mutation state prevents duplicate submissions and reloads through `listTimelines()` after successful writes. The existing local Drift schema and guest/auth shell are reused unchanged.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Name contract | Normalized required names and repository coverage | Validation must apply outside the UI too. |
| 2. Create/edit | Reusable form and successful/error flows | Dialog state must preserve input on failure. |
| 3. Row actions/delete | Overflow actions and safe confirmed deletion | Cascade warning and no premature delete. |
| 4. Integration/delivery | Regression suite and Android smoke verification | Local/guest behavior must remain unchanged. |

**Prerequisites:** `local-timeline-data-contract` and `signed-in-timeline-list` are already implemented; no credentials are needed for automated tests.

**Estimated effort:** ~3–4 focused implementation sessions across 4 phases.

## Open Risks & Assumptions

- Local timelines remain installation-scoped and can be seen or changed by guest and later authenticated sessions on the same device; this is an accepted MVP limitation, not account isolation.
- Manual Android verification depends on an available emulator/device; automated Flutter tests remain the required fallback.
- Repository deletion already removes child database rows and attempts photo cleanup; this slice does not redesign that existing storage behavior.

## Success Criteria (Summary)

- A user can create, rename, and delete a timeline from the list, with required-name validation and delete confirmation.
- Failed mutations preserve useful UI state and successful mutations show the repository-backed result in deterministic order.
- Existing auth, guest, local-retention, entry-storage behavior and Android build remain green.
