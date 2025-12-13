// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScoresTableTable extends ScoresTable
    with TableInfo<$ScoresTableTable, ScoresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _metadataUpdatedAtMeta = const VerificationMeta(
    'metadataUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> metadataUpdatedAt =
      GeneratedColumn<DateTime>(
        'metadata_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _fileUpdatedAtMeta = const VerificationMeta(
    'fileUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fileUpdatedAt =
      GeneratedColumn<DateTime>(
        'file_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _downloadedMeta = const VerificationMeta(
    'downloaded',
  );
  @override
  late final GeneratedColumn<bool> downloaded = GeneratedColumn<bool>(
    'downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("downloaded" IN (0, 1))',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FileType, String> fileType =
      GeneratedColumn<String>(
        'file_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<FileType>($ScoresTableTable.$converterfileType);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    createdAt,
    metadataUpdatedAt,
    fileUpdatedAt,
    downloaded,
    fileType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('metadata_updated_at')) {
      context.handle(
        _metadataUpdatedAtMeta,
        metadataUpdatedAt.isAcceptableOrUnknown(
          data['metadata_updated_at']!,
          _metadataUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('file_updated_at')) {
      context.handle(
        _fileUpdatedAtMeta,
        fileUpdatedAt.isAcceptableOrUnknown(
          data['file_updated_at']!,
          _fileUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('downloaded')) {
      context.handle(
        _downloadedMeta,
        downloaded.isAcceptableOrUnknown(data['downloaded']!, _downloadedMeta),
      );
    } else if (isInserting) {
      context.missing(_downloadedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoresTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoresTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      metadataUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}metadata_updated_at'],
      )!,
      fileUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}file_updated_at'],
      )!,
      downloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}downloaded'],
      )!,
      fileType: $ScoresTableTable.$converterfileType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}file_type'],
        )!,
      ),
    );
  }

  @override
  $ScoresTableTable createAlias(String alias) {
    return $ScoresTableTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FileType, String, String> $converterfileType =
      const EnumNameConverter<FileType>(FileType.values);
}

class ScoresTableData extends DataClass implements Insertable<ScoresTableData> {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;
  final bool downloaded;
  final FileType fileType;
  const ScoresTableData({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    required this.downloaded,
    required this.fileType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['metadata_updated_at'] = Variable<DateTime>(metadataUpdatedAt);
    map['file_updated_at'] = Variable<DateTime>(fileUpdatedAt);
    map['downloaded'] = Variable<bool>(downloaded);
    {
      map['file_type'] = Variable<String>(
        $ScoresTableTable.$converterfileType.toSql(fileType),
      );
    }
    return map;
  }

  ScoresTableCompanion toCompanion(bool nullToAbsent) {
    return ScoresTableCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      metadataUpdatedAt: Value(metadataUpdatedAt),
      fileUpdatedAt: Value(fileUpdatedAt),
      downloaded: Value(downloaded),
      fileType: Value(fileType),
    );
  }

  factory ScoresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoresTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      metadataUpdatedAt: serializer.fromJson<DateTime>(
        json['metadataUpdatedAt'],
      ),
      fileUpdatedAt: serializer.fromJson<DateTime>(json['fileUpdatedAt']),
      downloaded: serializer.fromJson<bool>(json['downloaded']),
      fileType: $ScoresTableTable.$converterfileType.fromJson(
        serializer.fromJson<String>(json['fileType']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'metadataUpdatedAt': serializer.toJson<DateTime>(metadataUpdatedAt),
      'fileUpdatedAt': serializer.toJson<DateTime>(fileUpdatedAt),
      'downloaded': serializer.toJson<bool>(downloaded),
      'fileType': serializer.toJson<String>(
        $ScoresTableTable.$converterfileType.toJson(fileType),
      ),
    };
  }

  ScoresTableData copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? metadataUpdatedAt,
    DateTime? fileUpdatedAt,
    bool? downloaded,
    FileType? fileType,
  }) => ScoresTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    createdAt: createdAt ?? this.createdAt,
    metadataUpdatedAt: metadataUpdatedAt ?? this.metadataUpdatedAt,
    fileUpdatedAt: fileUpdatedAt ?? this.fileUpdatedAt,
    downloaded: downloaded ?? this.downloaded,
    fileType: fileType ?? this.fileType,
  );
  ScoresTableData copyWithCompanion(ScoresTableCompanion data) {
    return ScoresTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      metadataUpdatedAt: data.metadataUpdatedAt.present
          ? data.metadataUpdatedAt.value
          : this.metadataUpdatedAt,
      fileUpdatedAt: data.fileUpdatedAt.present
          ? data.fileUpdatedAt.value
          : this.fileUpdatedAt,
      downloaded: data.downloaded.present
          ? data.downloaded.value
          : this.downloaded,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoresTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('metadataUpdatedAt: $metadataUpdatedAt, ')
          ..write('fileUpdatedAt: $fileUpdatedAt, ')
          ..write('downloaded: $downloaded, ')
          ..write('fileType: $fileType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    createdAt,
    metadataUpdatedAt,
    fileUpdatedAt,
    downloaded,
    fileType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoresTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.metadataUpdatedAt == this.metadataUpdatedAt &&
          other.fileUpdatedAt == this.fileUpdatedAt &&
          other.downloaded == this.downloaded &&
          other.fileType == this.fileType);
}

