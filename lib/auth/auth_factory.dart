import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'google_auth_repository.dart';
import 'mock_auth_repository.dart';

AuthRepository createAuthRepository() {
  const String mode = String.fromEnvironment('AUTH_MODE');
  if (kDebugMode && mode == 'mock') {
    return MockAuthRepository();
  }
  return GoogleAuthRepository();
}
