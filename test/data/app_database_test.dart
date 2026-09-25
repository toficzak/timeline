import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/data/app_database.dart';

void main() {
  test('stores a timeline entry and its creation timestamp', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final int timelineId = await database
        .into(database.timelines)
        .insert(TimelinesCompanion.insert(name: 'Weekend'));
    final DateTime createdAt = DateTime.utc(2026, 9, 25, 12, 30);

    final int entryId = await database.into(database.entries).insert(
      EntriesCompanion.insert(
        timelineId: timelineId,
        createdAt: createdAt,
        description: '',
      ),
    );
    final Entry entry = await (database.select(database.entries)
          ..where((Entries table) => table.id.equals(entryId)))
        .getSingle();

    expect(entry.timelineId, timelineId);
    expect(entry.createdAt.toUtc(), createdAt);
    expect(entry.description, isEmpty);
    expect(entry.photoPath, isNull);

    await (database.delete(database.timelines)
          ..where((Timelines table) => table.id.equals(timelineId)))
        .go();

    expect(await database.select(database.entries).get(), isEmpty);
  });
}
