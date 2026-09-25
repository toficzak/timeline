/// The application-owned representation of a timeline.
class Timeline {
  const Timeline({required this.id, required this.name});

  final int id;
  final String name;

  Timeline copyWith({String? name}) => Timeline(id: id, name: name ?? this.name);

  @override
  bool operator ==(Object other) =>
      other is Timeline && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// The application-owned representation of an entry and its optional photo.
class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.timelineId,
    required this.createdAt,
    required this.description,
    this.photoPath,
  });

  final int id;
  final int timelineId;
  final DateTime createdAt;
  final String description;
  final String? photoPath;

  TimelineEntry copyWith({
    String? description,
    String? photoPath,
    bool clearPhotoPath = false,
  }) => TimelineEntry(
    id: id,
    timelineId: timelineId,
    createdAt: createdAt,
    description: description ?? this.description,
    photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
  );

  @override
  bool operator ==(Object other) =>
      other is TimelineEntry &&
      other.id == id &&
      other.timelineId == timelineId &&
      other.createdAt == createdAt &&
      other.description == description &&
      other.photoPath == photoPath;

  @override
  int get hashCode =>
      Object.hash(id, timelineId, createdAt, description, photoPath);
}

typedef Entry = TimelineEntry;
