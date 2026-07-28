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
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recentTimeMeta = const VerificationMeta(
    'recentTime',
  );
  @override
  late final GeneratedColumn<DateTime> recentTime = GeneratedColumn<DateTime>(
    'recent_time',
    aliasedName,
    false,
    generatedAs: GeneratedAs(
      CustomExpression(
        "MAX(${lastOpened.name}, ${metadataUpdatedAt.name}, ${fileUpdatedAt.name})",
      ),
      false,
    ),
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastOpenedMeta = const VerificationMeta(
    'lastOpened',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpened = GeneratedColumn<DateTime>(
    'last_opened',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
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
        clientDefault: () => DateTime.now().toUtc(),
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
        clientDefault: () => DateTime.now().toUtc(),
      );
  static const VerificationMeta _writtenAtMeta = const VerificationMeta(
    'writtenAt',
  );
  @override
  late final GeneratedColumn<DateTime> writtenAt = GeneratedColumn<DateTime>(
    'written_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataUploadedMeta = const VerificationMeta(
    'metadataUploaded',
  );
  @override
  late final GeneratedColumn<bool> metadataUploaded = GeneratedColumn<bool>(
    'metadata_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("metadata_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fileUploadedMeta = const VerificationMeta(
    'fileUploaded',
  );
  @override
  late final GeneratedColumn<bool> fileUploaded = GeneratedColumn<bool>(
    'file_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("file_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _fileDownloadedMeta = const VerificationMeta(
    'fileDownloaded',
  );
  @override
  late final GeneratedColumn<bool> fileDownloaded = GeneratedColumn<bool>(
    'file_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("file_downloaded" IN (0, 1))',
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
  static const VerificationMeta _annotationsMeta = const VerificationMeta(
    'annotations',
  );
  @override
  late final GeneratedColumn<String> annotations = GeneratedColumn<String>(
    'annotations',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    composer,
    notes,
    searchText,
    recentTime,
    lastOpened,
    metadataUpdatedAt,
    fileUpdatedAt,
    writtenAt,
    metadataUploaded,
    fileUploaded,
    fileDownloaded,
    fileType,
    annotations,
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
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    if (data.containsKey('recent_time')) {
      context.handle(
        _recentTimeMeta,
        recentTime.isAcceptableOrUnknown(data['recent_time']!, _recentTimeMeta),
      );
    }
    if (data.containsKey('last_opened')) {
      context.handle(
        _lastOpenedMeta,
        lastOpened.isAcceptableOrUnknown(data['last_opened']!, _lastOpenedMeta),
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
    if (data.containsKey('written_at')) {
      context.handle(
        _writtenAtMeta,
        writtenAt.isAcceptableOrUnknown(data['written_at']!, _writtenAtMeta),
      );
    }
    if (data.containsKey('metadata_uploaded')) {
      context.handle(
        _metadataUploadedMeta,
        metadataUploaded.isAcceptableOrUnknown(
          data['metadata_uploaded']!,
          _metadataUploadedMeta,
        ),
      );
    }
    if (data.containsKey('file_uploaded')) {
      context.handle(
        _fileUploadedMeta,
        fileUploaded.isAcceptableOrUnknown(
          data['file_uploaded']!,
          _fileUploadedMeta,
        ),
      );
    }
    if (data.containsKey('file_downloaded')) {
      context.handle(
        _fileDownloadedMeta,
        fileDownloaded.isAcceptableOrUnknown(
          data['file_downloaded']!,
          _fileDownloadedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileDownloadedMeta);
    }
    if (data.containsKey('annotations')) {
      context.handle(
        _annotationsMeta,
        annotations.isAcceptableOrUnknown(
          data['annotations']!,
          _annotationsMeta,
        ),
      );
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
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      recentTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recent_time'],
      )!,
      lastOpened: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened'],
      )!,
      metadataUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}metadata_updated_at'],
      )!,
      fileUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}file_updated_at'],
      )!,
      writtenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}written_at'],
      ),
      metadataUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}metadata_uploaded'],
      )!,
      fileUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}file_uploaded'],
      )!,
      fileDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}file_downloaded'],
      )!,
      fileType: $ScoresTableTable.$converterfileType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}file_type'],
        )!,
      ),
      annotations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotations'],
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
  final String? composer;
  final String? notes;
  final String searchText;
  final DateTime recentTime;
  final DateTime lastOpened;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;
  final DateTime? writtenAt;
  final bool metadataUploaded;
  final bool fileUploaded;
  final bool fileDownloaded;
  final FileType fileType;
  final String? annotations;
  const ScoresTableData({
    required this.id,
    required this.title,
    this.composer,
    this.notes,
    required this.searchText,
    required this.recentTime,
    required this.lastOpened,
    required this.metadataUpdatedAt,
    required this.fileUpdatedAt,
    this.writtenAt,
    required this.metadataUploaded,
    required this.fileUploaded,
    required this.fileDownloaded,
    required this.fileType,
    this.annotations,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['search_text'] = Variable<String>(searchText);
    map['last_opened'] = Variable<DateTime>(lastOpened);
    map['metadata_updated_at'] = Variable<DateTime>(metadataUpdatedAt);
    map['file_updated_at'] = Variable<DateTime>(fileUpdatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['metadata_uploaded'] = Variable<bool>(metadataUploaded);
    map['file_uploaded'] = Variable<bool>(fileUploaded);
    map['file_downloaded'] = Variable<bool>(fileDownloaded);
    {
      map['file_type'] = Variable<String>(
        $ScoresTableTable.$converterfileType.toSql(fileType),
      );
    }
    if (!nullToAbsent || annotations != null) {
      map['annotations'] = Variable<String>(annotations);
    }
    return map;
  }

  ScoresTableCompanion toCompanion(bool nullToAbsent) {
    return ScoresTableCompanion(
      id: Value(id),
      title: Value(title),
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      searchText: Value(searchText),
      lastOpened: Value(lastOpened),
      metadataUpdatedAt: Value(metadataUpdatedAt),
      fileUpdatedAt: Value(fileUpdatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      metadataUploaded: Value(metadataUploaded),
      fileUploaded: Value(fileUploaded),
      fileDownloaded: Value(fileDownloaded),
      fileType: Value(fileType),
      annotations: annotations == null && nullToAbsent
          ? const Value.absent()
          : Value(annotations),
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
      composer: serializer.fromJson<String?>(json['composer']),
      notes: serializer.fromJson<String?>(json['notes']),
      searchText: serializer.fromJson<String>(json['searchText']),
      recentTime: serializer.fromJson<DateTime>(json['recentTime']),
      lastOpened: serializer.fromJson<DateTime>(json['lastOpened']),
      metadataUpdatedAt: serializer.fromJson<DateTime>(
        json['metadataUpdatedAt'],
      ),
      fileUpdatedAt: serializer.fromJson<DateTime>(json['fileUpdatedAt']),
      writtenAt: serializer.fromJson<DateTime?>(json['writtenAt']),
      metadataUploaded: serializer.fromJson<bool>(json['metadataUploaded']),
      fileUploaded: serializer.fromJson<bool>(json['fileUploaded']),
      fileDownloaded: serializer.fromJson<bool>(json['fileDownloaded']),
      fileType: $ScoresTableTable.$converterfileType.fromJson(
        serializer.fromJson<String>(json['fileType']),
      ),
      annotations: serializer.fromJson<String?>(json['annotations']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String?>(composer),
      'notes': serializer.toJson<String?>(notes),
      'searchText': serializer.toJson<String>(searchText),
      'recentTime': serializer.toJson<DateTime>(recentTime),
      'lastOpened': serializer.toJson<DateTime>(lastOpened),
      'metadataUpdatedAt': serializer.toJson<DateTime>(metadataUpdatedAt),
      'fileUpdatedAt': serializer.toJson<DateTime>(fileUpdatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'metadataUploaded': serializer.toJson<bool>(metadataUploaded),
      'fileUploaded': serializer.toJson<bool>(fileUploaded),
      'fileDownloaded': serializer.toJson<bool>(fileDownloaded),
      'fileType': serializer.toJson<String>(
        $ScoresTableTable.$converterfileType.toJson(fileType),
      ),
      'annotations': serializer.toJson<String?>(annotations),
    };
  }

  ScoresTableData copyWith({
    String? id,
    String? title,
    Value<String?> composer = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? searchText,
    DateTime? recentTime,
    DateTime? lastOpened,
    DateTime? metadataUpdatedAt,
    DateTime? fileUpdatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? metadataUploaded,
    bool? fileUploaded,
    bool? fileDownloaded,
    FileType? fileType,
    Value<String?> annotations = const Value.absent(),
  }) => ScoresTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    notes: notes.present ? notes.value : this.notes,
    searchText: searchText ?? this.searchText,
    recentTime: recentTime ?? this.recentTime,
    lastOpened: lastOpened ?? this.lastOpened,
    metadataUpdatedAt: metadataUpdatedAt ?? this.metadataUpdatedAt,
    fileUpdatedAt: fileUpdatedAt ?? this.fileUpdatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    metadataUploaded: metadataUploaded ?? this.metadataUploaded,
    fileUploaded: fileUploaded ?? this.fileUploaded,
    fileDownloaded: fileDownloaded ?? this.fileDownloaded,
    fileType: fileType ?? this.fileType,
    annotations: annotations.present ? annotations.value : this.annotations,
  );
  @override
  String toString() {
    return (StringBuffer('ScoresTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('notes: $notes, ')
          ..write('searchText: $searchText, ')
          ..write('recentTime: $recentTime, ')
          ..write('lastOpened: $lastOpened, ')
          ..write('metadataUpdatedAt: $metadataUpdatedAt, ')
          ..write('fileUpdatedAt: $fileUpdatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('metadataUploaded: $metadataUploaded, ')
          ..write('fileUploaded: $fileUploaded, ')
          ..write('fileDownloaded: $fileDownloaded, ')
          ..write('fileType: $fileType, ')
          ..write('annotations: $annotations')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    composer,
    notes,
    searchText,
    recentTime,
    lastOpened,
    metadataUpdatedAt,
    fileUpdatedAt,
    writtenAt,
    metadataUploaded,
    fileUploaded,
    fileDownloaded,
    fileType,
    annotations,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoresTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.notes == this.notes &&
          other.searchText == this.searchText &&
          other.recentTime == this.recentTime &&
          other.lastOpened == this.lastOpened &&
          other.metadataUpdatedAt == this.metadataUpdatedAt &&
          other.fileUpdatedAt == this.fileUpdatedAt &&
          other.writtenAt == this.writtenAt &&
          other.metadataUploaded == this.metadataUploaded &&
          other.fileUploaded == this.fileUploaded &&
          other.fileDownloaded == this.fileDownloaded &&
          other.fileType == this.fileType &&
          other.annotations == this.annotations);
}

class ScoresTableCompanion extends UpdateCompanion<ScoresTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> composer;
  final Value<String?> notes;
  final Value<String> searchText;
  final Value<DateTime> lastOpened;
  final Value<DateTime> metadataUpdatedAt;
  final Value<DateTime> fileUpdatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> metadataUploaded;
  final Value<bool> fileUploaded;
  final Value<bool> fileDownloaded;
  final Value<FileType> fileType;
  final Value<String?> annotations;
  final Value<int> rowid;
  const ScoresTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.notes = const Value.absent(),
    this.searchText = const Value.absent(),
    this.lastOpened = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.metadataUploaded = const Value.absent(),
    this.fileUploaded = const Value.absent(),
    this.fileDownloaded = const Value.absent(),
    this.fileType = const Value.absent(),
    this.annotations = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresTableCompanion.insert({
    required String id,
    required String title,
    this.composer = const Value.absent(),
    this.notes = const Value.absent(),
    required String searchText,
    this.lastOpened = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.metadataUploaded = const Value.absent(),
    this.fileUploaded = const Value.absent(),
    required bool fileDownloaded,
    required FileType fileType,
    this.annotations = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       searchText = Value(searchText),
       fileDownloaded = Value(fileDownloaded),
       fileType = Value(fileType);
  static Insertable<ScoresTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<String>? notes,
    Expression<String>? searchText,
    Expression<DateTime>? lastOpened,
    Expression<DateTime>? metadataUpdatedAt,
    Expression<DateTime>? fileUpdatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? metadataUploaded,
    Expression<bool>? fileUploaded,
    Expression<bool>? fileDownloaded,
    Expression<String>? fileType,
    Expression<String>? annotations,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (notes != null) 'notes': notes,
      if (searchText != null) 'search_text': searchText,
      if (lastOpened != null) 'last_opened': lastOpened,
      if (metadataUpdatedAt != null) 'metadata_updated_at': metadataUpdatedAt,
      if (fileUpdatedAt != null) 'file_updated_at': fileUpdatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (metadataUploaded != null) 'metadata_uploaded': metadataUploaded,
      if (fileUploaded != null) 'file_uploaded': fileUploaded,
      if (fileDownloaded != null) 'file_downloaded': fileDownloaded,
      if (fileType != null) 'file_type': fileType,
      if (annotations != null) 'annotations': annotations,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? composer,
    Value<String?>? notes,
    Value<String>? searchText,
    Value<DateTime>? lastOpened,
    Value<DateTime>? metadataUpdatedAt,
    Value<DateTime>? fileUpdatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? metadataUploaded,
    Value<bool>? fileUploaded,
    Value<bool>? fileDownloaded,
    Value<FileType>? fileType,
    Value<String?>? annotations,
    Value<int>? rowid,
  }) {
    return ScoresTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      notes: notes ?? this.notes,
      searchText: searchText ?? this.searchText,
      lastOpened: lastOpened ?? this.lastOpened,
      metadataUpdatedAt: metadataUpdatedAt ?? this.metadataUpdatedAt,
      fileUpdatedAt: fileUpdatedAt ?? this.fileUpdatedAt,
      writtenAt: writtenAt ?? this.writtenAt,
      metadataUploaded: metadataUploaded ?? this.metadataUploaded,
      fileUploaded: fileUploaded ?? this.fileUploaded,
      fileDownloaded: fileDownloaded ?? this.fileDownloaded,
      fileType: fileType ?? this.fileType,
      annotations: annotations ?? this.annotations,
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
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (lastOpened.present) {
      map['last_opened'] = Variable<DateTime>(lastOpened.value);
    }
    if (metadataUpdatedAt.present) {
      map['metadata_updated_at'] = Variable<DateTime>(metadataUpdatedAt.value);
    }
    if (fileUpdatedAt.present) {
      map['file_updated_at'] = Variable<DateTime>(fileUpdatedAt.value);
    }
    if (writtenAt.present) {
      map['written_at'] = Variable<DateTime>(writtenAt.value);
    }
    if (metadataUploaded.present) {
      map['metadata_uploaded'] = Variable<bool>(metadataUploaded.value);
    }
    if (fileUploaded.present) {
      map['file_uploaded'] = Variable<bool>(fileUploaded.value);
    }
    if (fileDownloaded.present) {
      map['file_downloaded'] = Variable<bool>(fileDownloaded.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(
        $ScoresTableTable.$converterfileType.toSql(fileType.value),
      );
    }
    if (annotations.present) {
      map['annotations'] = Variable<String>(annotations.value);
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
          ..write('composer: $composer, ')
          ..write('notes: $notes, ')
          ..write('searchText: $searchText, ')
          ..write('lastOpened: $lastOpened, ')
          ..write('metadataUpdatedAt: $metadataUpdatedAt, ')
          ..write('fileUpdatedAt: $fileUpdatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('metadataUploaded: $metadataUploaded, ')
          ..write('fileUploaded: $fileUploaded, ')
          ..write('fileDownloaded: $fileDownloaded, ')
          ..write('fileType: $fileType, ')
          ..write('annotations: $annotations, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenresTableTable extends GenresTable
    with TableInfo<$GenresTableTable, GenresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [score, genre];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genres';
  @override
  VerificationContext validateIntegrity(
    Insertable<GenresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {score, genre};
  @override
  GenresTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenresTableData(
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
    );
  }

  @override
  $GenresTableTable createAlias(String alias) {
    return $GenresTableTable(attachedDatabase, alias);
  }
}

class GenresTableData extends DataClass implements Insertable<GenresTableData> {
  final String score;
  final String genre;
  const GenresTableData({required this.score, required this.genre});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['genre'] = Variable<String>(genre);
    return map;
  }

  GenresTableCompanion toCompanion(bool nullToAbsent) {
    return GenresTableCompanion(score: Value(score), genre: Value(genre));
  }

  factory GenresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenresTableData(
      score: serializer.fromJson<String>(json['score']),
      genre: serializer.fromJson<String>(json['genre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'score': serializer.toJson<String>(score),
      'genre': serializer.toJson<String>(genre),
    };
  }

  GenresTableData copyWith({String? score, String? genre}) =>
      GenresTableData(score: score ?? this.score, genre: genre ?? this.genre);
  GenresTableData copyWithCompanion(GenresTableCompanion data) {
    return GenresTableData(
      score: data.score.present ? data.score.value : this.score,
      genre: data.genre.present ? data.genre.value : this.genre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenresTableData(')
          ..write('score: $score, ')
          ..write('genre: $genre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(score, genre);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GenresTableData &&
          other.score == this.score &&
          other.genre == this.genre);
}

class GenresTableCompanion extends UpdateCompanion<GenresTableData> {
  final Value<String> score;
  final Value<String> genre;
  final Value<int> rowid;
  const GenresTableCompanion({
    this.score = const Value.absent(),
    this.genre = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenresTableCompanion.insert({
    required String score,
    required String genre,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       genre = Value(genre);
  static Insertable<GenresTableData> custom({
    Expression<String>? score,
    Expression<String>? genre,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (score != null) 'score': score,
      if (genre != null) 'genre': genre,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenresTableCompanion copyWith({
    Value<String>? score,
    Value<String>? genre,
    Value<int>? rowid,
  }) {
    return GenresTableCompanion(
      score: score ?? this.score,
      genre: genre ?? this.genre,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GenresTableCompanion(')
          ..write('score: $score, ')
          ..write('genre: $genre, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentsTableTable extends InstrumentsTable
    with TableInfo<$InstrumentsTableTable, InstrumentsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _instrumentMeta = const VerificationMeta(
    'instrument',
  );
  @override
  late final GeneratedColumn<String> instrument = GeneratedColumn<String>(
    'instrument',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [score, instrument];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstrumentsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('instrument')) {
      context.handle(
        _instrumentMeta,
        instrument.isAcceptableOrUnknown(data['instrument']!, _instrumentMeta),
      );
    } else if (isInserting) {
      context.missing(_instrumentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {score, instrument};
  @override
  InstrumentsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentsTableData(
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      instrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument'],
      )!,
    );
  }

  @override
  $InstrumentsTableTable createAlias(String alias) {
    return $InstrumentsTableTable(attachedDatabase, alias);
  }
}

class InstrumentsTableData extends DataClass
    implements Insertable<InstrumentsTableData> {
  final String score;
  final String instrument;
  const InstrumentsTableData({required this.score, required this.instrument});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['instrument'] = Variable<String>(instrument);
    return map;
  }

  InstrumentsTableCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsTableCompanion(
      score: Value(score),
      instrument: Value(instrument),
    );
  }

  factory InstrumentsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentsTableData(
      score: serializer.fromJson<String>(json['score']),
      instrument: serializer.fromJson<String>(json['instrument']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'score': serializer.toJson<String>(score),
      'instrument': serializer.toJson<String>(instrument),
    };
  }

  InstrumentsTableData copyWith({String? score, String? instrument}) =>
      InstrumentsTableData(
        score: score ?? this.score,
        instrument: instrument ?? this.instrument,
      );
  InstrumentsTableData copyWithCompanion(InstrumentsTableCompanion data) {
    return InstrumentsTableData(
      score: data.score.present ? data.score.value : this.score,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsTableData(')
          ..write('score: $score, ')
          ..write('instrument: $instrument')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(score, instrument);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentsTableData &&
          other.score == this.score &&
          other.instrument == this.instrument);
}

class InstrumentsTableCompanion extends UpdateCompanion<InstrumentsTableData> {
  final Value<String> score;
  final Value<String> instrument;
  final Value<int> rowid;
  const InstrumentsTableCompanion({
    this.score = const Value.absent(),
    this.instrument = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentsTableCompanion.insert({
    required String score,
    required String instrument,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       instrument = Value(instrument);
  static Insertable<InstrumentsTableData> custom({
    Expression<String>? score,
    Expression<String>? instrument,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (score != null) 'score': score,
      if (instrument != null) 'instrument': instrument,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentsTableCompanion copyWith({
    Value<String>? score,
    Value<String>? instrument,
    Value<int>? rowid,
  }) {
    return InstrumentsTableCompanion(
      score: score ?? this.score,
      instrument: instrument ?? this.instrument,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (instrument.present) {
      map['instrument'] = Variable<String>(instrument.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsTableCompanion(')
          ..write('score: $score, ')
          ..write('instrument: $instrument, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTableTable extends TagsTable
    with TableInfo<$TagsTableTable, TagsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _writtenAtMeta = const VerificationMeta(
    'writtenAt',
  );
  @override
  late final GeneratedColumn<DateTime> writtenAt = GeneratedColumn<DateTime>(
    'written_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('written_at')) {
      context.handle(
        _writtenAtMeta,
        writtenAt.isAcceptableOrUnknown(data['written_at']!, _writtenAtMeta),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      writtenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}written_at'],
      ),
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $TagsTableTable createAlias(String alias) {
    return $TagsTableTable(attachedDatabase, alias);
  }
}

class TagsTableData extends DataClass implements Insertable<TagsTableData> {
  final String id;
  final String name;
  final int color;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const TagsTableData({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  TagsTableCompanion toCompanion(bool nullToAbsent) {
    return TagsTableCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory TagsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      writtenAt: serializer.fromJson<DateTime?>(json['writtenAt']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  TagsTableData copyWith({
    String? id,
    String? name,
    int? color,
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => TagsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  TagsTableData copyWithCompanion(TagsTableCompanion data) {
    return TagsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, updatedAt, writtenAt, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class TagsTableCompanion extends UpdateCompanion<TagsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const TagsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsTableCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<TagsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return TagsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
      writtenAt: writtenAt ?? this.writtenAt,
      uploaded: uploaded ?? this.uploaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (writtenAt.present) {
      map['written_at'] = Variable<DateTime>(writtenAt.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoreTagsTableTable extends ScoreTagsTable
    with TableInfo<$ScoreTagsTableTable, ScoreTagsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoreTagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES scores (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [score, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoreTagsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {score, tag};
  @override
  ScoreTagsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreTagsTableData(
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $ScoreTagsTableTable createAlias(String alias) {
    return $ScoreTagsTableTable(attachedDatabase, alias);
  }
}

class ScoreTagsTableData extends DataClass
    implements Insertable<ScoreTagsTableData> {
  final String score;
  final String tag;
  const ScoreTagsTableData({required this.score, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ScoreTagsTableCompanion toCompanion(bool nullToAbsent) {
    return ScoreTagsTableCompanion(score: Value(score), tag: Value(tag));
  }

  factory ScoreTagsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreTagsTableData(
      score: serializer.fromJson<String>(json['score']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'score': serializer.toJson<String>(score),
      'tag': serializer.toJson<String>(tag),
    };
  }

  ScoreTagsTableData copyWith({String? score, String? tag}) =>
      ScoreTagsTableData(score: score ?? this.score, tag: tag ?? this.tag);
  ScoreTagsTableData copyWithCompanion(ScoreTagsTableCompanion data) {
    return ScoreTagsTableData(
      score: data.score.present ? data.score.value : this.score,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreTagsTableData(')
          ..write('score: $score, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(score, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreTagsTableData &&
          other.score == this.score &&
          other.tag == this.tag);
}

class ScoreTagsTableCompanion extends UpdateCompanion<ScoreTagsTableData> {
  final Value<String> score;
  final Value<String> tag;
  final Value<int> rowid;
  const ScoreTagsTableCompanion({
    this.score = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoreTagsTableCompanion.insert({
    required String score,
    required String tag,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       tag = Value(tag);
  static Insertable<ScoreTagsTableData> custom({
    Expression<String>? score,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (score != null) 'score': score,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoreTagsTableCompanion copyWith({
    Value<String>? score,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return ScoreTagsTableCompanion(
      score: score ?? this.score,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoreTagsTableCompanion(')
          ..write('score: $score, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValueTableTable extends KeyValueTable
    with TableInfo<$KeyValueTableTable, KeyValueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValueTableTable createAlias(String alias) {
    return $KeyValueTableTable(attachedDatabase, alias);
  }
}

class KeyValueTableData extends DataClass
    implements Insertable<KeyValueTableData> {
  final String key;
  final String value;
  const KeyValueTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueTableCompanion toCompanion(bool nullToAbsent) {
    return KeyValueTableCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueTableData copyWith({String? key, String? value}) =>
      KeyValueTableData(key: key ?? this.key, value: value ?? this.value);
  KeyValueTableData copyWithCompanion(KeyValueTableCompanion data) {
    return KeyValueTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueTableCompanion extends UpdateCompanion<KeyValueTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValueTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedTagsTableTable extends DeletedTagsTable
    with TableInfo<$DeletedTagsTableTable, DeletedTagsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedTagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [tagId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedTagsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tagId};
  @override
  DeletedTagsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedTagsTableData(
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedTagsTableTable createAlias(String alias) {
    return $DeletedTagsTableTable(attachedDatabase, alias);
  }
}

class DeletedTagsTableData extends DataClass
    implements Insertable<DeletedTagsTableData> {
  final String tagId;
  final DateTime deletedAt;
  const DeletedTagsTableData({required this.tagId, required this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tag_id'] = Variable<String>(tagId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedTagsTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedTagsTableCompanion(
      tagId: Value(tagId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedTagsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedTagsTableData(
      tagId: serializer.fromJson<String>(json['tagId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tagId': serializer.toJson<String>(tagId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedTagsTableData copyWith({String? tagId, DateTime? deletedAt}) =>
      DeletedTagsTableData(
        tagId: tagId ?? this.tagId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  DeletedTagsTableData copyWithCompanion(DeletedTagsTableCompanion data) {
    return DeletedTagsTableData(
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedTagsTableData(')
          ..write('tagId: $tagId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tagId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedTagsTableData &&
          other.tagId == this.tagId &&
          other.deletedAt == this.deletedAt);
}

class DeletedTagsTableCompanion extends UpdateCompanion<DeletedTagsTableData> {
  final Value<String> tagId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedTagsTableCompanion({
    this.tagId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedTagsTableCompanion.insert({
    required String tagId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tagId = Value(tagId);
  static Insertable<DeletedTagsTableData> custom({
    Expression<String>? tagId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tagId != null) 'tag_id': tagId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedTagsTableCompanion copyWith({
    Value<String>? tagId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedTagsTableCompanion(
      tagId: tagId ?? this.tagId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedTagsTableCompanion(')
          ..write('tagId: $tagId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedScoresTableTable extends DeletedScoresTable
    with TableInfo<$DeletedScoresTableTable, DeletedScoresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedScoresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scoreIdMeta = const VerificationMeta(
    'scoreId',
  );
  @override
  late final GeneratedColumn<String> scoreId = GeneratedColumn<String>(
    'score_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [scoreId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedScoresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('score_id')) {
      context.handle(
        _scoreIdMeta,
        scoreId.isAcceptableOrUnknown(data['score_id']!, _scoreIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scoreId};
  @override
  DeletedScoresTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedScoresTableData(
      scoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedScoresTableTable createAlias(String alias) {
    return $DeletedScoresTableTable(attachedDatabase, alias);
  }
}

class DeletedScoresTableData extends DataClass
    implements Insertable<DeletedScoresTableData> {
  final String scoreId;
  final DateTime deletedAt;
  const DeletedScoresTableData({
    required this.scoreId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score_id'] = Variable<String>(scoreId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedScoresTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedScoresTableCompanion(
      scoreId: Value(scoreId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedScoresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedScoresTableData(
      scoreId: serializer.fromJson<String>(json['scoreId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scoreId': serializer.toJson<String>(scoreId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedScoresTableData copyWith({String? scoreId, DateTime? deletedAt}) =>
      DeletedScoresTableData(
        scoreId: scoreId ?? this.scoreId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  DeletedScoresTableData copyWithCompanion(DeletedScoresTableCompanion data) {
    return DeletedScoresTableData(
      scoreId: data.scoreId.present ? data.scoreId.value : this.scoreId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedScoresTableData(')
          ..write('scoreId: $scoreId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scoreId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedScoresTableData &&
          other.scoreId == this.scoreId &&
          other.deletedAt == this.deletedAt);
}

class DeletedScoresTableCompanion
    extends UpdateCompanion<DeletedScoresTableData> {
  final Value<String> scoreId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedScoresTableCompanion({
    this.scoreId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedScoresTableCompanion.insert({
    required String scoreId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scoreId = Value(scoreId);
  static Insertable<DeletedScoresTableData> custom({
    Expression<String>? scoreId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scoreId != null) 'score_id': scoreId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedScoresTableCompanion copyWith({
    Value<String>? scoreId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedScoresTableCompanion(
      scoreId: scoreId ?? this.scoreId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scoreId.present) {
      map['score_id'] = Variable<String>(scoreId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedScoresTableCompanion(')
          ..write('scoreId: $scoreId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LogMessageTableTable extends LogMessageTable
    with TableInfo<$LogMessageTableTable, LogMessageTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogMessageTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sessionStartTimeMeta = const VerificationMeta(
    'sessionStartTime',
  );
  @override
  late final GeneratedColumn<DateTime> sessionStartTime =
      GeneratedColumn<DateTime>(
        'session_start_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Level, String> level =
      GeneratedColumn<String>(
        'level',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Level>($LogMessageTableTable.$converterlevel);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stackTraceMeta = const VerificationMeta(
    'stackTrace',
  );
  @override
  late final GeneratedColumn<String> stackTrace = GeneratedColumn<String>(
    'stack_trace',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exceptionMeta = const VerificationMeta(
    'exception',
  );
  @override
  late final GeneratedColumn<String> exception = GeneratedColumn<String>(
    'exception',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionStartTime,
    time,
    level,
    tag,
    message,
    stackTrace,
    exception,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_message';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogMessageTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_start_time')) {
      context.handle(
        _sessionStartTimeMeta,
        sessionStartTime.isAcceptableOrUnknown(
          data['session_start_time']!,
          _sessionStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionStartTimeMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('stack_trace')) {
      context.handle(
        _stackTraceMeta,
        stackTrace.isAcceptableOrUnknown(data['stack_trace']!, _stackTraceMeta),
      );
    } else if (isInserting) {
      context.missing(_stackTraceMeta);
    }
    if (data.containsKey('exception')) {
      context.handle(
        _exceptionMeta,
        exception.isAcceptableOrUnknown(data['exception']!, _exceptionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogMessageTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogMessageTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}session_start_time'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}time'],
      )!,
      level: $LogMessageTableTable.$converterlevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}level'],
        )!,
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      stackTrace: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stack_trace'],
      )!,
      exception: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exception'],
      ),
    );
  }

  @override
  $LogMessageTableTable createAlias(String alias) {
    return $LogMessageTableTable(attachedDatabase, alias);
  }

  static TypeConverter<Level, String> $converterlevel =
      const LogLevelConverter();
}

class LogMessageTableData extends DataClass
    implements Insertable<LogMessageTableData> {
  final int id;
  final DateTime sessionStartTime;
  final DateTime time;
  final Level level;
  final String tag;
  final String message;
  final String stackTrace;
  final String? exception;
  const LogMessageTableData({
    required this.id,
    required this.sessionStartTime,
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    required this.stackTrace,
    this.exception,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_start_time'] = Variable<DateTime>(sessionStartTime);
    map['time'] = Variable<DateTime>(time);
    {
      map['level'] = Variable<String>(
        $LogMessageTableTable.$converterlevel.toSql(level),
      );
    }
    map['tag'] = Variable<String>(tag);
    map['message'] = Variable<String>(message);
    map['stack_trace'] = Variable<String>(stackTrace);
    if (!nullToAbsent || exception != null) {
      map['exception'] = Variable<String>(exception);
    }
    return map;
  }

  LogMessageTableCompanion toCompanion(bool nullToAbsent) {
    return LogMessageTableCompanion(
      id: Value(id),
      sessionStartTime: Value(sessionStartTime),
      time: Value(time),
      level: Value(level),
      tag: Value(tag),
      message: Value(message),
      stackTrace: Value(stackTrace),
      exception: exception == null && nullToAbsent
          ? const Value.absent()
          : Value(exception),
    );
  }

  factory LogMessageTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogMessageTableData(
      id: serializer.fromJson<int>(json['id']),
      sessionStartTime: serializer.fromJson<DateTime>(json['sessionStartTime']),
      time: serializer.fromJson<DateTime>(json['time']),
      level: serializer.fromJson<Level>(json['level']),
      tag: serializer.fromJson<String>(json['tag']),
      message: serializer.fromJson<String>(json['message']),
      stackTrace: serializer.fromJson<String>(json['stackTrace']),
      exception: serializer.fromJson<String?>(json['exception']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionStartTime': serializer.toJson<DateTime>(sessionStartTime),
      'time': serializer.toJson<DateTime>(time),
      'level': serializer.toJson<Level>(level),
      'tag': serializer.toJson<String>(tag),
      'message': serializer.toJson<String>(message),
      'stackTrace': serializer.toJson<String>(stackTrace),
      'exception': serializer.toJson<String?>(exception),
    };
  }

  LogMessageTableData copyWith({
    int? id,
    DateTime? sessionStartTime,
    DateTime? time,
    Level? level,
    String? tag,
    String? message,
    String? stackTrace,
    Value<String?> exception = const Value.absent(),
  }) => LogMessageTableData(
    id: id ?? this.id,
    sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    time: time ?? this.time,
    level: level ?? this.level,
    tag: tag ?? this.tag,
    message: message ?? this.message,
    stackTrace: stackTrace ?? this.stackTrace,
    exception: exception.present ? exception.value : this.exception,
  );
  LogMessageTableData copyWithCompanion(LogMessageTableCompanion data) {
    return LogMessageTableData(
      id: data.id.present ? data.id.value : this.id,
      sessionStartTime: data.sessionStartTime.present
          ? data.sessionStartTime.value
          : this.sessionStartTime,
      time: data.time.present ? data.time.value : this.time,
      level: data.level.present ? data.level.value : this.level,
      tag: data.tag.present ? data.tag.value : this.tag,
      message: data.message.present ? data.message.value : this.message,
      stackTrace: data.stackTrace.present
          ? data.stackTrace.value
          : this.stackTrace,
      exception: data.exception.present ? data.exception.value : this.exception,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogMessageTableData(')
          ..write('id: $id, ')
          ..write('sessionStartTime: $sessionStartTime, ')
          ..write('time: $time, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('exception: $exception')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionStartTime,
    time,
    level,
    tag,
    message,
    stackTrace,
    exception,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogMessageTableData &&
          other.id == this.id &&
          other.sessionStartTime == this.sessionStartTime &&
          other.time == this.time &&
          other.level == this.level &&
          other.tag == this.tag &&
          other.message == this.message &&
          other.stackTrace == this.stackTrace &&
          other.exception == this.exception);
}

class LogMessageTableCompanion extends UpdateCompanion<LogMessageTableData> {
  final Value<int> id;
  final Value<DateTime> sessionStartTime;
  final Value<DateTime> time;
  final Value<Level> level;
  final Value<String> tag;
  final Value<String> message;
  final Value<String> stackTrace;
  final Value<String?> exception;
  const LogMessageTableCompanion({
    this.id = const Value.absent(),
    this.sessionStartTime = const Value.absent(),
    this.time = const Value.absent(),
    this.level = const Value.absent(),
    this.tag = const Value.absent(),
    this.message = const Value.absent(),
    this.stackTrace = const Value.absent(),
    this.exception = const Value.absent(),
  });
  LogMessageTableCompanion.insert({
    this.id = const Value.absent(),
    required DateTime sessionStartTime,
    required DateTime time,
    required Level level,
    required String tag,
    required String message,
    required String stackTrace,
    this.exception = const Value.absent(),
  }) : sessionStartTime = Value(sessionStartTime),
       time = Value(time),
       level = Value(level),
       tag = Value(tag),
       message = Value(message),
       stackTrace = Value(stackTrace);
  static Insertable<LogMessageTableData> custom({
    Expression<int>? id,
    Expression<DateTime>? sessionStartTime,
    Expression<DateTime>? time,
    Expression<String>? level,
    Expression<String>? tag,
    Expression<String>? message,
    Expression<String>? stackTrace,
    Expression<String>? exception,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionStartTime != null) 'session_start_time': sessionStartTime,
      if (time != null) 'time': time,
      if (level != null) 'level': level,
      if (tag != null) 'tag': tag,
      if (message != null) 'message': message,
      if (stackTrace != null) 'stack_trace': stackTrace,
      if (exception != null) 'exception': exception,
    });
  }

  LogMessageTableCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? sessionStartTime,
    Value<DateTime>? time,
    Value<Level>? level,
    Value<String>? tag,
    Value<String>? message,
    Value<String>? stackTrace,
    Value<String?>? exception,
  }) {
    return LogMessageTableCompanion(
      id: id ?? this.id,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      time: time ?? this.time,
      level: level ?? this.level,
      tag: tag ?? this.tag,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      exception: exception ?? this.exception,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionStartTime.present) {
      map['session_start_time'] = Variable<DateTime>(sessionStartTime.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(
        $LogMessageTableTable.$converterlevel.toSql(level.value),
      );
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (stackTrace.present) {
      map['stack_trace'] = Variable<String>(stackTrace.value);
    }
    if (exception.present) {
      map['exception'] = Variable<String>(exception.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogMessageTableCompanion(')
          ..write('id: $id, ')
          ..write('sessionStartTime: $sessionStartTime, ')
          ..write('time: $time, ')
          ..write('level: $level, ')
          ..write('tag: $tag, ')
          ..write('message: $message, ')
          ..write('stackTrace: $stackTrace, ')
          ..write('exception: $exception')
          ..write(')'))
        .toString();
  }
}

class $SetlistsTableTable extends SetlistsTable
    with TableInfo<$SetlistsTableTable, SetlistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  static const VerificationMeta _writtenAtMeta = const VerificationMeta(
    'writtenAt',
  );
  @override
  late final GeneratedColumn<DateTime> writtenAt = GeneratedColumn<DateTime>(
    'written_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('written_at')) {
      context.handle(
        _writtenAtMeta,
        writtenAt.isAcceptableOrUnknown(data['written_at']!, _writtenAtMeta),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetlistsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      writtenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}written_at'],
      ),
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $SetlistsTableTable createAlias(String alias) {
    return $SetlistsTableTable(attachedDatabase, alias);
  }
}

class SetlistsTableData extends DataClass
    implements Insertable<SetlistsTableData> {
  final String id;
  final String name;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const SetlistsTableData({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  SetlistsTableCompanion toCompanion(bool nullToAbsent) {
    return SetlistsTableCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory SetlistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistsTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      writtenAt: serializer.fromJson<DateTime?>(json['writtenAt']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  SetlistsTableData copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => SetlistsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  SetlistsTableData copyWithCompanion(SetlistsTableCompanion data) {
    return SetlistsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, updatedAt, writtenAt, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class SetlistsTableCompanion extends UpdateCompanion<SetlistsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const SetlistsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistsTableCompanion.insert({
    required String id,
    required String name,
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<SetlistsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return SetlistsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      writtenAt: writtenAt ?? this.writtenAt,
      uploaded: uploaded ?? this.uploaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (writtenAt.present) {
      map['written_at'] = Variable<DateTime>(writtenAt.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistEntriesTableTable extends SetlistEntriesTable
    with TableInfo<$SetlistEntriesTableTable, SetlistEntriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setlistMeta = const VerificationMeta(
    'setlist',
  );
  @override
  late final GeneratedColumn<String> setlist = GeneratedColumn<String>(
    'setlist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES setlists (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [setlist, score, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlist_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setlist')) {
      context.handle(
        _setlistMeta,
        setlist.isAcceptableOrUnknown(data['setlist']!, _setlistMeta),
      );
    } else if (isInserting) {
      context.missing(_setlistMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setlist, position};
  @override
  SetlistEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistEntriesTableData(
      setlist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setlist'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SetlistEntriesTableTable createAlias(String alias) {
    return $SetlistEntriesTableTable(attachedDatabase, alias);
  }
}

class SetlistEntriesTableData extends DataClass
    implements Insertable<SetlistEntriesTableData> {
  final String setlist;
  final String score;
  final int position;
  const SetlistEntriesTableData({
    required this.setlist,
    required this.score,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setlist'] = Variable<String>(setlist);
    map['score'] = Variable<String>(score);
    map['position'] = Variable<int>(position);
    return map;
  }

  SetlistEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return SetlistEntriesTableCompanion(
      setlist: Value(setlist),
      score: Value(score),
      position: Value(position),
    );
  }

  factory SetlistEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistEntriesTableData(
      setlist: serializer.fromJson<String>(json['setlist']),
      score: serializer.fromJson<String>(json['score']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setlist': serializer.toJson<String>(setlist),
      'score': serializer.toJson<String>(score),
      'position': serializer.toJson<int>(position),
    };
  }

  SetlistEntriesTableData copyWith({
    String? setlist,
    String? score,
    int? position,
  }) => SetlistEntriesTableData(
    setlist: setlist ?? this.setlist,
    score: score ?? this.score,
    position: position ?? this.position,
  );
  SetlistEntriesTableData copyWithCompanion(SetlistEntriesTableCompanion data) {
    return SetlistEntriesTableData(
      setlist: data.setlist.present ? data.setlist.value : this.setlist,
      score: data.score.present ? data.score.value : this.score,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistEntriesTableData(')
          ..write('setlist: $setlist, ')
          ..write('score: $score, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setlist, score, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistEntriesTableData &&
          other.setlist == this.setlist &&
          other.score == this.score &&
          other.position == this.position);
}

class SetlistEntriesTableCompanion
    extends UpdateCompanion<SetlistEntriesTableData> {
  final Value<String> setlist;
  final Value<String> score;
  final Value<int> position;
  final Value<int> rowid;
  const SetlistEntriesTableCompanion({
    this.setlist = const Value.absent(),
    this.score = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistEntriesTableCompanion.insert({
    required String setlist,
    required String score,
    required int position,
    this.rowid = const Value.absent(),
  }) : setlist = Value(setlist),
       score = Value(score),
       position = Value(position);
  static Insertable<SetlistEntriesTableData> custom({
    Expression<String>? setlist,
    Expression<String>? score,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setlist != null) 'setlist': setlist,
      if (score != null) 'score': score,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistEntriesTableCompanion copyWith({
    Value<String>? setlist,
    Value<String>? score,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SetlistEntriesTableCompanion(
      setlist: setlist ?? this.setlist,
      score: score ?? this.score,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setlist.present) {
      map['setlist'] = Variable<String>(setlist.value);
    }
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistEntriesTableCompanion(')
          ..write('setlist: $setlist, ')
          ..write('score: $score, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedSetlistsTableTable extends DeletedSetlistsTable
    with TableInfo<$DeletedSetlistsTableTable, DeletedSetlistsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedSetlistsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setlistIdMeta = const VerificationMeta(
    'setlistId',
  );
  @override
  late final GeneratedColumn<String> setlistId = GeneratedColumn<String>(
    'setlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().toUtc(),
  );
  @override
  List<GeneratedColumn> get $columns => [setlistId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedSetlistsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setlist_id')) {
      context.handle(
        _setlistIdMeta,
        setlistId.isAcceptableOrUnknown(data['setlist_id']!, _setlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setlistIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {setlistId};
  @override
  DeletedSetlistsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedSetlistsTableData(
      setlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setlist_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedSetlistsTableTable createAlias(String alias) {
    return $DeletedSetlistsTableTable(attachedDatabase, alias);
  }
}

class DeletedSetlistsTableData extends DataClass
    implements Insertable<DeletedSetlistsTableData> {
  final String setlistId;
  final DateTime deletedAt;
  const DeletedSetlistsTableData({
    required this.setlistId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setlist_id'] = Variable<String>(setlistId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedSetlistsTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedSetlistsTableCompanion(
      setlistId: Value(setlistId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedSetlistsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedSetlistsTableData(
      setlistId: serializer.fromJson<String>(json['setlistId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setlistId': serializer.toJson<String>(setlistId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedSetlistsTableData copyWith({String? setlistId, DateTime? deletedAt}) =>
      DeletedSetlistsTableData(
        setlistId: setlistId ?? this.setlistId,
        deletedAt: deletedAt ?? this.deletedAt,
      );
  DeletedSetlistsTableData copyWithCompanion(
    DeletedSetlistsTableCompanion data,
  ) {
    return DeletedSetlistsTableData(
      setlistId: data.setlistId.present ? data.setlistId.value : this.setlistId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedSetlistsTableData(')
          ..write('setlistId: $setlistId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setlistId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedSetlistsTableData &&
          other.setlistId == this.setlistId &&
          other.deletedAt == this.deletedAt);
}

class DeletedSetlistsTableCompanion
    extends UpdateCompanion<DeletedSetlistsTableData> {
  final Value<String> setlistId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedSetlistsTableCompanion({
    this.setlistId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedSetlistsTableCompanion.insert({
    required String setlistId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : setlistId = Value(setlistId);
  static Insertable<DeletedSetlistsTableData> custom({
    Expression<String>? setlistId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setlistId != null) 'setlist_id': setlistId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedSetlistsTableCompanion copyWith({
    Value<String>? setlistId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedSetlistsTableCompanion(
      setlistId: setlistId ?? this.setlistId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setlistId.present) {
      map['setlist_id'] = Variable<String>(setlistId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedSetlistsTableCompanion(')
          ..write('setlistId: $setlistId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $ScoresTableTable scoresTable = $ScoresTableTable(this);
  late final $GenresTableTable genresTable = $GenresTableTable(this);
  late final $InstrumentsTableTable instrumentsTable = $InstrumentsTableTable(
    this,
  );
  late final $TagsTableTable tagsTable = $TagsTableTable(this);
  late final $ScoreTagsTableTable scoreTagsTable = $ScoreTagsTableTable(this);
  late final $KeyValueTableTable keyValueTable = $KeyValueTableTable(this);
  late final $DeletedTagsTableTable deletedTagsTable = $DeletedTagsTableTable(
    this,
  );
  late final $DeletedScoresTableTable deletedScoresTable =
      $DeletedScoresTableTable(this);
  late final $LogMessageTableTable logMessageTable = $LogMessageTableTable(
    this,
  );
  late final $SetlistsTableTable setlistsTable = $SetlistsTableTable(this);
  late final $SetlistEntriesTableTable setlistEntriesTable =
      $SetlistEntriesTableTable(this);
  late final $DeletedSetlistsTableTable deletedSetlistsTable =
      $DeletedSetlistsTableTable(this);
  late final Index searchTextIndex = Index(
    'search_text_index',
    'CREATE INDEX search_text_index ON scores (search_text)',
  );
  late final Index recentTimeIndex = Index(
    'recent_time_index',
    'CREATE INDEX recent_time_index ON scores (recent_time)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scoresTable,
    genresTable,
    instrumentsTable,
    tagsTable,
    scoreTagsTable,
    keyValueTable,
    deletedTagsTable,
    deletedScoresTable,
    logMessageTable,
    setlistsTable,
    setlistEntriesTable,
    deletedSetlistsTable,
    searchTextIndex,
    recentTimeIndex,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('genres', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('genres', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('instruments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('instruments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'scores',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('score_tags', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'setlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('setlist_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'setlists',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('setlist_entries', kind: UpdateKind.update)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ScoresTableTableCreateCompanionBuilder =
    ScoresTableCompanion Function({
      required String id,
      required String title,
      Value<String?> composer,
      Value<String?> notes,
      required String searchText,
      Value<DateTime> lastOpened,
      Value<DateTime> metadataUpdatedAt,
      Value<DateTime> fileUpdatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> metadataUploaded,
      Value<bool> fileUploaded,
      required bool fileDownloaded,
      required FileType fileType,
      Value<String?> annotations,
      Value<int> rowid,
    });
typedef $$ScoresTableTableUpdateCompanionBuilder =
    ScoresTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> composer,
      Value<String?> notes,
      Value<String> searchText,
      Value<DateTime> lastOpened,
      Value<DateTime> metadataUpdatedAt,
      Value<DateTime> fileUpdatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> metadataUploaded,
      Value<bool> fileUploaded,
      Value<bool> fileDownloaded,
      Value<FileType> fileType,
      Value<String?> annotations,
      Value<int> rowid,
    });

final class $$ScoresTableTableReferences
    extends BaseReferences<_$Database, $ScoresTableTable, ScoresTableData> {
  $$ScoresTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GenresTableTable, List<GenresTableData>>
  _genresTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.genresTable,
    aliasName: 'scores__id__genres__score',
  );

  $$GenresTableTableProcessedTableManager get genresTableRefs {
    final manager = $$GenresTableTableTableManager(
      $_db,
      $_db.genresTable,
    ).filter((f) => f.score.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_genresTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InstrumentsTableTable, List<InstrumentsTableData>>
  _instrumentsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.instrumentsTable,
    aliasName: 'scores__id__instruments__score',
  );

  $$InstrumentsTableTableProcessedTableManager get instrumentsTableRefs {
    final manager = $$InstrumentsTableTableTableManager(
      $_db,
      $_db.instrumentsTable,
    ).filter((f) => f.score.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _instrumentsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ScoreTagsTableTable, List<ScoreTagsTableData>>
  _scoreTagsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.scoreTagsTable,
    aliasName: 'scores__id__score_tags__score',
  );

  $$ScoreTagsTableTableProcessedTableManager get scoreTagsTableRefs {
    final manager = $$ScoreTagsTableTableTableManager(
      $_db,
      $_db.scoreTagsTable,
    ).filter((f) => f.score.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoreTagsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recentTime => $composableBuilder(
    column: $table.recentTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
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

  ColumnFilters<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get metadataUploaded => $composableBuilder(
    column: $table.metadataUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fileUploaded => $composableBuilder(
    column: $table.fileUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get fileDownloaded => $composableBuilder(
    column: $table.fileDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FileType, FileType, String> get fileType =>
      $composableBuilder(
        column: $table.fileType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get annotations => $composableBuilder(
    column: $table.annotations,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> genresTableRefs(
    Expression<bool> Function($$GenresTableTableFilterComposer f) f,
  ) {
    final $$GenresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.genresTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenresTableTableFilterComposer(
            $db: $db,
            $table: $db.genresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> instrumentsTableRefs(
    Expression<bool> Function($$InstrumentsTableTableFilterComposer f) f,
  ) {
    final $$InstrumentsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instrumentsTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableTableFilterComposer(
            $db: $db,
            $table: $db.instrumentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scoreTagsTableRefs(
    Expression<bool> Function($$ScoreTagsTableTableFilterComposer f) f,
  ) {
    final $$ScoreTagsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTagsTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableTableFilterComposer(
            $db: $db,
            $table: $db.scoreTagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recentTime => $composableBuilder(
    column: $table.recentTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
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

  ColumnOrderings<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get metadataUploaded => $composableBuilder(
    column: $table.metadataUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fileUploaded => $composableBuilder(
    column: $table.fileUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get fileDownloaded => $composableBuilder(
    column: $table.fileDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get annotations => $composableBuilder(
    column: $table.annotations,
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

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recentTime => $composableBuilder(
    column: $table.recentTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get metadataUpdatedAt => $composableBuilder(
    column: $table.metadataUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fileUpdatedAt => $composableBuilder(
    column: $table.fileUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get metadataUploaded => $composableBuilder(
    column: $table.metadataUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fileUploaded => $composableBuilder(
    column: $table.fileUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get fileDownloaded => $composableBuilder(
    column: $table.fileDownloaded,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FileType, String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<String> get annotations => $composableBuilder(
    column: $table.annotations,
    builder: (column) => column,
  );

  Expression<T> genresTableRefs<T extends Object>(
    Expression<T> Function($$GenresTableTableAnnotationComposer a) f,
  ) {
    final $$GenresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.genresTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GenresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.genresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> instrumentsTableRefs<T extends Object>(
    Expression<T> Function($$InstrumentsTableTableAnnotationComposer a) f,
  ) {
    final $$InstrumentsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instrumentsTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstrumentsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.instrumentsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scoreTagsTableRefs<T extends Object>(
    Expression<T> Function($$ScoreTagsTableTableAnnotationComposer a) f,
  ) {
    final $$ScoreTagsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTagsTable,
      getReferencedColumn: (t) => t.score,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scoreTagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (ScoresTableData, $$ScoresTableTableReferences),
          ScoresTableData,
          PrefetchHooks Function({
            bool genresTableRefs,
            bool instrumentsTableRefs,
            bool scoreTagsTableRefs,
          })
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
                Value<String?> composer = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> lastOpened = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> metadataUploaded = const Value.absent(),
                Value<bool> fileUploaded = const Value.absent(),
                Value<bool> fileDownloaded = const Value.absent(),
                Value<FileType> fileType = const Value.absent(),
                Value<String?> annotations = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion(
                id: id,
                title: title,
                composer: composer,
                notes: notes,
                searchText: searchText,
                lastOpened: lastOpened,
                metadataUpdatedAt: metadataUpdatedAt,
                fileUpdatedAt: fileUpdatedAt,
                writtenAt: writtenAt,
                metadataUploaded: metadataUploaded,
                fileUploaded: fileUploaded,
                fileDownloaded: fileDownloaded,
                fileType: fileType,
                annotations: annotations,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> composer = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String searchText,
                Value<DateTime> lastOpened = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> metadataUploaded = const Value.absent(),
                Value<bool> fileUploaded = const Value.absent(),
                required bool fileDownloaded,
                required FileType fileType,
                Value<String?> annotations = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion.insert(
                id: id,
                title: title,
                composer: composer,
                notes: notes,
                searchText: searchText,
                lastOpened: lastOpened,
                metadataUpdatedAt: metadataUpdatedAt,
                fileUpdatedAt: fileUpdatedAt,
                writtenAt: writtenAt,
                metadataUploaded: metadataUploaded,
                fileUploaded: fileUploaded,
                fileDownloaded: fileDownloaded,
                fileType: fileType,
                annotations: annotations,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScoresTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                genresTableRefs = false,
                instrumentsTableRefs = false,
                scoreTagsTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (genresTableRefs) db.genresTable,
                    if (instrumentsTableRefs) db.instrumentsTable,
                    if (scoreTagsTableRefs) db.scoreTagsTable,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (genresTableRefs)
                        await $_getPrefetchedData<
                          ScoresTableData,
                          $ScoresTableTable,
                          GenresTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableTableReferences
                              ._genresTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).genresTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.score == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (instrumentsTableRefs)
                        await $_getPrefetchedData<
                          ScoresTableData,
                          $ScoresTableTable,
                          InstrumentsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableTableReferences
                              ._instrumentsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).instrumentsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.score == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scoreTagsTableRefs)
                        await $_getPrefetchedData<
                          ScoresTableData,
                          $ScoresTableTable,
                          ScoreTagsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ScoresTableTableReferences
                              ._scoreTagsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ScoresTableTableReferences(
                                db,
                                table,
                                p0,
                              ).scoreTagsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.score == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (ScoresTableData, $$ScoresTableTableReferences),
      ScoresTableData,
      PrefetchHooks Function({
        bool genresTableRefs,
        bool instrumentsTableRefs,
        bool scoreTagsTableRefs,
      })
    >;
typedef $$GenresTableTableCreateCompanionBuilder =
    GenresTableCompanion Function({
      required String score,
      required String genre,
      Value<int> rowid,
    });
typedef $$GenresTableTableUpdateCompanionBuilder =
    GenresTableCompanion Function({
      Value<String> score,
      Value<String> genre,
      Value<int> rowid,
    });

final class $$GenresTableTableReferences
    extends BaseReferences<_$Database, $GenresTableTable, GenresTableData> {
  $$GenresTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ScoresTableTable _scoreTable(_$Database db) =>
      db.scoresTable.createAlias('genres__score__scores__id');

  $$ScoresTableTableProcessedTableManager get score {
    final $_column = $_itemColumn<String>('score')!;

    final manager = $$ScoresTableTableTableManager(
      $_db,
      $_db.scoresTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GenresTableTableFilterComposer
    extends Composer<_$Database, $GenresTableTable> {
  $$GenresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableTableFilterComposer get score {
    final $$ScoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableFilterComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenresTableTableOrderingComposer
    extends Composer<_$Database, $GenresTableTable> {
  $$GenresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableTableOrderingComposer get score {
    final $$ScoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenresTableTableAnnotationComposer
    extends Composer<_$Database, $GenresTableTable> {
  $$GenresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  $$ScoresTableTableAnnotationComposer get score {
    final $$ScoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenresTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $GenresTableTable,
          GenresTableData,
          $$GenresTableTableFilterComposer,
          $$GenresTableTableOrderingComposer,
          $$GenresTableTableAnnotationComposer,
          $$GenresTableTableCreateCompanionBuilder,
          $$GenresTableTableUpdateCompanionBuilder,
          (GenresTableData, $$GenresTableTableReferences),
          GenresTableData,
          PrefetchHooks Function({bool score})
        > {
  $$GenresTableTableTableManager(_$Database db, $GenresTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GenresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GenresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenresTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> score = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenresTableCompanion(
                score: score,
                genre: genre,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String score,
                required String genre,
                Value<int> rowid = const Value.absent(),
              }) => GenresTableCompanion.insert(
                score: score,
                genre: genre,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GenresTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({score = false}) {
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
                    if (score) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.score,
                                referencedTable: $$GenresTableTableReferences
                                    ._scoreTable(db),
                                referencedColumn: $$GenresTableTableReferences
                                    ._scoreTable(db)
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

typedef $$GenresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $GenresTableTable,
      GenresTableData,
      $$GenresTableTableFilterComposer,
      $$GenresTableTableOrderingComposer,
      $$GenresTableTableAnnotationComposer,
      $$GenresTableTableCreateCompanionBuilder,
      $$GenresTableTableUpdateCompanionBuilder,
      (GenresTableData, $$GenresTableTableReferences),
      GenresTableData,
      PrefetchHooks Function({bool score})
    >;
typedef $$InstrumentsTableTableCreateCompanionBuilder =
    InstrumentsTableCompanion Function({
      required String score,
      required String instrument,
      Value<int> rowid,
    });
typedef $$InstrumentsTableTableUpdateCompanionBuilder =
    InstrumentsTableCompanion Function({
      Value<String> score,
      Value<String> instrument,
      Value<int> rowid,
    });

final class $$InstrumentsTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $InstrumentsTableTable,
          InstrumentsTableData
        > {
  $$InstrumentsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScoresTableTable _scoreTable(_$Database db) =>
      db.scoresTable.createAlias('instruments__score__scores__id');

  $$ScoresTableTableProcessedTableManager get score {
    final $_column = $_itemColumn<String>('score')!;

    final manager = $$ScoresTableTableTableManager(
      $_db,
      $_db.scoresTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstrumentsTableTableFilterComposer
    extends Composer<_$Database, $InstrumentsTableTable> {
  $$InstrumentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnFilters(column),
  );

  $$ScoresTableTableFilterComposer get score {
    final $$ScoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableFilterComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentsTableTableOrderingComposer
    extends Composer<_$Database, $InstrumentsTableTable> {
  $$InstrumentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnOrderings(column),
  );

  $$ScoresTableTableOrderingComposer get score {
    final $$ScoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentsTableTableAnnotationComposer
    extends Composer<_$Database, $InstrumentsTableTable> {
  $$InstrumentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => column,
  );

  $$ScoresTableTableAnnotationComposer get score {
    final $$ScoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstrumentsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $InstrumentsTableTable,
          InstrumentsTableData,
          $$InstrumentsTableTableFilterComposer,
          $$InstrumentsTableTableOrderingComposer,
          $$InstrumentsTableTableAnnotationComposer,
          $$InstrumentsTableTableCreateCompanionBuilder,
          $$InstrumentsTableTableUpdateCompanionBuilder,
          (InstrumentsTableData, $$InstrumentsTableTableReferences),
          InstrumentsTableData,
          PrefetchHooks Function({bool score})
        > {
  $$InstrumentsTableTableTableManager(
    _$Database db,
    $InstrumentsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> score = const Value.absent(),
                Value<String> instrument = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstrumentsTableCompanion(
                score: score,
                instrument: instrument,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String score,
                required String instrument,
                Value<int> rowid = const Value.absent(),
              }) => InstrumentsTableCompanion.insert(
                score: score,
                instrument: instrument,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstrumentsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({score = false}) {
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
                    if (score) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.score,
                                referencedTable:
                                    $$InstrumentsTableTableReferences
                                        ._scoreTable(db),
                                referencedColumn:
                                    $$InstrumentsTableTableReferences
                                        ._scoreTable(db)
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

typedef $$InstrumentsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $InstrumentsTableTable,
      InstrumentsTableData,
      $$InstrumentsTableTableFilterComposer,
      $$InstrumentsTableTableOrderingComposer,
      $$InstrumentsTableTableAnnotationComposer,
      $$InstrumentsTableTableCreateCompanionBuilder,
      $$InstrumentsTableTableUpdateCompanionBuilder,
      (InstrumentsTableData, $$InstrumentsTableTableReferences),
      InstrumentsTableData,
      PrefetchHooks Function({bool score})
    >;
typedef $$TagsTableTableCreateCompanionBuilder =
    TagsTableCompanion Function({
      required String id,
      required String name,
      required int color,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$TagsTableTableUpdateCompanionBuilder =
    TagsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> color,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$TagsTableTableReferences
    extends BaseReferences<_$Database, $TagsTableTable, TagsTableData> {
  $$TagsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScoreTagsTableTable, List<ScoreTagsTableData>>
  _scoreTagsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.scoreTagsTable,
    aliasName: 'tags__id__score_tags__tag',
  );

  $$ScoreTagsTableTableProcessedTableManager get scoreTagsTableRefs {
    final manager = $$ScoreTagsTableTableTableManager(
      $_db,
      $_db.scoreTagsTable,
    ).filter((f) => f.tag.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scoreTagsTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableTableFilterComposer
    extends Composer<_$Database, $TagsTableTable> {
  $$TagsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> scoreTagsTableRefs(
    Expression<bool> Function($$ScoreTagsTableTableFilterComposer f) f,
  ) {
    final $$ScoreTagsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTagsTable,
      getReferencedColumn: (t) => t.tag,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableTableFilterComposer(
            $db: $db,
            $table: $db.scoreTagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableOrderingComposer
    extends Composer<_$Database, $TagsTableTable> {
  $$TagsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableTableAnnotationComposer
    extends Composer<_$Database, $TagsTableTable> {
  $$TagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  Expression<T> scoreTagsTableRefs<T extends Object>(
    Expression<T> Function($$ScoreTagsTableTableAnnotationComposer a) f,
  ) {
    final $$ScoreTagsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scoreTagsTable,
      getReferencedColumn: (t) => t.tag,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoreTagsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scoreTagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $TagsTableTable,
          TagsTableData,
          $$TagsTableTableFilterComposer,
          $$TagsTableTableOrderingComposer,
          $$TagsTableTableAnnotationComposer,
          $$TagsTableTableCreateCompanionBuilder,
          $$TagsTableTableUpdateCompanionBuilder,
          (TagsTableData, $$TagsTableTableReferences),
          TagsTableData,
          PrefetchHooks Function({bool scoreTagsTableRefs})
        > {
  $$TagsTableTableTableManager(_$Database db, $TagsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int color,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion.insert(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TagsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scoreTagsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (scoreTagsTableRefs) db.scoreTagsTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (scoreTagsTableRefs)
                    await $_getPrefetchedData<
                      TagsTableData,
                      $TagsTableTable,
                      ScoreTagsTableData
                    >(
                      currentTable: table,
                      referencedTable: $$TagsTableTableReferences
                          ._scoreTagsTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).scoreTagsTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tag == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $TagsTableTable,
      TagsTableData,
      $$TagsTableTableFilterComposer,
      $$TagsTableTableOrderingComposer,
      $$TagsTableTableAnnotationComposer,
      $$TagsTableTableCreateCompanionBuilder,
      $$TagsTableTableUpdateCompanionBuilder,
      (TagsTableData, $$TagsTableTableReferences),
      TagsTableData,
      PrefetchHooks Function({bool scoreTagsTableRefs})
    >;
typedef $$ScoreTagsTableTableCreateCompanionBuilder =
    ScoreTagsTableCompanion Function({
      required String score,
      required String tag,
      Value<int> rowid,
    });
typedef $$ScoreTagsTableTableUpdateCompanionBuilder =
    ScoreTagsTableCompanion Function({
      Value<String> score,
      Value<String> tag,
      Value<int> rowid,
    });

final class $$ScoreTagsTableTableReferences
    extends
        BaseReferences<_$Database, $ScoreTagsTableTable, ScoreTagsTableData> {
  $$ScoreTagsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ScoresTableTable _scoreTable(_$Database db) =>
      db.scoresTable.createAlias('score_tags__score__scores__id');

  $$ScoresTableTableProcessedTableManager get score {
    final $_column = $_itemColumn<String>('score')!;

    final manager = $$ScoresTableTableTableManager(
      $_db,
      $_db.scoresTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scoreTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTableTable _tagTable(_$Database db) =>
      db.tagsTable.createAlias('score_tags__tag__tags__id');

  $$TagsTableTableProcessedTableManager get tag {
    final $_column = $_itemColumn<String>('tag')!;

    final manager = $$TagsTableTableTableManager(
      $_db,
      $_db.tagsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ScoreTagsTableTableFilterComposer
    extends Composer<_$Database, $ScoreTagsTableTable> {
  $$ScoreTagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableTableFilterComposer get score {
    final $$ScoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableFilterComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableTableFilterComposer get tag {
    final $$TagsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tag,
      referencedTable: $db.tagsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableTableFilterComposer(
            $db: $db,
            $table: $db.tagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableTableOrderingComposer
    extends Composer<_$Database, $ScoreTagsTableTable> {
  $$ScoreTagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableTableOrderingComposer get score {
    final $$ScoresTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableOrderingComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableTableOrderingComposer get tag {
    final $$TagsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tag,
      referencedTable: $db.tagsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableTableOrderingComposer(
            $db: $db,
            $table: $db.tagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableTableAnnotationComposer
    extends Composer<_$Database, $ScoreTagsTableTable> {
  $$ScoreTagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ScoresTableTableAnnotationComposer get score {
    final $$ScoresTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.score,
      referencedTable: $db.scoresTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ScoresTableTableAnnotationComposer(
            $db: $db,
            $table: $db.scoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableTableAnnotationComposer get tag {
    final $$TagsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tag,
      referencedTable: $db.tagsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.tagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ScoreTagsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ScoreTagsTableTable,
          ScoreTagsTableData,
          $$ScoreTagsTableTableFilterComposer,
          $$ScoreTagsTableTableOrderingComposer,
          $$ScoreTagsTableTableAnnotationComposer,
          $$ScoreTagsTableTableCreateCompanionBuilder,
          $$ScoreTagsTableTableUpdateCompanionBuilder,
          (ScoreTagsTableData, $$ScoreTagsTableTableReferences),
          ScoreTagsTableData,
          PrefetchHooks Function({bool score, bool tag})
        > {
  $$ScoreTagsTableTableTableManager(_$Database db, $ScoreTagsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoreTagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoreTagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoreTagsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> score = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  ScoreTagsTableCompanion(score: score, tag: tag, rowid: rowid),
          createCompanionCallback:
              ({
                required String score,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => ScoreTagsTableCompanion.insert(
                score: score,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ScoreTagsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({score = false, tag = false}) {
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
                    if (score) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.score,
                                referencedTable: $$ScoreTagsTableTableReferences
                                    ._scoreTable(db),
                                referencedColumn:
                                    $$ScoreTagsTableTableReferences
                                        ._scoreTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (tag) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tag,
                                referencedTable: $$ScoreTagsTableTableReferences
                                    ._tagTable(db),
                                referencedColumn:
                                    $$ScoreTagsTableTableReferences
                                        ._tagTable(db)
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

typedef $$ScoreTagsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ScoreTagsTableTable,
      ScoreTagsTableData,
      $$ScoreTagsTableTableFilterComposer,
      $$ScoreTagsTableTableOrderingComposer,
      $$ScoreTagsTableTableAnnotationComposer,
      $$ScoreTagsTableTableCreateCompanionBuilder,
      $$ScoreTagsTableTableUpdateCompanionBuilder,
      (ScoreTagsTableData, $$ScoreTagsTableTableReferences),
      ScoreTagsTableData,
      PrefetchHooks Function({bool score, bool tag})
    >;
typedef $$KeyValueTableTableCreateCompanionBuilder =
    KeyValueTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValueTableTableUpdateCompanionBuilder =
    KeyValueTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$KeyValueTableTableFilterComposer
    extends Composer<_$Database, $KeyValueTableTable> {
  $$KeyValueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueTableTableOrderingComposer
    extends Composer<_$Database, $KeyValueTableTable> {
  $$KeyValueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueTableTableAnnotationComposer
    extends Composer<_$Database, $KeyValueTableTable> {
  $$KeyValueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $KeyValueTableTable,
          KeyValueTableData,
          $$KeyValueTableTableFilterComposer,
          $$KeyValueTableTableOrderingComposer,
          $$KeyValueTableTableAnnotationComposer,
          $$KeyValueTableTableCreateCompanionBuilder,
          $$KeyValueTableTableUpdateCompanionBuilder,
          (
            KeyValueTableData,
            BaseReferences<_$Database, $KeyValueTableTable, KeyValueTableData>,
          ),
          KeyValueTableData,
          PrefetchHooks Function()
        > {
  $$KeyValueTableTableTableManager(_$Database db, $KeyValueTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  KeyValueTableCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValueTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $KeyValueTableTable,
      KeyValueTableData,
      $$KeyValueTableTableFilterComposer,
      $$KeyValueTableTableOrderingComposer,
      $$KeyValueTableTableAnnotationComposer,
      $$KeyValueTableTableCreateCompanionBuilder,
      $$KeyValueTableTableUpdateCompanionBuilder,
      (
        KeyValueTableData,
        BaseReferences<_$Database, $KeyValueTableTable, KeyValueTableData>,
      ),
      KeyValueTableData,
      PrefetchHooks Function()
    >;
typedef $$DeletedTagsTableTableCreateCompanionBuilder =
    DeletedTagsTableCompanion Function({
      required String tagId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedTagsTableTableUpdateCompanionBuilder =
    DeletedTagsTableCompanion Function({
      Value<String> tagId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedTagsTableTableFilterComposer
    extends Composer<_$Database, $DeletedTagsTableTable> {
  $$DeletedTagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedTagsTableTableOrderingComposer
    extends Composer<_$Database, $DeletedTagsTableTable> {
  $$DeletedTagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedTagsTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedTagsTableTable> {
  $$DeletedTagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedTagsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedTagsTableTable,
          DeletedTagsTableData,
          $$DeletedTagsTableTableFilterComposer,
          $$DeletedTagsTableTableOrderingComposer,
          $$DeletedTagsTableTableAnnotationComposer,
          $$DeletedTagsTableTableCreateCompanionBuilder,
          $$DeletedTagsTableTableUpdateCompanionBuilder,
          (
            DeletedTagsTableData,
            BaseReferences<
              _$Database,
              $DeletedTagsTableTable,
              DeletedTagsTableData
            >,
          ),
          DeletedTagsTableData,
          PrefetchHooks Function()
        > {
  $$DeletedTagsTableTableTableManager(
    _$Database db,
    $DeletedTagsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedTagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedTagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletedTagsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tagId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedTagsTableCompanion(
                tagId: tagId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tagId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedTagsTableCompanion.insert(
                tagId: tagId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedTagsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedTagsTableTable,
      DeletedTagsTableData,
      $$DeletedTagsTableTableFilterComposer,
      $$DeletedTagsTableTableOrderingComposer,
      $$DeletedTagsTableTableAnnotationComposer,
      $$DeletedTagsTableTableCreateCompanionBuilder,
      $$DeletedTagsTableTableUpdateCompanionBuilder,
      (
        DeletedTagsTableData,
        BaseReferences<
          _$Database,
          $DeletedTagsTableTable,
          DeletedTagsTableData
        >,
      ),
      DeletedTagsTableData,
      PrefetchHooks Function()
    >;
typedef $$DeletedScoresTableTableCreateCompanionBuilder =
    DeletedScoresTableCompanion Function({
      required String scoreId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedScoresTableTableUpdateCompanionBuilder =
    DeletedScoresTableCompanion Function({
      Value<String> scoreId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedScoresTableTableFilterComposer
    extends Composer<_$Database, $DeletedScoresTableTable> {
  $$DeletedScoresTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scoreId => $composableBuilder(
    column: $table.scoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedScoresTableTableOrderingComposer
    extends Composer<_$Database, $DeletedScoresTableTable> {
  $$DeletedScoresTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scoreId => $composableBuilder(
    column: $table.scoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedScoresTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedScoresTableTable> {
  $$DeletedScoresTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scoreId =>
      $composableBuilder(column: $table.scoreId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedScoresTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedScoresTableTable,
          DeletedScoresTableData,
          $$DeletedScoresTableTableFilterComposer,
          $$DeletedScoresTableTableOrderingComposer,
          $$DeletedScoresTableTableAnnotationComposer,
          $$DeletedScoresTableTableCreateCompanionBuilder,
          $$DeletedScoresTableTableUpdateCompanionBuilder,
          (
            DeletedScoresTableData,
            BaseReferences<
              _$Database,
              $DeletedScoresTableTable,
              DeletedScoresTableData
            >,
          ),
          DeletedScoresTableData,
          PrefetchHooks Function()
        > {
  $$DeletedScoresTableTableTableManager(
    _$Database db,
    $DeletedScoresTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedScoresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedScoresTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletedScoresTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scoreId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedScoresTableCompanion(
                scoreId: scoreId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scoreId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedScoresTableCompanion.insert(
                scoreId: scoreId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedScoresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedScoresTableTable,
      DeletedScoresTableData,
      $$DeletedScoresTableTableFilterComposer,
      $$DeletedScoresTableTableOrderingComposer,
      $$DeletedScoresTableTableAnnotationComposer,
      $$DeletedScoresTableTableCreateCompanionBuilder,
      $$DeletedScoresTableTableUpdateCompanionBuilder,
      (
        DeletedScoresTableData,
        BaseReferences<
          _$Database,
          $DeletedScoresTableTable,
          DeletedScoresTableData
        >,
      ),
      DeletedScoresTableData,
      PrefetchHooks Function()
    >;
typedef $$LogMessageTableTableCreateCompanionBuilder =
    LogMessageTableCompanion Function({
      Value<int> id,
      required DateTime sessionStartTime,
      required DateTime time,
      required Level level,
      required String tag,
      required String message,
      required String stackTrace,
      Value<String?> exception,
    });
typedef $$LogMessageTableTableUpdateCompanionBuilder =
    LogMessageTableCompanion Function({
      Value<int> id,
      Value<DateTime> sessionStartTime,
      Value<DateTime> time,
      Value<Level> level,
      Value<String> tag,
      Value<String> message,
      Value<String> stackTrace,
      Value<String?> exception,
    });

class $$LogMessageTableTableFilterComposer
    extends Composer<_$Database, $LogMessageTableTable> {
  $$LogMessageTableTableFilterComposer({
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

  ColumnFilters<DateTime> get sessionStartTime => $composableBuilder(
    column: $table.sessionStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Level, Level, String> get level =>
      $composableBuilder(
        column: $table.level,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exception => $composableBuilder(
    column: $table.exception,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogMessageTableTableOrderingComposer
    extends Composer<_$Database, $LogMessageTableTable> {
  $$LogMessageTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get sessionStartTime => $composableBuilder(
    column: $table.sessionStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exception => $composableBuilder(
    column: $table.exception,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogMessageTableTableAnnotationComposer
    extends Composer<_$Database, $LogMessageTableTable> {
  $$LogMessageTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get sessionStartTime => $composableBuilder(
    column: $table.sessionStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Level, String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get stackTrace => $composableBuilder(
    column: $table.stackTrace,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exception =>
      $composableBuilder(column: $table.exception, builder: (column) => column);
}

class $$LogMessageTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $LogMessageTableTable,
          LogMessageTableData,
          $$LogMessageTableTableFilterComposer,
          $$LogMessageTableTableOrderingComposer,
          $$LogMessageTableTableAnnotationComposer,
          $$LogMessageTableTableCreateCompanionBuilder,
          $$LogMessageTableTableUpdateCompanionBuilder,
          (
            LogMessageTableData,
            BaseReferences<
              _$Database,
              $LogMessageTableTable,
              LogMessageTableData
            >,
          ),
          LogMessageTableData,
          PrefetchHooks Function()
        > {
  $$LogMessageTableTableTableManager(_$Database db, $LogMessageTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogMessageTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogMessageTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogMessageTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> sessionStartTime = const Value.absent(),
                Value<DateTime> time = const Value.absent(),
                Value<Level> level = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> stackTrace = const Value.absent(),
                Value<String?> exception = const Value.absent(),
              }) => LogMessageTableCompanion(
                id: id,
                sessionStartTime: sessionStartTime,
                time: time,
                level: level,
                tag: tag,
                message: message,
                stackTrace: stackTrace,
                exception: exception,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime sessionStartTime,
                required DateTime time,
                required Level level,
                required String tag,
                required String message,
                required String stackTrace,
                Value<String?> exception = const Value.absent(),
              }) => LogMessageTableCompanion.insert(
                id: id,
                sessionStartTime: sessionStartTime,
                time: time,
                level: level,
                tag: tag,
                message: message,
                stackTrace: stackTrace,
                exception: exception,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogMessageTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $LogMessageTableTable,
      LogMessageTableData,
      $$LogMessageTableTableFilterComposer,
      $$LogMessageTableTableOrderingComposer,
      $$LogMessageTableTableAnnotationComposer,
      $$LogMessageTableTableCreateCompanionBuilder,
      $$LogMessageTableTableUpdateCompanionBuilder,
      (
        LogMessageTableData,
        BaseReferences<_$Database, $LogMessageTableTable, LogMessageTableData>,
      ),
      LogMessageTableData,
      PrefetchHooks Function()
    >;
typedef $$SetlistsTableTableCreateCompanionBuilder =
    SetlistsTableCompanion Function({
      required String id,
      required String name,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$SetlistsTableTableUpdateCompanionBuilder =
    SetlistsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$SetlistsTableTableReferences
    extends BaseReferences<_$Database, $SetlistsTableTable, SetlistsTableData> {
  $$SetlistsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $SetlistEntriesTableTable,
    List<SetlistEntriesTableData>
  >
  _setlistEntriesTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.setlistEntriesTable,
    aliasName: 'setlists__id__setlist_entries__setlist',
  );

  $$SetlistEntriesTableTableProcessedTableManager get setlistEntriesTableRefs {
    final manager = $$SetlistEntriesTableTableTableManager(
      $_db,
      $_db.setlistEntriesTable,
    ).filter((f) => f.setlist.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _setlistEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SetlistsTableTableFilterComposer
    extends Composer<_$Database, $SetlistsTableTable> {
  $$SetlistsTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setlistEntriesTableRefs(
    Expression<bool> Function($$SetlistEntriesTableTableFilterComposer f) f,
  ) {
    final $$SetlistEntriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setlistEntriesTable,
      getReferencedColumn: (t) => t.setlist,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistEntriesTableTableFilterComposer(
            $db: $db,
            $table: $db.setlistEntriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetlistsTableTableOrderingComposer
    extends Composer<_$Database, $SetlistsTableTable> {
  $$SetlistsTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetlistsTableTableAnnotationComposer
    extends Composer<_$Database, $SetlistsTableTable> {
  $$SetlistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  Expression<T> setlistEntriesTableRefs<T extends Object>(
    Expression<T> Function($$SetlistEntriesTableTableAnnotationComposer a) f,
  ) {
    final $$SetlistEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.setlistEntriesTable,
          getReferencedColumn: (t) => t.setlist,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SetlistEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.setlistEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SetlistsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $SetlistsTableTable,
          SetlistsTableData,
          $$SetlistsTableTableFilterComposer,
          $$SetlistsTableTableOrderingComposer,
          $$SetlistsTableTableAnnotationComposer,
          $$SetlistsTableTableCreateCompanionBuilder,
          $$SetlistsTableTableUpdateCompanionBuilder,
          (SetlistsTableData, $$SetlistsTableTableReferences),
          SetlistsTableData,
          PrefetchHooks Function({bool setlistEntriesTableRefs})
        > {
  $$SetlistsTableTableTableManager(_$Database db, $SetlistsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsTableCompanion(
                id: id,
                name: name,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsTableCompanion.insert(
                id: id,
                name: name,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetlistsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlistEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (setlistEntriesTableRefs) db.setlistEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setlistEntriesTableRefs)
                    await $_getPrefetchedData<
                      SetlistsTableData,
                      $SetlistsTableTable,
                      SetlistEntriesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$SetlistsTableTableReferences
                          ._setlistEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SetlistsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).setlistEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.setlist == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SetlistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $SetlistsTableTable,
      SetlistsTableData,
      $$SetlistsTableTableFilterComposer,
      $$SetlistsTableTableOrderingComposer,
      $$SetlistsTableTableAnnotationComposer,
      $$SetlistsTableTableCreateCompanionBuilder,
      $$SetlistsTableTableUpdateCompanionBuilder,
      (SetlistsTableData, $$SetlistsTableTableReferences),
      SetlistsTableData,
      PrefetchHooks Function({bool setlistEntriesTableRefs})
    >;
typedef $$SetlistEntriesTableTableCreateCompanionBuilder =
    SetlistEntriesTableCompanion Function({
      required String setlist,
      required String score,
      required int position,
      Value<int> rowid,
    });
typedef $$SetlistEntriesTableTableUpdateCompanionBuilder =
    SetlistEntriesTableCompanion Function({
      Value<String> setlist,
      Value<String> score,
      Value<int> position,
      Value<int> rowid,
    });

final class $$SetlistEntriesTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $SetlistEntriesTableTable,
          SetlistEntriesTableData
        > {
  $$SetlistEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SetlistsTableTable _setlistTable(_$Database db) =>
      db.setlistsTable.createAlias('setlist_entries__setlist__setlists__id');

  $$SetlistsTableTableProcessedTableManager get setlist {
    final $_column = $_itemColumn<String>('setlist')!;

    final manager = $$SetlistsTableTableTableManager(
      $_db,
      $_db.setlistsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setlistTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetlistEntriesTableTableFilterComposer
    extends Composer<_$Database, $SetlistEntriesTableTable> {
  $$SetlistEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SetlistsTableTableFilterComposer get setlist {
    final $$SetlistsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlist,
      referencedTable: $db.setlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableTableFilterComposer(
            $db: $db,
            $table: $db.setlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistEntriesTableTableOrderingComposer
    extends Composer<_$Database, $SetlistEntriesTableTable> {
  $$SetlistEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SetlistsTableTableOrderingComposer get setlist {
    final $$SetlistsTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlist,
      referencedTable: $db.setlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableTableOrderingComposer(
            $db: $db,
            $table: $db.setlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistEntriesTableTableAnnotationComposer
    extends Composer<_$Database, $SetlistEntriesTableTable> {
  $$SetlistEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SetlistsTableTableAnnotationComposer get setlist {
    final $$SetlistsTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setlist,
      referencedTable: $db.setlistsTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetlistsTableTableAnnotationComposer(
            $db: $db,
            $table: $db.setlistsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetlistEntriesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $SetlistEntriesTableTable,
          SetlistEntriesTableData,
          $$SetlistEntriesTableTableFilterComposer,
          $$SetlistEntriesTableTableOrderingComposer,
          $$SetlistEntriesTableTableAnnotationComposer,
          $$SetlistEntriesTableTableCreateCompanionBuilder,
          $$SetlistEntriesTableTableUpdateCompanionBuilder,
          (SetlistEntriesTableData, $$SetlistEntriesTableTableReferences),
          SetlistEntriesTableData,
          PrefetchHooks Function({bool setlist})
        > {
  $$SetlistEntriesTableTableTableManager(
    _$Database db,
    $SetlistEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistEntriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SetlistEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> setlist = const Value.absent(),
                Value<String> score = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistEntriesTableCompanion(
                setlist: setlist,
                score: score,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setlist,
                required String score,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => SetlistEntriesTableCompanion.insert(
                setlist: setlist,
                score: score,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetlistEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setlist = false}) {
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
                    if (setlist) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setlist,
                                referencedTable:
                                    $$SetlistEntriesTableTableReferences
                                        ._setlistTable(db),
                                referencedColumn:
                                    $$SetlistEntriesTableTableReferences
                                        ._setlistTable(db)
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

typedef $$SetlistEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $SetlistEntriesTableTable,
      SetlistEntriesTableData,
      $$SetlistEntriesTableTableFilterComposer,
      $$SetlistEntriesTableTableOrderingComposer,
      $$SetlistEntriesTableTableAnnotationComposer,
      $$SetlistEntriesTableTableCreateCompanionBuilder,
      $$SetlistEntriesTableTableUpdateCompanionBuilder,
      (SetlistEntriesTableData, $$SetlistEntriesTableTableReferences),
      SetlistEntriesTableData,
      PrefetchHooks Function({bool setlist})
    >;
typedef $$DeletedSetlistsTableTableCreateCompanionBuilder =
    DeletedSetlistsTableCompanion Function({
      required String setlistId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedSetlistsTableTableUpdateCompanionBuilder =
    DeletedSetlistsTableCompanion Function({
      Value<String> setlistId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedSetlistsTableTableFilterComposer
    extends Composer<_$Database, $DeletedSetlistsTableTable> {
  $$DeletedSetlistsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get setlistId => $composableBuilder(
    column: $table.setlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedSetlistsTableTableOrderingComposer
    extends Composer<_$Database, $DeletedSetlistsTableTable> {
  $$DeletedSetlistsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get setlistId => $composableBuilder(
    column: $table.setlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedSetlistsTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedSetlistsTableTable> {
  $$DeletedSetlistsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get setlistId =>
      $composableBuilder(column: $table.setlistId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedSetlistsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedSetlistsTableTable,
          DeletedSetlistsTableData,
          $$DeletedSetlistsTableTableFilterComposer,
          $$DeletedSetlistsTableTableOrderingComposer,
          $$DeletedSetlistsTableTableAnnotationComposer,
          $$DeletedSetlistsTableTableCreateCompanionBuilder,
          $$DeletedSetlistsTableTableUpdateCompanionBuilder,
          (
            DeletedSetlistsTableData,
            BaseReferences<
              _$Database,
              $DeletedSetlistsTableTable,
              DeletedSetlistsTableData
            >,
          ),
          DeletedSetlistsTableData,
          PrefetchHooks Function()
        > {
  $$DeletedSetlistsTableTableTableManager(
    _$Database db,
    $DeletedSetlistsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedSetlistsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedSetlistsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedSetlistsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> setlistId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedSetlistsTableCompanion(
                setlistId: setlistId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String setlistId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedSetlistsTableCompanion.insert(
                setlistId: setlistId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedSetlistsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedSetlistsTableTable,
      DeletedSetlistsTableData,
      $$DeletedSetlistsTableTableFilterComposer,
      $$DeletedSetlistsTableTableOrderingComposer,
      $$DeletedSetlistsTableTableAnnotationComposer,
      $$DeletedSetlistsTableTableCreateCompanionBuilder,
      $$DeletedSetlistsTableTableUpdateCompanionBuilder,
      (
        DeletedSetlistsTableData,
        BaseReferences<
          _$Database,
          $DeletedSetlistsTableTable,
          DeletedSetlistsTableData
        >,
      ),
      DeletedSetlistsTableData,
      PrefetchHooks Function()
    >;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$ScoresTableTableTableManager get scoresTable =>
      $$ScoresTableTableTableManager(_db, _db.scoresTable);
  $$GenresTableTableTableManager get genresTable =>
      $$GenresTableTableTableManager(_db, _db.genresTable);
  $$InstrumentsTableTableTableManager get instrumentsTable =>
      $$InstrumentsTableTableTableManager(_db, _db.instrumentsTable);
  $$TagsTableTableTableManager get tagsTable =>
      $$TagsTableTableTableManager(_db, _db.tagsTable);
  $$ScoreTagsTableTableTableManager get scoreTagsTable =>
      $$ScoreTagsTableTableTableManager(_db, _db.scoreTagsTable);
  $$KeyValueTableTableTableManager get keyValueTable =>
      $$KeyValueTableTableTableManager(_db, _db.keyValueTable);
  $$DeletedTagsTableTableTableManager get deletedTagsTable =>
      $$DeletedTagsTableTableTableManager(_db, _db.deletedTagsTable);
  $$DeletedScoresTableTableTableManager get deletedScoresTable =>
      $$DeletedScoresTableTableTableManager(_db, _db.deletedScoresTable);
  $$LogMessageTableTableTableManager get logMessageTable =>
      $$LogMessageTableTableTableManager(_db, _db.logMessageTable);
  $$SetlistsTableTableTableManager get setlistsTable =>
      $$SetlistsTableTableTableManager(_db, _db.setlistsTable);
  $$SetlistEntriesTableTableTableManager get setlistEntriesTable =>
      $$SetlistEntriesTableTableTableManager(_db, _db.setlistEntriesTable);
  $$DeletedSetlistsTableTableTableManager get deletedSetlistsTable =>
      $$DeletedSetlistsTableTableTableManager(_db, _db.deletedSetlistsTable);
}
