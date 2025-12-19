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
    composer,
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
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
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
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
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
  final String? composer;
  final DateTime createdAt;
  final DateTime metadataUpdatedAt;
  final DateTime fileUpdatedAt;
  final bool downloaded;
  final FileType fileType;
  const ScoresTableData({
    required this.id,
    required this.title,
    this.composer,
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
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
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
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
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
      composer: serializer.fromJson<String?>(json['composer']),
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
      'composer': serializer.toJson<String?>(composer),
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
    Value<String?> composer = const Value.absent(),
    DateTime? createdAt,
    DateTime? metadataUpdatedAt,
    DateTime? fileUpdatedAt,
    bool? downloaded,
    FileType? fileType,
  }) => ScoresTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
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
      composer: data.composer.present ? data.composer.value : this.composer,
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
          ..write('composer: $composer, ')
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
    composer,
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
          other.composer == this.composer &&
          other.createdAt == this.createdAt &&
          other.metadataUpdatedAt == this.metadataUpdatedAt &&
          other.fileUpdatedAt == this.fileUpdatedAt &&
          other.downloaded == this.downloaded &&
          other.fileType == this.fileType);
}

class ScoresTableCompanion extends UpdateCompanion<ScoresTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> composer;
  final Value<DateTime> createdAt;
  final Value<DateTime> metadataUpdatedAt;
  final Value<DateTime> fileUpdatedAt;
  final Value<bool> downloaded;
  final Value<FileType> fileType;
  final Value<int> rowid;
  const ScoresTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
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
    this.composer = const Value.absent(),
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
    Expression<String>? composer,
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
      if (composer != null) 'composer': composer,
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
    Value<String?>? composer,
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
      composer: composer ?? this.composer,
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
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
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
          ..write('composer: $composer, ')
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
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, updatedAt];
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
  const TagsTableData({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TagsTableCompanion toCompanion(bool nullToAbsent) {
    return TagsTableCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      updatedAt: Value(updatedAt),
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
    };
  }

  TagsTableData copyWith({
    String? id,
    String? name,
    int? color,
    DateTime? updatedAt,
  }) => TagsTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TagsTableData copyWithCompanion(TagsTableCompanion data) {
    return TagsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt);
}

class TagsTableCompanion extends UpdateCompanion<TagsTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TagsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsTableCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<TagsTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
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
      Value<String?> composer,
      Value<DateTime> createdAt,
      Value<DateTime> metadataUpdatedAt,
      Value<DateTime> fileUpdatedAt,
      Value<bool> downloaded,
      Value<FileType> fileType,
      Value<int> rowid,
    });

final class $$ScoresTableTableReferences
    extends BaseReferences<_$Database, $ScoresTableTable, ScoresTableData> {
  $$ScoresTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GenresTableTable, List<GenresTableData>>
  _genresTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.genresTable,
    aliasName: $_aliasNameGenerator(db.scoresTable.id, db.genresTable.score),
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
    aliasName: $_aliasNameGenerator(
      db.scoresTable.id,
      db.instrumentsTable.score,
    ),
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
    aliasName: $_aliasNameGenerator(db.scoresTable.id, db.scoreTagsTable.score),
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

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

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
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                Value<bool> downloaded = const Value.absent(),
                Value<FileType> fileType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion(
                id: id,
                title: title,
                composer: composer,
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
                Value<String?> composer = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> metadataUpdatedAt = const Value.absent(),
                Value<DateTime> fileUpdatedAt = const Value.absent(),
                required bool downloaded,
                required FileType fileType,
                Value<int> rowid = const Value.absent(),
              }) => ScoresTableCompanion.insert(
                id: id,
                title: title,
                composer: composer,
                createdAt: createdAt,
                metadataUpdatedAt: metadataUpdatedAt,
                fileUpdatedAt: fileUpdatedAt,
                downloaded: downloaded,
                fileType: fileType,
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
      db.scoresTable.createAlias(
        $_aliasNameGenerator(db.genresTable.score, db.scoresTable.id),
      );

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
      db.scoresTable.createAlias(
        $_aliasNameGenerator(db.instrumentsTable.score, db.scoresTable.id),
      );

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
      Value<int> rowid,
    });
typedef $$TagsTableTableUpdateCompanionBuilder =
    TagsTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> color,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TagsTableTableReferences
    extends BaseReferences<_$Database, $TagsTableTable, TagsTableData> {
  $$TagsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ScoreTagsTableTable, List<ScoreTagsTableData>>
  _scoreTagsTableRefsTable(_$Database db) => MultiTypedResultKey.fromTable(
    db.scoreTagsTable,
    aliasName: $_aliasNameGenerator(db.tagsTable.id, db.scoreTagsTable.tag),
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
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int color,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsTableCompanion.insert(
                id: id,
                name: name,
                color: color,
                updatedAt: updatedAt,
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
      db.scoresTable.createAlias(
        $_aliasNameGenerator(db.scoreTagsTable.score, db.scoresTable.id),
      );

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

  static $TagsTableTable _tagTable(_$Database db) => db.tagsTable.createAlias(
    $_aliasNameGenerator(db.scoreTagsTable.tag, db.tagsTable.id),
  );

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
}
