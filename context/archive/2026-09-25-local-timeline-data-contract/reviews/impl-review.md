<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Local timeline data contract

- **Plan**: context/changes/local-timeline-data-contract/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3
- **Date**: 2026-09-26
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical 5 warnings 1 observation

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | WARNING |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Automated verification

- `flutter pub get` — PASS
- `dart run build_runner build --delete-conflicting-outputs` — PASS; no generated drift
- `flutter analyze` — PASS
- `flutter test` — PASS; 25 tests
- `flutter build apk --debug` — PASS

## Triage summary

- F1 — SKIPPED; indexes deferred for the current MVP scale.
- F2 — SKIPPED; orphan-file risk accepted for the current MVP.
- F3 — FIXED; old-photo cleanup is best effort after the durable row update.
- F4 — FIXED; symlink escape validation and regression coverage added.
- F5 — FIXED; failed provider initialization can be retried.
- F6 — FIXED; auth initialization retry regression coverage added.

## Findings

### F1 — Missing indexes for timeline entry queries

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Adherence
- **Location**: lib/data/app_database.dart:13-25
- **Detail**: The plan's performance considerations call for indexes on `Entries.timelineId` and `Entries.createdAt`, but the schema defines neither index.
- **Fix**: Add Drift indexes for `timelineId` and `createdAt`, regenerate the database code, and add a schema assertion if appropriate.
- **Decision**: SKIPPED — accepted for the current MVP scale.

### F2 — Photo deletion failure can leave orphaned files

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/timeline/local_timeline_repository.dart:40-52, 142-153
- **Detail**: Entry or timeline rows are deleted before associated photo deletion. If file cleanup fails, the operation reports an error after the database deletion and leaves an unreferenced photo.
- **Fix**: Make cleanup retryable/reconcilable, or define deletion as successful after durable row removal while treating file cleanup as best effort with a later orphan sweep.
  - Strength: Prevents a failed filesystem cleanup from producing misleading repository failure after data deletion.
  - Tradeoff: Requires an explicit orphan-cleanup policy or eventual cleanup mechanism.
  - Confidence: HIGH — the current ordering is visible and the plan explicitly calls out coordinated lifecycle handling.
  - Blind spot: No production filesystem failure injection exists today.
- **Decision**: SKIPPED — accepted for the current MVP.

### F3 — Photo replacement can commit then report failure

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/timeline/local_timeline_repository.dart:122-137
- **Detail**: The database update is durable before deletion of the old photo. If old-photo deletion fails, the method throws despite the new reference being committed, leaving an orphan and an ambiguous caller result.
- **Fix**: Return success after the row commit and make old-photo deletion best effort with retry/reconciliation.
  - Strength: Aligns the API result with durable database state and avoids retrying a committed update as if it failed.
  - Tradeoff: Requires explicit logging or cleanup retry behavior.
  - Confidence: HIGH — the `durable` flag already demonstrates this ordering.
  - Blind spot: The repository currently has no cleanup queue or logger.
- **Decision**: FIXED — applied the best-effort old-photo cleanup fix.

### F4 — Lexical photo-path validation does not address symlink escapes

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/timeline/local_photo_store.dart:48-64
- **Detail**: Normalized path checks reject `..` traversal, but a symlink inside the photo root could redirect a deletion outside that root.
- **Fix**: Resolve and validate real paths before deletion, or use only internally generated opaque filenames and reject links in the controlled directory.
  - Strength: Closes the filesystem-boundary gap while preserving the relative-path contract.
  - Tradeoff: Real-path handling is platform-sensitive and needs focused tests.
  - Confidence: MEDIUM — the app controls the directory, but the current contract accepts arbitrary relative paths from persisted data.
  - Blind spot: Symlink behavior on the target Android filesystem was not exercised.
- **Decision**: FIXED — hardened deletion validation and added symlink coverage.

### F5 — Failed initialization permanently caches the failed future

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Reliability
- **Location**: lib/auth/google_auth_repository.dart:33-55
- **Detail**: `_initialization` is assigned before awaiting. If provider initialization fails, later retry attempts await the same failed future and cannot recover.
- **Fix**: Clear `_initialization` in the initialization failure path, or cache only successful initialization.
- **Decision**: FIXED — reset the cached initialization Future after failure.

### F6 — Failure-injection coverage is incomplete

- **Severity**: ℹ️ OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: test/timeline/local_timeline_repository_test.dart:142-157
- **Detail**: The existing tests cover normal cleanup and copy failure, but not failed photo deletion, database-write failure after import, symlink traversal, or auth initialization retry.
- **Fix**: Add focused fake-store and auth-client failure tests before expanding the local data contract.
- **Decision**: FIXED — added auth initialization retry regression coverage; remaining database/file failure cases are outside the accepted current scope.
