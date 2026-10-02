# Signed-in and Guest Timeline List Implementation Plan

## Overview

Replace the authenticated placeholder shell with a readable list of locally stored timelines. The same local list is available after Google sign-in or through an explicit guest entry point because the existing MVP data contract is installation-local rather than account-scoped.

## Current State Analysis

`AuthGate` already switches between authentication states, and `main()` injects a `LocalTimelineRepository` into the private shell (`lib/main.dart:13-30,54-100`). The signed-in shell currently shows the session email and a debug-entry button instead of timelines (`lib/main.dart:123-189`).

The app-owned `TimelineRepository` already exposes `listTimelines()` (`lib/timeline/timeline_repository.dart:5-9`), and the local implementation maps Drift rows to `Timeline` values (`lib/timeline/local_timeline_repository.dart:24-28`). The query has no explicit ordering. The database has no account/provider column, and the accepted local contract says records belong to the installation, survive sign-out, and are shared by later authenticated accounts (`docs/local-timeline-data-contract.md:3-6,22-29`).

There is no timeline-list widget or list loading/error state. Existing tests use injected interfaces and handwritten fakes (`test/auth/auth_gate_test.dart:8-24`), while repository tests use in-memory Drift (`test/timeline/local_timeline_repository_test.dart:12-35`).

## Desired End State

After starting the app, a user can either sign in with Google or continue as a guest. Both paths show the same local timeline list, with deterministic insertion order, a clear empty state, an asynchronous loading state, and a retryable read error.

The list items are readable but not navigable in this change. Creating timelines, opening a timeline, displaying entries, and account-specific storage remain later work. Signing out still changes only authentication state and does not delete or hide local timelines.

### Key Discoveries:

- `TimelineRepository.listTimelines()` is already the correct UI seam; no new data API is required (`lib/timeline/timeline_repository.dart:5-9`).
- Local records intentionally have no owner key and must not be passed to `LocalDataCleaner` (`lib/auth/local_data_cleaner.dart:1-15`, `docs/local-timeline-data-contract.md:22-29`).
- The current list query is unordered, so the repository must make the chosen ascending-id insertion order explicit (`lib/timeline/local_timeline_repository.dart:24-28`).
- S-02 owns opening a selected timeline; S-01 should not add placeholder navigation.

## What We're NOT Doing

- No `providerId` column, per-account filtering, migration, backend, synchronization, backup, or cloud storage.
- No timeline creation form or action from the empty state.
- No navigation into entries, entry display, camera/gallery picker, or timeline CRUD UI.
- No deletion or hiding of local data on sign-out.
- No changes to Google authentication provider contracts or credential configuration.

## Implementation Approach

Keep authentication as the gate for the signed-in path, but add a UI-local guest mode to `AuthGate`; guest mode does not create an `AuthSession` or alter the auth repository. Reuse `TimelineRepository` through dependency injection, expose a focused list screen/controller with loading, loaded, empty, and error/retry states, and pass an optional session/action label so signed-in and guest shells share the local list while presenting appropriate access actions. Make `listTimelines()` explicitly order by ascending timeline id, then verify repository and widget behavior with fakes and existing in-memory storage conventions.

## Critical Implementation Details

### State sequencing

Guest mode is a local UI access state, not an authentication success state: it must not be persisted as a Google session or sent through `AuthRepository`. When the user signs out, the auth session ends and the app returns to the signed-out choice screen; local timeline rows remain untouched.

### User experience spec

The empty state has no create action. A timeline row is display-only until S-02 defines navigation. A list read failure must remain inside the local-list view with retry rather than being converted into an empty list or an auth failure.

## Phase 1: Local access and deterministic list contract

### Overview

Establish the guest-entry state boundary and make the existing repository return timelines in the agreed insertion order without changing the storage schema.

### Changes Required:

#### 1. Access state and repository ordering

**File**: `lib/main.dart`

**Intent**: Add an explicit guest entry path alongside Google sign-in and make the signed-in shell/list dependencies use the app-owned repository interface where fakes are needed. Preserve the existing auth lifecycle and local-data retention behavior.

