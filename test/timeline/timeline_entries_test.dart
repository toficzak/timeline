import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_entries_screen.dart';
import 'package:timelines/timeline/timeline_repository.dart';

class _FakeTimelineRepository implements TimelineRepository {
  _FakeTimelineRepository(this.responses);

  final List<Future<List<TimelineEntry>>> responses;
  final List<int> requestedTimelineIds = <int>[];

  @override
  Future<List<TimelineEntry>> listEntries(int timelineId) {
    requestedTimelineIds.add(timelineId);
    return responses.removeAt(0);
  }

  @override
  Future<Timeline> createTimeline(String name) => throw UnimplementedError();

  @override
  Future<List<Timeline>> listTimelines() => throw UnimplementedError();

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
  Future<TimelineEntry> updateEntry(
    TimelineEntry entry, {
    File? photo,
    bool removePhoto = false,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteEntry(int timelineId, int entryId) =>
      throw UnimplementedError();
}

TimelineEntry entry({
  required int id,
  required int timelineId,
  required DateTime createdAt,
  required String description,
}) => TimelineEntry(
  id: id,
  timelineId: timelineId,
  createdAt: createdAt,
  description: description,
);

Widget entriesApp({
  required Timeline timeline,
  required TimelineRepository repository,
}) => MaterialApp(
  home: TimelineEntriesScreen(timeline: timeline, repository: repository),
);

void main() {
  const Timeline timeline = Timeline(id: 7, name: 'Summer');

  testWidgets('shows loading state and requests the selected timeline id', (
    tester,
  ) async {
    final Completer<List<TimelineEntry>> response =
        Completer<List<TimelineEntry>>();
    final _FakeTimelineRepository repository = _FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[response.future],
    );
    await tester.pumpWidget(
      entriesApp(timeline: timeline, repository: repository),
    );

    expect(find.text('Summer'), findsOneWidget);
    expect(find.text('Loading entries...'), findsOneWidget);
    expect(repository.requestedTimelineIds, <int>[7]);

    response.complete(const <TimelineEntry>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows an empty message without an add-entry action', (
    tester,
  ) async {
    final _FakeTimelineRepository repository = _FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[
        Future<List<TimelineEntry>>.value(const []),
      ],
    );
    await tester.pumpWidget(
      entriesApp(timeline: timeline, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('No entries yet.'), findsOneWidget);
    expect(find.textContaining('Add'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets(
    'renders selected entries chronologically and filters other timelines',
    (tester) async {
      final DateTime early = DateTime(2024, 1, 1);
      final DateTime late = DateTime(2024, 1, 2);
      final _FakeTimelineRepository repository = _FakeTimelineRepository(
        <Future<List<TimelineEntry>>>[
          Future<List<TimelineEntry>>.value(<TimelineEntry>[
            entry(id: 2, timelineId: 7, createdAt: late, description: 'Later'),
            entry(
              id: 3,
              timelineId: 99,
              createdAt: early,
              description: 'Other',
            ),
            entry(id: 1, timelineId: 7, createdAt: early, description: 'First'),
          ]),
        ],
      );
      await tester.pumpWidget(
        entriesApp(timeline: timeline, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
      expect(
        tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
        containsAllInOrder(<String?>['First', 'Later']),
      );
    },
  );

  testWidgets('shows read failure and retries', (tester) async {
    final Completer<List<TimelineEntry>> failure =
        Completer<List<TimelineEntry>>();
    final _FakeTimelineRepository repository = _FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[
        failure.future,
        Future<List<TimelineEntry>>.value(<TimelineEntry>[
          entry(
            id: 1,
            timelineId: 7,
            createdAt: DateTime(2024),
            description: 'Recovered',
          ),
        ]),
      ],
    );
    await tester.pumpWidget(
      entriesApp(timeline: timeline, repository: repository),
    );
    failure.completeError(StateError('read failed'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load entries. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Summer'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.requestedTimelineIds, <int>[7, 7]);
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('back affordance returns to the previous screen', (tester) async {
    final _FakeTimelineRepository repository = _FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[
        Future<List<TimelineEntry>>.value(const []),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: Text('Previous screen')),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (context) =>
              TimelineEntriesScreen(timeline: timeline, repository: repository),
        ),
      ),
    );
    // Push the screen so AppBar supplies its standard back affordance.
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (context) =>
            TimelineEntriesScreen(timeline: timeline, repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
  });
}
