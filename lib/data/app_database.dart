import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Timelines extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
}

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get timelineId => integer().customConstraint(
    'NOT NULL REFERENCES timelines(id) ON DELETE CASCADE',
  )();

  DateTimeColumn get createdAt => dateTime()();

  TextColumn get description => text()();

  TextColumn get photoPath => text().nullable()();
}

@DriftDatabase(tables: <Type>[Timelines, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) => migrator.createAll(),
    beforeOpen: (OpeningDetails details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(
  name: 'timelines',
  native: DriftNativeOptions(
    databaseDirectory: getApplicationSupportDirectory,
  ),
);
