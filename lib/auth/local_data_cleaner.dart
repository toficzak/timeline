/// Compatibility seam for stores that are owned by an authenticated account.
///
/// Device-local timelines and their photos must not be supplied here: signing
/// out does not remove or hide that data.
abstract interface class LocalDataCleaner {
  Future<void> clearForAccount(String providerId);
}

/// A no-op implementation for account-scoped cleanup that is not enabled.
class NoopLocalDataCleaner implements LocalDataCleaner {
  const NoopLocalDataCleaner();

  @override
  Future<void> clearForAccount(String providerId) async {}
}
