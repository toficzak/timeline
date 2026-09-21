---
project: timelines
researched_at: 2026-09-20
recommended_platform: Google Play (Android)
runner_up: none
context_type: mvp
tech_stack:
  language: Dart
  framework: Flutter 3.47.5
  runtime: Android
---

## Recommendation

**Publish the MVP as a signed Android App Bundle through Google Play.**

No separate hosting or backend platform is selected for this MVP. This matches the declared Play Store target, small scale, low QPS, and the PRD decision that photos remain local. Google Play distributes the Android artifact; it does not provide application APIs, databases, or AI execution. The Google authentication and AI comparison requirements remain an explicit follow-up decision if they cannot be implemented without a backend or a client-safe managed service.

## Platform Comparison

Backend platforms were not compared as deployment targets because this MVP has no selected backend. Cloudflare Workers, Railway, Render, Vercel, Netlify, and Fly.io would add an operational surface that the current product decision does not require. The Android artifact is built with Flutter and uploaded to Play Console as an AAB; Play App Signing handles end-user signing after the upload configuration is completed.

### Shortlisted Platforms

None. Google Play is the selected distribution channel; a backend platform may be researched later as a separate infrastructure decision.

## Anti-Bias Cross-Check: Google Play / Android Only

### Devil's Advocate — Weaknesses

1. Local-only storage means uninstalling, losing, or replacing a phone can lose timeline data and photos.
2. Google login and AI comparison cannot safely depend on embedded private server credentials in the APK.
3. A Play release cannot repair a broken data model already stored on users' devices without an app update and migration path.
4. A personal Play Console account may require 12 opted-in closed-testers for 14 continuous days before production access.

### Pre-Mortem — How This Could Fail

The team built and uploaded the Flutter app successfully, but the MVP failed after release because “no backend” was treated as “no infrastructure decisions.” Photos and timeline records stayed only on one device, so a device reset erased the user's history. The planned Google login was postponed because the app had no server-side account model, while the AI comparison was never released because placing an API key in the APK would expose it. The Android application ID was left as `com.example.bootstrap_scaffold`, making the store identity unsuitable for the real product. Release signing was also left on the debug configuration, so the first production build could not follow a controlled key process. Finally, the team discovered too late that a new personal Play Console account needed a closed test with 12 testers continuously opted in for 14 days. The app was technically complete but not publishable as the promised product.

### Unknown Unknowns

- Whether the Google login and AI requirements are deferred, redesigned as local features, or moved to a managed client-safe service.
- The final permanent Android application ID and release signing ownership.
- Whether local photo storage satisfies users after backup, reinstall, and device migration scenarios.
- The Play Console account type and whether the 12-tester/14-day production gate applies.
- Which target API level and policy declarations will be required when the release is submitted.

## Operational Story

- **Preview deploys**: Use Flutter debug/release builds on a connected Android device or emulator; Play Console internal testing is the first distributable preview track.
- **Secrets**: Keep the upload keystore and `android/key.properties` outside version control. No backend secrets are part of this decision. Play App Signing owns the app-signing key after setup.
- **Rollback**: Halt or remove an unreleased Play release in Play Console. For a shipped update, publish a corrected higher `versionCode`; device-local data migrations must be handled by the app and do not roll back automatically.
- **Approval**: The agent may run checks and build artifacts. A human must own the signing key, Play Console declarations, release track, and production rollout.
- **Logs**: Use `flutter analyze`, `flutter test`, and `adb logcat` locally; inspect Android vitals and pre-launch reports in Play Console after upload. There are no backend runtime logs.

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|---|---|---:|---:|---|
| Local data loss on device replacement | Devil's advocate | M | H | Document local-only behavior and treat sync/backup as a separate product decision. |
| Auth and AI requirements conflict with no backend | Devil's advocate / Pre-mortem | H | H | Resolve the implementation path before claiming those requirements are complete. |
| Release still uses the debug signing config | Research finding | H | H | Configure a private upload keystore and Play App Signing before the first release. |
| Placeholder application ID reaches Play Console | Research finding | H | H | Replace `com.example.bootstrap_scaffold` before creating the app; Play package names are permanent. |
| Production access delayed by testing requirements | Unknown unknown | M | M | Confirm account type early and recruit at least 12 closed-testers if required. |

## Getting Started

1. Replace the placeholder application ID in `@android/app/build.gradle.kts` and app label in `@android/app/src/main/AndroidManifest.xml`.
2. Configure release signing; never commit the keystore or `android/key.properties`.
3. Run `flutter pub get`, `flutter analyze`, and available tests; the current repository has no Dart `test/` directory.
4. Build the release artifact with `flutter build appbundle --release`.
5. Create the app in Play Console, configure Play App Signing, upload the AAB to internal testing, then complete any required closed-test period before production.

## Out of Scope

This decision does not cover a custom backend, cloud synchronization, server-side AI, CI/CD automation, or production-scale architecture. It also does not resolve the product implementation of Google authentication; those require a new decision if they cannot remain client-only.

## Sources

- [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android)
- [Google Play: Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Google Play: Prepare and roll out a release](https://support.google.com/googleplay/android-developer/answer/9859348)
- [Google Play: Testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
