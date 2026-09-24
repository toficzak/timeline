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
