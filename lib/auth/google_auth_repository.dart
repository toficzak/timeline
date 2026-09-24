import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';
import 'auth_session.dart';
import 'local_data_cleaner.dart';

enum AuthFailureKind { provider, configuration, unavailable }

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.kind = AuthFailureKind.provider});

  final String message;
  final AuthFailureKind kind;

  @override
  String toString() => message;
}

class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository({
    GoogleSignIn? googleSignIn,
    LocalDataCleaner? localDataCleaner,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _localDataCleaner = localDataCleaner ?? const NoopLocalDataCleaner();

  final GoogleSignIn _googleSignIn;
  final LocalDataCleaner _localDataCleaner;
  AuthSession? _currentSession;

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  @override
  Future<AuthSession?> initialize() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
      final GoogleSignInAccount? account =
          await _googleSignIn.attemptLightweightAuthentication(
            reportAllExceptions: true,
          );
      _currentSession = account == null ? null : _sessionFor(account);
      return _currentSession;
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) {
        _currentSession = null;
        return null;
      }
      throw _mapError(error);
    } catch (error) {
      throw AuthFailure('Google Sign-In could not be initialized: $error');
    }
  }

  @override
  Future<AuthSession?> signIn() async {
    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      _currentSession = _sessionFor(account);
      return _currentSession;
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) {
        return null;
      }
      throw _mapError(error);
    } catch (error) {
      throw AuthFailure('Google Sign-In failed: $error');
    }
  }

  @override
  Future<void> signOut() async {
    final String? providerId = _currentSession?.providerId;
    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (error) {
      throw _mapError(error);
    } finally {
      _currentSession = null;
      if (providerId != null) {
        await _localDataCleaner.clearForAccount(providerId);
      }
    }
  }

  AuthSession _sessionFor(GoogleSignInAccount account) =>
      AuthSession(providerId: account.id, email: account.email);

  bool _isCancellation(GoogleSignInException error) =>
      error.code == GoogleSignInExceptionCode.canceled ||
      error.code == GoogleSignInExceptionCode.interrupted;

  AuthFailure _mapError(GoogleSignInException error) {
    final AuthFailureKind kind = switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError =>
        AuthFailureKind.configuration,
      GoogleSignInExceptionCode.uiUnavailable => AuthFailureKind.unavailable,
      _ => AuthFailureKind.provider,
    };
    return AuthFailure(
      error.description ?? 'Google Sign-In is temporarily unavailable.',
      kind: kind,
    );
  }
}
