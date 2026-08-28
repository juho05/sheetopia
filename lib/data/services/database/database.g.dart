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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceLinkMeta = const VerificationMeta(
    'sourceLink',
  );
  @override
  late final GeneratedColumn<String> sourceLink = GeneratedColumn<String>(
    'source_link',
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
  late final GeneratedColumnWithTypeConverter<ScoreType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ScoreType.score.name),
      ).withConverter<ScoreType>($ScoresTableTable.$convertertype);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    composer,
    source,
    sourceLink,
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
    type,
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_link')) {
      context.handle(
        _sourceLinkMeta,
        sourceLink.isAcceptableOrUnknown(data['source_link']!, _sourceLinkMeta),
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
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sourceLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_link'],
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
      type: $ScoresTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
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
  static JsonTypeConverter2<ScoreType, String, String> $convertertype =
      const EnumNameConverter<ScoreType>(ScoreType.values);
}

class ScoresTableData extends DataClass implements Insertable<ScoresTableData> {
  final String id;
  final String title;
  final String? composer;
  final String? source;
  final String? sourceLink;
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
  final ScoreType type;
  const ScoresTableData({
    required this.id,
    required this.title,
    this.composer,
    this.source,
    this.sourceLink,
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
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || sourceLink != null) {
      map['source_link'] = Variable<String>(sourceLink);
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
    {
      map['type'] = Variable<String>(
        $ScoresTableTable.$convertertype.toSql(type),
      );
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
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sourceLink: sourceLink == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLink),
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
      type: Value(type),
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
      source: serializer.fromJson<String?>(json['source']),
      sourceLink: serializer.fromJson<String?>(json['sourceLink']),
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
      type: $ScoresTableTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String?>(composer),
      'source': serializer.toJson<String?>(source),
      'sourceLink': serializer.toJson<String?>(sourceLink),
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
      'type': serializer.toJson<String>(
        $ScoresTableTable.$convertertype.toJson(type),
      ),
    };
  }

