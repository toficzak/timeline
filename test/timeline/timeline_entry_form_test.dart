import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/timeline/entry_photo_source.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_entry_form_screen.dart';
import 'package:timelines/timeline/timeline_repository.dart';

class _FakePhotoSource implements EntryPhotoSource {
  _FakePhotoSource({this.gallery});

  final Future<File?>? gallery;
  int galleryCalls = 0;
  int cameraCalls = 0;

  @override
  Future<File> captureFromCamera() {
    cameraCalls++;
    return Future<File>.value(File('/tmp/camera.png'));
  }

  @override
  Future<File?> pickFromGallery() {
    galleryCalls++;
    return gallery ?? Future<File?>.value(File('/tmp/gallery.png'));
  }
}

class _FakeRepository implements TimelineRepository {
  _FakeRepository({this.createResponse});

  final Future<TimelineEntry>? createResponse;
  int createCalls = 0;
  int? timelineId;
  String? description;
  File? photo;
  DateTime? createdAt;

  @override
  Future<TimelineEntry> createEntry({
    required int timelineId,
    required String description,
    File? photo,
    DateTime? createdAt,
  }) {
    createCalls++;
    this.timelineId = timelineId;
    this.description = description;
    this.photo = photo;
    this.createdAt = createdAt;
    return createResponse ??
        Future<TimelineEntry>.value(
          TimelineEntry(
            id: 1,
            timelineId: timelineId,
            createdAt: createdAt!,
            description: description,
            photoPath: photo?.path,
          ),
        );
  }

  @override
  Future<Timeline> createTimeline(String name) => throw UnimplementedError();

  @override
  Future<void> deleteEntry(int timelineId, int entryId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTimeline(int timelineId) => throw UnimplementedError();

  @override
  Future<List<TimelineEntry>> listEntries(int timelineId) =>
      throw UnimplementedError();

  @override
  Future<List<Timeline>> listTimelines() => throw UnimplementedError();

  @override
  Future<File> resolvePhoto(String relativePath) => throw UnimplementedError();

  @override
  Future<TimelineEntry> updateEntry(
    TimelineEntry entry, {
    File? photo,
    bool removePhoto = false,
  }) => throw UnimplementedError();

  @override
  Future<Timeline> updateTimeline(Timeline timeline) =>
      throw UnimplementedError();
}

Widget _app({
  required TimelineRepository repository,
  required EntryPhotoSource photoSource,
}) => MaterialApp(
  home: TimelineEntryFormScreen(
    timeline: const Timeline(id: 7, name: 'Summer'),
    repository: repository,
    photoSource: photoSource,
  ),
);

void main() {
  final Finder formScrollable = find.byType(Scrollable).first;

  testWidgets('shows the captured localized date and time first', (
    tester,
  ) async {
    final DateTime before = DateTime.now();
    await tester.pumpWidget(
      _app(repository: _FakeRepository(), photoSource: _FakePhotoSource()),
    );
    final DateTime after = DateTime.now();
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      tester.element(find.byType(TimelineEntryFormScreen)),
    );

    expect(
      find.text(localizations.formatFullDate(before.toLocal())),
      findsOneWidget,
    );
    expect(
      find.text(localizations.formatTimeOfDay(TimeOfDay.fromDateTime(after))),
      findsOneWidget,
    );
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Description (optional)'), findsOneWidget);
  });

  testWidgets('uses separate camera and gallery actions and supports removal', (
    tester,
  ) async {
    final _FakePhotoSource source = _FakePhotoSource();
    final _FakeRepository repository = _FakeRepository();
    await tester.pumpWidget(
      _app(repository: repository, photoSource: source),
    );

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(source.cameraCalls, 1);
    expect(find.text('Remove photo'), findsOneWidget);
    await tester.drag(formScrollable, const Offset(0, -250));
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Remove photo'))
        .onPressed!
        .call();
    await tester.pump();
    expect(find.text('Remove photo'), findsNothing);

    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(source.galleryCalls, 1);
    expect(find.text('Remove photo'), findsOneWidget);
    await tester.drag(formScrollable, const Offset(0, -250));
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
        .onPressed!
        .call();
    await tester.pumpAndSettle();
    expect(repository.photo?.path, '/tmp/gallery.png');
  });

  testWidgets('cancellation leaves the form unchanged and makes no save call', (
    tester,
  ) async {
    final _FakeRepository repository = _FakeRepository();
    await tester.pumpWidget(
      _app(repository: repository, photoSource: _FakePhotoSource()),
    );
    await tester.enterText(find.byType(TextField), 'Keep this text');
    await tester.drag(formScrollable, const Offset(0, -250));
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
        .onPressed!
        .call();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TimelineEntryFormScreen), findsNothing);
    expect(repository.createCalls, 0);
  });

  testWidgets('saves trimmed description with no photo and returns entry', (
    tester,
  ) async {
    final _FakeRepository repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                await Navigator.of(context).push<TimelineEntry>(
                  MaterialPageRoute<TimelineEntry>(
                    builder: (_) => _app(
                      repository: repository,
                      photoSource: _FakePhotoSource(),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  A note  ');
    await tester.drag(formScrollable, const Offset(0, -250));
    await tester.pumpAndSettle();
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
        .onPressed!
        .call();
    await tester.pumpAndSettle();

    expect(repository.timelineId, 7);
    expect(repository.description, 'A note');
    expect(repository.photo, isNull);
    expect(repository.createdAt, isNotNull);
    expect(find.byType(TimelineEntryFormScreen), findsNothing);
  });

  testWidgets(
    'preserves input after source and save failures and allows retry',
    (tester) async {
      final Completer<File?> gallery = Completer<File?>();
      final _FakePhotoSource source = _FakePhotoSource(gallery: gallery.future);
      final Completer<TimelineEntry> save = Completer<TimelineEntry>();
      final _FakeRepository repository = _FakeRepository(
        createResponse: save.future,
      );
      await tester.pumpWidget(
        _app(repository: repository, photoSource: source),
      );
      await tester.enterText(find.byType(TextField), '  preserved  ');

      await tester.drag(formScrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gallery'));
      gallery.completeError(StateError('gallery failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to select a photo. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  preserved  ',
      );

      await tester.drag(formScrollable, const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      save.completeError(StateError('save failed'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to save entry. Please try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '  preserved  ',
      );
    },
  );
}
