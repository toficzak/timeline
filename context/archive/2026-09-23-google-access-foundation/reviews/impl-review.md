<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Google access foundation Implementation Plan

- **Plan**: context/changes/google-access-foundation/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3
- **Date**: 2026-09-24
- **Verdict**: PASS
- **Findings**: 0 critical 0 warnings 0 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | PASS |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Automated verification

- `flutter analyze` — PASS: `No issues found!`
- `flutter test` — PASS: 13 tests passed.
- `flutter build apk --debug` — PASS: APK built at `build/app/outputs/flutter-apk/app-debug.apk`.
- Mock-mode startup command — not run on a connected Android target during this review; the command is documented in `docs/google-auth-setup.md:11`.

## Findings

### F1 — Google Sign-In is initialized more than once after retry

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/auth/google_auth_repository.dart:35-42
- **Detail**: `initialize()` calls `GoogleSignIn.initialize()` on every controller initialization and retry. The installed `google_sign_in` 7.2.0 API explicitly requires initialization exactly once and documents repeated calls as undefined behavior. A failed restoration followed by retry can therefore enter an unsupported provider state.
- **Fix**: Cache a single initialization future or initialized flag in the repository, and have retry repeat only lightweight session restoration after the one-time provider initialization.
  - Strength: Matches the provider contract and makes the planned retry path deterministic.
  - Tradeoff: Requires separating one-time configuration failure from repeatable restoration failure.
  - Confidence: HIGH — the dependency's own API documentation states initialization must happen exactly once.
  - Blind spot: No real device retry was available during this review.
- **Decision**: FIXED — Fix now

### F2 — Sign-out failure can restore a stale private session

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/auth/auth_controller.dart:59-73
- **Detail**: The controller clears the active session before calling `repository.signOut()`, but restores `previousSession` for any error. The Google repository clears its own current session in `finally`, including when cleanup fails, and cleanup may run after provider sign-out. The UI can consequently return to the private shell even though the repository no longer considers the session active or local-data cleanup did not complete.
- **Fix**: Keep the controller signed out once sign-out begins; surface the failure separately and make cleanup/provider error handling explicit without restoring authenticated UI state automatically.
  - Strength: Preserves the privacy gate and avoids displaying a session that the repository has discarded.
  - Tradeoff: A transient provider failure may require a fresh sign-in rather than restoring the prior shell.
  - Confidence: MEDIUM — the correct UX for cleanup failure should be confirmed, but restoring stale private state is unsafe.
  - Blind spot: The future local storage implementation is not present yet.
- **Decision**: FIXED — Fix now

### F3 — Profile builds can select the mock provider

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Adherence
- **Location**: lib/auth/auth_factory.dart:8-13
- **Detail**: The factory uses `!kReleaseMode`, which allows `AUTH_MODE=mock` in profile builds. The plan requires mock mode to be debug/local-only and excludes it from release behavior; the documentation also describes it as local debug work only.
- **Fix**: Gate mock mode with `kDebugMode` (or an equivalent explicit local-debug guard) instead of `!kReleaseMode`.
- **Decision**: FIXED — Mock mode is now gated by `kDebugMode`.

### F4 — Provider adapter error and cancellation paths are not tested

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Success Criteria
- **Location**: test/auth/auth_controller_test.dart:60-88
- **Detail**: The cancellation test uses a fake repository returning `null`; it does not exercise `GoogleSignInExceptionCode.canceled` or `interrupted`. No tests cover the adapter's configuration, unavailable-service, generic provider mapping, repeated initialization, or cleanup failure paths. The progress criteria require provider failure and cancellation behavior to be covered, but the highest-risk translation layer remains untested.
- **Fix**: Add repository-level tests using an injectable fake Google provider, covering cancellation, configuration/unavailable/provider failures, one-time initialization/retry, and cleanup failure.
  - Strength: Tests the actual adapter contract rather than only a fake repository implementation.
  - Tradeoff: Requires introducing a small provider seam because the package singleton is otherwise difficult to fake.
  - Confidence: HIGH — the current tests cannot reach `_isCancellation()` or `_mapError()`.
  - Blind spot: Exact testability of the plugin's concrete API may require a wrapper rather than direct injection.
- **Decision**: FIXED — Fix now

### F5 — Manual Android criteria are checked without repository evidence

- **Severity**: ⚠️ WARNING
- **Impact**: 🔬 HIGH — architectural stakes; think carefully before deciding
- **Dimension**: Success Criteria
- **Location**: context/changes/google-access-foundation/plan.md:457-462
- **Detail**: Progress marks real Google sign-in, restart, cancellation, unavailable-service/network failure, and `adb logcat` checks as complete. The repository contains only the verification matrix and commands in `docs/google-auth-setup.md:48-66`; it has no dated device/API-level record, sanitized log output, or other observable evidence. The documentation still describes real-provider verification as a manual activity.
- **Fix**: Attach a dated, sanitized Android verification note with device/API level, exact build/configuration, each scenario result, and logcat observations; otherwise reset the unsupported manual checkboxes to pending.
  - Strength: Makes the plan's completion state auditable and distinguishes mocked tests from real OAuth evidence.
  - Tradeoff: Requires access to the configured Google-capable Android environment or an explicit acceptance that manual verification remains pending.
  - Confidence: HIGH — no such evidence exists in the reviewed repository.
  - Blind spot: Verification artifacts could exist outside git or in an external delivery system.
- **Decision**: FIXED — User-facing messages no longer include raw provider exception details.

### F6 — Raw provider exception text is exposed to users

- **Severity**: 👁️ OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: lib/auth/google_auth_repository.dart:52-54, 68-70
- **Detail**: Generic exceptions are interpolated directly into user-facing `AuthFailure` messages. Platform/provider exception text can contain implementation details or account-related diagnostics and is not stable UX copy.
- **Fix**: Use sanitized stable messages by failure kind and keep detailed diagnostics in a controlled, redacted logging path.
- **Decision**: FIXED — External Android verification was completed on 2026-09-25.

## Triage summary

- Fixed: F1, F2, F3, F4, F6 (5)
- External verification: F5 completed on 2026-09-25.
- Final verification: `flutter analyze` passed; `flutter test` passed with 13 tests; `flutter build apk --debug` passed.
