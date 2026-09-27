import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/auth_repository.dart';
import 'package:timelines/auth/auth_session.dart';
import 'package:timelines/main.dart';

class GateFakeRepository implements AuthRepository {
  GateFakeRepository(this.session);

  AuthSession? session;
  int initializeCalls = 0;
  int signInCalls = 0;

  @override
  Future<AuthSession?> initialize() async {
    initializeCalls++;
    return session;
  }

  @override
  Future<AuthSession?> signIn() async {
    signInCalls++;
    return session;
  }

  @override
  Future<void> signOut() async => session = null;
}

Widget appFor(AuthController controller) => MaterialApp(
  home: AuthGate(controller: controller),
);

void main() {
  const AuthSession session = AuthSession(
    providerId: 'google-123',
    email: 'person@example.com',
  );

  testWidgets('signed-out state shows Google sign-in', (tester) async {
    final AuthController controller = AuthController(
      GateFakeRepository(null),
    );
    await tester.pumpWidget(appFor(controller));
    await tester.pump();

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Your private timelines'), findsNothing);
  });

  testWidgets('guest entry does not invoke authentication', (tester) async {
    final GateFakeRepository repository = GateFakeRepository(null);
    final AuthController controller = AuthController(repository);
    await tester.pumpWidget(appFor(controller));
    await tester.pump();

    await tester.tap(find.text('Continue as guest'));
    await tester.pump();

    expect(find.text('Your private timelines'), findsOneWidget);
    expect(repository.signInCalls, 0);
    expect(repository.initializeCalls, 1);
  });

  testWidgets('signed-in state shows private shell', (tester) async {
    final AuthController controller = AuthController(
      GateFakeRepository(session),
    );
    await tester.pumpWidget(appFor(controller));
    await tester.pump();

    expect(find.text('Your private timelines\nperson@example.com'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
  });

  testWidgets('sign-out returns to signed-out state', (tester) async {
    final AuthController controller = AuthController(
      GateFakeRepository(session),
    );
    await tester.pumpWidget(appFor(controller));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Your private timelines'), findsNothing);
  });

  testWidgets('sign-in is enabled after sign-out completes', (tester) async {
    final AuthController controller = AuthController(
      GateFakeRepository(session),
    );
    await tester.pumpWidget(appFor(controller));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Sign in with Google'),
    );
    expect(button.onPressed, isNotNull);
  });
}
