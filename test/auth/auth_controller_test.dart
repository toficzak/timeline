import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/auth_repository.dart';
import 'package:timelines/auth/auth_session.dart';
import 'package:timelines/auth/local_data_cleaner.dart';
import 'package:timelines/auth/mock_auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialSession, this.signInSession});

  AuthSession? initialSession;
  AuthSession? signInSession;
  Object? initializeError;
  Object? signInError;
  bool signedOut = false;

  @override
  Future<AuthSession?> initialize() async {
    if (initializeError != null) throw initializeError!;
    return initialSession;
  }

  @override
  Future<AuthSession?> signIn() async {
    if (signInError != null) throw signInError!;
    return signInSession;
  }

  @override
  Future<void> signOut() async => signedOut = true;
}

class RecordingCleaner implements LocalDataCleaner {
  String? clearedAccount;

  @override
  Future<void> clearForAccount(String providerId) async {
    clearedAccount = providerId;
  }
}

void main() {
  const AuthSession session = AuthSession(
    providerId: 'google-123',
    email: 'person@example.com',
  );

  test('starts loading, then restores a session', () async {
    final AuthController controller = AuthController(
      FakeAuthRepository(initialSession: session),
    );

    expect(controller.status, AuthStatus.loading);
    await controller.initialize();

    expect(controller.status, AuthStatus.signedIn);
    expect(controller.session, session);
  });

  test('signs in successfully and stays signed out on cancellation', () async {
    final FakeAuthRepository repository = FakeAuthRepository(
      signInSession: session,
    );
    final AuthController controller = AuthController(repository);
    await controller.initialize();
    await controller.signIn();
    expect(controller.status, AuthStatus.signedIn);

    repository.signInSession = null;
    await controller.signOut();
    await controller.signIn();
    expect(controller.status, AuthStatus.signedOut);
    expect(controller.session, isNull);
  });

  test('exposes provider failure and retries', () async {
    final FakeAuthRepository repository = FakeAuthRepository()
      ..initializeError = StateError('unavailable');
    final AuthController controller = AuthController(repository);
    await controller.initialize();
    expect(controller.status, AuthStatus.error);
    expect(controller.errorMessage, isNotNull);

    repository.initializeError = null;
    repository.initialSession = session;
    await controller.retry();
    expect(controller.status, AuthStatus.signedIn);
  });

  test('clears the active session before completing sign-out', () async {
    final FakeAuthRepository repository = FakeAuthRepository(
      initialSession: session,
    );
    final AuthController controller = AuthController(repository);
    await controller.initialize();
    await controller.signOut();

    expect(controller.status, AuthStatus.signedOut);
    expect(controller.session, isNull);
    expect(repository.signedOut, isTrue);
  });

  test('mock repository sends the stable account ID to cleanup', () async {
    final RecordingCleaner cleaner = RecordingCleaner();
    final AuthController controller = AuthController(
      MockAuthRepository(localDataCleaner: cleaner),
    );
    await controller.initialize();
    await controller.signOut();

    expect(cleaner.clearedAccount, MockAuthRepository.testSession.providerId);
  });
}
