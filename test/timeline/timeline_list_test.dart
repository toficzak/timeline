import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/auth_repository.dart';
import 'package:timelines/auth/auth_session.dart';
import 'package:timelines/main.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_list_screen.dart';
import 'package:timelines/timeline/timeline_repository.dart';

class FakeTimelineRepository implements TimelineRepository {
  FakeTimelineRepository(
    this.responses, {
    List<Future<Timeline>>? createResponses,
    List<Future<Timeline>>? updateResponses,
  }) : createResponses = createResponses ?? <Future<Timeline>>[],
       updateResponses = updateResponses ?? <Future<Timeline>>[];

  final List<Future<List<Timeline>>> responses;
  final List<Future<Timeline>> createResponses;
  final List<Future<Timeline>> updateResponses;
  int listCalls = 0;
  final List<String> createdNames = <String>[];
  final List<Timeline> updatedTimelines = <Timeline>[];

  @override
  Future<List<Timeline>> listTimelines() => responses[listCalls++];

  @override
  Future<Timeline> createTimeline(String name) {
    createdNames.add(name);
    if (createResponses.isNotEmpty) return createResponses.removeAt(0);
    return Future<Timeline>.value(Timeline(id: 100, name: name));
  }

  @override
  Future<Timeline> updateTimeline(Timeline timeline) {
    updatedTimelines.add(timeline);
    if (updateResponses.isNotEmpty) return updateResponses.removeAt(0);
    return Future<Timeline>.value(timeline);
  }

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

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.session);

  AuthSession? session;

  @override
  Future<AuthSession?> initialize() async => session;

  @override
  Future<AuthSession?> signIn() async => session;

  @override
  Future<void> signOut() async => session = null;
}

Widget listApp(TimelineRepository repository) => MaterialApp(
  home: Scaffold(body: TimelineListScreen(repository: repository)),
);

void main() {
  testWidgets('shows loading then timelines in ascending id order', (
    tester,
  ) async {
    final Completer<List<Timeline>> response = Completer<List<Timeline>>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[response.future],
    );
    await tester.pumpWidget(listApp(repository));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    response.complete(const <Timeline>[
      Timeline(id: 8, name: 'Later'),
      Timeline(id: 2, name: 'First'),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
      containsAllInOrder(<String?>['First', 'Later']),
    );
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('shows an explicit loading state during a slow read', (
    tester,
  ) async {
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.delayed(
          const Duration(milliseconds: 100),
          () => const <Timeline>[Timeline(id: 1, name: 'Loaded')],
        ),
      ],
    );
    await tester.pumpWidget(listApp(repository));

    expect(find.text('Loading timelines...'), findsOneWidget);
    expect(find.text('Loaded'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Loaded'), findsOneWidget);
  });

  testWidgets('shows an empty message with a create action', (tester) async {
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[]),
      ],
    );
    await tester.pumpWidget(listApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('No timelines yet.'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('creates a timeline and refreshes the list', (tester) async {
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[]),
        Future<List<Timeline>>.value(const <Timeline>[
          Timeline(id: 1, name: 'New name'),
        ]),
      ],
    );
    await tester.pumpWidget(listApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  New name  ');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();

    expect(repository.createdNames, <String>['New name']);
    expect(repository.listCalls, 2);
    expect(find.text('New name'), findsOneWidget);
  });

  testWidgets('validates blank names inline and supports cancellation', (
    tester,
  ) async {
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[]),
      ],
    );
    await tester.pumpWidget(listApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create').last);
    await tester.pump();

    expect(find.text('Timeline name cannot be empty.'), findsOneWidget);
    expect(repository.createdNames, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('No timelines yet.'), findsOneWidget);
  });

  testWidgets('edits a timeline and preserves input after an operation error', (
    tester,
  ) async {
    final Completer<Timeline> updateFailure = Completer<Timeline>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[
          Timeline(id: 1, name: 'Old name'),
        ]),
      ],
      updateResponses: <Future<Timeline>>[updateFailure.future],
    );
    await tester.pumpWidget(listApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit Old name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.tap(find.text('Save'));
    updateFailure.completeError(const InvalidTimelineNameFailure());
    await tester.pumpAndSettle();

    expect(find.text('Timeline name cannot be empty.'), findsOneWidget);
    expect(find.text('Renamed'), findsOneWidget);
    expect(find.text('Edit timeline'), findsOneWidget);
  });

  testWidgets('disables form controls while save is pending', (tester) async {
    final Completer<Timeline> save = Completer<Timeline>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[]),
        Future<List<Timeline>>.value(const <Timeline>[]),
      ],
      createResponses: <Future<Timeline>>[save.future],
    );
    await tester.pumpWidget(listApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pending');
    await tester.tap(find.text('Create').last);
    await tester.pump();

    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancel')).onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
      isNull,
    );
    save.complete(const Timeline(id: 1, name: 'Pending'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows an error and retries the read', (tester) async {
    final Completer<List<Timeline>> failure = Completer<List<Timeline>>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        failure.future,
        Future<List<Timeline>>.value(const <Timeline>[
          Timeline(id: 1, name: 'Recovered'),
        ]),
      ],
    );
    await tester.pumpWidget(listApp(repository));
    failure.completeError(StateError('read failed'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load timelines. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(
      find.text('Unable to load timelines. Please try again.'),
      findsNothing,
    );
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('signed-in presentation shares the list and keeps the email', (
    tester,
  ) async {
    final FakeTimelineRepository timelines = FakeTimelineRepository(
      <Future<List<Timeline>>>[
        Future<List<Timeline>>.value(const <Timeline>[
          Timeline(id: 1, name: 'Private'),
        ]),
      ],
    );
    final AuthController auth = AuthController(
      FakeAuthRepository(
        const AuthSession(providerId: 'google', email: 'person@example.com'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(controller: auth, repository: timelines),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Your private timelines\nperson@example.com'),
      findsOneWidget,
    );
    expect(find.text('Private'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
    expect(find.text('Create debug entry'), findsNothing);
  });

  testWidgets(
    'guest presentation shares the list without identity and offers sign-in',
    (tester) async {
      final FakeTimelineRepository timelines = FakeTimelineRepository(
        <Future<List<Timeline>>>[
          Future<List<Timeline>>.value(const <Timeline>[
            Timeline(id: 1, name: 'Shared locally'),
          ]),
        ],
      );
      final AuthController auth = AuthController(FakeAuthRepository(null));
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(controller: auth, repository: timelines),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue as guest'));
      await tester.pumpAndSettle();

      expect(find.text('Shared locally'), findsOneWidget);
      expect(find.text('Your private timelines'), findsOneWidget);
      expect(find.text('person@example.com'), findsNothing);
      expect(find.text('Sign in with Google'), findsOneWidget);
    },
  );
}