class ScoresTableCompanion extends UpdateCompanion<ScoresTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> metadataUpdatedAt;
  final Value<DateTime> fileUpdatedAt;
  final Value<bool> downloaded;
  final Value<FileType> fileType;
  final Value<int> rowid;
  const ScoresTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.fileType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresTableCompanion.insert({
    required String id,
    required String title,
    this.createdAt = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    required bool downloaded,
    required FileType fileType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       downloaded = Value(downloaded),
       fileType = Value(fileType);
  static Insertable<ScoresTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? metadataUpdatedAt,
    Expression<DateTime>? fileUpdatedAt,
    Expression<bool>? downloaded,
    Expression<String>? fileType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (metadataUpdatedAt != null) 'metadata_updated_at': metadataUpdatedAt,
      if (fileUpdatedAt != null) 'file_updated_at': fileUpdatedAt,
      if (downloaded != null) 'downloaded': downloaded,
      if (fileType != null) 'file_type': fileType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? metadataUpdatedAt,
    Value<DateTime>? fileUpdatedAt,
    Value<bool>? downloaded,
    Value<FileType>? fileType,
    Value<int>? rowid,
  }) {
    return ScoresTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      metadataUpdatedAt: metadataUpdatedAt ?? this.metadataUpdatedAt,
      fileUpdatedAt: fileUpdatedAt ?? this.fileUpdatedAt,
      downloaded: downloaded ?? this.downloaded,
      fileType: fileType ?? this.fileType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (metadataUpdatedAt.present) {
      map['metadata_updated_at'] = Variable<DateTime>(metadataUpdatedAt.value);
    }
    if (fileUpdatedAt.present) {
      map['file_updated_at'] = Variable<DateTime>(fileUpdatedAt.value);
    }
    if (downloaded.present) {
      map['downloaded'] = Variable<bool>(downloaded.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(
        $ScoresTableTable.$converterfileType.toSql(fileType.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('metadataUpdatedAt: $metadataUpdatedAt, ')
          ..write('fileUpdatedAt: $fileUpdatedAt, ')
          ..write('downloaded: $downloaded, ')
          ..write('fileType: $fileType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $ScoresTableTable scoresTable = $ScoresTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [scoresTable];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ScoresTableTableCreateCompanionBuilder =
    ScoresTableCompanion Function({
      required String id,
      required String title,
      Value<DateTime> createdAt,
      Value<DateTime> metadataUpdatedAt,
      Value<DateTime> fileUpdatedAt,
      required bool downloaded,
      required FileType fileType,
      Value<int> rowid,
    });
typedef $$ScoresTableTableUpdateCompanionBuilder =
    ScoresTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> createdAt,
      Value<DateTime> metadataUpdatedAt,
      Value<DateTime> fileUpdatedAt,
      Value<bool> downloaded,
      Value<FileType> fileType,
      Value<int> rowid,
    });

class $$ScoresTableTableFilterComposer
    extends Composer<_$Database, $ScoresTableTable> {
  $$ScoresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get metadataUpdatedAt => $composableBuilder(
    column: $table.metadataUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fileUpdatedAt => $composableBuilder(
    column: $table.fileUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FileType, FileType, String> get fileType =>
      $composableBuilder(
        column: $table.fileType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$ScoresTableTableOrderingComposer
    extends Composer<_$Database, $ScoresTableTable> {
  $$ScoresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get metadataUpdatedAt => $composableBuilder(
    column: $table.metadataUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fileUpdatedAt => $composableBuilder(
    column: $table.fileUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoresTableTableAnnotationComposer
    extends Composer<_$Database, $ScoresTableTable> {
  $$ScoresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get metadataUpdatedAt => $composableBuilder(
    column: $table.metadataUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fileUpdatedAt => $composableBuilder(
    column: $table.fileUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get downloaded => $composableBuilder(
    column: $table.downloaded,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FileType, String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);
}

class $$ScoresTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ScoresTableTable,
          ScoresTableData,
          $$ScoresTableTableFilterComposer,
          $$ScoresTableTableOrderingComposer,
          $$ScoresTableTableAnnotationComposer,
          $$ScoresTableTableCreateCompanionBuilder,
          $$ScoresTableTableUpdateCompanionBuilder,
          (
            ScoresTableData,
            BaseReferences<_$Database, $ScoresTableTable, ScoresTableData>,
          ),
          ScoresTableData,
          PrefetchHooks Function()
        > {
  $$ScoresTableTableTableManager(_$Database db, $ScoresTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoresTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<FileType> fileType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion(
                id: id,
                title: title,
                createdAt: createdAt,
                metadataUpdatedAt: metadataUpdatedAt,
                fileUpdatedAt: fileUpdatedAt,
                downloaded: downloaded,
                fileType: fileType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                required bool downloaded,
                required FileType fileType,
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion.insert(
                id: id,
                title: title,
                createdAt: createdAt,
                metadataUpdatedAt: metadataUpdatedAt,
                fileUpdatedAt: fileUpdatedAt,
                downloaded: downloaded,
                fileType: fileType,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScoresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ScoresTableTable,
      ScoresTableData,
      $$ScoresTableTableFilterComposer,
      $$ScoresTableTableOrderingComposer,
      $$ScoresTableTableAnnotationComposer,
      $$ScoresTableTableCreateCompanionBuilder,
      $$ScoresTableTableUpdateCompanionBuilder,
      (
        ScoresTableData,
        BaseReferences<_$Database, $ScoresTableTable, ScoresTableData>,
      ),
      ScoresTableData,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$ScoresTableTableTableManager get scoresTable =>
      $$ScoresTableTableTableManager(_db, _db.scoresTable);
}
