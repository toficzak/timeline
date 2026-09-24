import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'google_auth_repository.dart';
import 'local_data_cleaner.dart';
import 'mock_auth_repository.dart';

AuthRepository createAuthRepository({LocalDataCleaner? localDataCleaner}) {
  const String mode = String.fromEnvironment('AUTH_MODE');
  if (!kReleaseMode && mode == 'mock') {
    return MockAuthRepository(localDataCleaner: localDataCleaner);
  }
  return GoogleAuthRepository(localDataCleaner: localDataCleaner);
}