**Contract**: Guest access must be possible from the signed-out view, must not create an `AuthSession`, and must render the same local-list capability as a signed-in session. Sign-out must leave guest mode and return to the two-choice signed-out screen.

**File**: `lib/timeline/local_timeline_repository.dart`

**Intent**: Make the list order deterministic so the UI does not depend on SQLite’s unspecified row order.

**Contract**: `listTimelines()` returns all local timelines ordered by ascending database id, preserving the existing `Future<List<Timeline>>` interface and local installation scope.

### Success Criteria:

#### Automated Verification:

- Repository tests prove multiple timelines are returned in ascending id order.
- Existing auth and local-retention tests continue to pass without schema or cleanup changes.

#### Manual Verification:

- The signed-out screen visibly offers both Google sign-in and guest entry, and choosing guest does not invoke the auth repository.

**Implementation Note**: After completing this phase and automated verification, pause for human confirmation of the access-state behavior before proceeding.

---

## Phase 2: Timeline list screen

### Overview

Create the focused, testable screen that loads local timelines and presents the agreed states and display-only rows.

### Changes Required:

#### 1. Timeline list feature

**File**: `lib/timeline/timeline_list_screen.dart` (new)

**Intent**: Encapsulate asynchronous list loading and the user-visible loading, populated, empty, and retryable-error states instead of keeping data-fetching logic in the app bootstrap shell.

**Contract**: Accept a `TimelineRepository`, load via `listTimelines()`, render each timeline name in ascending-id order, show an empty message with no create action, and expose retry after a read failure. Rows remain non-navigable in S-01.

#### 2. Signed-in/guest presentation seam

**File**: `lib/main.dart`

**Intent**: Replace the debug-entry placeholder with the list screen while retaining sign-out for authenticated users and a sign-in action for guests.

**Contract**: Both access modes share the same repository/list screen; signed-in mode may show the session email and sign-out, while guest mode must not claim an authenticated identity and must offer a path to Google sign-in. No timeline creation or opening action is added.

### Success Criteria:

#### Automated Verification:

- Widget tests cover loading, populated, empty, error with retry, signed-in, and guest presentations using a fake `TimelineRepository`.
- Widget tests confirm timeline names render and no navigation/create action is exposed from a list row or empty state.

#### Manual Verification:

- A human can distinguish loading, an empty local store, and a read failure; retry reloads the list without signing out.
- A populated list is readable in both guest and signed-in modes, and the debug-entry control is no longer shown in this shell.

**Implementation Note**: After automated verification, pause for human confirmation of both guest and signed-in UI before proceeding.

---

## Phase 3: Integration and regression coverage

### Overview

Complete wiring and protect the boundaries between local data, authentication, and future timeline navigation.

### Changes Required:

#### 1. App integration and tests

**File**: `test/auth/auth_gate_test.dart`

**Intent**: Update existing gate coverage for the new guest choice and shared list handoff without weakening auth lifecycle assertions.

**Contract**: Tests must verify guest entry, signed-in list rendering, sign-out return to the two-choice screen, and preservation of existing auth error/retry behavior.

**File**: `test/timeline/timeline_list_test.dart` (new, or equivalent focused test file)

**Intent**: Keep list state behavior isolated from real credentials, platform storage, and Android configuration.

**Contract**: Use a handwritten repository fake and deterministic timeline values; retry must invoke the repository again and successful reload must replace the error state.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes.
- `flutter test` passes, including existing auth, retention, repository, and new widget tests.

#### Manual Verification:

- On a clean local store, guest entry shows the empty state; no unavailable create or seed action is required.
- With mock authentication available, signing out returns to the two-choice screen, and re-entering as guest shows the same empty local state without authenticated identity.

**Implementation Note**: Treat account-specific privacy as a documented future decision, not as a reason to route local rows through auth cleanup.

---

## Phase 4: Delivery verification

### Overview

Verify the complete Android-targeted flow and record that the change remains within the local MVP boundary.

### Changes Required:

#### 1. End-to-end smoke verification

**File**: `context/changes/signed-in-timeline-list/verification.md` (new during implementation if the workflow requires a verification log)

**Intent**: Record reproducible checks for both access modes and the Android build without introducing new product scope.

