import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_detail_screen.dart';
import 'package:timelines/timeline/timeline_repository.dart';

class FakeTimelineRepository implements TimelineRepository {
  FakeTimelineRepository(this.responses);

  final List<Future<List<TimelineEntry>>> responses;
  int listCalls = 0;
  int? requestedTimelineId;

  @override
  Future<List<TimelineEntry>> listEntries(int timelineId) {
    requestedTimelineId = timelineId;
    return responses[listCalls++];
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

Widget detailApp(TimelineRepository repository) => MaterialApp(
  home: TimelineDetailScreen(
    repository: repository,
    timeline: const Timeline(id: 7, name: 'Reading log'),
  ),
);

TimelineEntry entry(int id, DateTime createdAt, String description) =>
    TimelineEntry(
      id: id,
      timelineId: 7,
      createdAt: createdAt,
      description: description,
    );

void main() {
  testWidgets('shows loading and then entries grouped oldest-first by local day', (
    tester,
  ) async {
    final Completer<List<TimelineEntry>> response =
        Completer<List<TimelineEntry>>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[response.future],
    );
    await tester.pumpWidget(detailApp(repository));

    expect(find.text('Loading entries...'), findsOneWidget);
    response.complete(<TimelineEntry>[
      entry(3, DateTime(2025, 1, 3, 9), 'Newest entry'),
      entry(1, DateTime(2025, 1, 1, 9), 'Oldest entry'),
      entry(2, DateTime(2025, 1, 1, 18), 'Same day entry'),
    ]);
    await tester.pumpAndSettle();

    final MaterialLocalizations localizations = MaterialLocalizations.of(
      tester.element(find.byType(Scaffold)),
    );
    final String firstDay = localizations.formatMediumDate(
      DateTime(2025, 1, 1),
    );
    final String secondDay = localizations.formatMediumDate(
      DateTime(2025, 1, 3),
    );
    expect(find.text(firstDay), findsOneWidget);
    expect(find.text(secondDay), findsOneWidget);
    expect(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
      containsAllInOrder(<String?>[
        firstDay,
        'Oldest entry',
        'Same day entry',
        secondDay,
        'Newest entry',
      ]),
    );
    expect(repository.requestedTimelineId, 7);
    expect(find.byIcon(Icons.photo), findsNothing);
    expect(find.text('Create timeline'), findsNothing);
  });

  testWidgets('shows a usable empty state and add-entry action area', (
    tester,
  ) async {
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[
        Future<List<TimelineEntry>>.value(const <TimelineEntry>[]),
      ],
    );
    await tester.pumpWidget(detailApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('No entries yet.'), findsOneWidget);
    expect(find.byTooltip('Add entry'), findsOneWidget);
    expect(find.text('Create timeline'), findsNothing);
  });

  testWidgets('shows read failure and retries', (tester) async {
    final Completer<List<TimelineEntry>> failure =
        Completer<List<TimelineEntry>>();
    final FakeTimelineRepository repository = FakeTimelineRepository(
      <Future<List<TimelineEntry>>>[
        failure.future,
        Future<List<TimelineEntry>>.value(<TimelineEntry>[
          entry(1, DateTime(2025, 1, 1), 'Recovered entry'),
        ]),
      ],
    );
    await tester.pumpWidget(detailApp(repository));
    failure.completeError(StateError('read failed'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load entries. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(find.text('Recovered entry'), findsOneWidget);
  });
}
