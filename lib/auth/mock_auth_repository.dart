import 'auth_repository.dart';
import 'auth_session.dart';
import 'local_data_cleaner.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({LocalDataCleaner? localDataCleaner})
    : _localDataCleaner = localDataCleaner ?? const NoopLocalDataCleaner();

  static const AuthSession testSession = AuthSession(
    providerId: 'local-debug-account',
    email: 'local-debug@example.invalid',
  );

  final LocalDataCleaner _localDataCleaner;
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
    await _localDataCleaner.clearForAccount(testSession.providerId);
  }
}
