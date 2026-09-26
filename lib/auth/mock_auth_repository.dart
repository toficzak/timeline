import 'auth_repository.dart';
import 'auth_session.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  static const AuthSession testSession = AuthSession(
    providerId: 'local-debug-account',
    email: 'local-debug@example.invalid',
  );

  AuthSession? _session;

  @override
  Future<AuthSession?> initialize() async => _session ?? testSession;

  @override
  Future<AuthSession?> signIn() async {
    _session = testSession;
    return _session;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }
}
