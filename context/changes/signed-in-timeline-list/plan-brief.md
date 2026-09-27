# Signed-in and Guest Timeline List — Plan Brief

> Full plan: `context/changes/signed-in-timeline-list/plan.md`

## What & Why

This change turns the post-authentication placeholder into the first usable timeline-list flow. Because the MVP stores timelines only on the device, users can also enter as guests and see the same local list without configuring Google authentication.

## Starting Point

Google/mock authentication and the Drift-backed local timeline repository already exist. `AuthGate` currently shows a private placeholder shell with a debug-entry button; `listTimelines()` exists but has no explicit ordering, and no list UI handles loading, empty, or read-error states.

## Desired End State

The signed-out screen offers Google sign-in and guest entry. Both paths show a readable, ascending-id list of local timeline names with loading, empty, and retryable error states. Rows are display-only until the later S-02 change defines opening a timeline; local records remain after sign-out.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Data scope | Existing installation-local records | The completed local data contract has no account key and explicitly preserves records across sign-out. |
| Guest access | Full guest list | Local-only MVP data can be demonstrated without making Google setup a prerequisite. |
| Ordering | Ascending database id | It represents insertion order without adding a created-at field to timelines. |
| Empty state | Message with no create action | Creation is outside S-01 and belongs to a later CRUD flow. |
| Loading | Explicit asynchronous loading state | Repository reads are futures and should not appear to hang. |
| Read error | In-place error with retry | Local read failures are not authentication failures and should not force logout. |
| Row interaction | Display-only | Opening entries is owned by S-02, avoiding a placeholder navigation contract. |
| Verification | Repository/widget tests plus Android smoke test | The feature crosses local data, auth gating, UI state, and the target platform. |

## Scope

**In scope:**

- Guest entry alongside Google sign-in.
- Shared local timeline list for guest and authenticated presentation.
- Deterministic repository ordering.
- Loading, populated, empty, error, and retry states.
- Regression tests and Android debug-build/manual verification.

**Out of scope:**

- Account-specific storage, backend, sync, backup, and cloud photos.
- Timeline creation, editing, deletion, navigation, and entry display.
- Changes to Google auth contracts or local-data cleanup policy.

## Architecture / Approach

`AuthGate` keeps Google authentication behavior and adds a non-authenticated guest UI state. Both access modes inject the existing `TimelineRepository` into a focused list screen. The repository explicitly orders local rows by id; the screen owns async list state and exposes only display/retry behavior needed for S-01.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Local access and ordering | Guest state and deterministic local list contract | Accidentally treating guest as an authenticated session or changing retention. |
| 2. Timeline list screen | Shared list UI with loading, empty, error/retry states | Scope creep into creation or S-02 navigation. |
| 3. Integration and regressions | Wired auth/guest flows and automated coverage | Auth tests may remain coupled to the old placeholder. |
| 4. Delivery verification | Android build and manual end-to-end confidence | Google/device setup may be unavailable, requiring mock-auth verification. |

**Prerequisites:** Existing F-01 Google access, F-02 local data contract, Flutter/Android tooling; no backend or Google credentials for automated tests.
**Estimated effort:** Approximately 2–3 focused sessions across 4 phases.

## Open Risks & Assumptions

- Local timelines are shared by accounts using the same installation; this is accepted for the single-device MVP but must be revisited before multi-user use.
- The guest mode is intentionally not persisted and does not create an auth session.
- A future S-02 may replace display-only rows with navigation, but this plan does not prebuild that route.

## Success Criteria (Summary)

- A user can enter as guest or through Google and see the same ordered local timeline names.
- Empty, loading, and read-error states are clear and retryable without losing local data or auth state.
- Existing auth/data tests, `flutter analyze`, `flutter test`, and the Android debug build pass.
