import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/auth_repository.dart';
import 'package:timelines/auth/auth_session.dart';
import 'package:timelines/main.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_repository.dart';

class GateFakeRepository implements AuthRepository {
  GateFakeRepository(this.session);

  AuthSession? session;
  int initializeCalls = 0;
  int signInCalls = 0;
  Object? initializeError;

  @override
  Future<AuthSession?> initialize() async {
    initializeCalls++;
    if (initializeError != null) throw initializeError!;
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

class GateFakeTimelineRepository implements TimelineRepository {
  GateFakeTimelineRepository(this.timelines);

  final List<Timeline> timelines;
  int listCalls = 0;

  @override
  Future<List<Timeline>> listTimelines() async {
    listCalls++;
    return timelines;
  }

  @override
  Future<Timeline> createTimeline(String name) => throw UnimplementedError();

  @override
  Future<Timeline> updateTimeline(Timeline timeline) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTimeline(int timelineId) => throw UnimplementedError();

  @override
  Future<TimelineEntry> createEntry({
    required int timelineId,
    required String description,
    File? photo,
  }) => throw UnimplementedError();

  @override
  Future<List<TimelineEntry>> listEntries(int timelineId) =>
      throw UnimplementedError();

  @override
  Future<TimelineEntry> updateEntry(
    TimelineEntry entry, {
    File? photo,
    bool removePhoto = false,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEntry(int timelineId, int entryId) =>
      throw UnimplementedError();
}

Widget appFor(
  AuthController controller, {
  TimelineRepository? repository,
}) => MaterialApp(
  home: AuthGate(controller: controller, repository: repository),
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
    final GateFakeTimelineRepository timelines = GateFakeTimelineRepository(
      const <Timeline>[Timeline(id: 2, name: 'Shared timeline')],
    );
    final AuthController controller = AuthController(
      GateFakeRepository(session),
    );
    await tester.pumpWidget(appFor(controller, repository: timelines));
    await tester.pumpAndSettle();

    expect(find.text('Your private timelines\nperson@example.com'), findsOneWidget);
    expect(find.text('Shared timeline'), findsOneWidget);
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

  testWidgets('sign-out returns to choices and guest can reopen local list', (
    tester,
  ) async {
    final GateFakeTimelineRepository timelines = GateFakeTimelineRepository(
      const <Timeline>[Timeline(id: 1, name: 'Still local')],
    );
    final AuthController controller = AuthController(
      GateFakeRepository(session),
    );
    await tester.pumpWidget(appFor(controller, repository: timelines));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.text('Still local'), findsNothing);

    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Still local'), findsOneWidget);
    expect(find.text('person@example.com'), findsNothing);
    expect(timelines.listCalls, 2);
  });

  testWidgets('authentication error preserves retry behavior', (tester) async {
    final GateFakeRepository repository = GateFakeRepository(null)
      ..initializeError = StateError('provider unavailable');
    final AuthController controller = AuthController(repository);
    await tester.pumpWidget(appFor(controller));
    await tester.pump();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    repository.initializeError = null;
    repository.session = session;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Your private timelines\nperson@example.com'), findsOneWidget);
    expect(repository.initializeCalls, 2);
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
