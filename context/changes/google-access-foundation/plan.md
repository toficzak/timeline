# Google access foundation Implementation Plan

## Overview

Establish a private Google session for the Android Flutter app. The change adds the
official direct Google Sign-In integration behind an app-owned authentication
contract, gates the private app shell on that session, handles restoration,
sign-out, cancellation and failures, and provides automated seams plus a real
Android verification path.

## Current State Analysis

- `lib/main.dart:1-16` is only the default Material scaffold; there is no auth
  state, routing, session model or private-content gate.
- `pubspec.yaml:9-16` contains no authentication dependency and the repository
  has no `test/` directory.
- Android still uses `com.example.bootstrap_scaffold` as both namespace and
  application ID (`android/app/build.gradle.kts:7-20`) and
  `bootstrap_scaffold` as the visible application label
  (`android/app/src/main/AndroidManifest.xml:2-5`).
- The Android manifest has no auth-specific configuration and only debug/profile
  manifests currently declare `INTERNET`.
- The PRD requires Google-only private access and ownership of the user's own
  data (`context/foundation/prd.md:51-55,76-85`); the roadmap defines F-01 as
  starting and ending that private session (`context/foundation/roadmap.md:72-83`).
- There is no backend or Firebase decision. Infrastructure guidance explicitly
  keeps backend work outside this MVP (`context/foundation/infrastructure.md:13-17,74-76`).

## Desired End State

On Android, the app is named `Timelines` and uses the stable application ID
`com.github.toficzak.timelines`. A signed-out user sees a Google sign-in action
and cannot enter private app content; a successful sign-in produces an app-owned
session keyed by Google's stable account ID, with email available for display.

On startup, the app attempts to restore the provider session. Cancellation is a
quiet return to signed-out state, while unavailable services, network failures
and configuration failures produce a clear retryable message. Sign-out ends the
session and clears the current user's local data boundary without persisting
provider tokens in timeline data. The behavior is covered by fake-provider tests
and a manual Android OAuth check. Local debug runs can use a deterministic mock
session, so Google login is not required for every development restart.

### Key Discoveries:

- The official `google_sign_in` package currently documents the 7.x API shape,
  including singleton initialization and `authenticate()`; do not plan against
  the pre-7 `signIn()` API.
- An app-owned repository/controller seam is needed because no auth abstraction
  or test convention exists yet (`lib/main.dart:1-16`).
- OAuth registration must use the final package ID and signing fingerprints;
  the current release build still uses the debug signing configuration
  (`android/app/build.gradle.kts:32-37`).
- `google_sign_in` alone establishes client-side account recognition, not a
  server-verifiable application identity. Firebase, backend APIs and cloud
  synchronization remain outside this change.
- Daily local development needs a provider-independent path; forcing real OAuth
  for every UI iteration would make testing slow and dependent on network,
  Google Play services and account state.

## What We're NOT Doing

- No Firebase Authentication, Firebase project, backend, server-side token
  verification or cloud database.
- No iOS or web Google auth configuration; F-01 is Android-only.
- No timeline list, timeline storage schema, photo storage, entry UI or data
  synchronization; those belong to later roadmap items.
- No Contacts, Drive, Photos, Calendar or other Google API scopes.
- No custom OAuth implementation or manual token storage.
- No mock-auth bypass in release builds; the mock provider is debug/local-only.
- No production Play release signing migration beyond documenting the required
  fingerprint/configuration inputs; release signing is a separate delivery
  foundation.
- No secrets, OAuth client secrets, keystores or private fingerprints committed
  to the repository.

## Implementation Approach

Use `google_sign_in` as an infrastructure adapter and keep the rest of the app
dependent on an app-owned contract. Select the real or mock repository through a
debug-only configuration value such as `--dart-define=AUTH_MODE=mock`:

```text
AUTH_MODE=google -> GoogleSignIn adapter -┐
                                          ├-> AuthRepository -> AuthController/session state
AUTH_MODE=mock   -> MockAuthRepository  ──┘                         -> signed-out or private app shell
```

The session contains the stable provider ID and optional display email. The
controller owns loading, signed-in, signed-out and error states; the UI renders
those states and never calls the plugin directly. A local-data cleanup seam is
called during sign-out so later local timeline storage can enforce the agreed
clear-on-logout policy without coupling the auth UI to a storage package.

## Critical Implementation Details

