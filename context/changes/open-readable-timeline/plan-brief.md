# Open Timeline Entries — Plan Brief

> Full plan: `context/changes/open-readable-timeline/plan.md`

## What & Why

The app can already list and manage timelines, and the local repository already
stores entries per timeline. This change completes the next navigation step:
tapping a timeline opens its entries list, which initially presents an empty
state because entry creation is not yet available.

## Starting Point

`TimelineListScreen` renders timeline rows with an Edit/Delete overflow menu,
but rows are not navigable. `TimelineRepository.listEntries(timelineId)` and
the Drift relation already provide timeline-scoped, chronological reads. The
existing loading/error/retry patterns and injected widget-test fakes are the
project conventions to reuse.

## Desired End State

The main row tap opens a dedicated entries screen for the selected timeline.
The screen shows the timeline name, loading state, entries when available,
empty state without an add CTA, and retryable read errors. Back navigation
returns to the timeline list, while Edit/Delete remain unchanged.

## Key Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Row interaction | Whole row opens outside the trailing menu | Provides the largest and most natural mobile tap target while preserving row actions. |
| Empty state | Message with no action | Entry creation is explicitly unavailable in this slice. |
| Read errors | Error plus retry on the entries screen | Matches the existing list pattern and does not hide failures as empty data. |
| Data scope | `listEntries(selectedTimeline.id)` | Ensures each timeline displays only its own entries without changing storage. |
| Verification | Widget tests plus full regression/build checks | Covers navigation and states without requiring seeded device data or credentials. |

## Scope

**In scope:**

- New read-only timeline entries screen.
- Timeline-row navigation and back navigation.
- Loading, empty, populated, and retryable error states.
- Widget coverage for timeline identity and preservation of Edit/Delete.
- Analyze, test, debug APK, and manual smoke verification.

**Out of scope:**

- Entry CRUD, photos, descriptions, media rendering, and AI comparison.
- Schema, repository contract, backend, sync, account ownership, and auth changes.
- Add-entry CTA or any unavailable entry creation affordance.

## Architecture / Approach

Keep `TimelineListScreen` as the source screen and use Flutter navigation to a
focused `TimelineEntriesScreen`. Inject the existing `TimelineRepository`, pass
the selected `Timeline`, and load entries by its id. Reuse the project's
handwritten fake repository and asynchronous widget-state testing style.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Entries screen | Read-only screen with all data states | An error must not be rendered as an empty result. |
| 2. Row navigation | Tap-to-open while Edit/Delete remain independent | Popup menu must not trigger navigation. |
| 3. Verification | Full Flutter and Android-targeted checks | Manual checks require a runnable Android path. |

**Prerequisites:** Existing local timeline data contract, timeline list, and
timeline CRUD are implemented; no credentials are needed for automated tests.

**Estimated effort:** ~1–2 focused implementation sessions across 3 phases.

## Open Risks & Assumptions

- The current local repository contract remains the source of truth and its
  chronological ordering is sufficient for this read-only screen.
- Manual Android verification depends on an available emulator/device; the
  widget suite is the executable fallback for empty and error states.
- A populated manual entries check may remain deferred until entry creation or
  a data-seeding path exists; the plan does not invent one.

## Success Criteria (Summary)

- Tapping a timeline opens the correct timeline-specific entries screen.
- An empty timeline clearly reports no entries and offers no unavailable add
  action.
- Read failures can be retried without returning to the timeline list.
- Existing timeline CRUD and guest/signed-in flows remain green.
