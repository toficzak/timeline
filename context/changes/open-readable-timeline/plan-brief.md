# Open and read a timeline — Plan Brief

> Full plan: `context/changes/open-readable-timeline/plan.md`

## What & Why

This change lets a user open a timeline, read its entries grouped by local calendar day, and add a text entry. It advances the first usable timeline flow while keeping local storage, authentication, and the existing repository boundary unchanged.

## Starting Point

S-01 displays locally stored timelines through `TimelineListScreen`, but its rows are intentionally non-navigable. The repository already supports `listEntries(timelineId)` and `createEntry`, while the app has no detail route or entry form.

## Desired End State

Tapping a timeline opens a detail page with an AppBar back action, loading/error/empty states, and entries shown oldest-first under local-day headings. A FAB opens a text-entry form; submitting an optional description creates a local entry and refreshes the detail view.

## Key Decisions Made

| Decision | Choice | Why | Source |
| --- | --- | --- | --- |
| Add action | Text-only entry form | Delivers a working create flow without pulling photo work forward from S-03. | Plan |
| Entry grouping | Local calendar day, oldest-first | Matches the user's day context and preserves progress chronology. | Plan |
| Empty state | Message plus FAB | Makes a new timeline actionable without fake data. | Plan |
| Validation | Description optional | Supports date-only notes and keeps the form minimal. | Plan |
| Photos | Deferred to S-03 | Avoids picker, permissions, path resolution, and media UI in this slice. | Plan |
| Test data | Fake entries with fixed historical dates | Makes day grouping deterministic without a production seed path or schema change. | Plan |
| Errors | Retry for reads; preserve form on save failure | Reuses S-01's recovery pattern and avoids losing user input. | Plan |
| Navigation | AppBar back route | Uses the native Android navigation model and keeps list state outside the detail page. | Plan |

## Scope

**In scope:**

- Navigate from a timeline list row to a detail screen.
- Load and display entries by local calendar day in ascending order.
- Show loading, empty, read-error/retry, and create-error states.
- Add an optional-description text entry through a FAB and form.
- Cover detail, create, navigation, and regression behavior with fakes.

**Out of scope:**

- Photo picking, importing, resolving, or displaying.
- Timeline creation/editing/deletion.
- Entry editing/deletion.
- Backend, synchronization, account ownership, schema migration, or seed data.

## Architecture / Approach

`TimelineListScreen` receives an item-tap callback and pushes a `TimelineDetailScreen` with the selected `Timeline` and injected `TimelineRepository`. The detail screen owns its asynchronous read state and refreshes after a successful `createEntry`; the repository remains the only data seam. Day headings are derived at presentation time from each entry's local `createdAt` value.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Entry detail presentation | Readable detail page with day grouping and recovery states. | Correct local-day grouping around timezone boundaries. |
| 2. Navigation and text entry | Row navigation, back behavior, FAB, and optional-description form. | Preserving form data after save failure. |
| 3. Integration and verification | Full widget/auth regression coverage and Android smoke verification. | Manual verification needs a way to create local entries. |

**Prerequisites:** Completed S-01, existing `TimelineRepository` entry APIs, and the Android emulator/debug build path.
**Estimated effort:** ~2–3 implementation sessions across 3 phases.

## Open Risks & Assumptions

- Entries created by the production repository use the current time; historical dates are only supplied by test fakes.
- The first detail view is text-only; S-03 will decide how stored photo paths become readable image widgets.
- The local day is calculated from `createdAt.toLocal()` and is therefore device-timezone dependent.

## Success Criteria (Summary)

- A user can open a listed timeline, distinguish entries from different local days, and return to the list.
- A user can add an optional-description entry from the FAB, including on an initially empty timeline.
- Read and save failures are recoverable without losing form input, and automated tests plus Android smoke checks pass.
