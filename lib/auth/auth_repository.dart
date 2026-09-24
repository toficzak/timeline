import 'auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> initialize();

  Future<AuthSession?> signIn();

  Future<void> signOut();
}
