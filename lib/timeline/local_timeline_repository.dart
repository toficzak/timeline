import 'dart:io';

import 'package:drift/drift.dart';
import 'package:timelines/data/app_database.dart' as db;

import 'local_photo_store.dart';
import 'timeline.dart';
import 'timeline_repository.dart';

class LocalTimelineRepository implements TimelineRepository {
  LocalTimelineRepository(this.database, this.photoStore);

  final db.AppDatabase database;
  final PhotoStore photoStore;

  @override
  Future<Timeline> createTimeline(String name) async {
    final int id = await database.into(database.timelines).insert(
      db.TimelinesCompanion.insert(name: name),
    );
    return Timeline(id: id, name: name);
  }

  @override
  Future<List<Timeline>> listTimelines() async {
    final List<db.Timeline> rows = await (database.select(database.timelines)
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();
    return rows.map((row) => Timeline(id: row.id, name: row.name)).toList();
  }

  @override
  Future<Timeline> updateTimeline(Timeline timeline) async {
    final int count = await (database.update(database.timelines)
          ..where((table) => table.id.equals(timeline.id)))
        .write(db.TimelinesCompanion(name: Value(timeline.name)));
    if (count == 0) throw TimelineNotFoundFailure(timeline.id);
    return timeline;
  }

  @override
  Future<void> deleteTimeline(int timelineId) async {
    final List<db.Entry> entries = await (database.select(database.entries)
          ..where((table) => table.timelineId.equals(timelineId)))
        .get();
    final int count = await (database.delete(database.timelines)
          ..where((table) => table.id.equals(timelineId)))
        .go();
    if (count == 0) throw TimelineNotFoundFailure(timelineId);
    for (final db.Entry entry in entries) {
      final String? path = entry.photoPath;
      if (path != null) await photoStore.deletePhoto(path);
    }
  }

  @override
  Future<TimelineEntry> createEntry({
    required int timelineId,
    required String description,
    File? photo,
  }) async {
    await _requireTimeline(timelineId);
    String? path;
    try {
      if (photo != null) path = await photoStore.importPhoto(photo);
      final DateTime createdAt = DateTime.now().toUtc();
      final int id = await database.into(database.entries).insert(
        db.EntriesCompanion.insert(
          timelineId: timelineId,
          createdAt: createdAt,
          description: description,
          photoPath: Value(path),
        ),
      );
      return TimelineEntry(
        id: id,
        timelineId: timelineId,
        createdAt: createdAt,
        description: description,
        photoPath: path,
      );
    } catch (_) {
      if (path != null) await photoStore.deletePhoto(path);
      rethrow;
    }
  }

  @override
  Future<List<TimelineEntry>> listEntries(int timelineId) async {
    await _requireTimeline(timelineId);
    final List<db.Entry> rows = await (database.select(database.entries)
          ..where((table) => table.timelineId.equals(timelineId))
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
    return rows.map(_entry).toList();
  }

  @override
  Future<TimelineEntry> updateEntry(
    TimelineEntry entry, {
    File? photo,
    bool removePhoto = false,
  }) async {
    await _requireTimeline(entry.timelineId);
    final db.Entry? existing = await (database.select(database.entries)
          ..where((table) =>
              table.id.equals(entry.id) &
              table.timelineId.equals(entry.timelineId)))
        .getSingleOrNull();
    if (existing == null) throw EntryNotFoundFailure(entry.id);

    String? newPath = existing.photoPath;
    if (removePhoto) newPath = null;
    bool durable = false;
    try {
      if (photo != null) newPath = await photoStore.importPhoto(photo);
      final TimelineEntry updated = TimelineEntry(
        id: entry.id,
        timelineId: entry.timelineId,
        createdAt: existing.createdAt,
        description: entry.description,
        photoPath: newPath,
      );
      await (database.update(database.entries)
            ..where((table) => table.id.equals(entry.id)))
          .write(db.EntriesCompanion(
            description: Value(updated.description),
            photoPath: Value(newPath),
          ));
      durable = true;
      if (existing.photoPath != null && existing.photoPath != newPath) {
        try {
          await photoStore.deletePhoto(existing.photoPath!);
        } catch (_) {
          // The database now points to the durable replacement.
        }
      }
      return updated;
    } catch (_) {
      if (!durable && photo != null && newPath != existing.photoPath) {
        await photoStore.deletePhoto(newPath!);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(int timelineId, int entryId) async {
    await _requireTimeline(timelineId);
    final db.Entry? entry = await (database.select(database.entries)
          ..where((table) =>
              table.id.equals(entryId) & table.timelineId.equals(timelineId)))
        .getSingleOrNull();
    if (entry == null) throw EntryNotFoundFailure(entryId);
    await (database.delete(database.entries)
          ..where((table) => table.id.equals(entryId)))
        .go();
    if (entry.photoPath != null) await photoStore.deletePhoto(entry.photoPath!);
  }

  Future<void> _requireTimeline(int id) async {
    final db.Timeline? timeline = await (database.select(database.timelines)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    if (timeline == null) throw TimelineNotFoundFailure(id);
  }

  TimelineEntry _entry(db.Entry row) => TimelineEntry(
    id: row.id,
    timelineId: row.timelineId,
    createdAt: row.createdAt.toUtc(),
    description: row.description,
    photoPath: row.photoPath,
  );
}
