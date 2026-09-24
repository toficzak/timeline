import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/auth_repository.dart';
import 'package:timelines/auth/auth_session.dart';
import 'package:timelines/main.dart';

class GateFakeRepository implements AuthRepository {
  GateFakeRepository(this.session);

  AuthSession? session;

  @override
  Future<AuthSession?> initialize() async => session;

  @override
  Future<AuthSession?> signIn() async => session;

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
