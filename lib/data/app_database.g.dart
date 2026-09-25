// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TimelinesTable extends Timelines
    with TableInfo<$TimelinesTable, Timeline> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimelinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timelines';
  @override
  VerificationContext validateIntegrity(
    Insertable<Timeline> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Timeline map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Timeline(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TimelinesTable createAlias(String alias) {
    return $TimelinesTable(attachedDatabase, alias);
  }
}

class Timeline extends DataClass implements Insertable<Timeline> {
  final int id;
  final String name;
  const Timeline({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TimelinesCompanion toCompanion(bool nullToAbsent) {
    return TimelinesCompanion(id: Value(id), name: Value(name));
  }

  factory Timeline.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Timeline(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Timeline copyWith({int? id, String? name}) =>
      Timeline(id: id ?? this.id, name: name ?? this.name);
  Timeline copyWithCompanion(TimelinesCompanion data) {
    return Timeline(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Timeline(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Timeline && other.id == this.id && other.name == this.name);
}

class TimelinesCompanion extends UpdateCompanion<Timeline> {
  final Value<int> id;
  final Value<String> name;
  const TimelinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TimelinesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
  }) : name = Value(name);
  static Insertable<Timeline> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TimelinesCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TimelinesCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimelinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timelineIdMeta = const VerificationMeta(
    'timelineId',
  );
  @override
  late final GeneratedColumn<int> timelineId = GeneratedColumn<int>(
    'timeline_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES timelines(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timelineId,
    createdAt,
    description,
    photoPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timeline_id')) {
      context.handle(
        _timelineIdMeta,
        timelineId.isAcceptableOrUnknown(data['timeline_id']!, _timelineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_timelineIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timelineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timeline_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final int timelineId;
  final DateTime createdAt;
  final String description;
  final String? photoPath;
  const Entry({
    required this.id,
    required this.timelineId,
    required this.createdAt,
    required this.description,
    this.photoPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timeline_id'] = Variable<int>(timelineId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      timelineId: Value(timelineId),
      createdAt: Value(createdAt),
      description: Value(description),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      timelineId: serializer.fromJson<int>(json['timelineId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      description: serializer.fromJson<String>(json['description']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timelineId': serializer.toJson<int>(timelineId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'description': serializer.toJson<String>(description),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  Entry copyWith({
    int? id,
    int? timelineId,
    DateTime? createdAt,
    String? description,
    Value<String?> photoPath = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    timelineId: timelineId ?? this.timelineId,
    createdAt: createdAt ?? this.createdAt,
    description: description ?? this.description,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      timelineId: data.timelineId.present
          ? data.timelineId.value
          : this.timelineId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('createdAt: $createdAt, ')
          ..write('description: $description, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timelineId, createdAt, description, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.timelineId == this.timelineId &&
          other.createdAt == this.createdAt &&
          other.description == this.description &&
          other.photoPath == this.photoPath);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<int> timelineId;
  final Value<DateTime> createdAt;
  final Value<String> description;
  final Value<String?> photoPath;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.timelineId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.description = const Value.absent(),
    this.photoPath = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required int timelineId,
    required DateTime createdAt,
    required String description,
    this.photoPath = const Value.absent(),
  }) : timelineId = Value(timelineId),
       createdAt = Value(createdAt),
       description = Value(description);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<int>? timelineId,
    Expression<DateTime>? createdAt,
    Expression<String>? description,
    Expression<String>? photoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timelineId != null) 'timeline_id': timelineId,
      if (createdAt != null) 'created_at': createdAt,
      if (description != null) 'description': description,
      if (photoPath != null) 'photo_path': photoPath,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? timelineId,
    Value<DateTime>? createdAt,
    Value<String>? description,
    Value<String?>? photoPath,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      timelineId: timelineId ?? this.timelineId,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timelineId.present) {
      map['timeline_id'] = Variable<int>(timelineId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('timelineId: $timelineId, ')
          ..write('createdAt: $createdAt, ')
          ..write('description: $description, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TimelinesTable timelines = $TimelinesTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [timelines, entries];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'timelines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TimelinesTableCreateCompanionBuilder =
    TimelinesCompanion Function({Value<int> id, required String name});
typedef $$TimelinesTableUpdateCompanionBuilder =
    TimelinesCompanion Function({Value<int> id, Value<String> name});

final class $$TimelinesTableReferences
    extends BaseReferences<_$AppDatabase, $TimelinesTable, Timeline> {
  $$TimelinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: $_aliasNameGenerator(db.timelines.id, db.entries.timelineId),
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.timelineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TimelinesTableFilterComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.timelineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TimelinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimelinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimelinesTable> {
  $$TimelinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.timelineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TimelinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimelinesTable,
          Timeline,
          $$TimelinesTableFilterComposer,
          $$TimelinesTableOrderingComposer,
          $$TimelinesTableAnnotationComposer,
          $$TimelinesTableCreateCompanionBuilder,
          $$TimelinesTableUpdateCompanionBuilder,
          (Timeline, $$TimelinesTableReferences),
          Timeline,
          PrefetchHooks Function({bool entriesRefs})
        > {
  $$TimelinesTableTableManager(_$AppDatabase db, $TimelinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimelinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimelinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimelinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TimelinesCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TimelinesCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimelinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<Timeline, $TimelinesTable, Entry>(
                      currentTable: table,
                      referencedTable: $$TimelinesTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TimelinesTableReferences(db, table, p0).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.timelineId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TimelinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimelinesTable,
      Timeline,
      $$TimelinesTableFilterComposer,
      $$TimelinesTableOrderingComposer,
      $$TimelinesTableAnnotationComposer,
      $$TimelinesTableCreateCompanionBuilder,
      $$TimelinesTableUpdateCompanionBuilder,
      (Timeline, $$TimelinesTableReferences),
      Timeline,
      PrefetchHooks Function({bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      required int timelineId,
      required DateTime createdAt,
      required String description,
      Value<String?> photoPath,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<int> id,
      Value<int> timelineId,
      Value<DateTime> createdAt,
      Value<String> description,
      Value<String?> photoPath,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TimelinesTable _timelineIdTable(_$AppDatabase db) =>
      db.timelines.createAlias(
        $_aliasNameGenerator(db.entries.timelineId, db.timelines.id),
      );

  $$TimelinesTableProcessedTableManager get timelineId {
    final $_column = $_itemColumn<int>('timeline_id')!;

    final manager = $$TimelinesTableTableManager(
      $_db,
      $_db.timelines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_timelineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  $$TimelinesTableFilterComposer get timelineId {
    final $$TimelinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableFilterComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$TimelinesTableOrderingComposer get timelineId {
    final $$TimelinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableOrderingComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  $$TimelinesTableAnnotationComposer get timelineId {
    final $$TimelinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.timelineId,
      referencedTable: $db.timelines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimelinesTableAnnotationComposer(
            $db: $db,
            $table: $db.timelines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool timelineId})
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timelineId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                timelineId: timelineId,
                createdAt: createdAt,
                description: description,
                photoPath: photoPath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timelineId,
                required DateTime createdAt,
                required String description,
                Value<String?> photoPath = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                timelineId: timelineId,
                createdAt: createdAt,
                description: description,
                photoPath: photoPath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({timelineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (timelineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.timelineId,
                                referencedTable: $$EntriesTableReferences
                                    ._timelineIdTable(db),
                                referencedColumn: $$EntriesTableReferences
                                    ._timelineIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool timelineId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TimelinesTableTableManager get timelines =>
      $$TimelinesTableTableManager(_db, _db.timelines);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
}
