// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Scores extends Table with TableInfo<Scores, ScoresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Scores(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL',
  );
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT CURRENT_TIMESTAMP',
    defaultValue: const CustomExpression('CURRENT_TIMESTAMP'),
  );
  late final GeneratedColumn<String> metadataUpdatedAt =
      GeneratedColumn<String>(
        'metadata_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT CURRENT_TIMESTAMP',
        defaultValue: const CustomExpression('CURRENT_TIMESTAMP'),
      );
  late final GeneratedColumn<String> fileUpdatedAt = GeneratedColumn<String>(
    'file_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT CURRENT_TIMESTAMP',
    defaultValue: const CustomExpression('CURRENT_TIMESTAMP'),
  );
  late final GeneratedColumn<int> downloaded = GeneratedColumn<int>(
    'downloaded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (downloaded IN (0, 1))',
  );
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    composer,
    searchText,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoresData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoresData(
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
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      metadataUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_updated_at'],
      )!,
      fileUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_updated_at'],
      )!,
      downloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
    );
  }

  @override
  Scores createAlias(String alias) {
    return Scores(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class ScoresData extends DataClass implements Insertable<ScoresData> {
  final String id;
  final String title;
  final String? composer;
  final String searchText;
  final String createdAt;
  final String metadataUpdatedAt;
  final String fileUpdatedAt;
  final int downloaded;
  final String fileType;
  const ScoresData({
    required this.id,
    required this.title,
    this.composer,
    required this.searchText,
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
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<String>(createdAt);
    map['metadata_updated_at'] = Variable<String>(metadataUpdatedAt);
    map['file_updated_at'] = Variable<String>(fileUpdatedAt);
    map['downloaded'] = Variable<int>(downloaded);
    map['file_type'] = Variable<String>(fileType);
    return map;
  }

  ScoresCompanion toCompanion(bool nullToAbsent) {
    return ScoresCompanion(
      id: Value(id),
      title: Value(title),
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      metadataUpdatedAt: Value(metadataUpdatedAt),
      fileUpdatedAt: Value(fileUpdatedAt),
      downloaded: Value(downloaded),
      fileType: Value(fileType),
    );
  }

  factory ScoresData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoresData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String?>(json['composer']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      metadataUpdatedAt: serializer.fromJson<String>(json['metadataUpdatedAt']),
      fileUpdatedAt: serializer.fromJson<String>(json['fileUpdatedAt']),
      downloaded: serializer.fromJson<int>(json['downloaded']),
      fileType: serializer.fromJson<String>(json['fileType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String?>(composer),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<String>(createdAt),
      'metadataUpdatedAt': serializer.toJson<String>(metadataUpdatedAt),
      'fileUpdatedAt': serializer.toJson<String>(fileUpdatedAt),
      'downloaded': serializer.toJson<int>(downloaded),
      'fileType': serializer.toJson<String>(fileType),
    };
  }

  ScoresData copyWith({
    String? id,
    String? title,
    Value<String?> composer = const Value.absent(),
    String? searchText,
    String? createdAt,
    String? metadataUpdatedAt,
    String? fileUpdatedAt,
    int? downloaded,
    String? fileType,
  }) => ScoresData(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    metadataUpdatedAt: metadataUpdatedAt ?? this.metadataUpdatedAt,
    fileUpdatedAt: fileUpdatedAt ?? this.fileUpdatedAt,
    downloaded: downloaded ?? this.downloaded,
    fileType: fileType ?? this.fileType,
  );
  ScoresData copyWithCompanion(ScoresCompanion data) {
    return ScoresData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
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
    return (StringBuffer('ScoresData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('searchText: $searchText, ')
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
    searchText,
    createdAt,
    metadataUpdatedAt,
    fileUpdatedAt,
    downloaded,
    fileType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoresData &&
          other.id == this.id &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.metadataUpdatedAt == this.metadataUpdatedAt &&
          other.fileUpdatedAt == this.fileUpdatedAt &&
          other.downloaded == this.downloaded &&
          other.fileType == this.fileType);
}

class ScoresCompanion extends UpdateCompanion<ScoresData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> composer;
  final Value<String> searchText;
  final Value<String> createdAt;
  final Value<String> metadataUpdatedAt;
  final Value<String> fileUpdatedAt;
  final Value<int> downloaded;
  final Value<String> fileType;
  final Value<int> rowid;
  const ScoresCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    this.downloaded = const Value.absent(),
    this.fileType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresCompanion.insert({
    required String id,
    required String title,
    this.composer = const Value.absent(),
    required String searchText,
    this.createdAt = const Value.absent(),
    this.metadataUpdatedAt = const Value.absent(),
    this.fileUpdatedAt = const Value.absent(),
    required int downloaded,
    required String fileType,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       searchText = Value(searchText),
       downloaded = Value(downloaded),
       fileType = Value(fileType);
  static Insertable<ScoresData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<String>? searchText,
    Expression<String>? createdAt,
    Expression<String>? metadataUpdatedAt,
    Expression<String>? fileUpdatedAt,
    Expression<int>? downloaded,
    Expression<String>? fileType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (metadataUpdatedAt != null) 'metadata_updated_at': metadataUpdatedAt,
      if (fileUpdatedAt != null) 'file_updated_at': fileUpdatedAt,
      if (downloaded != null) 'downloaded': downloaded,
      if (fileType != null) 'file_type': fileType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? composer,
    Value<String>? searchText,
    Value<String>? createdAt,
    Value<String>? metadataUpdatedAt,
    Value<String>? fileUpdatedAt,
    Value<int>? downloaded,
    Value<String>? fileType,
    Value<int>? rowid,
  }) {
    return ScoresCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      searchText: searchText ?? this.searchText,
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
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (metadataUpdatedAt.present) {
      map['metadata_updated_at'] = Variable<String>(metadataUpdatedAt.value);
    }
    if (fileUpdatedAt.present) {
      map['file_updated_at'] = Variable<String>(fileUpdatedAt.value);
    }
    if (downloaded.present) {
      map['downloaded'] = Variable<int>(downloaded.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('searchText: $searchText, ')
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

class Genres extends Table with TableInfo<Genres, GenresData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Genres(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES scores(id)ON UPDATE CASCADE ON DELETE CASCADE',
  );
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [score, genre];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'genres';
  @override
  Set<GeneratedColumn> get $primaryKey => {score, genre};
  @override
  GenresData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GenresData(
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
  Genres createAlias(String alias) {
    return Genres(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(score, genre)'];
  @override
  bool get dontWriteConstraints => true;
}

class GenresData extends DataClass implements Insertable<GenresData> {
  final String score;
  final String genre;
  const GenresData({required this.score, required this.genre});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['genre'] = Variable<String>(genre);
    return map;
  }

  GenresCompanion toCompanion(bool nullToAbsent) {
    return GenresCompanion(score: Value(score), genre: Value(genre));
  }

  factory GenresData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GenresData(
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

  GenresData copyWith({String? score, String? genre}) =>
      GenresData(score: score ?? this.score, genre: genre ?? this.genre);
  GenresData copyWithCompanion(GenresCompanion data) {
    return GenresData(
      score: data.score.present ? data.score.value : this.score,
      genre: data.genre.present ? data.genre.value : this.genre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GenresData(')
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
      (other is GenresData &&
          other.score == this.score &&
          other.genre == this.genre);
}

class GenresCompanion extends UpdateCompanion<GenresData> {
  final Value<String> score;
  final Value<String> genre;
  final Value<int> rowid;
  const GenresCompanion({
    this.score = const Value.absent(),
    this.genre = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenresCompanion.insert({
    required String score,
    required String genre,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       genre = Value(genre);
  static Insertable<GenresData> custom({
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

  GenresCompanion copyWith({
    Value<String>? score,
    Value<String>? genre,
    Value<int>? rowid,
  }) {
    return GenresCompanion(
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
    return (StringBuffer('GenresCompanion(')
          ..write('score: $score, ')
          ..write('genre: $genre, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Instruments extends Table with TableInfo<Instruments, InstrumentsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Instruments(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES scores(id)ON UPDATE CASCADE ON DELETE CASCADE',
  );
  late final GeneratedColumn<String> instrument = GeneratedColumn<String>(
    'instrument',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [score, instrument];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instruments';
  @override
  Set<GeneratedColumn> get $primaryKey => {score, instrument};
  @override
  InstrumentsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentsData(
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
  Instruments createAlias(String alias) {
    return Instruments(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(score, instrument)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class InstrumentsData extends DataClass implements Insertable<InstrumentsData> {
  final String score;
  final String instrument;
  const InstrumentsData({required this.score, required this.instrument});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['instrument'] = Variable<String>(instrument);
    return map;
  }

  InstrumentsCompanion toCompanion(bool nullToAbsent) {
    return InstrumentsCompanion(
      score: Value(score),
      instrument: Value(instrument),
    );
  }

  factory InstrumentsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentsData(
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

  InstrumentsData copyWith({String? score, String? instrument}) =>
      InstrumentsData(
        score: score ?? this.score,
        instrument: instrument ?? this.instrument,
      );
  InstrumentsData copyWithCompanion(InstrumentsCompanion data) {
    return InstrumentsData(
      score: data.score.present ? data.score.value : this.score,
      instrument: data.instrument.present
          ? data.instrument.value
          : this.instrument,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentsData(')
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
      (other is InstrumentsData &&
          other.score == this.score &&
          other.instrument == this.instrument);
}

class InstrumentsCompanion extends UpdateCompanion<InstrumentsData> {
  final Value<String> score;
  final Value<String> instrument;
  final Value<int> rowid;
  const InstrumentsCompanion({
    this.score = const Value.absent(),
    this.instrument = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentsCompanion.insert({
    required String score,
    required String instrument,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       instrument = Value(instrument);
  static Insertable<InstrumentsData> custom({
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

  InstrumentsCompanion copyWith({
    Value<String>? score,
    Value<String>? instrument,
    Value<int>? rowid,
  }) {
    return InstrumentsCompanion(
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
    return (StringBuffer('InstrumentsCompanion(')
          ..write('score: $score, ')
          ..write('instrument: $instrument, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Tags extends Table with TableInfo<Tags, TagsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Tags(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT CURRENT_TIMESTAMP',
    defaultValue: const CustomExpression('CURRENT_TIMESTAMP'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagsData(
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
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Tags createAlias(String alias) {
    return Tags(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class TagsData extends DataClass implements Insertable<TagsData> {
  final String id;
  final String name;
  final int color;
  final String updatedAt;
  const TagsData({
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
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      updatedAt: Value(updatedAt),
    );
  }

  factory TagsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagsData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TagsData copyWith({
    String? id,
    String? name,
    int? color,
    String? updatedAt,
  }) => TagsData(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TagsData copyWithCompanion(TagsCompanion data) {
    return TagsData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsData(')
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
      (other is TagsData &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<TagsData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color);
  static Insertable<TagsData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? updatedAt,
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

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
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
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScoreTags extends Table with TableInfo<ScoreTags, ScoreTagsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScoreTags(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> score = GeneratedColumn<String>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES scores(id)ON UPDATE CASCADE ON DELETE CASCADE',
  );
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES tags(id)ON UPDATE CASCADE ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [score, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'score_tags';
  @override
  Set<GeneratedColumn> get $primaryKey => {score, tag};
  @override
  ScoreTagsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreTagsData(
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
  ScoreTags createAlias(String alias) {
    return ScoreTags(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(score, tag)'];
  @override
  bool get dontWriteConstraints => true;
}

class ScoreTagsData extends DataClass implements Insertable<ScoreTagsData> {
  final String score;
  final String tag;
  const ScoreTagsData({required this.score, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['score'] = Variable<String>(score);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  ScoreTagsCompanion toCompanion(bool nullToAbsent) {
    return ScoreTagsCompanion(score: Value(score), tag: Value(tag));
  }

  factory ScoreTagsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreTagsData(
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

  ScoreTagsData copyWith({String? score, String? tag}) =>
      ScoreTagsData(score: score ?? this.score, tag: tag ?? this.tag);
  ScoreTagsData copyWithCompanion(ScoreTagsCompanion data) {
    return ScoreTagsData(
      score: data.score.present ? data.score.value : this.score,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreTagsData(')
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
      (other is ScoreTagsData &&
          other.score == this.score &&
          other.tag == this.tag);
}

class ScoreTagsCompanion extends UpdateCompanion<ScoreTagsData> {
  final Value<String> score;
  final Value<String> tag;
  final Value<int> rowid;
  const ScoreTagsCompanion({
    this.score = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoreTagsCompanion.insert({
    required String score,
    required String tag,
    this.rowid = const Value.absent(),
  }) : score = Value(score),
       tag = Value(tag);
  static Insertable<ScoreTagsData> custom({
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

  ScoreTagsCompanion copyWith({
    Value<String>? score,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return ScoreTagsCompanion(
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
    return (StringBuffer('ScoreTagsCompanion(')
          ..write('score: $score, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class KeyValue extends Table with TableInfo<KeyValue, KeyValueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  KeyValue(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueData(
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
  KeyValue createAlias(String alias) {
    return KeyValue(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY("key")'];
  @override
  bool get dontWriteConstraints => true;
}

class KeyValueData extends DataClass implements Insertable<KeyValueData> {
  final String key;
  final String value;
  const KeyValueData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValueCompanion toCompanion(bool nullToAbsent) {
    return KeyValueCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueData(
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

  KeyValueData copyWith({String? key, String? value}) =>
      KeyValueData(key: key ?? this.key, value: value ?? this.value);
  KeyValueData copyWithCompanion(KeyValueCompanion data) {
    return KeyValueData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueData(')
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
      (other is KeyValueData &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueCompanion extends UpdateCompanion<KeyValueData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValueCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValueData> custom({
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

  KeyValueCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return KeyValueCompanion(
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
    return (StringBuffer('KeyValueCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV2 extends GeneratedDatabase {
  DatabaseAtV2(QueryExecutor e) : super(e);
  late final Scores scores = Scores(this);
  late final Genres genres = Genres(this);
  late final Instruments instruments = Instruments(this);
  late final Tags tags = Tags(this);
  late final ScoreTags scoreTags = ScoreTags(this);
  late final KeyValue keyValue = KeyValue(this);
  late final Index searchTextIndex = Index(
    'search_text_index',
    'CREATE INDEX search_text_index ON scores (search_text)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scores,
    genres,
    instruments,
    tags,
    scoreTags,
    keyValue,
    searchTextIndex,
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
  int get schemaVersion => 2;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
