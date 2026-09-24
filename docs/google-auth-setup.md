# Google Sign-In setup

This project uses direct Google Sign-In on Android. The app package ID is
`com.github.toficzak.timelines`.

## Local development

Use the deterministic mock provider while building the UI:

```bash
flutter run --dart-define=AUTH_MODE=mock
```

Mock mode is intended for local debug work only. It must not be used for a
release build, and it does not represent a real Google identity.

For the real direct Google Cloud flow, pass the Web application OAuth client ID
as `serverClientId` through a local Dart define:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id \
  --dart-define=AUTH_MODE=google
```

The Android OAuth client ID is not passed to Dart. Android selects it using the
application ID and signing certificate fingerprint registered below. The Web
client ID is an identifier, not a client secret; never commit client secrets,
keystores or private key material.

## OAuth registration checklist

1. Create or select the Google project used for the Android app.
2. Register an Android OAuth client for package ID
   `com.github.toficzak.timelines`.
3. Collect the SHA-1/SHA-256 fingerprints for the debug signing certificate
   used during local testing.
4. When release signing is configured, register the release certificate
   fingerprints separately. Debug and release identities are distinct.
5. Test on an Android emulator or device with Google Play services.
6. Keep OAuth secrets, keystores, private keys and certificate material outside
   this repository. Do not commit credential values or private fingerprints.

The debug OAuth client and signing fingerprints are environment configuration,
not application source. The real provider flow is verified manually after the
auth behavior phase is implemented.

## Android verification matrix

| Scenario | Build/configuration | Expected result | Diagnostics |
| --- | --- | --- | --- |
| Mock startup | `AUTH_MODE=mock` | Deterministic local session opens; no account picker | `flutter run --dart-define=AUTH_MODE=mock` |
| Real debug sign-in | Debug APK, Android OAuth client, Web client ID | Google account selection completes and private shell shows the email | `adb logcat` |
| Account-picker cancellation | Real debug configuration | App remains signed out without an alarming error | `adb logcat` |
| Missing network or Play services | Real debug configuration | Signed-out state or retryable error is shown; no crash | `adb logcat` |
| Restart after sign-in | Real debug configuration | Existing Google session is restored before the sign-in screen appears | `adb logcat` |
| Sign-out | Real debug configuration | Private shell disappears and local cleanup boundary runs | `adb logcat` |

Use mock mode for repeatable local UI checks. Use the real debug configuration
for OAuth checks; never put the Web client ID, secrets or keystores in source
control. For the real flow, install the debug APK with:

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
