import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';
import 'auth_session.dart';
import 'google_sign_in_client.dart';

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
    GoogleSignInClient? client,
  }) : _client = client ?? PluginGoogleSignInClient();

  final GoogleSignInClient _client;
  Future<void>? _initialization;
  AuthSession? _currentSession;

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  @override
  Future<AuthSession?> initialize() async {
    try {
      _initialization ??= _client.initialize(
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
      await _initialization;
      final GoogleAccount? account =
          await _client.attemptLightweightAuthentication(
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
    } catch (_) {
      throw const AuthFailure(
        'Google Sign-In could not be initialized. Please try again.',
      );
    }
  }

  @override
  Future<AuthSession?> signIn() async {
    try {
      final GoogleAccount account = await _client.authenticate();
      _currentSession = _sessionFor(account);
      return _currentSession;
    } on GoogleSignInException catch (error) {
      if (_isCancellation(error)) {
        return null;
      }
      throw _mapError(error);
    } catch (_) {
      throw const AuthFailure('Google Sign-In failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } on GoogleSignInException catch (error) {
      throw _mapError(error);
    } finally {
      _currentSession = null;
    }
  }

  AuthSession _sessionFor(GoogleAccount account) =>
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
    final String message = switch (kind) {
      AuthFailureKind.configuration =>
        'Google Sign-In is not configured correctly. Please try again later.',
      AuthFailureKind.unavailable =>
        'Google Sign-In is unavailable right now. Please try again.',
      AuthFailureKind.provider =>
        'Google Sign-In failed. Please try again.',
    };
    return AuthFailure(message, kind: kind);
  }
}
