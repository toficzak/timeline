import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timelines/auth/google_auth_repository.dart';
import 'package:timelines/auth/google_sign_in_client.dart';

class FakeGoogleSignInClient implements GoogleSignInClient {
  int initializeCalls = 0;
  GoogleAccount? restoredAccount;
  GoogleAccount? authenticatedAccount;
  Object? lightweightError;
  Object? authenticateError;

  @override
  Future<void> initialize({String? serverClientId}) async {
    initializeCalls++;
  }

  @override
  Future<GoogleAccount?> attemptLightweightAuthentication({
    bool reportAllExceptions = false,
  }) async {
    if (lightweightError != null) throw lightweightError!;
    return restoredAccount;
  }

  @override
  Future<GoogleAccount> authenticate() async {
    if (authenticateError != null) throw authenticateError!;
    return authenticatedAccount!;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  test('initializes the provider once when restoration is retried', () async {
    final FakeGoogleSignInClient client = FakeGoogleSignInClient();
    final GoogleAuthRepository repository = GoogleAuthRepository(client: client);

    await repository.initialize();
    await repository.initialize();

    expect(client.initializeCalls, 1);
  });

  test('maps account-picker cancellation to signed out', () async {
    final FakeGoogleSignInClient client = FakeGoogleSignInClient()
      ..authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    final GoogleAuthRepository repository = GoogleAuthRepository(client: client);

    expect(await repository.signIn(), isNull);
  });

  test('maps provider configuration errors to configuration failures', () async {
    final FakeGoogleSignInClient client = FakeGoogleSignInClient()
      ..lightweightError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
        description: 'configuration failure',
      );
    final GoogleAuthRepository repository = GoogleAuthRepository(client: client);

    await expectLater(
      repository.initialize(),
      throwsA(
        isA<AuthFailure>().having(
          (AuthFailure failure) => failure.kind,
          'kind',
          AuthFailureKind.configuration,
        ),
      ),
    );
  });

  test('does not expose provider exception details in failure messages', () async {
    final FakeGoogleSignInClient client = FakeGoogleSignInClient()
      ..authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'sensitive provider diagnostic',
      );
    final GoogleAuthRepository repository = GoogleAuthRepository(client: client);

    await expectLater(
      repository.signIn(),
      throwsA(
        isA<AuthFailure>().having(
          (AuthFailure failure) => failure.message,
          'message',
          isNot(contains('sensitive provider diagnostic')),
        ),
      ),
    );
  });
}