Google provider initialization/restoration must complete before the app decides
whether to show the sign-in screen or private shell; otherwise a valid existing
session can briefly appear signed out. The manual OAuth checklist must capture
the Android package ID and debug/release certificate fingerprints, while keeping
credentials and keystores outside version control.

## Phase 1: Android identity and provider setup

### Overview

Make the Flutter package and Android target ready for the selected direct Google
Sign-In provider, and record the external setup steps needed for a real device
verification without placing secrets in source control.

### Changes Required:

#### 1. Flutter dependency, application metadata and local auth mode

**File**: `pubspec.yaml`

**Intent**: Add the official `google_sign_in` dependency, rename the package
metadata from the scaffold placeholder to the Timelines product identity, and
document the debug switch used to avoid real Google login during local work.

**Contract**: The dependency must resolve to the current compatible 7.x API
line; the package remains Android-focused and continues using Flutter's existing
test/lint dependencies. The mock mode is explicit, deterministic and excluded
from release behavior.

#### 2. Android package identity

**File**: `android/app/build.gradle.kts`

**Intent**: Replace the scaffold namespace and application ID with the stable
`com.github.toficzak.timelines` identity before OAuth registration.

**Contract**: `namespace` and `defaultConfig.applicationId` are both exactly
`com.github.toficzak.timelines`; existing SDK, JVM and version settings remain
unchanged.

#### 3. Android application label and runtime prerequisites

**File**: `android/app/src/main/AndroidManifest.xml`

**Intent**: Expose `Timelines` as the Android application name and ensure the
release/main manifest has the network capability required by the provider.

**Contract**: The application label is `Timelines`; auth-related manifest
changes are limited to the selected plugin's documented requirements and do not
introduce broad Google API permissions.

#### 4. OAuth setup checklist

**File**: `docs/google-auth-setup.md`

**Intent**: Document the human-owned steps for creating/registering the Google
OAuth Android client, using the final package ID, collecting debug and release
certificate fingerprints, and testing on an emulator/device with Google Play
services.

**Contract**: The checklist explicitly states that OAuth secrets, keystores and
private key material stay outside git, distinguishes local debug from release
identity, and records no real credential values.

### Success Criteria:

#### Automated Verification:

- `flutter pub get` resolves `google_sign_in` and updates `pubspec.lock`.
- `flutter analyze` passes with the renamed package metadata and dependency.
- `flutter build apk --debug` completes with application ID
  `com.github.toficzak.timelines`.
- A documented debug command can select mock auth without requiring a Google
  account or network access.

#### Manual Verification:

- The Android launcher and app information identify the app as `Timelines`.
- The OAuth checklist can be followed without exposing a secret or keystore in
  the repository.

**Implementation Note**: After automated checks pass, pause for human
confirmation that the package identity and OAuth setup checklist are correct
before proceeding to the auth behavior phase.

---

## Phase 2: Session contract and gated app flow

### Overview

Implement the app-owned auth boundary, provider adapter, session restoration,
sign-in/sign-out lifecycle and the minimal signed-out/private UI states.

### Changes Required:

#### 1. Authentication contracts and session value

**Files**: `lib/auth/auth_session.dart`, `lib/auth/auth_repository.dart`

**Intent**: Define the provider-independent session and operations that the UI
and future timeline features consume.

**Contract**: A session exposes the stable Google account ID and optional email;
the repository exposes initialization/restoration, sign-in, sign-out and a
session state stream or equivalent observable contract. Provider account types
must not escape this boundary.

#### 2. Google provider adapter and local-data cleanup seam

**Files**: `lib/auth/google_auth_repository.dart`,
`lib/auth/local_data_cleaner.dart`

**Intent**: Translate the current `google_sign_in` API into the app-owned
contract and provide the explicit clear-on-logout hook selected for the MVP.

**Contract**: Initialization/restoration occurs before the initial auth state is
published; cancellation maps to signed-out without an alarming failure; other
provider failures become typed/user-presentable auth errors. Sign-out clears the
provider session and invokes cleanup for the current stable account ID. No
access or ID token is persisted in timeline data.

#### 3. Mock provider for local development

**Files**: `lib/auth/mock_auth_repository.dart`, `lib/auth/auth_factory.dart`

**Intent**: Provide a deterministic local repository that creates a clearly
labelled test session, restores it across debug restarts when mock mode is
selected, and avoids all Google/network dependencies during UI development.

