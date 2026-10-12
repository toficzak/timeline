import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:timelines/data/app_database.dart' as db;
import 'package:timelines/timeline/local_timeline_repository.dart';
import 'package:timelines/timeline/local_photo_store.dart';
import 'package:timelines/timeline/timeline.dart';
import 'package:timelines/timeline/timeline_repository.dart';

void main() {
  late db.AppDatabase database;
  late FakePhotoStore photos;
  late LocalTimelineRepository repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    photos = FakePhotoStore();
    repository = LocalTimelineRepository(database, photos);
  });

  tearDown(() => database.close());

  test('performs timeline CRUD', () async {
    final Timeline created = await repository.createTimeline('Weekend');
    expect(await repository.listTimelines(), [created]);

    final Timeline renamed = created.copyWith(name: 'Weekends');
    expect(await repository.updateTimeline(renamed), renamed);
    expect(await repository.listTimelines(), [renamed]);

    await repository.deleteTimeline(created.id);
    expect(await repository.listTimelines(), isEmpty);
  });

  test('trims timeline names when creating and updating', () async {
    final Timeline created = await repository.createTimeline('  Weekend  ');
    expect(created.name, 'Weekend');

    final Timeline updated = await repository.updateTimeline(
      created.copyWith(name: '\tWeekends\n'),
    );
    expect(updated.name, 'Weekends');
    expect((await repository.listTimelines()).single.name, 'Weekends');
  });

  test(
    'rejects blank and whitespace-only timeline names without rows',
    () async {
      expect(
        () => repository.createTimeline(''),
        throwsA(isA<InvalidTimelineNameFailure>()),
      );
      expect(
        () => repository.createTimeline(' \t\n '),
        throwsA(isA<InvalidTimelineNameFailure>()),
      );

      final Timeline timeline = await repository.createTimeline('Valid');
      expect(
        () => repository.updateTimeline(timeline.copyWith(name: '  ')),
        throwsA(isA<InvalidTimelineNameFailure>()),
      );
      expect(await repository.listTimelines(), [timeline]);
    },
  );

  test('accepts duplicate normalized timeline names', () async {
    final Timeline first = await repository.createTimeline('Weekend');
    final Timeline second = await repository.createTimeline('  Weekend  ');

    expect(second.name, first.name);
    expect(await repository.listTimelines(), [first, second]);
  });

  test('rejects updates and deletes for missing timelines', () async {
    expect(
      () => repository.updateTimeline(const Timeline(id: 99, name: 'Missing')),
      throwsA(isA<TimelineNotFoundFailure>()),
    );
    expect(
      () => repository.deleteTimeline(99),
      throwsA(isA<TimelineNotFoundFailure>()),
    );
  });

  test(
    'timeline CRUD does not alter another timeline or its entries',
    () async {
      final Timeline first = await repository.createTimeline('First');
      final Timeline second = await repository.createTimeline('Second');
      final TimelineEntry secondEntry = await repository.createEntry(
        timelineId: second.id,
        description: 'keep me',
      );

      final Timeline renamed = await repository.updateTimeline(
        first.copyWith(name: '  Renamed  '),
      );
      await repository.deleteTimeline(first.id);

      expect(renamed.name, 'Renamed');
      expect(await repository.listTimelines(), [second]);
      final List<TimelineEntry> remainingEntries = await repository.listEntries(
        second.id,
      );
      expect(remainingEntries, hasLength(1));
      expect(remainingEntries.single.id, secondEntry.id);
      expect(remainingEntries.single.timelineId, secondEntry.timelineId);
      expect(remainingEntries.single.description, secondEntry.description);
    },
  );

  test('lists timelines in ascending database id order', () async {
    final Timeline first = await repository.createTimeline('First');
    final Timeline second = await repository.createTimeline('Second');
    final Timeline third = await repository.createTimeline('Third');

    await repository.deleteTimeline(second.id);
    final Timeline fourth = await repository.createTimeline('Fourth');

    expect((await repository.listTimelines()).map((timeline) => timeline.id), [
      first.id,
      third.id,
      fourth.id,
    ]);
  });

  test(
    'performs entry CRUD and keeps entries ordered by creation time',
    () async {
      final Timeline timeline = await repository.createTimeline('Journal');
      final TimelineEntry first = await repository.createEntry(
        timelineId: timeline.id,
        description: 'first',
      );
      final TimelineEntry second = await repository.createEntry(
        timelineId: timeline.id,
        description: 'second',
      );
      expect(
        (await repository.listEntries(timeline.id))
            .map((entry) => entry.description),
        ['first', 'second'],
      );

      final TimelineEntry updated = first.copyWith(description: 'updated');
      final TimelineEntry saved = await repository.updateEntry(updated);
      expect(saved.id, updated.id);
      expect(saved.timelineId, updated.timelineId);
      expect(saved.description, 'updated');
      expect(
        (await repository.listEntries(timeline.id)).first.description,
        'updated',
      );

      await repository.deleteEntry(timeline.id, second.id);
      expect(
        (await repository.listEntries(timeline.id))
            .map((entry) => entry.description),
        ['updated'],
      );
    },
  );

  test('stores at most one optional photo as a relative path', () async {
    final Timeline timeline = await repository.createTimeline('Photos');
    final TimelineEntry withoutPhoto = await repository.createEntry(
      timelineId: timeline.id,
      description: 'none',
    );
    expect(withoutPhoto.photoPath, isNull);

    final TimelineEntry withPhoto = await repository.createEntry(
      timelineId: timeline.id,
      description: 'one',
      photo: File('/source/one.jpg'),
    );
    expect(withPhoto.photoPath, 'entries/photo-1.jpg');
    final db.Entry row = await (database.select(
      database.entries,
    )..where((table) => table.id.equals(withPhoto.id))).getSingle();
    expect(row.photoPath, 'entries/photo-1.jpg');
    expect(withPhoto.photoPath, isNot(startsWith('/')));
  });

  test('normalizes an explicit creation timestamp to UTC', () async {
    final Timeline timeline = await repository.createTimeline('Timestamps');
    final DateTime timestamp = DateTime(2026, 9, 25, 12, 30);

    final TimelineEntry entry = await repository.createEntry(
      timelineId: timeline.id,
      description: 'captured',
      createdAt: timestamp,
    );
    final db.Entry row = await (database.select(
      database.entries,
    )..where((table) => table.id.equals(entry.id))).getSingle();

    expect(entry.createdAt.isUtc, isTrue);
    expect(entry.createdAt, timestamp.toUtc());
    expect(row.createdAt.toUtc(), timestamp.toUtc());
  });

  test('replacing and removing a photo clean up the old reference', () async {
    final Timeline timeline = await repository.createTimeline('Photos');
    final TimelineEntry entry = await repository.createEntry(
      timelineId: timeline.id,
      description: 'photo',
      photo: File('/source/one.jpg'),
    );
    final TimelineEntry replacement = await repository.updateEntry(
      entry.copyWith(description: 'replaced'),
      photo: File('/source/two.png'),
    );

    expect(replacement.photoPath, 'entries/photo-2.png');
    expect(photos.deleted, contains('entries/photo-1.jpg'));
    expect(photos.deleted, isNot(contains('entries/photo-2.png')));

    final TimelineEntry removed = await repository.updateEntry(
      replacement,
      removePhoto: true,
    );
    expect(removed.photoPath, isNull);
    expect(photos.deleted, contains('entries/photo-2.png'));
  });

  test('cleans up a photo when its entry or timeline is deleted', () async {
    final Timeline timeline = await repository.createTimeline('Photos');
    final TimelineEntry entry = await repository.createEntry(
      timelineId: timeline.id,
      description: 'entry',
      photo: File('/source/photo.jpg'),
    );
    await repository.deleteEntry(timeline.id, entry.id);
    expect(photos.deleted, contains(entry.photoPath));

    final TimelineEntry second = await repository.createEntry(
      timelineId: timeline.id,
      description: 'second',
      photo: File('/source/second.jpg'),
    );
    await repository.deleteTimeline(timeline.id);
    expect(photos.deleted, contains(second.photoPath));
    expect(await database.select(database.entries).get(), isEmpty);
  });

  test('rejects missing timelines for entry reads and creation', () async {
    expect(
      () => repository.listEntries(99),
      throwsA(isA<TimelineNotFoundFailure>()),
    );
    expect(
      () => repository.createEntry(timelineId: 99, description: 'orphan'),
      throwsA(isA<TimelineNotFoundFailure>()),
    );
  });

  test('does not leave a destination after a photo copy error', () async {
    final Directory root = await Directory(
      p.join(
        Directory.systemTemp.path,
        'timeline-photo-test-${DateTime.now().microsecondsSinceEpoch}',
      ),
    ).create();
    addTearDown(() => root.delete(recursive: true));
    final LocalPhotoStore store = LocalPhotoStore(root);

    expect(
      () => store.importPhoto(File(p.join(root.path, 'missing.jpg'))),
      throwsA(isA<FileSystemException>()),
    );
    expect(await Directory(p.join(root.path, 'entries')).exists(), isFalse);
  });

  test('rejects photo deletion through a symlink outside the root', () async {
    final Directory root = await Directory(
      p.join(
        Directory.systemTemp.path,
        'timeline-photo-test-${DateTime.now().microsecondsSinceEpoch}',
      ),
    ).create();
    final Directory entries = await Directory(p.join(root.path, 'entries'))
        .create();
    final File outside = File(p.join(root.parent.path, 'outside-photo.jpg'));
    await outside.writeAsString('private');
    await Link(p.join(entries.path, 'escape.jpg')).create(outside.path);
    addTearDown(() async {
      await root.delete(recursive: true);
      if (await outside.exists()) await outside.delete();
    });
    final LocalPhotoStore store = LocalPhotoStore(root);

    expect(
      () => store.deletePhoto('entries/escape.jpg'),
      throwsA(isA<InvalidPhotoPathFailure>()),
    );
    expect(await outside.exists(), isTrue);
  });

  test(
    'resolves an existing relative photo path below the store root',
    () async {
      final Directory root = await Directory(
        p.join(
          Directory.systemTemp.path,
          'timeline-photo-test-${DateTime.now().microsecondsSinceEpoch}',
        ),
      ).create();
      final File photo = File(p.join(root.path, 'entries', 'photo.jpg'));
      await photo.parent.create(recursive: true);
      await photo.writeAsString('photo');
      addTearDown(() => root.delete(recursive: true));
      final LocalPhotoStore store = LocalPhotoStore(root);

      final File resolved = await store.resolvePhoto('entries/photo.jpg');
      expect(resolved.path, photo.path);
    },
  );

  test('rejects traversal when resolving a photo path', () async {
    final Directory root = await Directory(
      p.join(
        Directory.systemTemp.path,
        'timeline-photo-test-${DateTime.now().microsecondsSinceEpoch}',
      ),
    ).create();
    addTearDown(() => root.delete(recursive: true));
    final LocalPhotoStore store = LocalPhotoStore(root);

    expect(
      () => store.resolvePhoto('../outside-photo.jpg'),
      throwsA(isA<InvalidPhotoPathFailure>()),
    );
  });

  test('deleting a timeline cascades to child rows', () async {
    final Timeline timeline = await repository.createTimeline('Cascade');
    await repository.createEntry(timelineId: timeline.id, description: 'child');
    await repository.deleteTimeline(timeline.id);

    expect(await database.select(database.entries).get(), isEmpty);
  });
}

// The fake deliberately models paths as relative values so these tests never
// need platform channels, credentials, or a real application directory.
class FakePhotoStore implements PhotoStore {
  int _sequence = 0;
  final List<String> deleted = [];

  @override
  Future<String> importPhoto(File source) async {
    _sequence++;
    return 'entries/photo-$_sequence${extension(source.path)}';
  }

  @override
  Future<File> resolvePhoto(String relativePath) =>
      Future<File>.value(File(relativePath));

  @override
  Future<void> deletePhoto(String relativePath) async {
    deleted.add(relativePath);
  }

  String extension(String path) => path.substring(path.lastIndexOf('.'));
}
