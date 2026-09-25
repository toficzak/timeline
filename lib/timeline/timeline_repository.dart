import 'dart:io';

import 'timeline.dart';

abstract interface class TimelineRepository {
  Future<Timeline> createTimeline(String name);
  Future<List<Timeline>> listTimelines();
  Future<Timeline> updateTimeline(Timeline timeline);
  Future<void> deleteTimeline(int timelineId);

  Future<TimelineEntry> createEntry({
    required int timelineId,
    required String description,
    File? photo,
  });
  Future<List<TimelineEntry>> listEntries(int timelineId);
  Future<TimelineEntry> updateEntry(
    TimelineEntry entry, {
    File? photo,
    bool removePhoto = false,
  });
  Future<void> deleteEntry(int timelineId, int entryId);
}

sealed class TimelineRepositoryFailure implements Exception {
  const TimelineRepositoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class TimelineNotFoundFailure extends TimelineRepositoryFailure {
  const TimelineNotFoundFailure(int timelineId)
      : super('Timeline $timelineId does not exist.');
}

class EntryNotFoundFailure extends TimelineRepositoryFailure {
  const EntryNotFoundFailure(int entryId)
      : super('Entry $entryId does not exist in the requested timeline.');
}

class InvalidPhotoPathFailure extends TimelineRepositoryFailure {
  const InvalidPhotoPathFailure(String path)
      : super('Invalid photo path: $path');
}