**Contract**: Mock mode is selected only through an explicit debug/local
configuration such as `--dart-define=AUTH_MODE=mock`; the factory must reject or
ignore that mode in release builds and use the real Google repository instead.
The mock account must use a stable non-production ID and must never be treated
as a real Google identity.

#### 4. Auth controller/state holder

**File**: `lib/auth/auth_controller.dart`

**Intent**: Coordinate repository lifecycle and expose deterministic loading,
signed-out, signed-in and retryable-error states to the widget tree.

**Contract**: The controller prevents sign-in re-entry while an operation is in
flight, supports retry after an error, retains the signed-out state after
cancellation, and clears the active session before returning to the signed-out
UI on sign-out.

#### 5. Signed-out and private app shell

**File**: `lib/main.dart` (plus focused widgets under `lib/auth/` if needed)

**Intent**: Replace the Hello World scaffold with a minimal auth gate: a
sign-in action, startup loading state, retryable error state, signed-in shell
placeholder and sign-out action.

**Contract**: Signed-out users cannot reach private content; signed-in content
shows the selected email when available and exposes sign-out. This phase does
not implement the timeline list; the private shell is the handoff point for
S-01.

### Success Criteria:

#### Automated Verification:

- Auth controller tests cover startup loading, restored session, successful
  sign-in, cancellation, provider failure, retry and sign-out.
- Widget tests verify that signed-out state shows sign-in, signed-in state shows
  the private shell, and sign-out returns to signed-out state.
- `flutter analyze` passes with no unhandled auth state or lint errors.
- `flutter test` passes with the fake repository and cleanup seam.
- Mock-mode startup and sign-in tests do not require Google credentials,
  network access or Google Play services.

#### Manual Verification:

- A user can start Google sign-in, complete it, see the signed-in shell and
  return to the shell after restarting the app with the session available.
- Cancelling account selection returns quietly to the sign-in screen; a
  configured failure shows a clear retry action.
- Signing out removes the private shell and triggers the agreed local-data
  cleanup boundary.
- Running the app in documented mock mode reaches the private shell without
  showing a Google account picker.

**Implementation Note**: After automated checks pass, pause for human
confirmation of the auth state transitions and user-facing messages before
proceeding to final Android verification.

---

## Phase 3: Test and Android verification path

### Overview

Complete the executable test seams and verify the real OAuth flow on the target
Android environment using the manual configuration checklist.

### Changes Required:

#### 1. Auth unit and widget tests

**Files**: `test/auth/auth_controller_test.dart`,
`test/auth/auth_gate_test.dart`

**Intent**: Lock down the session state machine and privacy gate without making
automated tests depend on Google accounts or network availability.

**Contract**: Tests use a fake `AuthRepository` and fake cleanup implementation;
they cover every state transition named in Phase 2 and assert that private
content is absent while signed out.

#### 2. Real-device verification notes

**File**: `docs/google-auth-setup.md`

**Intent**: Add a concise verification matrix for debug build, Google-capable
device/emulator, cancellation, no-network/service failure, restart/session
restore and sign-out.

**Contract**: The matrix records expected result and diagnostic command (for
example `adb logcat`) without requiring secrets or a backend. It distinguishes
mock-mode local checks from real Google OAuth checks.

#### 3. Repository verification

**Files**: `pubspec.lock`, generated plugin registration as produced by Flutter

**Intent**: Verify dependency resolution and generated Android integration while
keeping generated files consistent with the repository's normal Flutter flow.

**Contract**: No hand-edits to generated plugin registrants; dependency and
platform changes are reproducible from `pubspec.yaml` and the documented setup.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes.
- `flutter test` passes with all auth tests.
- `flutter build apk --debug` completes using the final application ID.
- The documented mock-mode command starts without a Google account or network.

#### Manual Verification:

- On a Google-capable Android device/emulator with configured OAuth, sign-in
  completes and the private shell is shown.
- In mock mode, the app starts with the deterministic test session and does not
  invoke the Google account picker.
- Restarting the app restores the session; signing out clears access and local
  user data according to the selected policy.
- Account-picker cancellation, unavailable Google services and network failure
  leave the app signed out and provide the documented user feedback.
- `adb logcat` shows no unexpected auth crash or token leakage during the
  scenarios above.

**Implementation Note**: This phase is complete only after the human Android
smoke test confirms the real provider flow; mocked tests alone do not prove
OAuth configuration.