**Contract**: Verification covers guest entry, Google-authenticated entry where credentials are available, local list rendering, retry/empty states, sign-out retention, and a successful debug APK build.

### Success Criteria:

#### Automated Verification:

- `flutter build apk --debug` completes successfully.
- Generated files and static analysis remain clean after the final implementation.

#### Manual Verification:

- On a target Android device or emulator, the user can choose guest entry, see local timelines, sign in when configured, sign out, and re-enter as guest without losing local records.

**Implementation Note**: Google credentials are not required for automated tests; use mock auth mode where appropriate for the guest/auth shell smoke path.

---

## Testing Strategy

### Unit Tests:

- Verify explicit ascending-id repository ordering.
- Verify list state transitions for success, empty result, failure, and retry.
- Verify guest mode does not call Google auth and sign-out does not clear local data.

### Integration Tests:

- Exercise `AuthGate` with a fake auth repository and fake timeline repository for signed-out choice, guest list, signed-in list, and sign-out.

### Manual Testing Steps:

1. Launch with an empty local database and confirm both access buttons are present.
2. Continue as guest and confirm loading followed by the empty state with no create action.
3. If a separate local-data seed path is available, re-enter as guest and verify ascending creation/id order; otherwise record the populated-list check as deferred until such a path exists.
4. Force a repository read failure, use retry, and confirm the error does not log the user out.
5. Sign in or use mock auth, sign out, then re-enter as guest and confirm the signed-out choices, guest empty state, and absence of authenticated identity; populated-data retention remains deferred without a seed path.

## Performance Considerations

The roadmap targets small local data volume and low usage. One repository read and a standard Flutter list are sufficient; no caching, pagination, backend, or reactive database stream is required for S-01.

## Migration Notes

No schema migration is required. Existing local rows are displayed as-is, and the new explicit ordering does not alter stored data. The device-local/shared-across-accounts limitation remains documented and is not silently converted into account ownership.

## References

- `context/foundation/roadmap.md:38-47,113-126`
- `context/foundation/prd.md:43-64,76-85`
- `docs/local-timeline-data-contract.md:3-6,22-29`
- `lib/main.dart:54-189`
- `lib/timeline/timeline_repository.dart:5-16`
- `lib/timeline/local_timeline_repository.dart:24-28`
- `test/auth/auth_gate_test.dart:23-81`
- `test/timeline/local_timeline_repository_test.dart:25-35`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append — <commit sha> when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Local access and deterministic list contract

#### Automated

- [x] 1.1 Repository tests prove multiple timelines are returned in ascending id order.
- [x] 1.2 Existing auth and local-retention tests continue to pass without schema or cleanup changes.

#### Manual

- [ ] 1.3 The signed-out screen visibly offers both Google sign-in and guest entry, and choosing guest does not invoke the auth repository.

### Phase 2: Timeline list screen

#### Automated

- [x] 2.1 Widget tests cover loading, populated, empty, error with retry, signed-in, and guest presentations using a fake TimelineRepository.
- [x] 2.2 Widget tests confirm timeline names render and no navigation/create action is exposed from a list row or empty state.

#### Manual

- [x] 2.3 A human can distinguish loading, an empty local store, and a read failure; retry reloads the list without signing out. — 6921eb1
- [x] 2.4 A populated list is readable in both guest and signed-in modes, and the debug-entry control is no longer shown in this shell. — 6921eb1

### Phase 3: Integration and regression coverage

#### Automated

- [x] 3.1 `flutter analyze` passes.
- [x] 3.2 `flutter test` passes, including existing auth, retention, repository, and new widget tests.

#### Manual

- [x] 3.3 On a clean local store, guest entry shows the empty state; no unavailable create or seed action is required.
- [x] 3.4 With mock authentication available, signing out returns to the two-choice screen, and re-entering as guest shows the same empty local state without authenticated identity.

### Phase 4: Delivery verification

#### Automated

- [ ] 4.1 `flutter build apk --debug` completes successfully.
- [ ] 4.2 Generated files and static analysis remain clean after the final implementation.

#### Manual

- [ ] 4.3 On a target Android device or emulator, the user can choose guest entry, see local timelines, sign in when configured, sign out, and re-enter as guest without losing local records.
