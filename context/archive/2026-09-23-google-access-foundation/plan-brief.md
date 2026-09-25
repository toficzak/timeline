# Google access foundation — Plan Brief

> Full plan: `context/changes/google-access-foundation/plan.md`

## What & Why

This plan adds the first real access boundary to Timelines: a user can sign in
with Google on Android and enter a private app shell only after authentication.
It is the F-01 foundation required before the signed-in timeline list can be
built, while keeping the current MVP free of Firebase, backend services and
cloud photo storage.

## Starting Point

The repository is an untouched Flutter scaffold with a Hello World screen, no
auth dependency, no session model and no tests. Android still has the generated
placeholder identity `com.example.bootstrap_scaffold`, and OAuth credentials
have not been created.

## Desired End State

The app is presented as `Timelines` and uses the stable Android application ID
`com.github.toficzak.timelines`. A signed-out user sees a Google sign-in action;
successful login creates an app-owned session keyed by Google's stable account
ID, restores when possible, and gates the private shell. Cancellation is quiet,
other failures are retryable, and sign-out clears the user's local data boundary.
Daily debug work can use an explicit mock-auth mode, so a Google account is not
needed for every local restart; release builds always use real Google OAuth.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
| --- | --- | --- | --- |
| Authentication provider | Direct `google_sign_in`, no Firebase | It is the smallest provider path compatible with the current local-only, no-backend MVP. | Plan |
| Supported platform | Android only | The roadmap and infrastructure target Android/Google Play, avoiding unnecessary iOS/web OAuth work. | Plan |
| Product name | `Timelines` | This is the user-visible application name replacing the scaffold label. | Plan |
| Android application ID | `com.github.toficzak.timelines` | A stable technical identity is required before OAuth registration and future Play distribution. | Plan |
| Local session identity | Stable Google account ID plus optional displayed email | The ID is safer for ownership than a changeable email address, while email makes the session understandable. | Plan |
| Session restoration | Provider/plugin restoration at startup | It preserves normal Google session convenience without app-managed token storage. | Plan |
| Sign-out policy | Clear current user's local data boundary | This matches the explicit user decision and protects local data on a shared device. | Plan |
| Failure behavior | Quiet cancellation; clear retryable errors otherwise | It separates normal user choice from service/configuration problems. | Plan |
| OAuth setup | Manual checklist, no secrets in git | Google project access and signing fingerprints are human-owned external configuration. | Plan |
| Local testing | Explicit debug-only mock auth mode | Daily UI work should not depend on Google accounts, network or Play services, while release behavior remains real OAuth. | Plan |

## Scope

**In scope:**

- Direct Google Sign-In dependency and Android identity configuration.
- App-owned session, repository adapter, controller and auth-gated shell.
- Startup restoration, sign-in, sign-out, cancellation and retryable errors.
- Stable account ID and optional email display.
- Fake-provider unit/widget tests and real Android smoke-test checklist.
- Explicit debug mock mode for local development without repeated Google login.

**Out of scope:**

- Firebase, backend, server-side token verification and synchronization.
- Timeline list/data contract, entries, photos and AI comparison.
- iOS/web auth, additional Google scopes and production signing migration.
- Shipping or enabling mock authentication in release builds.

## Architecture / Approach

The Flutter UI talks to an app-owned `AuthController`, which depends on an
`AuthRepository`. A `GoogleSignIn` adapter translates provider accounts and
errors into app-owned session states, while a debug-only mock repository provides
a deterministic local session. The controller exposes loading, signed-out,
signed-in and error states to an auth gate; a cleanup seam is invoked on
sign-out for the later local timeline store.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Android identity and provider setup | Final app identity, dependency and safe OAuth checklist | Incorrect package ID or signing fingerprint blocks real login. |
| 2. Session contract and gated app flow | Testable auth lifecycle, mock mode and private app shell | Provider lifecycle/error states must not leak into UI incorrectly. |
| 3. Test and Android verification path | Automated coverage plus real-device confirmation | Mocks cannot prove external OAuth configuration. |

**Prerequisites:** Flutter/Android tooling, access to create or configure the
Google OAuth Android client, a Google-capable emulator/device, and the debug
certificate fingerprint. No backend or Firebase project is required.

**Estimated effort:** Approximately 3 focused implementation sessions plus one
manual Android configuration and smoke-test session, subject to Google OAuth
setup availability.

## Open Risks & Assumptions

- Direct client-side Google Sign-In identifies the account locally but is not a
  server security boundary; that must be revisited if a backend is introduced.
- The final release signing fingerprint is not yet available; the checklist
  must cover debug and release identities before Play distribution.
- The chosen clear-on-logout policy applies to future local timeline data; F-01
  has no existing data store, so the implementation must preserve an explicit
  cleanup seam rather than inventing a storage layer.
- OAuth testing depends on external Google configuration and Google Play
  services, so automated tests intentionally use a fake provider.
- The mock mode must be impossible in release builds; a configuration mistake
  that selects it in a shipped artifact would bypass the access requirement.

## Success Criteria (Summary)

- A configured Android user can sign in with Google, restart and restore the
  session, then sign out back to a protected signed-out screen.
- A developer can run the documented debug mock mode and reach the private shell
  without a Google account or network connection.
- Cancellation and service/network/configuration failures produce the agreed
  safe, understandable outcomes without crashes or token leakage.
- `flutter analyze`, `flutter test` and a debug APK build pass, and the manual
  OAuth checklist verifies the real provider flow on Android.