---

## Testing Strategy

### Unit Tests:

- Test the auth controller with a fake repository for initialization,
  restoration, sign-in success, cancellation, failure, retry and sign-out.
- Test the local-data cleanup seam receives the stable account ID on sign-out.
- Test provider error mapping so cancellation is not displayed as a failure.

### Integration Tests:

- Use widget tests for the auth gate and private-content protection.
- Treat the real Google account-picker flow as manual Android integration
  verification because it requires external OAuth credentials and a
  Google-capable device or emulator.

### Manual Testing Steps:

1. Follow `docs/google-auth-setup.md` without committing credentials.
2. Run the documented mock-auth debug command and verify the private shell opens
   without a Google account or network.
3. Build and install the debug APK using the final package ID and real OAuth
   configuration.
4. Start sign-in and complete it with a test Google account.
5. Restart the app and verify real session restoration.
6. Cancel account selection and verify a quiet signed-out state.
7. Simulate unavailable network/services and verify a retryable message.
8. Sign out and verify private content is inaccessible and cleanup runs.

## Performance Considerations

The auth flow is startup- and user-action-bound; no polling or background
network loop is needed. Keep provider initialization single-shot and avoid
blocking the first Flutter frame beyond the explicit loading state.

## Migration Notes

There is no existing auth or user data to migrate. The placeholder Android
application ID is changed before OAuth registration, so no released package
compatibility is required. Future local timeline storage must use the session's
stable account ID and honor the clear-on-logout cleanup seam.

## References

- `context/foundation/prd.md:51-55,76-85`
- `context/foundation/roadmap.md:59-83,115-126`
- `context/foundation/tech-stack.md:1-29`
- `context/foundation/infrastructure.md:13-17,48-76`
- `android/app/build.gradle.kts:7-39`
- `android/app/src/main/AndroidManifest.xml:1-45`
- `pubspec.yaml:9-16`
- `lib/main.dart:1-16`
- Official package documentation: https://pub.dev/packages/google_sign_in

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Android identity and provider setup

#### Automated

- [ ] 1.1 `flutter pub get` resolves `google_sign_in` and updates `pubspec.lock`
- [ ] 1.2 `flutter analyze` passes with the renamed package metadata and dependency
- [ ] 1.3 `flutter build apk --debug` completes with application ID `com.github.toficzak.timelines`
- [ ] 1.4 A documented debug command can select mock auth without requiring a Google account or network access

#### Manual

- [ ] 1.5 The Android launcher and app information identify the app as `Timelines`
- [ ] 1.6 The OAuth checklist can be followed without exposing a secret or keystore in the repository

### Phase 2: Session contract and gated app flow

#### Automated

- [ ] 2.1 Auth controller tests cover startup loading, restored session, successful sign-in, cancellation, provider failure, retry and sign-out
- [ ] 2.2 Widget tests verify signed-out sign-in, signed-in private shell and sign-out return
- [ ] 2.3 `flutter analyze` passes with no unhandled auth state or lint errors
- [ ] 2.4 `flutter test` passes with the fake repository and cleanup seam
- [ ] 2.5 Mock-mode startup and sign-in tests do not require Google credentials, network access or Google Play services

#### Manual

- [ ] 2.6 A user can complete sign-in, see the signed-in shell and return to it after restart when the provider session is available
- [ ] 2.7 Cancellation returns quietly and a configured failure shows a clear retry action
- [ ] 2.8 Sign-out removes the private shell and triggers the local-data cleanup boundary
- [ ] 2.9 Running the app in documented mock mode reaches the private shell without showing a Google account picker

### Phase 3: Test and Android verification path

#### Automated

- [ ] 3.1 `flutter analyze` passes
- [ ] 3.2 `flutter test` passes with all auth tests
- [ ] 3.3 `flutter build apk --debug` completes using the final application ID
- [ ] 3.4 The documented mock-mode command starts without a Google account or network

#### Manual

- [ ] 3.5 Real Google sign-in completes on a configured Google-capable Android device or emulator
- [ ] 3.6 In mock mode, the app starts with the deterministic test session and does not invoke the Google account picker
- [ ] 3.7 Restart, sign-out, cancellation, unavailable services and network failure match the documented outcomes
- [ ] 3.8 `adb logcat` shows no unexpected auth crash or token leakage during verification