  ScoresTableData copyWith({
    String? id,
    String? title,
    Value<String?> composer = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> sourceLink = const Value.absent(),
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
    ScoreType? type,
  }) => ScoresTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    source: source.present ? source.value : this.source,
    sourceLink: sourceLink.present ? sourceLink.value : this.sourceLink,
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
    type: type ?? this.type,
  );
  @override
  String toString() {
    return (StringBuffer('ScoresTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('source: $source, ')
          ..write('sourceLink: $sourceLink, ')
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
          ..write('annotations: $annotations, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    composer,
    source,
    sourceLink,
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
    type,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoresTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.source == this.source &&
          other.sourceLink == this.sourceLink &&
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
          other.annotations == this.annotations &&
          other.type == this.type);
}

class ScoresTableCompanion extends UpdateCompanion<ScoresTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> composer;
  final Value<String?> source;
  final Value<String?> sourceLink;
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
  final Value<ScoreType> type;
  final Value<int> rowid;
  const ScoresTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceLink = const Value.absent(),
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
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresTableCompanion.insert({
    required String id,
    required String title,
    this.composer = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceLink = const Value.absent(),
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
    this.type = const Value.absent(),
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
    Expression<String>? source,
    Expression<String>? sourceLink,
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
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (source != null) 'source': source,
      if (sourceLink != null) 'source_link': sourceLink,
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
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? composer,
    Value<String?>? source,
    Value<String?>? sourceLink,
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
    Value<ScoreType>? type,
    Value<int>? rowid,
  }) {
    return ScoresTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      source: source ?? this.source,
      sourceLink: sourceLink ?? this.sourceLink,
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
      type: type ?? this.type,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceLink.present) {
      map['source_link'] = Variable<String>(sourceLink.value);
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
    if (type.present) {
      map['type'] = Variable<String>(
        $ScoresTableTable.$convertertype.toSql(type.value),
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
          ..write('composer: $composer, ')
          ..write('source: $source, ')
          ..write('sourceLink: $sourceLink, ')
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
          ..write('type: $type, ')
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
  @override
  late final GeneratedColumnWithTypeConverter<TagType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(TagType.score.name),
      ).withConverter<TagType>($TagsTableTable.$convertertype);
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
    type,
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
      type: $TagsTableTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
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

  static JsonTypeConverter2<TagType, String, String> $convertertype =
      const EnumNameConverter<TagType>(TagType.values);
}

class TagsTableData extends DataClass implements Insertable<TagsTableData> {
  final String id;
  final String name;
  final int color;
  final DateTime updatedAt;
  final TagType type;
  final DateTime? writtenAt;
  final bool uploaded;
  const TagsTableData({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
    required this.type,
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
    {
      map['type'] = Variable<String>(
        $TagsTableTable.$convertertype.toSql(type),
      );
    }
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
      type: Value(type),
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
      type: $TagsTableTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
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
      'type': serializer.toJson<String>(
        $TagsTableTable.$convertertype.toJson(type),
      ),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  TagsTableData copyWith({
    String? id,
    String? name,
    int? color,
    DateTime? updatedAt,
    TagType? type,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => TagsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  TagsTableData copyWithCompanion(TagsTableCompanion data) {
    return TagsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
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
          ..write('type: $type, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, updatedAt, type, writtenAt, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class TagsTableCompanion extends UpdateCompanion<TagsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<DateTime> updatedAt;
  final Value<TagType> type;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const TagsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsTableCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
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
    Expression<String>? type,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
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
    Value<TagType>? type,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return TagsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
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
    if (type.present) {
      map['type'] = Variable<String>(
        $TagsTableTable.$convertertype.toSql(type.value),
      );
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
          ..write('type: $type, ')
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

class $ExerciseCategoriesTableTable extends ExerciseCategoriesTable
    with TableInfo<$ExerciseCategoriesTableTable, ExerciseCategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseCategoriesTableTable(this.attachedDatabase, [this._alias]);
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
    position,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseCategoriesTableData> instance, {
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
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
  ExerciseCategoriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseCategoriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
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
  $ExerciseCategoriesTableTable createAlias(String alias) {
    return $ExerciseCategoriesTableTable(attachedDatabase, alias);
  }
}

class ExerciseCategoriesTableData extends DataClass
    implements Insertable<ExerciseCategoriesTableData> {
  final String id;
  final String name;
  final int position;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const ExerciseCategoriesTableData({
    required this.id,
    required this.name,
    required this.position,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  ExerciseCategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return ExerciseCategoriesTableCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory ExerciseCategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseCategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
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
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  ExerciseCategoriesTableData copyWith({
    String? id,
    String? name,
    int? position,
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => ExerciseCategoriesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  ExerciseCategoriesTableData copyWithCompanion(
    ExerciseCategoriesTableCompanion data,
  ) {
    return ExerciseCategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseCategoriesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, position, updatedAt, writtenAt, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseCategoriesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class ExerciseCategoriesTableCompanion
    extends UpdateCompanion<ExerciseCategoriesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const ExerciseCategoriesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseCategoriesTableCompanion.insert({
    required String id,
    required String name,
    required int position,
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position);
  static Insertable<ExerciseCategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseCategoriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return ExerciseCategoriesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
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
    if (position.present) {
      map['position'] = Variable<int>(position.value);
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
    return (StringBuffer('ExerciseCategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTableTable extends ExercisesTable
    with TableInfo<$ExercisesTableTable, ExercisesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercise_categories (id) ON UPDATE CASCADE ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceLinkMeta = const VerificationMeta(
    'sourceLink',
  );
  @override
  late final GeneratedColumn<String> sourceLink = GeneratedColumn<String>(
    'source_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instrumentMeta = const VerificationMeta(
    'instrument',
  );
  @override
  late final GeneratedColumn<String> instrument = GeneratedColumn<String>(
    'instrument',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetBpmMeta = const VerificationMeta(
    'targetBpm',
  );
  @override
  late final GeneratedColumn<int> targetBpm = GeneratedColumn<int>(
    'target_bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    category,
    description,
    source,
    sourceLink,
    instrument,
    targetBpm,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExercisesTableData> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_link')) {
      context.handle(
        _sourceLinkMeta,
        sourceLink.isAcceptableOrUnknown(data['source_link']!, _sourceLinkMeta),
      );
    }
    if (data.containsKey('instrument')) {
      context.handle(
        _instrumentMeta,
        instrument.isAcceptableOrUnknown(data['instrument']!, _instrumentMeta),
      );
    }
    if (data.containsKey('target_bpm')) {
      context.handle(
        _targetBpmMeta,
        targetBpm.isAcceptableOrUnknown(data['target_bpm']!, _targetBpmMeta),
      );
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
  ExercisesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExercisesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      sourceLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_link'],
      ),
      instrument: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instrument'],
      ),
      targetBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_bpm'],
      ),
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
  $ExercisesTableTable createAlias(String alias) {
    return $ExercisesTableTable(attachedDatabase, alias);
  }
}

class ExercisesTableData extends DataClass
    implements Insertable<ExercisesTableData> {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? source;
  final String? sourceLink;
  final String? instrument;
  final int? targetBpm;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const ExercisesTableData({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.source,
    this.sourceLink,
    this.instrument,
    this.targetBpm,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || sourceLink != null) {
      map['source_link'] = Variable<String>(sourceLink);
    }
    if (!nullToAbsent || instrument != null) {
      map['instrument'] = Variable<String>(instrument);
    }
    if (!nullToAbsent || targetBpm != null) {
      map['target_bpm'] = Variable<int>(targetBpm);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  ExercisesTableCompanion toCompanion(bool nullToAbsent) {
    return ExercisesTableCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      sourceLink: sourceLink == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLink),
      instrument: instrument == null && nullToAbsent
          ? const Value.absent()
          : Value(instrument),
      targetBpm: targetBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBpm),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory ExercisesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExercisesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      source: serializer.fromJson<String?>(json['source']),
      sourceLink: serializer.fromJson<String?>(json['sourceLink']),
      instrument: serializer.fromJson<String?>(json['instrument']),
      targetBpm: serializer.fromJson<int?>(json['targetBpm']),
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
      'category': serializer.toJson<String?>(category),
      'description': serializer.toJson<String?>(description),
      'source': serializer.toJson<String?>(source),
      'sourceLink': serializer.toJson<String?>(sourceLink),
      'instrument': serializer.toJson<String?>(instrument),
      'targetBpm': serializer.toJson<int?>(targetBpm),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  ExercisesTableData copyWith({
    String? id,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> sourceLink = const Value.absent(),
    Value<String?> instrument = const Value.absent(),
    Value<int?> targetBpm = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => ExercisesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    description: description.present ? description.value : this.description,
    source: source.present ? source.value : this.source,
    sourceLink: sourceLink.present ? sourceLink.value : this.sourceLink,
    instrument: instrument.present ? instrument.value : this.instrument,
    targetBpm: targetBpm.present ? targetBpm.value : this.targetBpm,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  ExercisesTableData copyWithCompanion(ExercisesTableCompanion data) {
    return ExercisesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      source: data.source.present ? data.source.value : this.source,
      sourceLink: data.sourceLink.present
          ? data.sourceLink.value
          : this.sourceLink,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
      targetBpm: data.targetBpm.present ? data.targetBpm.value : this.targetBpm,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('sourceLink: $sourceLink, ')
          ..write('instrument: $instrument, ')
          ..write('targetBpm: $targetBpm, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    description,
    source,
    sourceLink,
    instrument,
    targetBpm,
    updatedAt,
    writtenAt,
    uploaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExercisesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.description == this.description &&
          other.source == this.source &&
          other.sourceLink == this.sourceLink &&
          other.instrument == this.instrument &&
          other.targetBpm == this.targetBpm &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class ExercisesTableCompanion extends UpdateCompanion<ExercisesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<String?> description;
  final Value<String?> source;
  final Value<String?> sourceLink;
  final Value<String?> instrument;
  final Value<int?> targetBpm;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const ExercisesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceLink = const Value.absent(),
    this.instrument = const Value.absent(),
    this.targetBpm = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesTableCompanion.insert({
    required String id,
    required String name,
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceLink = const Value.absent(),
    this.instrument = const Value.absent(),
    this.targetBpm = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ExercisesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? source,
    Expression<String>? sourceLink,
    Expression<String>? instrument,
    Expression<int>? targetBpm,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (source != null) 'source': source,
      if (sourceLink != null) 'source_link': sourceLink,
      if (instrument != null) 'instrument': instrument,
      if (targetBpm != null) 'target_bpm': targetBpm,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<String?>? description,
    Value<String?>? source,
    Value<String?>? sourceLink,
    Value<String?>? instrument,
    Value<int?>? targetBpm,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return ExercisesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      source: source ?? this.source,
      sourceLink: sourceLink ?? this.sourceLink,
      instrument: instrument ?? this.instrument,
      targetBpm: targetBpm ?? this.targetBpm,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceLink.present) {
      map['source_link'] = Variable<String>(sourceLink.value);
    }
    if (instrument.present) {
      map['instrument'] = Variable<String>(instrument.value);
    }
    if (targetBpm.present) {
      map['target_bpm'] = Variable<int>(targetBpm.value);
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
    return (StringBuffer('ExercisesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('source: $source, ')
          ..write('sourceLink: $sourceLink, ')
          ..write('instrument: $instrument, ')
          ..write('targetBpm: $targetBpm, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseScoresTableTable extends ExerciseScoresTable
    with TableInfo<$ExerciseScoresTableTable, ExerciseScoresTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseScoresTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseMeta = const VerificationMeta(
    'exercise',
  );
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
    'exercise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON UPDATE CASCADE ON DELETE CASCADE',
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownedMeta = const VerificationMeta('owned');
  @override
  late final GeneratedColumn<bool> owned = GeneratedColumn<bool>(
    'owned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("owned" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    exercise,
    score,
    position,
    name,
    owned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseScoresTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise')) {
      context.handle(
        _exerciseMeta,
        exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseMeta);
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owned')) {
      context.handle(
        _ownedMeta,
        owned.isAcceptableOrUnknown(data['owned']!, _ownedMeta),
      );
    } else if (isInserting) {
      context.missing(_ownedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exercise, position};
  @override
  ExerciseScoresTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseScoresTableData(
      exercise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      owned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}owned'],
      )!,
    );
  }

  @override
  $ExerciseScoresTableTable createAlias(String alias) {
    return $ExerciseScoresTableTable(attachedDatabase, alias);
  }
}

class ExerciseScoresTableData extends DataClass
    implements Insertable<ExerciseScoresTableData> {
  final String exercise;
  final String score;
  final int position;
  final String name;
  final bool owned;
  const ExerciseScoresTableData({
    required this.exercise,
    required this.score,
    required this.position,
    required this.name,
    required this.owned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise'] = Variable<String>(exercise);
    map['score'] = Variable<String>(score);
    map['position'] = Variable<int>(position);
    map['name'] = Variable<String>(name);
    map['owned'] = Variable<bool>(owned);
    return map;
  }

  ExerciseScoresTableCompanion toCompanion(bool nullToAbsent) {
    return ExerciseScoresTableCompanion(
      exercise: Value(exercise),
      score: Value(score),
      position: Value(position),
      name: Value(name),
      owned: Value(owned),
    );
  }

  factory ExerciseScoresTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseScoresTableData(
      exercise: serializer.fromJson<String>(json['exercise']),
      score: serializer.fromJson<String>(json['score']),
      position: serializer.fromJson<int>(json['position']),
      name: serializer.fromJson<String>(json['name']),
      owned: serializer.fromJson<bool>(json['owned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exercise': serializer.toJson<String>(exercise),
      'score': serializer.toJson<String>(score),
      'position': serializer.toJson<int>(position),
      'name': serializer.toJson<String>(name),
      'owned': serializer.toJson<bool>(owned),
    };
  }

  ExerciseScoresTableData copyWith({
    String? exercise,
    String? score,
    int? position,
    String? name,
    bool? owned,
  }) => ExerciseScoresTableData(
    exercise: exercise ?? this.exercise,
    score: score ?? this.score,
    position: position ?? this.position,
    name: name ?? this.name,
    owned: owned ?? this.owned,
  );
  ExerciseScoresTableData copyWithCompanion(ExerciseScoresTableCompanion data) {
    return ExerciseScoresTableData(
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
      score: data.score.present ? data.score.value : this.score,
      position: data.position.present ? data.position.value : this.position,
      name: data.name.present ? data.name.value : this.name,
      owned: data.owned.present ? data.owned.value : this.owned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseScoresTableData(')
          ..write('exercise: $exercise, ')
          ..write('score: $score, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('owned: $owned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exercise, score, position, name, owned);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseScoresTableData &&
          other.exercise == this.exercise &&
          other.score == this.score &&
          other.position == this.position &&
          other.name == this.name &&
          other.owned == this.owned);
}

class ExerciseScoresTableCompanion
    extends UpdateCompanion<ExerciseScoresTableData> {
  final Value<String> exercise;
  final Value<String> score;
  final Value<int> position;
  final Value<String> name;
  final Value<bool> owned;
  final Value<int> rowid;
  const ExerciseScoresTableCompanion({
    this.exercise = const Value.absent(),
    this.score = const Value.absent(),
    this.position = const Value.absent(),
    this.name = const Value.absent(),
    this.owned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseScoresTableCompanion.insert({
    required String exercise,
    required String score,
    required int position,
    required String name,
    required bool owned,
    this.rowid = const Value.absent(),
  }) : exercise = Value(exercise),
       score = Value(score),
       position = Value(position),
       name = Value(name),
       owned = Value(owned);
  static Insertable<ExerciseScoresTableData> custom({
    Expression<String>? exercise,
    Expression<String>? score,
    Expression<int>? position,
    Expression<String>? name,
    Expression<bool>? owned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exercise != null) 'exercise': exercise,
      if (score != null) 'score': score,
      if (position != null) 'position': position,
      if (name != null) 'name': name,
      if (owned != null) 'owned': owned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseScoresTableCompanion copyWith({
    Value<String>? exercise,
    Value<String>? score,
    Value<int>? position,
    Value<String>? name,
    Value<bool>? owned,
    Value<int>? rowid,
  }) {
    return ExerciseScoresTableCompanion(
      exercise: exercise ?? this.exercise,
      score: score ?? this.score,
      position: position ?? this.position,
      name: name ?? this.name,
      owned: owned ?? this.owned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
    }
    if (score.present) {
      map['score'] = Variable<String>(score.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (owned.present) {
      map['owned'] = Variable<bool>(owned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseScoresTableCompanion(')
          ..write('exercise: $exercise, ')
          ..write('score: $score, ')
          ..write('position: $position, ')
          ..write('name: $name, ')
          ..write('owned: $owned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseTagsTableTable extends ExerciseTagsTable
    with TableInfo<$ExerciseTagsTableTable, ExerciseTagsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseTagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseMeta = const VerificationMeta(
    'exercise',
  );
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
    'exercise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON UPDATE CASCADE ON DELETE CASCADE',
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
  List<GeneratedColumn> get $columns => [exercise, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseTagsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise')) {
      context.handle(
        _exerciseMeta,
        exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseMeta);
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
  Set<GeneratedColumn> get $primaryKey => {exercise, tag};
  @override
  ExerciseTagsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseTagsTableData(
      exercise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $ExerciseTagsTableTable createAlias(String alias) {
    return $ExerciseTagsTableTable(attachedDatabase, alias);
  }
}

class ExerciseTagsTableData extends DataClass
    implements Insertable<ExerciseTagsTableData> {
  final String exercise;
  final String tag;
  const ExerciseTagsTableData({required this.exercise, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise'] = Variable<String>(exercise);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ExerciseTagsTableCompanion toCompanion(bool nullToAbsent) {
    return ExerciseTagsTableCompanion(
      exercise: Value(exercise),
      tag: Value(tag),
    );
  }

  factory ExerciseTagsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseTagsTableData(
      exercise: serializer.fromJson<String>(json['exercise']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exercise': serializer.toJson<String>(exercise),
      'tag': serializer.toJson<String>(tag),
    };
  }

  ExerciseTagsTableData copyWith({String? exercise, String? tag}) =>
      ExerciseTagsTableData(
        exercise: exercise ?? this.exercise,
        tag: tag ?? this.tag,
      );
  ExerciseTagsTableData copyWithCompanion(ExerciseTagsTableCompanion data) {
    return ExerciseTagsTableData(
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseTagsTableData(')
          ..write('exercise: $exercise, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exercise, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseTagsTableData &&
          other.exercise == this.exercise &&
          other.tag == this.tag);
}

class ExerciseTagsTableCompanion
    extends UpdateCompanion<ExerciseTagsTableData> {
  final Value<String> exercise;
  final Value<String> tag;
  final Value<int> rowid;
  const ExerciseTagsTableCompanion({
    this.exercise = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseTagsTableCompanion.insert({
    required String exercise,
    required String tag,
    this.rowid = const Value.absent(),
  }) : exercise = Value(exercise),
       tag = Value(tag);
  static Insertable<ExerciseTagsTableData> custom({
    Expression<String>? exercise,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exercise != null) 'exercise': exercise,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseTagsTableCompanion copyWith({
    Value<String>? exercise,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return ExerciseTagsTableCompanion(
      exercise: exercise ?? this.exercise,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
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
    return (StringBuffer('ExerciseTagsTableCompanion(')
          ..write('exercise: $exercise, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeRoutinesTableTable extends PracticeRoutinesTable
    with TableInfo<$PracticeRoutinesTableTable, PracticeRoutinesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeRoutinesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    description,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeRoutinesTableData> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
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
  PracticeRoutinesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeRoutinesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
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
  $PracticeRoutinesTableTable createAlias(String alias) {
    return $PracticeRoutinesTableTable(attachedDatabase, alias);
  }
}

class PracticeRoutinesTableData extends DataClass
    implements Insertable<PracticeRoutinesTableData> {
  final String id;
  final String name;
  final String? description;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const PracticeRoutinesTableData({
    required this.id,
    required this.name,
    this.description,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  PracticeRoutinesTableCompanion toCompanion(bool nullToAbsent) {
    return PracticeRoutinesTableCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory PracticeRoutinesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeRoutinesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
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
      'description': serializer.toJson<String?>(description),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  PracticeRoutinesTableData copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => PracticeRoutinesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  PracticeRoutinesTableData copyWithCompanion(
    PracticeRoutinesTableCompanion data,
  ) {
    return PracticeRoutinesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeRoutinesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, updatedAt, writtenAt, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeRoutinesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class PracticeRoutinesTableCompanion
    extends UpdateCompanion<PracticeRoutinesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const PracticeRoutinesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeRoutinesTableCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PracticeRoutinesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeRoutinesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return PracticeRoutinesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
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
    return (StringBuffer('PracticeRoutinesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeRoutineEntriesTableTable extends PracticeRoutineEntriesTable
    with
        TableInfo<
          $PracticeRoutineEntriesTableTable,
          PracticeRoutineEntriesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeRoutineEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineMeta = const VerificationMeta(
    'routine',
  );
  @override
  late final GeneratedColumn<String> routine = GeneratedColumn<String>(
    'routine',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_routines (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseMeta = const VerificationMeta(
    'exercise',
  );
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
    'exercise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id) ON UPDATE CASCADE ON DELETE RESTRICT',
    ),
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
  static const VerificationMeta _extraNotesMeta = const VerificationMeta(
    'extraNotes',
  );
  @override
  late final GeneratedColumn<String> extraNotes = GeneratedColumn<String>(
    'extra_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> targetDuration =
      GeneratedColumn<int>(
        'target_duration',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>(
        $PracticeRoutineEntriesTableTable.$convertertargetDurationn,
      );
  static const VerificationMeta _defaultScoreMeta = const VerificationMeta(
    'defaultScore',
  );
  @override
  late final GeneratedColumn<String> defaultScore = GeneratedColumn<String>(
    'default_score',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    routine,
    exercise,
    position,
    extraNotes,
    targetDuration,
    defaultScore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_routine_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeRoutineEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('routine')) {
      context.handle(
        _routineMeta,
        routine.isAcceptableOrUnknown(data['routine']!, _routineMeta),
      );
    } else if (isInserting) {
      context.missing(_routineMeta);
    }
    if (data.containsKey('exercise')) {
      context.handle(
        _exerciseMeta,
        exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('extra_notes')) {
      context.handle(
        _extraNotesMeta,
        extraNotes.isAcceptableOrUnknown(data['extra_notes']!, _extraNotesMeta),
      );
    }
    if (data.containsKey('default_score')) {
      context.handle(
        _defaultScoreMeta,
        defaultScore.isAcceptableOrUnknown(
          data['default_score']!,
          _defaultScoreMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeRoutineEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeRoutineEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      routine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine'],
      )!,
      exercise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      extraNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_notes'],
      ),
      targetDuration: $PracticeRoutineEntriesTableTable
          .$convertertargetDurationn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}target_duration'],
            ),
          ),
      defaultScore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_score'],
      ),
    );
  }

  @override
  $PracticeRoutineEntriesTableTable createAlias(String alias) {
    return $PracticeRoutineEntriesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<Duration, int> $convertertargetDuration =
      const DurationConverter();
  static TypeConverter<Duration?, int?> $convertertargetDurationn =
      NullAwareTypeConverter.wrap($convertertargetDuration);
}

class PracticeRoutineEntriesTableData extends DataClass
    implements Insertable<PracticeRoutineEntriesTableData> {
  final String id;
  final String routine;
  final String exercise;
  final int position;
  final String? extraNotes;
  final Duration? targetDuration;
  final String? defaultScore;
  const PracticeRoutineEntriesTableData({
    required this.id,
    required this.routine,
    required this.exercise,
    required this.position,
    this.extraNotes,
    this.targetDuration,
    this.defaultScore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['routine'] = Variable<String>(routine);
    map['exercise'] = Variable<String>(exercise);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || extraNotes != null) {
      map['extra_notes'] = Variable<String>(extraNotes);
    }
    if (!nullToAbsent || targetDuration != null) {
      map['target_duration'] = Variable<int>(
        $PracticeRoutineEntriesTableTable.$convertertargetDurationn.toSql(
          targetDuration,
        ),
      );
    }
    if (!nullToAbsent || defaultScore != null) {
      map['default_score'] = Variable<String>(defaultScore);
    }
    return map;
  }

  PracticeRoutineEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return PracticeRoutineEntriesTableCompanion(
      id: Value(id),
      routine: Value(routine),
      exercise: Value(exercise),
      position: Value(position),
      extraNotes: extraNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(extraNotes),
      targetDuration: targetDuration == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDuration),
      defaultScore: defaultScore == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultScore),
    );
  }

  factory PracticeRoutineEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeRoutineEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      routine: serializer.fromJson<String>(json['routine']),
      exercise: serializer.fromJson<String>(json['exercise']),
      position: serializer.fromJson<int>(json['position']),
      extraNotes: serializer.fromJson<String?>(json['extraNotes']),
      targetDuration: serializer.fromJson<Duration?>(json['targetDuration']),
      defaultScore: serializer.fromJson<String?>(json['defaultScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'routine': serializer.toJson<String>(routine),
      'exercise': serializer.toJson<String>(exercise),
      'position': serializer.toJson<int>(position),
      'extraNotes': serializer.toJson<String?>(extraNotes),
      'targetDuration': serializer.toJson<Duration?>(targetDuration),
      'defaultScore': serializer.toJson<String?>(defaultScore),
    };
  }

  PracticeRoutineEntriesTableData copyWith({
    String? id,
    String? routine,
    String? exercise,
    int? position,
    Value<String?> extraNotes = const Value.absent(),
    Value<Duration?> targetDuration = const Value.absent(),
    Value<String?> defaultScore = const Value.absent(),
  }) => PracticeRoutineEntriesTableData(
    id: id ?? this.id,
    routine: routine ?? this.routine,
    exercise: exercise ?? this.exercise,
    position: position ?? this.position,
    extraNotes: extraNotes.present ? extraNotes.value : this.extraNotes,
    targetDuration: targetDuration.present
        ? targetDuration.value
        : this.targetDuration,
    defaultScore: defaultScore.present ? defaultScore.value : this.defaultScore,
  );
  PracticeRoutineEntriesTableData copyWithCompanion(
    PracticeRoutineEntriesTableCompanion data,
  ) {
    return PracticeRoutineEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      routine: data.routine.present ? data.routine.value : this.routine,
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
      position: data.position.present ? data.position.value : this.position,
      extraNotes: data.extraNotes.present
          ? data.extraNotes.value
          : this.extraNotes,
      targetDuration: data.targetDuration.present
          ? data.targetDuration.value
          : this.targetDuration,
      defaultScore: data.defaultScore.present
          ? data.defaultScore.value
          : this.defaultScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeRoutineEntriesTableData(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('exercise: $exercise, ')
          ..write('position: $position, ')
          ..write('extraNotes: $extraNotes, ')
          ..write('targetDuration: $targetDuration, ')
          ..write('defaultScore: $defaultScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    routine,
    exercise,
    position,
    extraNotes,
    targetDuration,
    defaultScore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeRoutineEntriesTableData &&
          other.id == this.id &&
          other.routine == this.routine &&
          other.exercise == this.exercise &&
          other.position == this.position &&
          other.extraNotes == this.extraNotes &&
          other.targetDuration == this.targetDuration &&
          other.defaultScore == this.defaultScore);
}

class PracticeRoutineEntriesTableCompanion
    extends UpdateCompanion<PracticeRoutineEntriesTableData> {
  final Value<String> id;
  final Value<String> routine;
  final Value<String> exercise;
  final Value<int> position;
  final Value<String?> extraNotes;
  final Value<Duration?> targetDuration;
  final Value<String?> defaultScore;
  final Value<int> rowid;
  const PracticeRoutineEntriesTableCompanion({
    this.id = const Value.absent(),
    this.routine = const Value.absent(),
    this.exercise = const Value.absent(),
    this.position = const Value.absent(),
    this.extraNotes = const Value.absent(),
    this.targetDuration = const Value.absent(),
    this.defaultScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeRoutineEntriesTableCompanion.insert({
    required String id,
    required String routine,
    required String exercise,
    required int position,
    this.extraNotes = const Value.absent(),
    this.targetDuration = const Value.absent(),
    this.defaultScore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       routine = Value(routine),
       exercise = Value(exercise),
       position = Value(position);
  static Insertable<PracticeRoutineEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? routine,
    Expression<String>? exercise,
    Expression<int>? position,
    Expression<String>? extraNotes,
    Expression<int>? targetDuration,
    Expression<String>? defaultScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routine != null) 'routine': routine,
      if (exercise != null) 'exercise': exercise,
      if (position != null) 'position': position,
      if (extraNotes != null) 'extra_notes': extraNotes,
      if (targetDuration != null) 'target_duration': targetDuration,
      if (defaultScore != null) 'default_score': defaultScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeRoutineEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? routine,
    Value<String>? exercise,
    Value<int>? position,
    Value<String?>? extraNotes,
    Value<Duration?>? targetDuration,
    Value<String?>? defaultScore,
    Value<int>? rowid,
  }) {
    return PracticeRoutineEntriesTableCompanion(
      id: id ?? this.id,
      routine: routine ?? this.routine,
      exercise: exercise ?? this.exercise,
      position: position ?? this.position,
      extraNotes: extraNotes ?? this.extraNotes,
      targetDuration: targetDuration ?? this.targetDuration,
      defaultScore: defaultScore ?? this.defaultScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (routine.present) {
      map['routine'] = Variable<String>(routine.value);
    }
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (extraNotes.present) {
      map['extra_notes'] = Variable<String>(extraNotes.value);
    }
    if (targetDuration.present) {
      map['target_duration'] = Variable<int>(
        $PracticeRoutineEntriesTableTable.$convertertargetDurationn.toSql(
          targetDuration.value,
        ),
      );
    }
    if (defaultScore.present) {
      map['default_score'] = Variable<String>(defaultScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeRoutineEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('routine: $routine, ')
          ..write('exercise: $exercise, ')
          ..write('position: $position, ')
          ..write('extraNotes: $extraNotes, ')
          ..write('targetDuration: $targetDuration, ')
          ..write('defaultScore: $defaultScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionsTableTable extends PracticeSessionsTable
    with TableInfo<$PracticeSessionsTableTable, PracticeSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routineMeta = const VerificationMeta(
    'routine',
  );
  @override
  late final GeneratedColumn<String> routine = GeneratedColumn<String>(
    'routine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    startedAt,
    endedAt,
    routine,
    description,
    updatedAt,
    writtenAt,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('routine')) {
      context.handle(
        _routineMeta,
        routine.isAcceptableOrUnknown(data['routine']!, _routineMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
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
  PracticeSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSessionsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      routine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
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
  $PracticeSessionsTableTable createAlias(String alias) {
    return $PracticeSessionsTableTable(attachedDatabase, alias);
  }
}

class PracticeSessionsTableData extends DataClass
    implements Insertable<PracticeSessionsTableData> {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? routine;
  final String? description;
  final DateTime updatedAt;
  final DateTime? writtenAt;
  final bool uploaded;
  const PracticeSessionsTableData({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.routine,
    this.description,
    required this.updatedAt,
    this.writtenAt,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || routine != null) {
      map['routine'] = Variable<String>(routine);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || writtenAt != null) {
      map['written_at'] = Variable<DateTime>(writtenAt);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  PracticeSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsTableCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      routine: routine == null && nullToAbsent
          ? const Value.absent()
          : Value(routine),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      updatedAt: Value(updatedAt),
      writtenAt: writtenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(writtenAt),
      uploaded: Value(uploaded),
    );
  }

  factory PracticeSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      routine: serializer.fromJson<String?>(json['routine']),
      description: serializer.fromJson<String?>(json['description']),
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
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'routine': serializer.toJson<String?>(routine),
      'description': serializer.toJson<String?>(description),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'writtenAt': serializer.toJson<DateTime?>(writtenAt),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  PracticeSessionsTableData copyWith({
    String? id,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> routine = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> writtenAt = const Value.absent(),
    bool? uploaded,
  }) => PracticeSessionsTableData(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    routine: routine.present ? routine.value : this.routine,
    description: description.present ? description.value : this.description,
    updatedAt: updatedAt ?? this.updatedAt,
    writtenAt: writtenAt.present ? writtenAt.value : this.writtenAt,
    uploaded: uploaded ?? this.uploaded,
  );
  PracticeSessionsTableData copyWithCompanion(
    PracticeSessionsTableCompanion data,
  ) {
    return PracticeSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      routine: data.routine.present ? data.routine.value : this.routine,
      description: data.description.present
          ? data.description.value
          : this.description,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsTableData(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('routine: $routine, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    routine,
    description,
    updatedAt,
    writtenAt,
    uploaded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSessionsTableData &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.routine == this.routine &&
          other.description == this.description &&
          other.updatedAt == this.updatedAt &&
          other.writtenAt == this.writtenAt &&
          other.uploaded == this.uploaded);
}

class PracticeSessionsTableCompanion
    extends UpdateCompanion<PracticeSessionsTableData> {
  final Value<String> id;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> routine;
  final Value<String?> description;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> writtenAt;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const PracticeSessionsTableCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.routine = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeSessionsTableCompanion.insert({
    required String id,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.routine = const Value.absent(),
    this.description = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt);
  static Insertable<PracticeSessionsTableData> custom({
    Expression<String>? id,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? routine,
    Expression<String>? description,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? writtenAt,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (routine != null) 'routine': routine,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (writtenAt != null) 'written_at': writtenAt,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeSessionsTableCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? routine,
    Value<String?>? description,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? writtenAt,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return PracticeSessionsTableCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      routine: routine ?? this.routine,
      description: description ?? this.description,
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
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (routine.present) {
      map['routine'] = Variable<String>(routine.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
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
    return (StringBuffer('PracticeSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('routine: $routine, ')
          ..write('description: $description, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionEntriesTableTable extends PracticeSessionEntriesTable
    with
        TableInfo<
          $PracticeSessionEntriesTableTable,
          PracticeSessionEntriesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionMeta = const VerificationMeta(
    'session',
  );
  @override
  late final GeneratedColumn<String> session = GeneratedColumn<String>(
    'session',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseMeta = const VerificationMeta(
    'exercise',
  );
  @override
  late final GeneratedColumn<String> exercise = GeneratedColumn<String>(
    'exercise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routineEntryMeta = const VerificationMeta(
    'routineEntry',
  );
  @override
  late final GeneratedColumn<String> routineEntry = GeneratedColumn<String>(
    'routine_entry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> duration =
      GeneratedColumn<int>(
        'duration',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>(
        $PracticeSessionEntriesTableTable.$converterduration,
      );
  static const VerificationMeta _runningSinceMeta = const VerificationMeta(
    'runningSince',
  );
  @override
  late final GeneratedColumn<DateTime> runningSince = GeneratedColumn<DateTime>(
    'running_since',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    session,
    exercise,
    routineEntry,
    duration,
    runningSince,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_session_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSessionEntriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session')) {
      context.handle(
        _sessionMeta,
        session.isAcceptableOrUnknown(data['session']!, _sessionMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionMeta);
    }
    if (data.containsKey('exercise')) {
      context.handle(
        _exerciseMeta,
        exercise.isAcceptableOrUnknown(data['exercise']!, _exerciseMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseMeta);
    }
    if (data.containsKey('routine_entry')) {
      context.handle(
        _routineEntryMeta,
        routineEntry.isAcceptableOrUnknown(
          data['routine_entry']!,
          _routineEntryMeta,
        ),
      );
    }
    if (data.containsKey('running_since')) {
      context.handle(
        _runningSinceMeta,
        runningSince.isAcceptableOrUnknown(
          data['running_since']!,
          _runningSinceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSessionEntriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSessionEntriesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      session: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session'],
      )!,
      exercise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise'],
      )!,
      routineEntry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_entry'],
      ),
      duration: $PracticeSessionEntriesTableTable.$converterduration.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration'],
        )!,
      ),
      runningSince: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}running_since'],
      ),
    );
  }

  @override
  $PracticeSessionEntriesTableTable createAlias(String alias) {
    return $PracticeSessionEntriesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<Duration, int> $converterduration =
      const DurationConverter();
}

class PracticeSessionEntriesTableData extends DataClass
    implements Insertable<PracticeSessionEntriesTableData> {
  final String id;
  final String session;
  final String exercise;
  final String? routineEntry;
  final Duration duration;
  final DateTime? runningSince;
  const PracticeSessionEntriesTableData({
    required this.id,
    required this.session,
    required this.exercise,
    this.routineEntry,
    required this.duration,
    this.runningSince,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session'] = Variable<String>(session);
    map['exercise'] = Variable<String>(exercise);
    if (!nullToAbsent || routineEntry != null) {
      map['routine_entry'] = Variable<String>(routineEntry);
    }
    {
      map['duration'] = Variable<int>(
        $PracticeSessionEntriesTableTable.$converterduration.toSql(duration),
      );
    }
    if (!nullToAbsent || runningSince != null) {
      map['running_since'] = Variable<DateTime>(runningSince);
    }
    return map;
  }

  PracticeSessionEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionEntriesTableCompanion(
      id: Value(id),
      session: Value(session),
      exercise: Value(exercise),
      routineEntry: routineEntry == null && nullToAbsent
          ? const Value.absent()
          : Value(routineEntry),
      duration: Value(duration),
      runningSince: runningSince == null && nullToAbsent
          ? const Value.absent()
          : Value(runningSince),
    );
  }

  factory PracticeSessionEntriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSessionEntriesTableData(
      id: serializer.fromJson<String>(json['id']),
      session: serializer.fromJson<String>(json['session']),
      exercise: serializer.fromJson<String>(json['exercise']),
      routineEntry: serializer.fromJson<String?>(json['routineEntry']),
      duration: serializer.fromJson<Duration>(json['duration']),
      runningSince: serializer.fromJson<DateTime?>(json['runningSince']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'session': serializer.toJson<String>(session),
      'exercise': serializer.toJson<String>(exercise),
      'routineEntry': serializer.toJson<String?>(routineEntry),
      'duration': serializer.toJson<Duration>(duration),
      'runningSince': serializer.toJson<DateTime?>(runningSince),
    };
  }

  PracticeSessionEntriesTableData copyWith({
    String? id,
    String? session,
    String? exercise,
    Value<String?> routineEntry = const Value.absent(),
    Duration? duration,
    Value<DateTime?> runningSince = const Value.absent(),
  }) => PracticeSessionEntriesTableData(
    id: id ?? this.id,
    session: session ?? this.session,
    exercise: exercise ?? this.exercise,
    routineEntry: routineEntry.present ? routineEntry.value : this.routineEntry,
    duration: duration ?? this.duration,
    runningSince: runningSince.present ? runningSince.value : this.runningSince,
  );
  PracticeSessionEntriesTableData copyWithCompanion(
    PracticeSessionEntriesTableCompanion data,
  ) {
    return PracticeSessionEntriesTableData(
      id: data.id.present ? data.id.value : this.id,
      session: data.session.present ? data.session.value : this.session,
      exercise: data.exercise.present ? data.exercise.value : this.exercise,
      routineEntry: data.routineEntry.present
          ? data.routineEntry.value
          : this.routineEntry,
      duration: data.duration.present ? data.duration.value : this.duration,
      runningSince: data.runningSince.present
          ? data.runningSince.value
          : this.runningSince,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionEntriesTableData(')
          ..write('id: $id, ')
          ..write('session: $session, ')
          ..write('exercise: $exercise, ')
          ..write('routineEntry: $routineEntry, ')
          ..write('duration: $duration, ')
          ..write('runningSince: $runningSince')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, session, exercise, routineEntry, duration, runningSince);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSessionEntriesTableData &&
          other.id == this.id &&
          other.session == this.session &&
          other.exercise == this.exercise &&
          other.routineEntry == this.routineEntry &&
          other.duration == this.duration &&
          other.runningSince == this.runningSince);
}

class PracticeSessionEntriesTableCompanion
    extends UpdateCompanion<PracticeSessionEntriesTableData> {
  final Value<String> id;
  final Value<String> session;
  final Value<String> exercise;
  final Value<String?> routineEntry;
  final Value<Duration> duration;
  final Value<DateTime?> runningSince;
  final Value<int> rowid;
  const PracticeSessionEntriesTableCompanion({
    this.id = const Value.absent(),
    this.session = const Value.absent(),
    this.exercise = const Value.absent(),
    this.routineEntry = const Value.absent(),
    this.duration = const Value.absent(),
    this.runningSince = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeSessionEntriesTableCompanion.insert({
    required String id,
    required String session,
    required String exercise,
    this.routineEntry = const Value.absent(),
    this.duration = const Value.absent(),
    this.runningSince = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       session = Value(session),
       exercise = Value(exercise);
  static Insertable<PracticeSessionEntriesTableData> custom({
    Expression<String>? id,
    Expression<String>? session,
    Expression<String>? exercise,
    Expression<String>? routineEntry,
    Expression<int>? duration,
    Expression<DateTime>? runningSince,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (session != null) 'session': session,
      if (exercise != null) 'exercise': exercise,
      if (routineEntry != null) 'routine_entry': routineEntry,
      if (duration != null) 'duration': duration,
      if (runningSince != null) 'running_since': runningSince,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeSessionEntriesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? session,
    Value<String>? exercise,
    Value<String?>? routineEntry,
    Value<Duration>? duration,
    Value<DateTime?>? runningSince,
    Value<int>? rowid,
  }) {
    return PracticeSessionEntriesTableCompanion(
      id: id ?? this.id,
      session: session ?? this.session,
      exercise: exercise ?? this.exercise,
      routineEntry: routineEntry ?? this.routineEntry,
      duration: duration ?? this.duration,
      runningSince: runningSince ?? this.runningSince,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (session.present) {
      map['session'] = Variable<String>(session.value);
    }
    if (exercise.present) {
      map['exercise'] = Variable<String>(exercise.value);
    }
    if (routineEntry.present) {
      map['routine_entry'] = Variable<String>(routineEntry.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(
        $PracticeSessionEntriesTableTable.$converterduration.toSql(
          duration.value,
        ),
      );
    }
    if (runningSince.present) {
      map['running_since'] = Variable<DateTime>(runningSince.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('session: $session, ')
          ..write('exercise: $exercise, ')
          ..write('routineEntry: $routineEntry, ')
          ..write('duration: $duration, ')
          ..write('runningSince: $runningSince, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedExerciseCategoriesTableTable
    extends DeletedExerciseCategoriesTable
    with
        TableInfo<
          $DeletedExerciseCategoriesTableTable,
          DeletedExerciseCategoriesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedExerciseCategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
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
  List<GeneratedColumn> get $columns => [categoryId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_exercise_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedExerciseCategoriesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {categoryId};
  @override
  DeletedExerciseCategoriesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedExerciseCategoriesTableData(
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedExerciseCategoriesTableTable createAlias(String alias) {
    return $DeletedExerciseCategoriesTableTable(attachedDatabase, alias);
  }
}

class DeletedExerciseCategoriesTableData extends DataClass
    implements Insertable<DeletedExerciseCategoriesTableData> {
  final String categoryId;
  final DateTime deletedAt;
  const DeletedExerciseCategoriesTableData({
    required this.categoryId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_id'] = Variable<String>(categoryId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedExerciseCategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedExerciseCategoriesTableCompanion(
      categoryId: Value(categoryId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedExerciseCategoriesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedExerciseCategoriesTableData(
      categoryId: serializer.fromJson<String>(json['categoryId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryId': serializer.toJson<String>(categoryId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedExerciseCategoriesTableData copyWith({
    String? categoryId,
    DateTime? deletedAt,
  }) => DeletedExerciseCategoriesTableData(
    categoryId: categoryId ?? this.categoryId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedExerciseCategoriesTableData copyWithCompanion(
    DeletedExerciseCategoriesTableCompanion data,
  ) {
    return DeletedExerciseCategoriesTableData(
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedExerciseCategoriesTableData(')
          ..write('categoryId: $categoryId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(categoryId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedExerciseCategoriesTableData &&
          other.categoryId == this.categoryId &&
          other.deletedAt == this.deletedAt);
}

class DeletedExerciseCategoriesTableCompanion
    extends UpdateCompanion<DeletedExerciseCategoriesTableData> {
  final Value<String> categoryId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedExerciseCategoriesTableCompanion({
    this.categoryId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedExerciseCategoriesTableCompanion.insert({
    required String categoryId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : categoryId = Value(categoryId);
  static Insertable<DeletedExerciseCategoriesTableData> custom({
    Expression<String>? categoryId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryId != null) 'category_id': categoryId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedExerciseCategoriesTableCompanion copyWith({
    Value<String>? categoryId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedExerciseCategoriesTableCompanion(
      categoryId: categoryId ?? this.categoryId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
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
    return (StringBuffer('DeletedExerciseCategoriesTableCompanion(')
          ..write('categoryId: $categoryId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedExercisesTableTable extends DeletedExercisesTable
    with TableInfo<$DeletedExercisesTableTable, DeletedExercisesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedExercisesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
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
  List<GeneratedColumn> get $columns => [exerciseId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedExercisesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {exerciseId};
  @override
  DeletedExercisesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedExercisesTableData(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedExercisesTableTable createAlias(String alias) {
    return $DeletedExercisesTableTable(attachedDatabase, alias);
  }
}

class DeletedExercisesTableData extends DataClass
    implements Insertable<DeletedExercisesTableData> {
  final String exerciseId;
  final DateTime deletedAt;
  const DeletedExercisesTableData({
    required this.exerciseId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedExercisesTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedExercisesTableCompanion(
      exerciseId: Value(exerciseId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedExercisesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedExercisesTableData(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedExercisesTableData copyWith({
    String? exerciseId,
    DateTime? deletedAt,
  }) => DeletedExercisesTableData(
    exerciseId: exerciseId ?? this.exerciseId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedExercisesTableData copyWithCompanion(
    DeletedExercisesTableCompanion data,
  ) {
    return DeletedExercisesTableData(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedExercisesTableData(')
          ..write('exerciseId: $exerciseId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedExercisesTableData &&
          other.exerciseId == this.exerciseId &&
          other.deletedAt == this.deletedAt);
}

class DeletedExercisesTableCompanion
    extends UpdateCompanion<DeletedExercisesTableData> {
  final Value<String> exerciseId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedExercisesTableCompanion({
    this.exerciseId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedExercisesTableCompanion.insert({
    required String exerciseId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId);
  static Insertable<DeletedExercisesTableData> custom({
    Expression<String>? exerciseId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedExercisesTableCompanion copyWith({
    Value<String>? exerciseId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedExercisesTableCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
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
    return (StringBuffer('DeletedExercisesTableCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedPracticeRoutinesTableTable extends DeletedPracticeRoutinesTable
    with
        TableInfo<
          $DeletedPracticeRoutinesTableTable,
          DeletedPracticeRoutinesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedPracticeRoutinesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routineIdMeta = const VerificationMeta(
    'routineId',
  );
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
    'routine_id',
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
  List<GeneratedColumn> get $columns => [routineId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_practice_routines';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedPracticeRoutinesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('routine_id')) {
      context.handle(
        _routineIdMeta,
        routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_routineIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {routineId};
  @override
  DeletedPracticeRoutinesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedPracticeRoutinesTableData(
      routineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}routine_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedPracticeRoutinesTableTable createAlias(String alias) {
    return $DeletedPracticeRoutinesTableTable(attachedDatabase, alias);
  }
}

class DeletedPracticeRoutinesTableData extends DataClass
    implements Insertable<DeletedPracticeRoutinesTableData> {
  final String routineId;
  final DateTime deletedAt;
  const DeletedPracticeRoutinesTableData({
    required this.routineId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['routine_id'] = Variable<String>(routineId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedPracticeRoutinesTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedPracticeRoutinesTableCompanion(
      routineId: Value(routineId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedPracticeRoutinesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedPracticeRoutinesTableData(
      routineId: serializer.fromJson<String>(json['routineId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routineId': serializer.toJson<String>(routineId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedPracticeRoutinesTableData copyWith({
    String? routineId,
    DateTime? deletedAt,
  }) => DeletedPracticeRoutinesTableData(
    routineId: routineId ?? this.routineId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedPracticeRoutinesTableData copyWithCompanion(
    DeletedPracticeRoutinesTableCompanion data,
  ) {
    return DeletedPracticeRoutinesTableData(
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedPracticeRoutinesTableData(')
          ..write('routineId: $routineId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routineId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedPracticeRoutinesTableData &&
          other.routineId == this.routineId &&
          other.deletedAt == this.deletedAt);
}

class DeletedPracticeRoutinesTableCompanion
    extends UpdateCompanion<DeletedPracticeRoutinesTableData> {
  final Value<String> routineId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedPracticeRoutinesTableCompanion({
    this.routineId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedPracticeRoutinesTableCompanion.insert({
    required String routineId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : routineId = Value(routineId);
  static Insertable<DeletedPracticeRoutinesTableData> custom({
    Expression<String>? routineId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routineId != null) 'routine_id': routineId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedPracticeRoutinesTableCompanion copyWith({
    Value<String>? routineId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedPracticeRoutinesTableCompanion(
      routineId: routineId ?? this.routineId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
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
    return (StringBuffer('DeletedPracticeRoutinesTableCompanion(')
          ..write('routineId: $routineId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedPracticeSessionsTableTable extends DeletedPracticeSessionsTable
    with
        TableInfo<
          $DeletedPracticeSessionsTableTable,
          DeletedPracticeSessionsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedPracticeSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
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
  List<GeneratedColumn> get $columns => [sessionId, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedPracticeSessionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  DeletedPracticeSessionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedPracticeSessionsTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      )!,
    );
  }

  @override
  $DeletedPracticeSessionsTableTable createAlias(String alias) {
    return $DeletedPracticeSessionsTableTable(attachedDatabase, alias);
  }
}

class DeletedPracticeSessionsTableData extends DataClass
    implements Insertable<DeletedPracticeSessionsTableData> {
  final String sessionId;
  final DateTime deletedAt;
  const DeletedPracticeSessionsTableData({
    required this.sessionId,
    required this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['deleted_at'] = Variable<DateTime>(deletedAt);
    return map;
  }

  DeletedPracticeSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return DeletedPracticeSessionsTableCompanion(
      sessionId: Value(sessionId),
      deletedAt: Value(deletedAt),
    );
  }

  factory DeletedPracticeSessionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedPracticeSessionsTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      deletedAt: serializer.fromJson<DateTime>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'deletedAt': serializer.toJson<DateTime>(deletedAt),
    };
  }

  DeletedPracticeSessionsTableData copyWith({
    String? sessionId,
    DateTime? deletedAt,
  }) => DeletedPracticeSessionsTableData(
    sessionId: sessionId ?? this.sessionId,
    deletedAt: deletedAt ?? this.deletedAt,
  );
  DeletedPracticeSessionsTableData copyWithCompanion(
    DeletedPracticeSessionsTableCompanion data,
  ) {
    return DeletedPracticeSessionsTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedPracticeSessionsTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedPracticeSessionsTableData &&
          other.sessionId == this.sessionId &&
          other.deletedAt == this.deletedAt);
}

class DeletedPracticeSessionsTableCompanion
    extends UpdateCompanion<DeletedPracticeSessionsTableData> {
  final Value<String> sessionId;
  final Value<DateTime> deletedAt;
  final Value<int> rowid;
  const DeletedPracticeSessionsTableCompanion({
    this.sessionId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedPracticeSessionsTableCompanion.insert({
    required String sessionId,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId);
  static Insertable<DeletedPracticeSessionsTableData> custom({
    Expression<String>? sessionId,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedPracticeSessionsTableCompanion copyWith({
    Value<String>? sessionId,
    Value<DateTime>? deletedAt,
    Value<int>? rowid,
  }) {
    return DeletedPracticeSessionsTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
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
    return (StringBuffer('DeletedPracticeSessionsTableCompanion(')
          ..write('sessionId: $sessionId, ')
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
  late final $ExerciseCategoriesTableTable exerciseCategoriesTable =
      $ExerciseCategoriesTableTable(this);
  late final $ExercisesTableTable exercisesTable = $ExercisesTableTable(this);
  late final $ExerciseScoresTableTable exerciseScoresTable =
      $ExerciseScoresTableTable(this);
  late final $ExerciseTagsTableTable exerciseTagsTable =
      $ExerciseTagsTableTable(this);
  late final $PracticeRoutinesTableTable practiceRoutinesTable =
      $PracticeRoutinesTableTable(this);
  late final $PracticeRoutineEntriesTableTable practiceRoutineEntriesTable =
      $PracticeRoutineEntriesTableTable(this);
  late final $PracticeSessionsTableTable practiceSessionsTable =
      $PracticeSessionsTableTable(this);
  late final $PracticeSessionEntriesTableTable practiceSessionEntriesTable =
      $PracticeSessionEntriesTableTable(this);
  late final $DeletedExerciseCategoriesTableTable
  deletedExerciseCategoriesTable = $DeletedExerciseCategoriesTableTable(this);
  late final $DeletedExercisesTableTable deletedExercisesTable =
      $DeletedExercisesTableTable(this);
  late final $DeletedPracticeRoutinesTableTable deletedPracticeRoutinesTable =
      $DeletedPracticeRoutinesTableTable(this);
  late final $DeletedPracticeSessionsTableTable deletedPracticeSessionsTable =
      $DeletedPracticeSessionsTableTable(this);
  late final Index searchTextIndex = Index(
    'search_text_index',
    'CREATE INDEX search_text_index ON scores (search_text)',
  );
  late final Index recentTimeIndex = Index(
    'recent_time_index',
    'CREATE INDEX recent_time_index ON scores (recent_time)',
  );
  late final Index exercisesCategoryIndex = Index(
    'exercises_category_index',
    'CREATE INDEX exercises_category_index ON exercises (category)',
  );
  late final Index exerciseScoresScoreIndex = Index(
    'exercise_scores_score_index',
    'CREATE INDEX exercise_scores_score_index ON exercise_scores (score)',
  );
  late final Index practiceRoutineEntriesRoutineIndex = Index(
    'practice_routine_entries_routine_index',
    'CREATE INDEX practice_routine_entries_routine_index ON practice_routine_entries (routine)',
  );
  late final Index practiceRoutineEntriesExerciseIndex = Index(
    'practice_routine_entries_exercise_index',
    'CREATE INDEX practice_routine_entries_exercise_index ON practice_routine_entries (exercise)',
  );
  late final Index practiceSessionsStartedAtIndex = Index(
    'practice_sessions_started_at_index',
    'CREATE INDEX practice_sessions_started_at_index ON practice_sessions (started_at)',
  );
  late final Index practiceSessionsRoutineIndex = Index(
    'practice_sessions_routine_index',
    'CREATE INDEX practice_sessions_routine_index ON practice_sessions (routine)',
  );
  late final Index practiceSessionEntriesExerciseIndex = Index(
    'practice_session_entries_exercise_index',
    'CREATE INDEX practice_session_entries_exercise_index ON practice_session_entries (exercise)',
  );
  late final Index practiceSessionEntriesRoutineEntryIndex = Index(
    'practice_session_entries_routine_entry_index',
    'CREATE INDEX practice_session_entries_routine_entry_index ON practice_session_entries (routine_entry)',
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
    exerciseCategoriesTable,
    exercisesTable,
    exerciseScoresTable,
    exerciseTagsTable,
    practiceRoutinesTable,
    practiceRoutineEntriesTable,
    practiceSessionsTable,
    practiceSessionEntriesTable,
    deletedExerciseCategoriesTable,
    deletedExercisesTable,
    deletedPracticeRoutinesTable,
    deletedPracticeSessionsTable,
    searchTextIndex,
    recentTimeIndex,
    exercisesCategoryIndex,
    exerciseScoresScoreIndex,
    practiceRoutineEntriesRoutineIndex,
    practiceRoutineEntriesExerciseIndex,
    practiceSessionsStartedAtIndex,
    practiceSessionsRoutineIndex,
    practiceSessionEntriesExerciseIndex,
    practiceSessionEntriesRoutineEntryIndex,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercise_categories',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('exercises', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_scores', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('exercise_scores', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('exercise_tags', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('exercise_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('exercise_tags', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_routines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('practice_routine_entries', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_routines',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('practice_routine_entries', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'exercises',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('practice_routine_entries', kind: UpdateKind.update),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('practice_session_entries', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_sessions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('practice_session_entries', kind: UpdateKind.update),
      ],
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
      Value<String?> source,
      Value<String?> sourceLink,
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
      Value<ScoreType> type,
      Value<int> rowid,
    });
typedef $$ScoresTableTableUpdateCompanionBuilder =
    ScoresTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> composer,
      Value<String?> source,
      Value<String?> sourceLink,
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
      Value<ScoreType> type,
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
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

  ColumnWithTypeConverterFilters<ScoreType, ScoreType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
    builder: (column) => column,
  );

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

  GeneratedColumnWithTypeConverter<ScoreType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

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
                Value<String?> source = const Value.absent(),
                Value<String?> sourceLink = const Value.absent(),
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
                Value<ScoreType> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion(
                id: id,
                title: title,
                composer: composer,
                source: source,
                sourceLink: sourceLink,
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
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> composer = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceLink = const Value.absent(),
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
                Value<ScoreType> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion.insert(
                id: id,
                title: title,
                composer: composer,
                source: source,
                sourceLink: sourceLink,
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
                type: type,
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
      Value<TagType> type,
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
      Value<TagType> type,
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

  static MultiTypedResultKey<
    $ExerciseTagsTableTable,
    List<ExerciseTagsTableData>
  >
  _exerciseTagsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.exerciseTagsTable,
    aliasName: 'tags__id__exercise_tags__tag',
  );

  $$ExerciseTagsTableTableProcessedTableManager get exerciseTagsTableRefs {
    final manager = $$ExerciseTagsTableTableTableManager(
      $_db,
      $_db.exerciseTagsTable,
    ).filter((f) => f.tag.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseTagsTableRefsTable($_db),
    );
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

  ColumnWithTypeConverterFilters<TagType, TagType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
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

  Expression<bool> exerciseTagsTableRefs(
    Expression<bool> Function($$ExerciseTagsTableTableFilterComposer f) f,
  ) {
    final $$ExerciseTagsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseTagsTable,
      getReferencedColumn: (t) => t.tag,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseTagsTableTableFilterComposer(
            $db: $db,
            $table: $db.exerciseTagsTable,
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  GeneratedColumnWithTypeConverter<TagType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

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

  Expression<T> exerciseTagsTableRefs<T extends Object>(
    Expression<T> Function($$ExerciseTagsTableTableAnnotationComposer a) f,
  ) {
    final $$ExerciseTagsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseTagsTable,
          getReferencedColumn: (t) => t.tag,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseTagsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseTagsTable,
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
          PrefetchHooks Function({
            bool scoreTagsTableRefs,
            bool exerciseTagsTableRefs,
          })
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
                Value<TagType> type = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                type: type,
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
                Value<TagType> type = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion.insert(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                type: type,
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
          prefetchHooksCallback:
              ({scoreTagsTableRefs = false, exerciseTagsTableRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (scoreTagsTableRefs) db.scoreTagsTable,
                    if (exerciseTagsTableRefs) db.exerciseTagsTable,
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
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tag == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseTagsTableRefs)
                        await $_getPrefetchedData<
                          TagsTableData,
                          $TagsTableTable,
                          ExerciseTagsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$TagsTableTableReferences
                              ._exerciseTagsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TagsTableTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseTagsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tag == item.id,
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
      PrefetchHooks Function({
        bool scoreTagsTableRefs,
        bool exerciseTagsTableRefs,
      })
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
typedef $$ExerciseCategoriesTableTableCreateCompanionBuilder =
    ExerciseCategoriesTableCompanion Function({
      required String id,
      required String name,
      required int position,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$ExerciseCategoriesTableTableUpdateCompanionBuilder =
    ExerciseCategoriesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$ExerciseCategoriesTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $ExerciseCategoriesTableTable,
          ExerciseCategoriesTableData
        > {
  $$ExerciseCategoriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExercisesTableTable, List<ExercisesTableData>>
  _exercisesTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.exercisesTable,
    aliasName: 'exercise_categories__id__exercises__category',
  );

  $$ExercisesTableTableProcessedTableManager get exercisesTableRefs {
    final manager = $$ExercisesTableTableTableManager(
      $_db,
      $_db.exercisesTable,
    ).filter((f) => f.category.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_exercisesTableRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExerciseCategoriesTableTableFilterComposer
    extends Composer<_$Database, $ExerciseCategoriesTableTable> {
  $$ExerciseCategoriesTableTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
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

  Expression<bool> exercisesTableRefs(
    Expression<bool> Function($$ExercisesTableTableFilterComposer f) f,
  ) {
    final $$ExercisesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableFilterComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseCategoriesTableTableOrderingComposer
    extends Composer<_$Database, $ExerciseCategoriesTableTable> {
  $$ExerciseCategoriesTableTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
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

class $$ExerciseCategoriesTableTableAnnotationComposer
    extends Composer<_$Database, $ExerciseCategoriesTableTable> {
  $$ExerciseCategoriesTableTableAnnotationComposer({
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

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  Expression<T> exercisesTableRefs<T extends Object>(
    Expression<T> Function($$ExercisesTableTableAnnotationComposer a) f,
  ) {
    final $$ExercisesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExerciseCategoriesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ExerciseCategoriesTableTable,
          ExerciseCategoriesTableData,
          $$ExerciseCategoriesTableTableFilterComposer,
          $$ExerciseCategoriesTableTableOrderingComposer,
          $$ExerciseCategoriesTableTableAnnotationComposer,
          $$ExerciseCategoriesTableTableCreateCompanionBuilder,
          $$ExerciseCategoriesTableTableUpdateCompanionBuilder,
          (
            ExerciseCategoriesTableData,
            $$ExerciseCategoriesTableTableReferences,
          ),
          ExerciseCategoriesTableData,
          PrefetchHooks Function({bool exercisesTableRefs})
        > {
  $$ExerciseCategoriesTableTableTableManager(
    _$Database db,
    $ExerciseCategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseCategoriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExerciseCategoriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseCategoriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseCategoriesTableCompanion(
                id: id,
                name: name,
                position: position,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int position,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseCategoriesTableCompanion.insert(
                id: id,
                name: name,
                position: position,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseCategoriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercisesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exercisesTableRefs) db.exercisesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exercisesTableRefs)
                    await $_getPrefetchedData<
                      ExerciseCategoriesTableData,
                      $ExerciseCategoriesTableTable,
                      ExercisesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$ExerciseCategoriesTableTableReferences
                          ._exercisesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ExerciseCategoriesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).exercisesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.category == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ExerciseCategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ExerciseCategoriesTableTable,
      ExerciseCategoriesTableData,
      $$ExerciseCategoriesTableTableFilterComposer,
      $$ExerciseCategoriesTableTableOrderingComposer,
      $$ExerciseCategoriesTableTableAnnotationComposer,
      $$ExerciseCategoriesTableTableCreateCompanionBuilder,
      $$ExerciseCategoriesTableTableUpdateCompanionBuilder,
      (ExerciseCategoriesTableData, $$ExerciseCategoriesTableTableReferences),
      ExerciseCategoriesTableData,
      PrefetchHooks Function({bool exercisesTableRefs})
    >;
typedef $$ExercisesTableTableCreateCompanionBuilder =
    ExercisesTableCompanion Function({
      required String id,
      required String name,
      Value<String?> category,
      Value<String?> description,
      Value<String?> source,
      Value<String?> sourceLink,
      Value<String?> instrument,
      Value<int?> targetBpm,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$ExercisesTableTableUpdateCompanionBuilder =
    ExercisesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> category,
      Value<String?> description,
      Value<String?> source,
      Value<String?> sourceLink,
      Value<String?> instrument,
      Value<int?> targetBpm,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$ExercisesTableTableReferences
    extends
        BaseReferences<_$Database, $ExercisesTableTable, ExercisesTableData> {
  $$ExercisesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExerciseCategoriesTableTable _categoryTable(_$Database db) => db
      .exerciseCategoriesTable
      .createAlias('exercises__category__exercise_categories__id');

  $$ExerciseCategoriesTableTableProcessedTableManager? get category {
    final $_column = $_itemColumn<String>('category');
    if ($_column == null) return null;
    final manager = $$ExerciseCategoriesTableTableTableManager(
      $_db,
      $_db.exerciseCategoriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ExerciseScoresTableTable,
    List<ExerciseScoresTableData>
  >
  _exerciseScoresTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.exerciseScoresTable,
    aliasName: 'exercises__id__exercise_scores__exercise',
  );

  $$ExerciseScoresTableTableProcessedTableManager get exerciseScoresTableRefs {
    final manager = $$ExerciseScoresTableTableTableManager(
      $_db,
      $_db.exerciseScoresTable,
    ).filter((f) => f.exercise.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseScoresTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ExerciseTagsTableTable,
    List<ExerciseTagsTableData>
  >
  _exerciseTagsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.exerciseTagsTable,
    aliasName: 'exercises__id__exercise_tags__exercise',
  );

  $$ExerciseTagsTableTableProcessedTableManager get exerciseTagsTableRefs {
    final manager = $$ExerciseTagsTableTableTableManager(
      $_db,
      $_db.exerciseTagsTable,
    ).filter((f) => f.exercise.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exerciseTagsTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $PracticeRoutineEntriesTableTable,
    List<PracticeRoutineEntriesTableData>
  >
  _practiceRoutineEntriesTableRefsTable(_$Database db) =>
      MultiTypedResultKey.fromTable(
        db.practiceRoutineEntriesTable,
        aliasName: 'exercises__id__practice_routine_entries__exercise',
      );

  $$PracticeRoutineEntriesTableTableProcessedTableManager
  get practiceRoutineEntriesTableRefs {
    final manager = $$PracticeRoutineEntriesTableTableTableManager(
      $_db,
      $_db.practiceRoutineEntriesTable,
    ).filter((f) => f.exercise.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceRoutineEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableTableFilterComposer
    extends Composer<_$Database, $ExercisesTableTable> {
  $$ExercisesTableTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetBpm => $composableBuilder(
    column: $table.targetBpm,
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

  $$ExerciseCategoriesTableTableFilterComposer get category {
    final $$ExerciseCategoriesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.category,
          referencedTable: $db.exerciseCategoriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseCategoriesTableTableFilterComposer(
                $db: $db,
                $table: $db.exerciseCategoriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<bool> exerciseScoresTableRefs(
    Expression<bool> Function($$ExerciseScoresTableTableFilterComposer f) f,
  ) {
    final $$ExerciseScoresTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseScoresTable,
      getReferencedColumn: (t) => t.exercise,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseScoresTableTableFilterComposer(
            $db: $db,
            $table: $db.exerciseScoresTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exerciseTagsTableRefs(
    Expression<bool> Function($$ExerciseTagsTableTableFilterComposer f) f,
  ) {
    final $$ExerciseTagsTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exerciseTagsTable,
      getReferencedColumn: (t) => t.exercise,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExerciseTagsTableTableFilterComposer(
            $db: $db,
            $table: $db.exerciseTagsTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> practiceRoutineEntriesTableRefs(
    Expression<bool> Function(
      $$PracticeRoutineEntriesTableTableFilterComposer f,
    )
    f,
  ) {
    final $$PracticeRoutineEntriesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceRoutineEntriesTable,
          getReferencedColumn: (t) => t.exercise,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutineEntriesTableTableFilterComposer(
                $db: $db,
                $table: $db.practiceRoutineEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExercisesTableTableOrderingComposer
    extends Composer<_$Database, $ExercisesTableTable> {
  $$ExercisesTableTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetBpm => $composableBuilder(
    column: $table.targetBpm,
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

  $$ExerciseCategoriesTableTableOrderingComposer get category {
    final $$ExerciseCategoriesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.category,
          referencedTable: $db.exerciseCategoriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseCategoriesTableTableOrderingComposer(
                $db: $db,
                $table: $db.exerciseCategoriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ExercisesTableTableAnnotationComposer
    extends Composer<_$Database, $ExercisesTableTable> {
  $$ExercisesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceLink => $composableBuilder(
    column: $table.sourceLink,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instrument => $composableBuilder(
    column: $table.instrument,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetBpm =>
      $composableBuilder(column: $table.targetBpm, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  $$ExerciseCategoriesTableTableAnnotationComposer get category {
    final $$ExerciseCategoriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.category,
          referencedTable: $db.exerciseCategoriesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseCategoriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseCategoriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> exerciseScoresTableRefs<T extends Object>(
    Expression<T> Function($$ExerciseScoresTableTableAnnotationComposer a) f,
  ) {
    final $$ExerciseScoresTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseScoresTable,
          getReferencedColumn: (t) => t.exercise,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseScoresTableTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseScoresTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> exerciseTagsTableRefs<T extends Object>(
    Expression<T> Function($$ExerciseTagsTableTableAnnotationComposer a) f,
  ) {
    final $$ExerciseTagsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.exerciseTagsTable,
          getReferencedColumn: (t) => t.exercise,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ExerciseTagsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.exerciseTagsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> practiceRoutineEntriesTableRefs<T extends Object>(
    Expression<T> Function(
      $$PracticeRoutineEntriesTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$PracticeRoutineEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceRoutineEntriesTable,
          getReferencedColumn: (t) => t.exercise,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutineEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceRoutineEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ExercisesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ExercisesTableTable,
          ExercisesTableData,
          $$ExercisesTableTableFilterComposer,
          $$ExercisesTableTableOrderingComposer,
          $$ExercisesTableTableAnnotationComposer,
          $$ExercisesTableTableCreateCompanionBuilder,
          $$ExercisesTableTableUpdateCompanionBuilder,
          (ExercisesTableData, $$ExercisesTableTableReferences),
          ExercisesTableData,
          PrefetchHooks Function({
            bool category,
            bool exerciseScoresTableRefs,
            bool exerciseTagsTableRefs,
            bool practiceRoutineEntriesTableRefs,
          })
        > {
  $$ExercisesTableTableTableManager(_$Database db, $ExercisesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceLink = const Value.absent(),
                Value<String?> instrument = const Value.absent(),
                Value<int?> targetBpm = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesTableCompanion(
                id: id,
                name: name,
                category: category,
                description: description,
                source: source,
                sourceLink: sourceLink,
                instrument: instrument,
                targetBpm: targetBpm,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> sourceLink = const Value.absent(),
                Value<String?> instrument = const Value.absent(),
                Value<int?> targetBpm = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesTableCompanion.insert(
                id: id,
                name: name,
                category: category,
                description: description,
                source: source,
                sourceLink: sourceLink,
                instrument: instrument,
                targetBpm: targetBpm,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExercisesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                category = false,
                exerciseScoresTableRefs = false,
                exerciseTagsTableRefs = false,
                practiceRoutineEntriesTableRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (exerciseScoresTableRefs) db.exerciseScoresTable,
                    if (exerciseTagsTableRefs) db.exerciseTagsTable,
                    if (practiceRoutineEntriesTableRefs)
                      db.practiceRoutineEntriesTable,
                  ],
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
                        if (category) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.category,
                                    referencedTable:
                                        $$ExercisesTableTableReferences
                                            ._categoryTable(db),
                                    referencedColumn:
                                        $$ExercisesTableTableReferences
                                            ._categoryTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (exerciseScoresTableRefs)
                        await $_getPrefetchedData<
                          ExercisesTableData,
                          $ExercisesTableTable,
                          ExerciseScoresTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableTableReferences
                              ._exerciseScoresTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseScoresTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exercise == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exerciseTagsTableRefs)
                        await $_getPrefetchedData<
                          ExercisesTableData,
                          $ExercisesTableTable,
                          ExerciseTagsTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableTableReferences
                              ._exerciseTagsTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).exerciseTagsTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exercise == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (practiceRoutineEntriesTableRefs)
                        await $_getPrefetchedData<
                          ExercisesTableData,
                          $ExercisesTableTable,
                          PracticeRoutineEntriesTableData
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableTableReferences
                              ._practiceRoutineEntriesTableRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceRoutineEntriesTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exercise == item.id,
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

typedef $$ExercisesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ExercisesTableTable,
      ExercisesTableData,
      $$ExercisesTableTableFilterComposer,
      $$ExercisesTableTableOrderingComposer,
      $$ExercisesTableTableAnnotationComposer,
      $$ExercisesTableTableCreateCompanionBuilder,
      $$ExercisesTableTableUpdateCompanionBuilder,
      (ExercisesTableData, $$ExercisesTableTableReferences),
      ExercisesTableData,
      PrefetchHooks Function({
        bool category,
        bool exerciseScoresTableRefs,
        bool exerciseTagsTableRefs,
        bool practiceRoutineEntriesTableRefs,
      })
    >;
typedef $$ExerciseScoresTableTableCreateCompanionBuilder =
    ExerciseScoresTableCompanion Function({
      required String exercise,
      required String score,
      required int position,
      required String name,
      required bool owned,
      Value<int> rowid,
    });
typedef $$ExerciseScoresTableTableUpdateCompanionBuilder =
    ExerciseScoresTableCompanion Function({
      Value<String> exercise,
      Value<String> score,
      Value<int> position,
      Value<String> name,
      Value<bool> owned,
      Value<int> rowid,
    });

final class $$ExerciseScoresTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $ExerciseScoresTableTable,
          ExerciseScoresTableData
        > {
  $$ExerciseScoresTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTableTable _exerciseTable(_$Database db) =>
      db.exercisesTable.createAlias('exercise_scores__exercise__exercises__id');

  $$ExercisesTableTableProcessedTableManager get exercise {
    final $_column = $_itemColumn<String>('exercise')!;

    final manager = $$ExercisesTableTableTableManager(
      $_db,
      $_db.exercisesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExerciseScoresTableTableFilterComposer
    extends Composer<_$Database, $ExerciseScoresTableTable> {
  $$ExerciseScoresTableTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnFilters(column),
  );

  $$ExercisesTableTableFilterComposer get exercise {
    final $$ExercisesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableFilterComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseScoresTableTableOrderingComposer
    extends Composer<_$Database, $ExerciseScoresTableTable> {
  $$ExerciseScoresTableTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get owned => $composableBuilder(
    column: $table.owned,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExercisesTableTableOrderingComposer get exercise {
    final $$ExercisesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableOrderingComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseScoresTableTableAnnotationComposer
    extends Composer<_$Database, $ExerciseScoresTableTable> {
  $$ExerciseScoresTableTableAnnotationComposer({
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get owned =>
      $composableBuilder(column: $table.owned, builder: (column) => column);

  $$ExercisesTableTableAnnotationComposer get exercise {
    final $$ExercisesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExerciseScoresTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ExerciseScoresTableTable,
          ExerciseScoresTableData,
          $$ExerciseScoresTableTableFilterComposer,
          $$ExerciseScoresTableTableOrderingComposer,
          $$ExerciseScoresTableTableAnnotationComposer,
          $$ExerciseScoresTableTableCreateCompanionBuilder,
          $$ExerciseScoresTableTableUpdateCompanionBuilder,
          (ExerciseScoresTableData, $$ExerciseScoresTableTableReferences),
          ExerciseScoresTableData,
          PrefetchHooks Function({bool exercise})
        > {
  $$ExerciseScoresTableTableTableManager(
    _$Database db,
    $ExerciseScoresTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseScoresTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseScoresTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExerciseScoresTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exercise = const Value.absent(),
                Value<String> score = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> owned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseScoresTableCompanion(
                exercise: exercise,
                score: score,
                position: position,
                name: name,
                owned: owned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exercise,
                required String score,
                required int position,
                required String name,
                required bool owned,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseScoresTableCompanion.insert(
                exercise: exercise,
                score: score,
                position: position,
                name: name,
                owned: owned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseScoresTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercise = false}) {
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
                    if (exercise) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exercise,
                                referencedTable:
                                    $$ExerciseScoresTableTableReferences
                                        ._exerciseTable(db),
                                referencedColumn:
                                    $$ExerciseScoresTableTableReferences
                                        ._exerciseTable(db)
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

typedef $$ExerciseScoresTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ExerciseScoresTableTable,
      ExerciseScoresTableData,
      $$ExerciseScoresTableTableFilterComposer,
      $$ExerciseScoresTableTableOrderingComposer,
      $$ExerciseScoresTableTableAnnotationComposer,
      $$ExerciseScoresTableTableCreateCompanionBuilder,
      $$ExerciseScoresTableTableUpdateCompanionBuilder,
      (ExerciseScoresTableData, $$ExerciseScoresTableTableReferences),
      ExerciseScoresTableData,
      PrefetchHooks Function({bool exercise})
    >;
typedef $$ExerciseTagsTableTableCreateCompanionBuilder =
    ExerciseTagsTableCompanion Function({
      required String exercise,
      required String tag,
      Value<int> rowid,
    });
typedef $$ExerciseTagsTableTableUpdateCompanionBuilder =
    ExerciseTagsTableCompanion Function({
      Value<String> exercise,
      Value<String> tag,
      Value<int> rowid,
    });

final class $$ExerciseTagsTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $ExerciseTagsTableTable,
          ExerciseTagsTableData
        > {
  $$ExerciseTagsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExercisesTableTable _exerciseTable(_$Database db) =>
      db.exercisesTable.createAlias('exercise_tags__exercise__exercises__id');

  $$ExercisesTableTableProcessedTableManager get exercise {
    final $_column = $_itemColumn<String>('exercise')!;

    final manager = $$ExercisesTableTableTableManager(
      $_db,
      $_db.exercisesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTableTable _tagTable(_$Database db) =>
      db.tagsTable.createAlias('exercise_tags__tag__tags__id');

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

class $$ExerciseTagsTableTableFilterComposer
    extends Composer<_$Database, $ExerciseTagsTableTable> {
  $$ExerciseTagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableTableFilterComposer get exercise {
    final $$ExercisesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableFilterComposer(
            $db: $db,
            $table: $db.exercisesTable,
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

class $$ExerciseTagsTableTableOrderingComposer
    extends Composer<_$Database, $ExerciseTagsTableTable> {
  $$ExerciseTagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableTableOrderingComposer get exercise {
    final $$ExercisesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableOrderingComposer(
            $db: $db,
            $table: $db.exercisesTable,
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

class $$ExerciseTagsTableTableAnnotationComposer
    extends Composer<_$Database, $ExerciseTagsTableTable> {
  $$ExerciseTagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ExercisesTableTableAnnotationComposer get exercise {
    final $$ExercisesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.exercisesTable,
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

class $$ExerciseTagsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $ExerciseTagsTableTable,
          ExerciseTagsTableData,
          $$ExerciseTagsTableTableFilterComposer,
          $$ExerciseTagsTableTableOrderingComposer,
          $$ExerciseTagsTableTableAnnotationComposer,
          $$ExerciseTagsTableTableCreateCompanionBuilder,
          $$ExerciseTagsTableTableUpdateCompanionBuilder,
          (ExerciseTagsTableData, $$ExerciseTagsTableTableReferences),
          ExerciseTagsTableData,
          PrefetchHooks Function({bool exercise, bool tag})
        > {
  $$ExerciseTagsTableTableTableManager(
    _$Database db,
    $ExerciseTagsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseTagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseTagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseTagsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exercise = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseTagsTableCompanion(
                exercise: exercise,
                tag: tag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exercise,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => ExerciseTagsTableCompanion.insert(
                exercise: exercise,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExerciseTagsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exercise = false, tag = false}) {
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
                    if (exercise) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exercise,
                                referencedTable:
                                    $$ExerciseTagsTableTableReferences
                                        ._exerciseTable(db),
                                referencedColumn:
                                    $$ExerciseTagsTableTableReferences
                                        ._exerciseTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (tag) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tag,
                                referencedTable:
                                    $$ExerciseTagsTableTableReferences
                                        ._tagTable(db),
                                referencedColumn:
                                    $$ExerciseTagsTableTableReferences
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

typedef $$ExerciseTagsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $ExerciseTagsTableTable,
      ExerciseTagsTableData,
      $$ExerciseTagsTableTableFilterComposer,
      $$ExerciseTagsTableTableOrderingComposer,
      $$ExerciseTagsTableTableAnnotationComposer,
      $$ExerciseTagsTableTableCreateCompanionBuilder,
      $$ExerciseTagsTableTableUpdateCompanionBuilder,
      (ExerciseTagsTableData, $$ExerciseTagsTableTableReferences),
      ExerciseTagsTableData,
      PrefetchHooks Function({bool exercise, bool tag})
    >;
typedef $$PracticeRoutinesTableTableCreateCompanionBuilder =
    PracticeRoutinesTableCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$PracticeRoutinesTableTableUpdateCompanionBuilder =
    PracticeRoutinesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$PracticeRoutinesTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $PracticeRoutinesTableTable,
          PracticeRoutinesTableData
        > {
  $$PracticeRoutinesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PracticeRoutineEntriesTableTable,
    List<PracticeRoutineEntriesTableData>
  >
  _practiceRoutineEntriesTableRefsTable(_$Database db) =>
      MultiTypedResultKey.fromTable(
        db.practiceRoutineEntriesTable,
        aliasName: 'practice_routines__id__practice_routine_entries__routine',
      );

  $$PracticeRoutineEntriesTableTableProcessedTableManager
  get practiceRoutineEntriesTableRefs {
    final manager = $$PracticeRoutineEntriesTableTableTableManager(
      $_db,
      $_db.practiceRoutineEntriesTable,
    ).filter((f) => f.routine.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceRoutineEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeRoutinesTableTableFilterComposer
    extends Composer<_$Database, $PracticeRoutinesTableTable> {
  $$PracticeRoutinesTableTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  Expression<bool> practiceRoutineEntriesTableRefs(
    Expression<bool> Function(
      $$PracticeRoutineEntriesTableTableFilterComposer f,
    )
    f,
  ) {
    final $$PracticeRoutineEntriesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceRoutineEntriesTable,
          getReferencedColumn: (t) => t.routine,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutineEntriesTableTableFilterComposer(
                $db: $db,
                $table: $db.practiceRoutineEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PracticeRoutinesTableTableOrderingComposer
    extends Composer<_$Database, $PracticeRoutinesTableTable> {
  $$PracticeRoutinesTableTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

class $$PracticeRoutinesTableTableAnnotationComposer
    extends Composer<_$Database, $PracticeRoutinesTableTable> {
  $$PracticeRoutinesTableTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  Expression<T> practiceRoutineEntriesTableRefs<T extends Object>(
    Expression<T> Function(
      $$PracticeRoutineEntriesTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$PracticeRoutineEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceRoutineEntriesTable,
          getReferencedColumn: (t) => t.routine,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutineEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceRoutineEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PracticeRoutinesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $PracticeRoutinesTableTable,
          PracticeRoutinesTableData,
          $$PracticeRoutinesTableTableFilterComposer,
          $$PracticeRoutinesTableTableOrderingComposer,
          $$PracticeRoutinesTableTableAnnotationComposer,
          $$PracticeRoutinesTableTableCreateCompanionBuilder,
          $$PracticeRoutinesTableTableUpdateCompanionBuilder,
          (PracticeRoutinesTableData, $$PracticeRoutinesTableTableReferences),
          PracticeRoutinesTableData,
          PrefetchHooks Function({bool practiceRoutineEntriesTableRefs})
        > {
  $$PracticeRoutinesTableTableTableManager(
    _$Database db,
    $PracticeRoutinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeRoutinesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PracticeRoutinesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PracticeRoutinesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRoutinesTableCompanion(
                id: id,
                name: name,
                description: description,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRoutinesTableCompanion.insert(
                id: id,
                name: name,
                description: description,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeRoutinesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({practiceRoutineEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (practiceRoutineEntriesTableRefs)
                  db.practiceRoutineEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (practiceRoutineEntriesTableRefs)
                    await $_getPrefetchedData<
                      PracticeRoutinesTableData,
                      $PracticeRoutinesTableTable,
                      PracticeRoutineEntriesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$PracticeRoutinesTableTableReferences
                          ._practiceRoutineEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PracticeRoutinesTableTableReferences(
                            db,
                            table,
                            p0,
                          ).practiceRoutineEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.routine == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PracticeRoutinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $PracticeRoutinesTableTable,
      PracticeRoutinesTableData,
      $$PracticeRoutinesTableTableFilterComposer,
      $$PracticeRoutinesTableTableOrderingComposer,
      $$PracticeRoutinesTableTableAnnotationComposer,
      $$PracticeRoutinesTableTableCreateCompanionBuilder,
      $$PracticeRoutinesTableTableUpdateCompanionBuilder,
      (PracticeRoutinesTableData, $$PracticeRoutinesTableTableReferences),
      PracticeRoutinesTableData,
      PrefetchHooks Function({bool practiceRoutineEntriesTableRefs})
    >;
typedef $$PracticeRoutineEntriesTableTableCreateCompanionBuilder =
    PracticeRoutineEntriesTableCompanion Function({
      required String id,
      required String routine,
      required String exercise,
      required int position,
      Value<String?> extraNotes,
      Value<Duration?> targetDuration,
      Value<String?> defaultScore,
      Value<int> rowid,
    });
typedef $$PracticeRoutineEntriesTableTableUpdateCompanionBuilder =
    PracticeRoutineEntriesTableCompanion Function({
      Value<String> id,
      Value<String> routine,
      Value<String> exercise,
      Value<int> position,
      Value<String?> extraNotes,
      Value<Duration?> targetDuration,
      Value<String?> defaultScore,
      Value<int> rowid,
    });

final class $$PracticeRoutineEntriesTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $PracticeRoutineEntriesTableTable,
          PracticeRoutineEntriesTableData
        > {
  $$PracticeRoutineEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeRoutinesTableTable _routineTable(_$Database db) => db
      .practiceRoutinesTable
      .createAlias('practice_routine_entries__routine__practice_routines__id');

  $$PracticeRoutinesTableTableProcessedTableManager get routine {
    final $_column = $_itemColumn<String>('routine')!;

    final manager = $$PracticeRoutinesTableTableTableManager(
      $_db,
      $_db.practiceRoutinesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTableTable _exerciseTable(_$Database db) => db.exercisesTable
      .createAlias('practice_routine_entries__exercise__exercises__id');

  $$ExercisesTableTableProcessedTableManager get exercise {
    final $_column = $_itemColumn<String>('exercise')!;

    final manager = $$ExercisesTableTableTableManager(
      $_db,
      $_db.exercisesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeRoutineEntriesTableTableFilterComposer
    extends Composer<_$Database, $PracticeRoutineEntriesTableTable> {
  $$PracticeRoutineEntriesTableTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraNotes => $composableBuilder(
    column: $table.extraNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration?, Duration, int> get targetDuration =>
      $composableBuilder(
        column: $table.targetDuration,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeRoutinesTableTableFilterComposer get routine {
    final $$PracticeRoutinesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routine,
          referencedTable: $db.practiceRoutinesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutinesTableTableFilterComposer(
                $db: $db,
                $table: $db.practiceRoutinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ExercisesTableTableFilterComposer get exercise {
    final $$ExercisesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableFilterComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeRoutineEntriesTableTableOrderingComposer
    extends Composer<_$Database, $PracticeRoutineEntriesTableTable> {
  $$PracticeRoutineEntriesTableTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraNotes => $composableBuilder(
    column: $table.extraNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDuration => $composableBuilder(
    column: $table.targetDuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeRoutinesTableTableOrderingComposer get routine {
    final $$PracticeRoutinesTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routine,
          referencedTable: $db.practiceRoutinesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutinesTableTableOrderingComposer(
                $db: $db,
                $table: $db.practiceRoutinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ExercisesTableTableOrderingComposer get exercise {
    final $$ExercisesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableOrderingComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeRoutineEntriesTableTableAnnotationComposer
    extends Composer<_$Database, $PracticeRoutineEntriesTableTable> {
  $$PracticeRoutineEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get extraNotes => $composableBuilder(
    column: $table.extraNotes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration?, int> get targetDuration =>
      $composableBuilder(
        column: $table.targetDuration,
        builder: (column) => column,
      );

  GeneratedColumn<String> get defaultScore => $composableBuilder(
    column: $table.defaultScore,
    builder: (column) => column,
  );

  $$PracticeRoutinesTableTableAnnotationComposer get routine {
    final $$PracticeRoutinesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.routine,
          referencedTable: $db.practiceRoutinesTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeRoutinesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceRoutinesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$ExercisesTableTableAnnotationComposer get exercise {
    final $$ExercisesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exercise,
      referencedTable: $db.exercisesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.exercisesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeRoutineEntriesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $PracticeRoutineEntriesTableTable,
          PracticeRoutineEntriesTableData,
          $$PracticeRoutineEntriesTableTableFilterComposer,
          $$PracticeRoutineEntriesTableTableOrderingComposer,
          $$PracticeRoutineEntriesTableTableAnnotationComposer,
          $$PracticeRoutineEntriesTableTableCreateCompanionBuilder,
          $$PracticeRoutineEntriesTableTableUpdateCompanionBuilder,
          (
            PracticeRoutineEntriesTableData,
            $$PracticeRoutineEntriesTableTableReferences,
          ),
          PracticeRoutineEntriesTableData,
          PrefetchHooks Function({bool routine, bool exercise})
        > {
  $$PracticeRoutineEntriesTableTableTableManager(
    _$Database db,
    $PracticeRoutineEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeRoutineEntriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PracticeRoutineEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PracticeRoutineEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> routine = const Value.absent(),
                Value<String> exercise = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> extraNotes = const Value.absent(),
                Value<Duration?> targetDuration = const Value.absent(),
                Value<String?> defaultScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRoutineEntriesTableCompanion(
                id: id,
                routine: routine,
                exercise: exercise,
                position: position,
                extraNotes: extraNotes,
                targetDuration: targetDuration,
                defaultScore: defaultScore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String routine,
                required String exercise,
                required int position,
                Value<String?> extraNotes = const Value.absent(),
                Value<Duration?> targetDuration = const Value.absent(),
                Value<String?> defaultScore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRoutineEntriesTableCompanion.insert(
                id: id,
                routine: routine,
                exercise: exercise,
                position: position,
                extraNotes: extraNotes,
                targetDuration: targetDuration,
                defaultScore: defaultScore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeRoutineEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({routine = false, exercise = false}) {
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
                    if (routine) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.routine,
                                referencedTable:
                                    $$PracticeRoutineEntriesTableTableReferences
                                        ._routineTable(db),
                                referencedColumn:
                                    $$PracticeRoutineEntriesTableTableReferences
                                        ._routineTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (exercise) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.exercise,
                                referencedTable:
                                    $$PracticeRoutineEntriesTableTableReferences
                                        ._exerciseTable(db),
                                referencedColumn:
                                    $$PracticeRoutineEntriesTableTableReferences
                                        ._exerciseTable(db)
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

typedef $$PracticeRoutineEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $PracticeRoutineEntriesTableTable,
      PracticeRoutineEntriesTableData,
      $$PracticeRoutineEntriesTableTableFilterComposer,
      $$PracticeRoutineEntriesTableTableOrderingComposer,
      $$PracticeRoutineEntriesTableTableAnnotationComposer,
      $$PracticeRoutineEntriesTableTableCreateCompanionBuilder,
      $$PracticeRoutineEntriesTableTableUpdateCompanionBuilder,
      (
        PracticeRoutineEntriesTableData,
        $$PracticeRoutineEntriesTableTableReferences,
      ),
      PracticeRoutineEntriesTableData,
      PrefetchHooks Function({bool routine, bool exercise})
    >;
typedef $$PracticeSessionsTableTableCreateCompanionBuilder =
    PracticeSessionsTableCompanion Function({
      required String id,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<String?> routine,
      Value<String?> description,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$PracticeSessionsTableTableUpdateCompanionBuilder =
    PracticeSessionsTableCompanion Function({
      Value<String> id,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String?> routine,
      Value<String?> description,
      Value<DateTime> updatedAt,
      Value<DateTime?> writtenAt,
      Value<bool> uploaded,
      Value<int> rowid,
    });

final class $$PracticeSessionsTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $PracticeSessionsTableTable,
          PracticeSessionsTableData
        > {
  $$PracticeSessionsTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $PracticeSessionEntriesTableTable,
    List<PracticeSessionEntriesTableData>
  >
  _practiceSessionEntriesTableRefsTable(_$Database db) =>
      MultiTypedResultKey.fromTable(
        db.practiceSessionEntriesTable,
        aliasName: 'practice_sessions__id__practice_session_entries__session',
      );

  $$PracticeSessionEntriesTableTableProcessedTableManager
  get practiceSessionEntriesTableRefs {
    final manager = $$PracticeSessionEntriesTableTableTableManager(
      $_db,
      $_db.practiceSessionEntriesTable,
    ).filter((f) => f.session.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceSessionEntriesTableRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeSessionsTableTableFilterComposer
    extends Composer<_$Database, $PracticeSessionsTableTable> {
  $$PracticeSessionsTableTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routine => $composableBuilder(
    column: $table.routine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  Expression<bool> practiceSessionEntriesTableRefs(
    Expression<bool> Function(
      $$PracticeSessionEntriesTableTableFilterComposer f,
    )
    f,
  ) {
    final $$PracticeSessionEntriesTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceSessionEntriesTable,
          getReferencedColumn: (t) => t.session,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeSessionEntriesTableTableFilterComposer(
                $db: $db,
                $table: $db.practiceSessionEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableOrderingComposer
    extends Composer<_$Database, $PracticeSessionsTableTable> {
  $$PracticeSessionsTableTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routine => $composableBuilder(
    column: $table.routine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

class $$PracticeSessionsTableTableAnnotationComposer
    extends Composer<_$Database, $PracticeSessionsTableTable> {
  $$PracticeSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get routine =>
      $composableBuilder(column: $table.routine, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);

  Expression<T> practiceSessionEntriesTableRefs<T extends Object>(
    Expression<T> Function(
      $$PracticeSessionEntriesTableTableAnnotationComposer a,
    )
    f,
  ) {
    final $$PracticeSessionEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceSessionEntriesTable,
          getReferencedColumn: (t) => t.session,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeSessionEntriesTableTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceSessionEntriesTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $PracticeSessionsTableTable,
          PracticeSessionsTableData,
          $$PracticeSessionsTableTableFilterComposer,
          $$PracticeSessionsTableTableOrderingComposer,
          $$PracticeSessionsTableTableAnnotationComposer,
          $$PracticeSessionsTableTableCreateCompanionBuilder,
          $$PracticeSessionsTableTableUpdateCompanionBuilder,
          (PracticeSessionsTableData, $$PracticeSessionsTableTableReferences),
          PracticeSessionsTableData,
          PrefetchHooks Function({bool practiceSessionEntriesTableRefs})
        > {
  $$PracticeSessionsTableTableTableManager(
    _$Database db,
    $PracticeSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PracticeSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> routine = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsTableCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                routine: routine,
                description: description,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> routine = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> writtenAt = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionsTableCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                routine: routine,
                description: description,
                updatedAt: updatedAt,
                writtenAt: writtenAt,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeSessionsTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({practiceSessionEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (practiceSessionEntriesTableRefs)
                  db.practiceSessionEntriesTable,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (practiceSessionEntriesTableRefs)
                    await $_getPrefetchedData<
                      PracticeSessionsTableData,
                      $PracticeSessionsTableTable,
                      PracticeSessionEntriesTableData
                    >(
                      currentTable: table,
                      referencedTable: $$PracticeSessionsTableTableReferences
                          ._practiceSessionEntriesTableRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PracticeSessionsTableTableReferences(
                            db,
                            table,
                            p0,
                          ).practiceSessionEntriesTableRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.session == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PracticeSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $PracticeSessionsTableTable,
      PracticeSessionsTableData,
      $$PracticeSessionsTableTableFilterComposer,
      $$PracticeSessionsTableTableOrderingComposer,
      $$PracticeSessionsTableTableAnnotationComposer,
      $$PracticeSessionsTableTableCreateCompanionBuilder,
      $$PracticeSessionsTableTableUpdateCompanionBuilder,
      (PracticeSessionsTableData, $$PracticeSessionsTableTableReferences),
      PracticeSessionsTableData,
      PrefetchHooks Function({bool practiceSessionEntriesTableRefs})
    >;
typedef $$PracticeSessionEntriesTableTableCreateCompanionBuilder =
    PracticeSessionEntriesTableCompanion Function({
      required String id,
      required String session,
      required String exercise,
      Value<String?> routineEntry,
      Value<Duration> duration,
      Value<DateTime?> runningSince,
      Value<int> rowid,
    });
typedef $$PracticeSessionEntriesTableTableUpdateCompanionBuilder =
    PracticeSessionEntriesTableCompanion Function({
      Value<String> id,
      Value<String> session,
      Value<String> exercise,
      Value<String?> routineEntry,
      Value<Duration> duration,
      Value<DateTime?> runningSince,
      Value<int> rowid,
    });

final class $$PracticeSessionEntriesTableTableReferences
    extends
        BaseReferences<
          _$Database,
          $PracticeSessionEntriesTableTable,
          PracticeSessionEntriesTableData
        > {
  $$PracticeSessionEntriesTableTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeSessionsTableTable _sessionTable(_$Database db) => db
      .practiceSessionsTable
      .createAlias('practice_session_entries__session__practice_sessions__id');

  $$PracticeSessionsTableTableProcessedTableManager get session {
    final $_column = $_itemColumn<String>('session')!;

    final manager = $$PracticeSessionsTableTableTableManager(
      $_db,
      $_db.practiceSessionsTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeSessionEntriesTableTableFilterComposer
    extends Composer<_$Database, $PracticeSessionEntriesTableTable> {
  $$PracticeSessionEntriesTableTableFilterComposer({
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

  ColumnFilters<String> get exercise => $composableBuilder(
    column: $table.exercise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routineEntry => $composableBuilder(
    column: $table.routineEntry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get duration =>
      $composableBuilder(
        column: $table.duration,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get runningSince => $composableBuilder(
    column: $table.runningSince,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeSessionsTableTableFilterComposer get session {
    final $$PracticeSessionsTableTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.session,
          referencedTable: $db.practiceSessionsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeSessionsTableTableFilterComposer(
                $db: $db,
                $table: $db.practiceSessionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PracticeSessionEntriesTableTableOrderingComposer
    extends Composer<_$Database, $PracticeSessionEntriesTableTable> {
  $$PracticeSessionEntriesTableTableOrderingComposer({
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

  ColumnOrderings<String> get exercise => $composableBuilder(
    column: $table.exercise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routineEntry => $composableBuilder(
    column: $table.routineEntry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get runningSince => $composableBuilder(
    column: $table.runningSince,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableTableOrderingComposer get session {
    final $$PracticeSessionsTableTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.session,
          referencedTable: $db.practiceSessionsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeSessionsTableTableOrderingComposer(
                $db: $db,
                $table: $db.practiceSessionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PracticeSessionEntriesTableTableAnnotationComposer
    extends Composer<_$Database, $PracticeSessionEntriesTableTable> {
  $$PracticeSessionEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exercise =>
      $composableBuilder(column: $table.exercise, builder: (column) => column);

  GeneratedColumn<String> get routineEntry => $composableBuilder(
    column: $table.routineEntry,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration, int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get runningSince => $composableBuilder(
    column: $table.runningSince,
    builder: (column) => column,
  );

  $$PracticeSessionsTableTableAnnotationComposer get session {
    final $$PracticeSessionsTableTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.session,
          referencedTable: $db.practiceSessionsTable,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeSessionsTableTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceSessionsTable,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$PracticeSessionEntriesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $PracticeSessionEntriesTableTable,
          PracticeSessionEntriesTableData,
          $$PracticeSessionEntriesTableTableFilterComposer,
          $$PracticeSessionEntriesTableTableOrderingComposer,
          $$PracticeSessionEntriesTableTableAnnotationComposer,
          $$PracticeSessionEntriesTableTableCreateCompanionBuilder,
          $$PracticeSessionEntriesTableTableUpdateCompanionBuilder,
          (
            PracticeSessionEntriesTableData,
            $$PracticeSessionEntriesTableTableReferences,
          ),
          PracticeSessionEntriesTableData,
          PrefetchHooks Function({bool session})
        > {
  $$PracticeSessionEntriesTableTableTableManager(
    _$Database db,
    $PracticeSessionEntriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionEntriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PracticeSessionEntriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PracticeSessionEntriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> session = const Value.absent(),
                Value<String> exercise = const Value.absent(),
                Value<String?> routineEntry = const Value.absent(),
                Value<Duration> duration = const Value.absent(),
                Value<DateTime?> runningSince = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionEntriesTableCompanion(
                id: id,
                session: session,
                exercise: exercise,
                routineEntry: routineEntry,
                duration: duration,
                runningSince: runningSince,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String session,
                required String exercise,
                Value<String?> routineEntry = const Value.absent(),
                Value<Duration> duration = const Value.absent(),
                Value<DateTime?> runningSince = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeSessionEntriesTableCompanion.insert(
                id: id,
                session: session,
                exercise: exercise,
                routineEntry: routineEntry,
                duration: duration,
                runningSince: runningSince,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeSessionEntriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({session = false}) {
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
                    if (session) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.session,
                                referencedTable:
                                    $$PracticeSessionEntriesTableTableReferences
                                        ._sessionTable(db),
                                referencedColumn:
                                    $$PracticeSessionEntriesTableTableReferences
                                        ._sessionTable(db)
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

typedef $$PracticeSessionEntriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $PracticeSessionEntriesTableTable,
      PracticeSessionEntriesTableData,
      $$PracticeSessionEntriesTableTableFilterComposer,
      $$PracticeSessionEntriesTableTableOrderingComposer,
      $$PracticeSessionEntriesTableTableAnnotationComposer,
      $$PracticeSessionEntriesTableTableCreateCompanionBuilder,
      $$PracticeSessionEntriesTableTableUpdateCompanionBuilder,
      (
        PracticeSessionEntriesTableData,
        $$PracticeSessionEntriesTableTableReferences,
      ),
      PracticeSessionEntriesTableData,
      PrefetchHooks Function({bool session})
    >;
typedef $$DeletedExerciseCategoriesTableTableCreateCompanionBuilder =
    DeletedExerciseCategoriesTableCompanion Function({
      required String categoryId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedExerciseCategoriesTableTableUpdateCompanionBuilder =
    DeletedExerciseCategoriesTableCompanion Function({
      Value<String> categoryId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedExerciseCategoriesTableTableFilterComposer
    extends Composer<_$Database, $DeletedExerciseCategoriesTableTable> {
  $$DeletedExerciseCategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedExerciseCategoriesTableTableOrderingComposer
    extends Composer<_$Database, $DeletedExerciseCategoriesTableTable> {
  $$DeletedExerciseCategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedExerciseCategoriesTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedExerciseCategoriesTableTable> {
  $$DeletedExerciseCategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedExerciseCategoriesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedExerciseCategoriesTableTable,
          DeletedExerciseCategoriesTableData,
          $$DeletedExerciseCategoriesTableTableFilterComposer,
          $$DeletedExerciseCategoriesTableTableOrderingComposer,
          $$DeletedExerciseCategoriesTableTableAnnotationComposer,
          $$DeletedExerciseCategoriesTableTableCreateCompanionBuilder,
          $$DeletedExerciseCategoriesTableTableUpdateCompanionBuilder,
          (
            DeletedExerciseCategoriesTableData,
            BaseReferences<
              _$Database,
              $DeletedExerciseCategoriesTableTable,
              DeletedExerciseCategoriesTableData
            >,
          ),
          DeletedExerciseCategoriesTableData,
          PrefetchHooks Function()
        > {
  $$DeletedExerciseCategoriesTableTableTableManager(
    _$Database db,
    $DeletedExerciseCategoriesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedExerciseCategoriesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DeletedExerciseCategoriesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedExerciseCategoriesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> categoryId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedExerciseCategoriesTableCompanion(
                categoryId: categoryId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String categoryId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedExerciseCategoriesTableCompanion.insert(
                categoryId: categoryId,
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

typedef $$DeletedExerciseCategoriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedExerciseCategoriesTableTable,
      DeletedExerciseCategoriesTableData,
      $$DeletedExerciseCategoriesTableTableFilterComposer,
      $$DeletedExerciseCategoriesTableTableOrderingComposer,
      $$DeletedExerciseCategoriesTableTableAnnotationComposer,
      $$DeletedExerciseCategoriesTableTableCreateCompanionBuilder,
      $$DeletedExerciseCategoriesTableTableUpdateCompanionBuilder,
      (
        DeletedExerciseCategoriesTableData,
        BaseReferences<
          _$Database,
          $DeletedExerciseCategoriesTableTable,
          DeletedExerciseCategoriesTableData
        >,
      ),
      DeletedExerciseCategoriesTableData,
      PrefetchHooks Function()
    >;
typedef $$DeletedExercisesTableTableCreateCompanionBuilder =
    DeletedExercisesTableCompanion Function({
      required String exerciseId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedExercisesTableTableUpdateCompanionBuilder =
    DeletedExercisesTableCompanion Function({
      Value<String> exerciseId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedExercisesTableTableFilterComposer
    extends Composer<_$Database, $DeletedExercisesTableTable> {
  $$DeletedExercisesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedExercisesTableTableOrderingComposer
    extends Composer<_$Database, $DeletedExercisesTableTable> {
  $$DeletedExercisesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedExercisesTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedExercisesTableTable> {
  $$DeletedExercisesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedExercisesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedExercisesTableTable,
          DeletedExercisesTableData,
          $$DeletedExercisesTableTableFilterComposer,
          $$DeletedExercisesTableTableOrderingComposer,
          $$DeletedExercisesTableTableAnnotationComposer,
          $$DeletedExercisesTableTableCreateCompanionBuilder,
          $$DeletedExercisesTableTableUpdateCompanionBuilder,
          (
            DeletedExercisesTableData,
            BaseReferences<
              _$Database,
              $DeletedExercisesTableTable,
              DeletedExercisesTableData
            >,
          ),
          DeletedExercisesTableData,
          PrefetchHooks Function()
        > {
  $$DeletedExercisesTableTableTableManager(
    _$Database db,
    $DeletedExercisesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedExercisesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DeletedExercisesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedExercisesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedExercisesTableCompanion(
                exerciseId: exerciseId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedExercisesTableCompanion.insert(
                exerciseId: exerciseId,
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

typedef $$DeletedExercisesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedExercisesTableTable,
      DeletedExercisesTableData,
      $$DeletedExercisesTableTableFilterComposer,
      $$DeletedExercisesTableTableOrderingComposer,
      $$DeletedExercisesTableTableAnnotationComposer,
      $$DeletedExercisesTableTableCreateCompanionBuilder,
      $$DeletedExercisesTableTableUpdateCompanionBuilder,
      (
        DeletedExercisesTableData,
        BaseReferences<
          _$Database,
          $DeletedExercisesTableTable,
          DeletedExercisesTableData
        >,
      ),
      DeletedExercisesTableData,
      PrefetchHooks Function()
    >;
typedef $$DeletedPracticeRoutinesTableTableCreateCompanionBuilder =
    DeletedPracticeRoutinesTableCompanion Function({
      required String routineId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedPracticeRoutinesTableTableUpdateCompanionBuilder =
    DeletedPracticeRoutinesTableCompanion Function({
      Value<String> routineId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedPracticeRoutinesTableTableFilterComposer
    extends Composer<_$Database, $DeletedPracticeRoutinesTableTable> {
  $$DeletedPracticeRoutinesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedPracticeRoutinesTableTableOrderingComposer
    extends Composer<_$Database, $DeletedPracticeRoutinesTableTable> {
  $$DeletedPracticeRoutinesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get routineId => $composableBuilder(
    column: $table.routineId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedPracticeRoutinesTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedPracticeRoutinesTableTable> {
  $$DeletedPracticeRoutinesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedPracticeRoutinesTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedPracticeRoutinesTableTable,
          DeletedPracticeRoutinesTableData,
          $$DeletedPracticeRoutinesTableTableFilterComposer,
          $$DeletedPracticeRoutinesTableTableOrderingComposer,
          $$DeletedPracticeRoutinesTableTableAnnotationComposer,
          $$DeletedPracticeRoutinesTableTableCreateCompanionBuilder,
          $$DeletedPracticeRoutinesTableTableUpdateCompanionBuilder,
          (
            DeletedPracticeRoutinesTableData,
            BaseReferences<
              _$Database,
              $DeletedPracticeRoutinesTableTable,
              DeletedPracticeRoutinesTableData
            >,
          ),
          DeletedPracticeRoutinesTableData,
          PrefetchHooks Function()
        > {
  $$DeletedPracticeRoutinesTableTableTableManager(
    _$Database db,
    $DeletedPracticeRoutinesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedPracticeRoutinesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DeletedPracticeRoutinesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedPracticeRoutinesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> routineId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedPracticeRoutinesTableCompanion(
                routineId: routineId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String routineId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedPracticeRoutinesTableCompanion.insert(
                routineId: routineId,
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

typedef $$DeletedPracticeRoutinesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedPracticeRoutinesTableTable,
      DeletedPracticeRoutinesTableData,
      $$DeletedPracticeRoutinesTableTableFilterComposer,
      $$DeletedPracticeRoutinesTableTableOrderingComposer,
      $$DeletedPracticeRoutinesTableTableAnnotationComposer,
      $$DeletedPracticeRoutinesTableTableCreateCompanionBuilder,
      $$DeletedPracticeRoutinesTableTableUpdateCompanionBuilder,
      (
        DeletedPracticeRoutinesTableData,
        BaseReferences<
          _$Database,
          $DeletedPracticeRoutinesTableTable,
          DeletedPracticeRoutinesTableData
        >,
      ),
      DeletedPracticeRoutinesTableData,
      PrefetchHooks Function()
    >;
typedef $$DeletedPracticeSessionsTableTableCreateCompanionBuilder =
    DeletedPracticeSessionsTableCompanion Function({
      required String sessionId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });
typedef $$DeletedPracticeSessionsTableTableUpdateCompanionBuilder =
    DeletedPracticeSessionsTableCompanion Function({
      Value<String> sessionId,
      Value<DateTime> deletedAt,
      Value<int> rowid,
    });

class $$DeletedPracticeSessionsTableTableFilterComposer
    extends Composer<_$Database, $DeletedPracticeSessionsTableTable> {
  $$DeletedPracticeSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeletedPracticeSessionsTableTableOrderingComposer
    extends Composer<_$Database, $DeletedPracticeSessionsTableTable> {
  $$DeletedPracticeSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeletedPracticeSessionsTableTableAnnotationComposer
    extends Composer<_$Database, $DeletedPracticeSessionsTableTable> {
  $$DeletedPracticeSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DeletedPracticeSessionsTableTableTableManager
    extends
        RootTableManager<
          _$Database,
          $DeletedPracticeSessionsTableTable,
          DeletedPracticeSessionsTableData,
          $$DeletedPracticeSessionsTableTableFilterComposer,
          $$DeletedPracticeSessionsTableTableOrderingComposer,
          $$DeletedPracticeSessionsTableTableAnnotationComposer,
          $$DeletedPracticeSessionsTableTableCreateCompanionBuilder,
          $$DeletedPracticeSessionsTableTableUpdateCompanionBuilder,
          (
            DeletedPracticeSessionsTableData,
            BaseReferences<
              _$Database,
              $DeletedPracticeSessionsTableTable,
              DeletedPracticeSessionsTableData
            >,
          ),
          DeletedPracticeSessionsTableData,
          PrefetchHooks Function()
        > {
  $$DeletedPracticeSessionsTableTableTableManager(
    _$Database db,
    $DeletedPracticeSessionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedPracticeSessionsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DeletedPracticeSessionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeletedPracticeSessionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedPracticeSessionsTableCompanion(
                sessionId: sessionId,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                Value<DateTime> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedPracticeSessionsTableCompanion.insert(
                sessionId: sessionId,
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

typedef $$DeletedPracticeSessionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$Database,
      $DeletedPracticeSessionsTableTable,
      DeletedPracticeSessionsTableData,
      $$DeletedPracticeSessionsTableTableFilterComposer,
      $$DeletedPracticeSessionsTableTableOrderingComposer,
      $$DeletedPracticeSessionsTableTableAnnotationComposer,
      $$DeletedPracticeSessionsTableTableCreateCompanionBuilder,
      $$DeletedPracticeSessionsTableTableUpdateCompanionBuilder,
      (
        DeletedPracticeSessionsTableData,
        BaseReferences<
          _$Database,
          $DeletedPracticeSessionsTableTable,
          DeletedPracticeSessionsTableData
        >,
      ),
      DeletedPracticeSessionsTableData,
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
  $$ExerciseCategoriesTableTableTableManager get exerciseCategoriesTable =>
      $$ExerciseCategoriesTableTableTableManager(
        _db,
        _db.exerciseCategoriesTable,
      );
  $$ExercisesTableTableTableManager get exercisesTable =>
      $$ExercisesTableTableTableManager(_db, _db.exercisesTable);
  $$ExerciseScoresTableTableTableManager get exerciseScoresTable =>
      $$ExerciseScoresTableTableTableManager(_db, _db.exerciseScoresTable);
  $$ExerciseTagsTableTableTableManager get exerciseTagsTable =>
      $$ExerciseTagsTableTableTableManager(_db, _db.exerciseTagsTable);
  $$PracticeRoutinesTableTableTableManager get practiceRoutinesTable =>
      $$PracticeRoutinesTableTableTableManager(_db, _db.practiceRoutinesTable);
  $$PracticeRoutineEntriesTableTableTableManager
  get practiceRoutineEntriesTable =>
      $$PracticeRoutineEntriesTableTableTableManager(
        _db,
        _db.practiceRoutineEntriesTable,
      );
  $$PracticeSessionsTableTableTableManager get practiceSessionsTable =>
      $$PracticeSessionsTableTableTableManager(_db, _db.practiceSessionsTable);
  $$PracticeSessionEntriesTableTableTableManager
  get practiceSessionEntriesTable =>
      $$PracticeSessionEntriesTableTableTableManager(
        _db,
        _db.practiceSessionEntriesTable,
      );
  $$DeletedExerciseCategoriesTableTableTableManager
  get deletedExerciseCategoriesTable =>
      $$DeletedExerciseCategoriesTableTableTableManager(
        _db,
        _db.deletedExerciseCategoriesTable,
      );
  $$DeletedExercisesTableTableTableManager get deletedExercisesTable =>
      $$DeletedExercisesTableTableTableManager(_db, _db.deletedExercisesTable);
  $$DeletedPracticeRoutinesTableTableTableManager
  get deletedPracticeRoutinesTable =>
      $$DeletedPracticeRoutinesTableTableTableManager(
        _db,
        _db.deletedPracticeRoutinesTable,
      );
  $$DeletedPracticeSessionsTableTableTableManager
  get deletedPracticeSessionsTable =>
      $$DeletedPracticeSessionsTableTableTableManager(
        _db,
        _db.deletedPracticeSessionsTable,
      );
}
