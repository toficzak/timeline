import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'auth_session.dart';
import 'google_auth_repository.dart';

enum AuthStatus { loading, signedOut, signedIn, error }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.loading;
  AuthSession? _session;
  String? _errorMessage;
  bool _operationInFlight = false;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get operationInFlight => _operationInFlight;

  Future<void> initialize() async {
    if (_operationInFlight) return;
    _operationInFlight = true;
    _setState(AuthStatus.loading);
    try {
      _session = await _repository.initialize();
      _errorMessage = null;
      _setState(_session == null ? AuthStatus.signedOut : AuthStatus.signedIn);
    } catch (error) {
      _session = null;
      _setError(error);
    } finally {
      _operationInFlight = false;
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    if (_operationInFlight) return;
    _operationInFlight = true;
    try {
      final AuthSession? session = await _repository.signIn();
      _session = session;
      _errorMessage = null;
      _setState(session == null ? AuthStatus.signedOut : AuthStatus.signedIn);
    } catch (error) {
      _session = null;
      _setError(error);
    } finally {
      _operationInFlight = false;
      notifyListeners();
    }
  }

  Future<void> retry() => initialize();

  Future<void> signOut() async {
    if (_operationInFlight) return;
    _operationInFlight = true;
    final AuthSession? previousSession = _session;
    _session = null;
    _setState(AuthStatus.signedOut);
    try {
      await _repository.signOut();
      _errorMessage = null;
    } catch (error) {
      _session = previousSession;
      _setError(error);
    } finally {
      _operationInFlight = false;
      notifyListeners();
    }
  }

  void _setState(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(Object error) {
    _errorMessage = error is AuthFailure
        ? error.message
        : 'Something went wrong. Please try again.';
    _setState(AuthStatus.error);
  }
}
