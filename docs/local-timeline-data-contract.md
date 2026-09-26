# Local timeline data contract

Timelines are device-local data. The database and imported entry photos belong
to the installation, not to the currently authenticated Google account. They
are shared when different accounts use the same installation. The app does not
synchronize or back up these records or photos.

## Storage

The local Drift database contains two tables:

- `timelines`: an auto-incrementing ID and the timeline name.
- `entries`: a timeline ID, UTC creation time, description, and one nullable
  photo path.

Entries reference their parent timeline and are removed when that timeline is
deleted. An entry has at most one photo. Photo files are copied below the
app-controlled application support directory, while the database stores only a
relative path. The database and photo store are accessed through
`LocalTimelineRepository`, which is the seam for later timeline UI work.

## Authentication and retention

Authentication gates the UI but does not own local timeline data. Signing out
clears the active auth session only; it does not delete or hide the database or
the photo directory. Signing in again on the same installation exposes the
same local records. `LocalDataCleaner` remains available only as a compatibility
seam for future account-scoped stores and must not receive the timeline
repository or its photo store.

In mock mode, run with `--dart-define=AUTH_MODE=mock`. A developer can create an
entry through the debug repository path, sign out, sign in again, and verify
that it remains available.

## Lifecycle limitation and test boundary

This is local persistence, not a backup guarantee. Uninstalling the app,
clearing its data, or replacing the device can lose timeline records and
photos. Future synchronization, export, and backup decisions are outside this
contract.

Persistence tests use an in-memory Drift executor and fake photo stores. They
do not require credentials, network access, platform gallery access, or real
user files.
