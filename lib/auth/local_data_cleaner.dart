abstract interface class LocalDataCleaner {
  Future<void> clearForAccount(String providerId);
}

class NoopLocalDataCleaner implements LocalDataCleaner {
  const NoopLocalDataCleaner();

  @override
  Future<void> clearForAccount(String providerId) async {}
}
