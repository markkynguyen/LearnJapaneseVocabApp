// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 50),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#6366F1'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: _nowSeconds);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, color, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(Insertable<Folder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final int id;
  final String name;
  final String? description;
  final String color;
  final int createdAt;
  const Folder(
      {required this.id,
      required this.name,
      this.description,
      required this.color,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color'] = Variable<String>(color);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<String>(json['color']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<String>(color),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Folder copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? color,
          int? createdAt}) =>
      Folder(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
      );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> color;
  final Value<int> createdAt;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FoldersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Folder> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? color,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FoldersCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? color,
      Value<int>? createdAt}) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VocabularyTable extends Vocabulary
    with TableInfo<$VocabularyTable, VocabularyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<int> folderId = GeneratedColumn<int>(
      'folder_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES folders (id) ON DELETE CASCADE'));
  static const VerificationMeta _kanjiMeta = const VerificationMeta('kanji');
  @override
  late final GeneratedColumn<String> kanji = GeneratedColumn<String>(
      'kanji', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kanaMeta = const VerificationMeta('kana');
  @override
  late final GeneratedColumn<String> kana =
      GeneratedColumn<String>('kana', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _romajiMeta = const VerificationMeta('romaji');
  @override
  late final GeneratedColumn<String> romaji =
      GeneratedColumn<String>('romaji', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _meaningMeta =
      const VerificationMeta('meaning');
  @override
  late final GeneratedColumn<String> meaning =
      GeneratedColumn<String>('meaning', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  static const VerificationMeta _pitchAccentMeta =
      const VerificationMeta('pitchAccent');
  @override
  late final GeneratedColumn<String> pitchAccent = GeneratedColumn<String>(
      'pitch_accent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exampleMeta =
      const VerificationMeta('example');
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
      'example', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      clientDefault: _nowSeconds);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        folderId,
        kanji,
        kana,
        romaji,
        meaning,
        pitchAccent,
        example,
        note,
        audioPath,
        isFavorite,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary';
  @override
  VerificationContext validateIntegrity(Insertable<VocabularyEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('kanji')) {
      context.handle(
          _kanjiMeta, kanji.isAcceptableOrUnknown(data['kanji']!, _kanjiMeta));
    }
    if (data.containsKey('kana')) {
      context.handle(
          _kanaMeta, kana.isAcceptableOrUnknown(data['kana']!, _kanaMeta));
    } else if (isInserting) {
      context.missing(_kanaMeta);
    }
    if (data.containsKey('romaji')) {
      context.handle(_romajiMeta,
          romaji.isAcceptableOrUnknown(data['romaji']!, _romajiMeta));
    } else if (isInserting) {
      context.missing(_romajiMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(_meaningMeta,
          meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta));
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('pitch_accent')) {
      context.handle(
          _pitchAccentMeta,
          pitchAccent.isAcceptableOrUnknown(
              data['pitch_accent']!, _pitchAccentMeta));
    }
    if (data.containsKey('example')) {
      context.handle(_exampleMeta,
          example.isAcceptableOrUnknown(data['example']!, _exampleMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}folder_id'])!,
      kanji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kanji']),
      kana: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kana'])!,
      romaji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}romaji'])!,
      meaning: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning'])!,
      pitchAccent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pitch_accent']),
      example: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VocabularyTable createAlias(String alias) {
    return $VocabularyTable(attachedDatabase, alias);
  }
}

class VocabularyEntry extends DataClass implements Insertable<VocabularyEntry> {
  final int id;
  final int folderId;
  final String? kanji;
  final String kana;
  final String romaji;
  final String meaning;
  final String? pitchAccent;
  final String? example;
  final String? note;
  final String? audioPath;
  final bool isFavorite;
  final int createdAt;
  const VocabularyEntry(
      {required this.id,
      required this.folderId,
      this.kanji,
      required this.kana,
      required this.romaji,
      required this.meaning,
      this.pitchAccent,
      this.example,
      this.note,
      this.audioPath,
      required this.isFavorite,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['folder_id'] = Variable<int>(folderId);
    if (!nullToAbsent || kanji != null) {
      map['kanji'] = Variable<String>(kanji);
    }
    map['kana'] = Variable<String>(kana);
    map['romaji'] = Variable<String>(romaji);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || pitchAccent != null) {
      map['pitch_accent'] = Variable<String>(pitchAccent);
    }
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || audioPath != null) {
      map['audio_path'] = Variable<String>(audioPath);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  VocabularyCompanion toCompanion(bool nullToAbsent) {
    return VocabularyCompanion(
      id: Value(id),
      folderId: Value(folderId),
      kanji:
          kanji == null && nullToAbsent ? const Value.absent() : Value(kanji),
      kana: Value(kana),
      romaji: Value(romaji),
      meaning: Value(meaning),
      pitchAccent: pitchAccent == null && nullToAbsent
          ? const Value.absent()
          : Value(pitchAccent),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      audioPath: audioPath == null && nullToAbsent
          ? const Value.absent()
          : Value(audioPath),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
    );
  }

  factory VocabularyEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyEntry(
      id: serializer.fromJson<int>(json['id']),
      folderId: serializer.fromJson<int>(json['folderId']),
      kanji: serializer.fromJson<String?>(json['kanji']),
      kana: serializer.fromJson<String>(json['kana']),
      romaji: serializer.fromJson<String>(json['romaji']),
      meaning: serializer.fromJson<String>(json['meaning']),
      pitchAccent: serializer.fromJson<String?>(json['pitchAccent']),
      example: serializer.fromJson<String?>(json['example']),
      note: serializer.fromJson<String?>(json['note']),
      audioPath: serializer.fromJson<String?>(json['audioPath']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'folderId': serializer.toJson<int>(folderId),
      'kanji': serializer.toJson<String?>(kanji),
      'kana': serializer.toJson<String>(kana),
      'romaji': serializer.toJson<String>(romaji),
      'meaning': serializer.toJson<String>(meaning),
      'pitchAccent': serializer.toJson<String?>(pitchAccent),
      'example': serializer.toJson<String?>(example),
      'note': serializer.toJson<String?>(note),
      'audioPath': serializer.toJson<String?>(audioPath),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  VocabularyEntry copyWith(
          {int? id,
          int? folderId,
          Value<String?> kanji = const Value.absent(),
          String? kana,
          String? romaji,
          String? meaning,
          Value<String?> pitchAccent = const Value.absent(),
          Value<String?> example = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> audioPath = const Value.absent(),
          bool? isFavorite,
          int? createdAt}) =>
      VocabularyEntry(
        id: id ?? this.id,
        folderId: folderId ?? this.folderId,
        kanji: kanji.present ? kanji.value : this.kanji,
        kana: kana ?? this.kana,
        romaji: romaji ?? this.romaji,
        meaning: meaning ?? this.meaning,
        pitchAccent: pitchAccent.present ? pitchAccent.value : this.pitchAccent,
        example: example.present ? example.value : this.example,
        note: note.present ? note.value : this.note,
        audioPath: audioPath.present ? audioPath.value : this.audioPath,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt ?? this.createdAt,
      );
  VocabularyEntry copyWithCompanion(VocabularyCompanion data) {
    return VocabularyEntry(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      kanji: data.kanji.present ? data.kanji.value : this.kanji,
      kana: data.kana.present ? data.kana.value : this.kana,
      romaji: data.romaji.present ? data.romaji.value : this.romaji,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      pitchAccent:
          data.pitchAccent.present ? data.pitchAccent.value : this.pitchAccent,
      example: data.example.present ? data.example.value : this.example,
      note: data.note.present ? data.note.value : this.note,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyEntry(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('kanji: $kanji, ')
          ..write('kana: $kana, ')
          ..write('romaji: $romaji, ')
          ..write('meaning: $meaning, ')
          ..write('pitchAccent: $pitchAccent, ')
          ..write('example: $example, ')
          ..write('note: $note, ')
          ..write('audioPath: $audioPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, folderId, kanji, kana, romaji, meaning,
      pitchAccent, example, note, audioPath, isFavorite, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyEntry &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.kanji == this.kanji &&
          other.kana == this.kana &&
          other.romaji == this.romaji &&
          other.meaning == this.meaning &&
          other.pitchAccent == this.pitchAccent &&
          other.example == this.example &&
          other.note == this.note &&
          other.audioPath == this.audioPath &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt);
}

class VocabularyCompanion extends UpdateCompanion<VocabularyEntry> {
  final Value<int> id;
  final Value<int> folderId;
  final Value<String?> kanji;
  final Value<String> kana;
  final Value<String> romaji;
  final Value<String> meaning;
  final Value<String?> pitchAccent;
  final Value<String?> example;
  final Value<String?> note;
  final Value<String?> audioPath;
  final Value<bool> isFavorite;
  final Value<int> createdAt;
  const VocabularyCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.kanji = const Value.absent(),
    this.kana = const Value.absent(),
    this.romaji = const Value.absent(),
    this.meaning = const Value.absent(),
    this.pitchAccent = const Value.absent(),
    this.example = const Value.absent(),
    this.note = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  VocabularyCompanion.insert({
    this.id = const Value.absent(),
    required int folderId,
    this.kanji = const Value.absent(),
    required String kana,
    required String romaji,
    required String meaning,
    this.pitchAccent = const Value.absent(),
    this.example = const Value.absent(),
    this.note = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : folderId = Value(folderId),
        kana = Value(kana),
        romaji = Value(romaji),
        meaning = Value(meaning);
  static Insertable<VocabularyEntry> custom({
    Expression<int>? id,
    Expression<int>? folderId,
    Expression<String>? kanji,
    Expression<String>? kana,
    Expression<String>? romaji,
    Expression<String>? meaning,
    Expression<String>? pitchAccent,
    Expression<String>? example,
    Expression<String>? note,
    Expression<String>? audioPath,
    Expression<bool>? isFavorite,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (kanji != null) 'kanji': kanji,
      if (kana != null) 'kana': kana,
      if (romaji != null) 'romaji': romaji,
      if (meaning != null) 'meaning': meaning,
      if (pitchAccent != null) 'pitch_accent': pitchAccent,
      if (example != null) 'example': example,
      if (note != null) 'note': note,
      if (audioPath != null) 'audio_path': audioPath,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  VocabularyCompanion copyWith(
      {Value<int>? id,
      Value<int>? folderId,
      Value<String?>? kanji,
      Value<String>? kana,
      Value<String>? romaji,
      Value<String>? meaning,
      Value<String?>? pitchAccent,
      Value<String?>? example,
      Value<String?>? note,
      Value<String?>? audioPath,
      Value<bool>? isFavorite,
      Value<int>? createdAt}) {
    return VocabularyCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      kanji: kanji ?? this.kanji,
      kana: kana ?? this.kana,
      romaji: romaji ?? this.romaji,
      meaning: meaning ?? this.meaning,
      pitchAccent: pitchAccent ?? this.pitchAccent,
      example: example ?? this.example,
      note: note ?? this.note,
      audioPath: audioPath ?? this.audioPath,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<int>(folderId.value);
    }
    if (kanji.present) {
      map['kanji'] = Variable<String>(kanji.value);
    }
    if (kana.present) {
      map['kana'] = Variable<String>(kana.value);
    }
    if (romaji.present) {
      map['romaji'] = Variable<String>(romaji.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (pitchAccent.present) {
      map['pitch_accent'] = Variable<String>(pitchAccent.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('kanji: $kanji, ')
          ..write('kana: $kana, ')
          ..write('romaji: $romaji, ')
          ..write('meaning: $meaning, ')
          ..write('pitchAccent: $pitchAccent, ')
          ..write('example: $example, ')
          ..write('note: $note, ')
          ..write('audioPath: $audioPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SrsProgressTable extends SrsProgress
    with TableInfo<$SrsProgressTable, SrsProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _vocabIdMeta =
      const VerificationMeta('vocabId');
  @override
  late final GeneratedColumn<int> vocabId = GeneratedColumn<int>(
      'vocab_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES vocabulary (id) ON DELETE CASCADE'));
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
      'level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _intervalDaysMeta =
      const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
      'interval_days', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextReviewAtMeta =
      const VerificationMeta('nextReviewAt');
  @override
  late final GeneratedColumn<int> nextReviewAt = GeneratedColumn<int>(
      'next_review_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wrongCountMeta =
      const VerificationMeta('wrongCount');
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
      'wrong_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<int> lastReviewedAt = GeneratedColumn<int>(
      'last_reviewed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vocabId,
        level,
        intervalDays,
        nextReviewAt,
        correctCount,
        wrongCount,
        lastReviewedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_progress';
  @override
  VerificationContext validateIntegrity(Insertable<SrsProgressEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vocab_id')) {
      context.handle(_vocabIdMeta,
          vocabId.isAcceptableOrUnknown(data['vocab_id']!, _vocabIdMeta));
    } else if (isInserting) {
      context.missing(_vocabIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(
          _intervalDaysMeta,
          intervalDays.isAcceptableOrUnknown(
              data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
          _nextReviewAtMeta,
          nextReviewAt.isAcceptableOrUnknown(
              data['next_review_at']!, _nextReviewAtMeta));
    } else if (isInserting) {
      context.missing(_nextReviewAtMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
          _wrongCountMeta,
          wrongCount.isAcceptableOrUnknown(
              data['wrong_count']!, _wrongCountMeta));
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {vocabId},
      ];
  @override
  SrsProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsProgressEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      vocabId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}vocab_id'])!,
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}level'])!,
      intervalDays: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}interval_days'])!,
      nextReviewAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_review_at'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      wrongCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wrong_count'])!,
      lastReviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_reviewed_at']),
    );
  }

  @override
  $SrsProgressTable createAlias(String alias) {
    return $SrsProgressTable(attachedDatabase, alias);
  }
}

class SrsProgressEntry extends DataClass
    implements Insertable<SrsProgressEntry> {
  final int id;
  final int vocabId;
  final int level;
  final double intervalDays;
  final int nextReviewAt;
  final int correctCount;
  final int wrongCount;
  final int? lastReviewedAt;
  const SrsProgressEntry(
      {required this.id,
      required this.vocabId,
      required this.level,
      required this.intervalDays,
      required this.nextReviewAt,
      required this.correctCount,
      required this.wrongCount,
      this.lastReviewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vocab_id'] = Variable<int>(vocabId);
    map['level'] = Variable<int>(level);
    map['interval_days'] = Variable<double>(intervalDays);
    map['next_review_at'] = Variable<int>(nextReviewAt);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt);
    }
    return map;
  }

  SrsProgressCompanion toCompanion(bool nullToAbsent) {
    return SrsProgressCompanion(
      id: Value(id),
      vocabId: Value(vocabId),
      level: Value(level),
      intervalDays: Value(intervalDays),
      nextReviewAt: Value(nextReviewAt),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
    );
  }

  factory SrsProgressEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsProgressEntry(
      id: serializer.fromJson<int>(json['id']),
      vocabId: serializer.fromJson<int>(json['vocabId']),
      level: serializer.fromJson<int>(json['level']),
      intervalDays: serializer.fromJson<double>(json['intervalDays']),
      nextReviewAt: serializer.fromJson<int>(json['nextReviewAt']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      lastReviewedAt: serializer.fromJson<int?>(json['lastReviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vocabId': serializer.toJson<int>(vocabId),
      'level': serializer.toJson<int>(level),
      'intervalDays': serializer.toJson<double>(intervalDays),
      'nextReviewAt': serializer.toJson<int>(nextReviewAt),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'lastReviewedAt': serializer.toJson<int?>(lastReviewedAt),
    };
  }

  SrsProgressEntry copyWith(
          {int? id,
          int? vocabId,
          int? level,
          double? intervalDays,
          int? nextReviewAt,
          int? correctCount,
          int? wrongCount,
          Value<int?> lastReviewedAt = const Value.absent()}) =>
      SrsProgressEntry(
        id: id ?? this.id,
        vocabId: vocabId ?? this.vocabId,
        level: level ?? this.level,
        intervalDays: intervalDays ?? this.intervalDays,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
      );
  SrsProgressEntry copyWithCompanion(SrsProgressCompanion data) {
    return SrsProgressEntry(
      id: data.id.present ? data.id.value : this.id,
      vocabId: data.vocabId.present ? data.vocabId.value : this.vocabId,
      level: data.level.present ? data.level.value : this.level,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount:
          data.wrongCount.present ? data.wrongCount.value : this.wrongCount,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsProgressEntry(')
          ..write('id: $id, ')
          ..write('vocabId: $vocabId, ')
          ..write('level: $level, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vocabId, level, intervalDays,
      nextReviewAt, correctCount, wrongCount, lastReviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsProgressEntry &&
          other.id == this.id &&
          other.vocabId == this.vocabId &&
          other.level == this.level &&
          other.intervalDays == this.intervalDays &&
          other.nextReviewAt == this.nextReviewAt &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.lastReviewedAt == this.lastReviewedAt);
}

class SrsProgressCompanion extends UpdateCompanion<SrsProgressEntry> {
  final Value<int> id;
  final Value<int> vocabId;
  final Value<int> level;
  final Value<double> intervalDays;
  final Value<int> nextReviewAt;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<int?> lastReviewedAt;
  const SrsProgressCompanion({
    this.id = const Value.absent(),
    this.vocabId = const Value.absent(),
    this.level = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  });
  SrsProgressCompanion.insert({
    this.id = const Value.absent(),
    required int vocabId,
    this.level = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required int nextReviewAt,
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
  })  : vocabId = Value(vocabId),
        nextReviewAt = Value(nextReviewAt);
  static Insertable<SrsProgressEntry> custom({
    Expression<int>? id,
    Expression<int>? vocabId,
    Expression<int>? level,
    Expression<double>? intervalDays,
    Expression<int>? nextReviewAt,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<int>? lastReviewedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vocabId != null) 'vocab_id': vocabId,
      if (level != null) 'level': level,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
    });
  }

  SrsProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? vocabId,
      Value<int>? level,
      Value<double>? intervalDays,
      Value<int>? nextReviewAt,
      Value<int>? correctCount,
      Value<int>? wrongCount,
      Value<int?>? lastReviewedAt}) {
    return SrsProgressCompanion(
      id: id ?? this.id,
      vocabId: vocabId ?? this.vocabId,
      level: level ?? this.level,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vocabId.present) {
      map['vocab_id'] = Variable<int>(vocabId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<int>(nextReviewAt.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<int>(lastReviewedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsProgressCompanion(')
          ..write('id: $id, ')
          ..write('vocabId: $vocabId, ')
          ..write('level: $level, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewedAt: $lastReviewedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, AppSettings> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _notifyEnabledMeta =
      const VerificationMeta('notifyEnabled');
  @override
  late final GeneratedColumn<bool> notifyEnabled = GeneratedColumn<bool>(
      'notify_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notify_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _notifyHourMeta =
      const VerificationMeta('notifyHour');
  @override
  late final GeneratedColumn<int> notifyHour = GeneratedColumn<int>(
      'notify_hour', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(8));
  static const VerificationMeta _notifyMinuteMeta =
      const VerificationMeta('notifyMinute');
  @override
  late final GeneratedColumn<int> notifyMinute = GeneratedColumn<int>(
      'notify_minute', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sessionSizeMeta =
      const VerificationMeta('sessionSize');
  @override
  late final GeneratedColumn<int> sessionSize = GeneratedColumn<int>(
      'session_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _quizDirectionMeta =
      const VerificationMeta('quizDirection');
  @override
  late final GeneratedColumn<String> quizDirection = GeneratedColumn<String>(
      'quiz_direction', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ja_to_vi'));
  static const VerificationMeta _quizListenCountMeta =
      const VerificationMeta('quizListenCount');
  @override
  late final GeneratedColumn<int> quizListenCount = GeneratedColumn<int>(
      'quiz_listen_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quizReadCountMeta =
      const VerificationMeta('quizReadCount');
  @override
  late final GeneratedColumn<int> quizReadCount = GeneratedColumn<int>(
      'quiz_read_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quizWriteCountMeta =
      const VerificationMeta('quizWriteCount');
  @override
  late final GeneratedColumn<int> quizWriteCount = GeneratedColumn<int>(
      'quiz_write_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quizChooseWordCountMeta =
      const VerificationMeta('quizChooseWordCount');
  @override
  late final GeneratedColumn<int> quizChooseWordCount = GeneratedColumn<int>(
      'quiz_choose_word_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quizChooseMeaningCountMeta =
      const VerificationMeta('quizChooseMeaningCount');
  @override
  late final GeneratedColumn<int> quizChooseMeaningCount = GeneratedColumn<int>(
      'quiz_choose_meaning_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _quizRetryLimitMeta =
      const VerificationMeta('quizRetryLimit');
  @override
  late final GeneratedColumn<int> quizRetryLimit = GeneratedColumn<int>(
      'quiz_retry_limit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _newWordSessionSizeMeta =
      const VerificationMeta('newWordSessionSize');
  @override
  late final GeneratedColumn<int> newWordSessionSize = GeneratedColumn<int>(
      'new_word_session_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _newWordListenCountMeta =
      const VerificationMeta('newWordListenCount');
  @override
  late final GeneratedColumn<int> newWordListenCount = GeneratedColumn<int>(
      'new_word_listen_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _newWordWriteCountMeta =
      const VerificationMeta('newWordWriteCount');
  @override
  late final GeneratedColumn<int> newWordWriteCount = GeneratedColumn<int>(
      'new_word_write_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _newWordChooseWordCountMeta =
      const VerificationMeta('newWordChooseWordCount');
  @override
  late final GeneratedColumn<int> newWordChooseWordCount = GeneratedColumn<int>(
      'new_word_choose_word_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _newWordChooseMeaningCountMeta =
      const VerificationMeta('newWordChooseMeaningCount');
  @override
  late final GeneratedColumn<int> newWordChooseMeaningCount =
      GeneratedColumn<int>('new_word_choose_meaning_count', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  static const VerificationMeta _quizJapaneseScriptMeta =
      const VerificationMeta('quizJapaneseScript');
  @override
  late final GeneratedColumn<String> quizJapaneseScript =
      GeneratedColumn<String>('quiz_japanese_script', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('kanji'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('light'));
  static const VerificationMeta _srsLevel1IntervalDaysMeta =
      const VerificationMeta('srsLevel1IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel1IntervalDays =
      GeneratedColumn<double>('srs_level1_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(2 / 24));
  static const VerificationMeta _srsLevel2IntervalDaysMeta =
      const VerificationMeta('srsLevel2IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel2IntervalDays =
      GeneratedColumn<double>('srs_level2_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1.0));
  static const VerificationMeta _srsLevel3IntervalDaysMeta =
      const VerificationMeta('srsLevel3IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel3IntervalDays =
      GeneratedColumn<double>('srs_level3_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(2.0));
  static const VerificationMeta _srsLevel4IntervalDaysMeta =
      const VerificationMeta('srsLevel4IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel4IntervalDays =
      GeneratedColumn<double>('srs_level4_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(3.0));
  static const VerificationMeta _srsLevel5IntervalDaysMeta =
      const VerificationMeta('srsLevel5IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel5IntervalDays =
      GeneratedColumn<double>('srs_level5_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(5.0));
  static const VerificationMeta _srsLevel6IntervalDaysMeta =
      const VerificationMeta('srsLevel6IntervalDays');
  @override
  late final GeneratedColumn<double> srsLevel6IntervalDays =
      GeneratedColumn<double>('srs_level6_interval_days', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(8.0));
  static const VerificationMeta _flashcardShowKanaMeta =
      const VerificationMeta('flashcardShowKana');
  @override
  late final GeneratedColumn<bool> flashcardShowKana = GeneratedColumn<bool>(
      'flashcard_show_kana', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("flashcard_show_kana" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _flashcardShowRomajiMeta =
      const VerificationMeta('flashcardShowRomaji');
  @override
  late final GeneratedColumn<bool> flashcardShowRomaji = GeneratedColumn<bool>(
      'flashcard_show_romaji', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("flashcard_show_romaji" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _defaultKanaSeededMeta =
      const VerificationMeta('defaultKanaSeeded');
  @override
  late final GeneratedColumn<bool> defaultKanaSeeded = GeneratedColumn<bool>(
      'default_kana_seeded', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("default_kana_seeded" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        notifyEnabled,
        notifyHour,
        notifyMinute,
        sessionSize,
        quizDirection,
        quizListenCount,
        quizReadCount,
        quizWriteCount,
        quizChooseWordCount,
        quizChooseMeaningCount,
        quizRetryLimit,
        newWordSessionSize,
        newWordListenCount,
        newWordWriteCount,
        newWordChooseWordCount,
        newWordChooseMeaningCount,
        quizJapaneseScript,
        themeMode,
        srsLevel1IntervalDays,
        srsLevel2IntervalDays,
        srsLevel3IntervalDays,
        srsLevel4IntervalDays,
        srsLevel5IntervalDays,
        srsLevel6IntervalDays,
        flashcardShowKana,
        flashcardShowRomaji,
        defaultKanaSeeded
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSettings> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notify_enabled')) {
      context.handle(
          _notifyEnabledMeta,
          notifyEnabled.isAcceptableOrUnknown(
              data['notify_enabled']!, _notifyEnabledMeta));
    }
    if (data.containsKey('notify_hour')) {
      context.handle(
          _notifyHourMeta,
          notifyHour.isAcceptableOrUnknown(
              data['notify_hour']!, _notifyHourMeta));
    }
    if (data.containsKey('notify_minute')) {
      context.handle(
          _notifyMinuteMeta,
          notifyMinute.isAcceptableOrUnknown(
              data['notify_minute']!, _notifyMinuteMeta));
    }
    if (data.containsKey('session_size')) {
      context.handle(
          _sessionSizeMeta,
          sessionSize.isAcceptableOrUnknown(
              data['session_size']!, _sessionSizeMeta));
    }
    if (data.containsKey('quiz_direction')) {
      context.handle(
          _quizDirectionMeta,
          quizDirection.isAcceptableOrUnknown(
              data['quiz_direction']!, _quizDirectionMeta));
    }
    if (data.containsKey('quiz_listen_count')) {
      context.handle(
          _quizListenCountMeta,
          quizListenCount.isAcceptableOrUnknown(
              data['quiz_listen_count']!, _quizListenCountMeta));
    }
    if (data.containsKey('quiz_read_count')) {
      context.handle(
          _quizReadCountMeta,
          quizReadCount.isAcceptableOrUnknown(
              data['quiz_read_count']!, _quizReadCountMeta));
    }
    if (data.containsKey('quiz_write_count')) {
      context.handle(
          _quizWriteCountMeta,
          quizWriteCount.isAcceptableOrUnknown(
              data['quiz_write_count']!, _quizWriteCountMeta));
    }
    if (data.containsKey('quiz_choose_word_count')) {
      context.handle(
          _quizChooseWordCountMeta,
          quizChooseWordCount.isAcceptableOrUnknown(
              data['quiz_choose_word_count']!, _quizChooseWordCountMeta));
    }
    if (data.containsKey('quiz_choose_meaning_count')) {
      context.handle(
          _quizChooseMeaningCountMeta,
          quizChooseMeaningCount.isAcceptableOrUnknown(
              data['quiz_choose_meaning_count']!, _quizChooseMeaningCountMeta));
    }
    if (data.containsKey('quiz_retry_limit')) {
      context.handle(
          _quizRetryLimitMeta,
          quizRetryLimit.isAcceptableOrUnknown(
              data['quiz_retry_limit']!, _quizRetryLimitMeta));
    }
    if (data.containsKey('new_word_session_size')) {
      context.handle(
          _newWordSessionSizeMeta,
          newWordSessionSize.isAcceptableOrUnknown(
              data['new_word_session_size']!, _newWordSessionSizeMeta));
    }
    if (data.containsKey('new_word_listen_count')) {
      context.handle(
          _newWordListenCountMeta,
          newWordListenCount.isAcceptableOrUnknown(
              data['new_word_listen_count']!, _newWordListenCountMeta));
    }
    if (data.containsKey('new_word_write_count')) {
      context.handle(
          _newWordWriteCountMeta,
          newWordWriteCount.isAcceptableOrUnknown(
              data['new_word_write_count']!, _newWordWriteCountMeta));
    }
    if (data.containsKey('new_word_choose_word_count')) {
      context.handle(
          _newWordChooseWordCountMeta,
          newWordChooseWordCount.isAcceptableOrUnknown(
              data['new_word_choose_word_count']!,
              _newWordChooseWordCountMeta));
    }
    if (data.containsKey('new_word_choose_meaning_count')) {
      context.handle(
          _newWordChooseMeaningCountMeta,
          newWordChooseMeaningCount.isAcceptableOrUnknown(
              data['new_word_choose_meaning_count']!,
              _newWordChooseMeaningCountMeta));
    }
    if (data.containsKey('quiz_japanese_script')) {
      context.handle(
          _quizJapaneseScriptMeta,
          quizJapaneseScript.isAcceptableOrUnknown(
              data['quiz_japanese_script']!, _quizJapaneseScriptMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('srs_level1_interval_days')) {
      context.handle(
          _srsLevel1IntervalDaysMeta,
          srsLevel1IntervalDays.isAcceptableOrUnknown(
              data['srs_level1_interval_days']!, _srsLevel1IntervalDaysMeta));
    }
    if (data.containsKey('srs_level2_interval_days')) {
      context.handle(
          _srsLevel2IntervalDaysMeta,
          srsLevel2IntervalDays.isAcceptableOrUnknown(
              data['srs_level2_interval_days']!, _srsLevel2IntervalDaysMeta));
    }
    if (data.containsKey('srs_level3_interval_days')) {
      context.handle(
          _srsLevel3IntervalDaysMeta,
          srsLevel3IntervalDays.isAcceptableOrUnknown(
              data['srs_level3_interval_days']!, _srsLevel3IntervalDaysMeta));
    }
    if (data.containsKey('srs_level4_interval_days')) {
      context.handle(
          _srsLevel4IntervalDaysMeta,
          srsLevel4IntervalDays.isAcceptableOrUnknown(
              data['srs_level4_interval_days']!, _srsLevel4IntervalDaysMeta));
    }
    if (data.containsKey('srs_level5_interval_days')) {
      context.handle(
          _srsLevel5IntervalDaysMeta,
          srsLevel5IntervalDays.isAcceptableOrUnknown(
              data['srs_level5_interval_days']!, _srsLevel5IntervalDaysMeta));
    }
    if (data.containsKey('srs_level6_interval_days')) {
      context.handle(
          _srsLevel6IntervalDaysMeta,
          srsLevel6IntervalDays.isAcceptableOrUnknown(
              data['srs_level6_interval_days']!, _srsLevel6IntervalDaysMeta));
    }
    if (data.containsKey('flashcard_show_kana')) {
      context.handle(
          _flashcardShowKanaMeta,
          flashcardShowKana.isAcceptableOrUnknown(
              data['flashcard_show_kana']!, _flashcardShowKanaMeta));
    }
    if (data.containsKey('flashcard_show_romaji')) {
      context.handle(
          _flashcardShowRomajiMeta,
          flashcardShowRomaji.isAcceptableOrUnknown(
              data['flashcard_show_romaji']!, _flashcardShowRomajiMeta));
    }
    if (data.containsKey('default_kana_seeded')) {
      context.handle(
          _defaultKanaSeededMeta,
          defaultKanaSeeded.isAcceptableOrUnknown(
              data['default_kana_seeded']!, _defaultKanaSeededMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettings map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettings(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notifyEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}notify_enabled'])!,
      notifyHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_hour'])!,
      notifyMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_minute'])!,
      sessionSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}session_size'])!,
      quizDirection: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quiz_direction'])!,
      quizListenCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_listen_count'])!,
      quizReadCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_read_count'])!,
      quizWriteCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_write_count'])!,
      quizChooseWordCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}quiz_choose_word_count'])!,
      quizChooseMeaningCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}quiz_choose_meaning_count'])!,
      quizRetryLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_retry_limit'])!,
      newWordSessionSize: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}new_word_session_size'])!,
      newWordListenCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}new_word_listen_count'])!,
      newWordWriteCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}new_word_write_count'])!,
      newWordChooseWordCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}new_word_choose_word_count'])!,
      newWordChooseMeaningCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}new_word_choose_meaning_count'])!,
      quizJapaneseScript: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}quiz_japanese_script'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      srsLevel1IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level1_interval_days'])!,
      srsLevel2IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level2_interval_days'])!,
      srsLevel3IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level3_interval_days'])!,
      srsLevel4IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level4_interval_days'])!,
      srsLevel5IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level5_interval_days'])!,
      srsLevel6IntervalDays: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}srs_level6_interval_days'])!,
      flashcardShowKana: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}flashcard_show_kana'])!,
      flashcardShowRomaji: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}flashcard_show_romaji'])!,
      defaultKanaSeeded: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}default_kana_seeded'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class AppSettings extends DataClass implements Insertable<AppSettings> {
  final int id;
  final bool notifyEnabled;
  final int notifyHour;
  final int notifyMinute;
  final int sessionSize;
  final String quizDirection;
  final int quizListenCount;
  final int quizReadCount;
  final int quizWriteCount;
  final int quizChooseWordCount;
  final int quizChooseMeaningCount;
  final int quizRetryLimit;
  final int newWordSessionSize;
  final int newWordListenCount;
  final int newWordWriteCount;
  final int newWordChooseWordCount;
  final int newWordChooseMeaningCount;
  final String quizJapaneseScript;
  final String themeMode;
  final double srsLevel1IntervalDays;
  final double srsLevel2IntervalDays;
  final double srsLevel3IntervalDays;
  final double srsLevel4IntervalDays;
  final double srsLevel5IntervalDays;
  final double srsLevel6IntervalDays;
  final bool flashcardShowKana;
  final bool flashcardShowRomaji;
  final bool defaultKanaSeeded;
  const AppSettings(
      {required this.id,
      required this.notifyEnabled,
      required this.notifyHour,
      required this.notifyMinute,
      required this.sessionSize,
      required this.quizDirection,
      required this.quizListenCount,
      required this.quizReadCount,
      required this.quizWriteCount,
      required this.quizChooseWordCount,
      required this.quizChooseMeaningCount,
      required this.quizRetryLimit,
      required this.newWordSessionSize,
      required this.newWordListenCount,
      required this.newWordWriteCount,
      required this.newWordChooseWordCount,
      required this.newWordChooseMeaningCount,
      required this.quizJapaneseScript,
      required this.themeMode,
      required this.srsLevel1IntervalDays,
      required this.srsLevel2IntervalDays,
      required this.srsLevel3IntervalDays,
      required this.srsLevel4IntervalDays,
      required this.srsLevel5IntervalDays,
      required this.srsLevel6IntervalDays,
      required this.flashcardShowKana,
      required this.flashcardShowRomaji,
      required this.defaultKanaSeeded});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notify_enabled'] = Variable<bool>(notifyEnabled);
    map['notify_hour'] = Variable<int>(notifyHour);
    map['notify_minute'] = Variable<int>(notifyMinute);
    map['session_size'] = Variable<int>(sessionSize);
    map['quiz_direction'] = Variable<String>(quizDirection);
    map['quiz_listen_count'] = Variable<int>(quizListenCount);
    map['quiz_read_count'] = Variable<int>(quizReadCount);
    map['quiz_write_count'] = Variable<int>(quizWriteCount);
    map['quiz_choose_word_count'] = Variable<int>(quizChooseWordCount);
    map['quiz_choose_meaning_count'] = Variable<int>(quizChooseMeaningCount);
    map['quiz_retry_limit'] = Variable<int>(quizRetryLimit);
    map['new_word_session_size'] = Variable<int>(newWordSessionSize);
    map['new_word_listen_count'] = Variable<int>(newWordListenCount);
    map['new_word_write_count'] = Variable<int>(newWordWriteCount);
    map['new_word_choose_word_count'] = Variable<int>(newWordChooseWordCount);
    map['new_word_choose_meaning_count'] =
        Variable<int>(newWordChooseMeaningCount);
    map['quiz_japanese_script'] = Variable<String>(quizJapaneseScript);
    map['theme_mode'] = Variable<String>(themeMode);
    map['srs_level1_interval_days'] = Variable<double>(srsLevel1IntervalDays);
    map['srs_level2_interval_days'] = Variable<double>(srsLevel2IntervalDays);
    map['srs_level3_interval_days'] = Variable<double>(srsLevel3IntervalDays);
    map['srs_level4_interval_days'] = Variable<double>(srsLevel4IntervalDays);
    map['srs_level5_interval_days'] = Variable<double>(srsLevel5IntervalDays);
    map['srs_level6_interval_days'] = Variable<double>(srsLevel6IntervalDays);
    map['flashcard_show_kana'] = Variable<bool>(flashcardShowKana);
    map['flashcard_show_romaji'] = Variable<bool>(flashcardShowRomaji);
    map['default_kana_seeded'] = Variable<bool>(defaultKanaSeeded);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      notifyEnabled: Value(notifyEnabled),
      notifyHour: Value(notifyHour),
      notifyMinute: Value(notifyMinute),
      sessionSize: Value(sessionSize),
      quizDirection: Value(quizDirection),
      quizListenCount: Value(quizListenCount),
      quizReadCount: Value(quizReadCount),
      quizWriteCount: Value(quizWriteCount),
      quizChooseWordCount: Value(quizChooseWordCount),
      quizChooseMeaningCount: Value(quizChooseMeaningCount),
      quizRetryLimit: Value(quizRetryLimit),
      newWordSessionSize: Value(newWordSessionSize),
      newWordListenCount: Value(newWordListenCount),
      newWordWriteCount: Value(newWordWriteCount),
      newWordChooseWordCount: Value(newWordChooseWordCount),
      newWordChooseMeaningCount: Value(newWordChooseMeaningCount),
      quizJapaneseScript: Value(quizJapaneseScript),
      themeMode: Value(themeMode),
      srsLevel1IntervalDays: Value(srsLevel1IntervalDays),
      srsLevel2IntervalDays: Value(srsLevel2IntervalDays),
      srsLevel3IntervalDays: Value(srsLevel3IntervalDays),
      srsLevel4IntervalDays: Value(srsLevel4IntervalDays),
      srsLevel5IntervalDays: Value(srsLevel5IntervalDays),
      srsLevel6IntervalDays: Value(srsLevel6IntervalDays),
      flashcardShowKana: Value(flashcardShowKana),
      flashcardShowRomaji: Value(flashcardShowRomaji),
      defaultKanaSeeded: Value(defaultKanaSeeded),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettings(
      id: serializer.fromJson<int>(json['id']),
      notifyEnabled: serializer.fromJson<bool>(json['notifyEnabled']),
      notifyHour: serializer.fromJson<int>(json['notifyHour']),
      notifyMinute: serializer.fromJson<int>(json['notifyMinute']),
      sessionSize: serializer.fromJson<int>(json['sessionSize']),
      quizDirection: serializer.fromJson<String>(json['quizDirection']),
      quizListenCount: serializer.fromJson<int>(json['quizListenCount']),
      quizReadCount: serializer.fromJson<int>(json['quizReadCount']),
      quizWriteCount: serializer.fromJson<int>(json['quizWriteCount']),
      quizChooseWordCount:
          serializer.fromJson<int>(json['quizChooseWordCount']),
      quizChooseMeaningCount:
          serializer.fromJson<int>(json['quizChooseMeaningCount']),
      quizRetryLimit: serializer.fromJson<int>(json['quizRetryLimit']),
      newWordSessionSize: serializer.fromJson<int>(json['newWordSessionSize']),
      newWordListenCount: serializer.fromJson<int>(json['newWordListenCount']),
      newWordWriteCount: serializer.fromJson<int>(json['newWordWriteCount']),
      newWordChooseWordCount:
          serializer.fromJson<int>(json['newWordChooseWordCount']),
      newWordChooseMeaningCount:
          serializer.fromJson<int>(json['newWordChooseMeaningCount']),
      quizJapaneseScript:
          serializer.fromJson<String>(json['quizJapaneseScript']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      srsLevel1IntervalDays:
          serializer.fromJson<double>(json['srsLevel1IntervalDays']),
      srsLevel2IntervalDays:
          serializer.fromJson<double>(json['srsLevel2IntervalDays']),
      srsLevel3IntervalDays:
          serializer.fromJson<double>(json['srsLevel3IntervalDays']),
      srsLevel4IntervalDays:
          serializer.fromJson<double>(json['srsLevel4IntervalDays']),
      srsLevel5IntervalDays:
          serializer.fromJson<double>(json['srsLevel5IntervalDays']),
      srsLevel6IntervalDays:
          serializer.fromJson<double>(json['srsLevel6IntervalDays']),
      flashcardShowKana: serializer.fromJson<bool>(json['flashcardShowKana']),
      flashcardShowRomaji:
          serializer.fromJson<bool>(json['flashcardShowRomaji']),
      defaultKanaSeeded: serializer.fromJson<bool>(json['defaultKanaSeeded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notifyEnabled': serializer.toJson<bool>(notifyEnabled),
      'notifyHour': serializer.toJson<int>(notifyHour),
      'notifyMinute': serializer.toJson<int>(notifyMinute),
      'sessionSize': serializer.toJson<int>(sessionSize),
      'quizDirection': serializer.toJson<String>(quizDirection),
      'quizListenCount': serializer.toJson<int>(quizListenCount),
      'quizReadCount': serializer.toJson<int>(quizReadCount),
      'quizWriteCount': serializer.toJson<int>(quizWriteCount),
      'quizChooseWordCount': serializer.toJson<int>(quizChooseWordCount),
      'quizChooseMeaningCount': serializer.toJson<int>(quizChooseMeaningCount),
      'quizRetryLimit': serializer.toJson<int>(quizRetryLimit),
      'newWordSessionSize': serializer.toJson<int>(newWordSessionSize),
      'newWordListenCount': serializer.toJson<int>(newWordListenCount),
      'newWordWriteCount': serializer.toJson<int>(newWordWriteCount),
      'newWordChooseWordCount': serializer.toJson<int>(newWordChooseWordCount),
      'newWordChooseMeaningCount':
          serializer.toJson<int>(newWordChooseMeaningCount),
      'quizJapaneseScript': serializer.toJson<String>(quizJapaneseScript),
      'themeMode': serializer.toJson<String>(themeMode),
      'srsLevel1IntervalDays': serializer.toJson<double>(srsLevel1IntervalDays),
      'srsLevel2IntervalDays': serializer.toJson<double>(srsLevel2IntervalDays),
      'srsLevel3IntervalDays': serializer.toJson<double>(srsLevel3IntervalDays),
      'srsLevel4IntervalDays': serializer.toJson<double>(srsLevel4IntervalDays),
      'srsLevel5IntervalDays': serializer.toJson<double>(srsLevel5IntervalDays),
      'srsLevel6IntervalDays': serializer.toJson<double>(srsLevel6IntervalDays),
      'flashcardShowKana': serializer.toJson<bool>(flashcardShowKana),
      'flashcardShowRomaji': serializer.toJson<bool>(flashcardShowRomaji),
      'defaultKanaSeeded': serializer.toJson<bool>(defaultKanaSeeded),
    };
  }

  AppSettings copyWith(
          {int? id,
          bool? notifyEnabled,
          int? notifyHour,
          int? notifyMinute,
          int? sessionSize,
          String? quizDirection,
          int? quizListenCount,
          int? quizReadCount,
          int? quizWriteCount,
          int? quizChooseWordCount,
          int? quizChooseMeaningCount,
          int? quizRetryLimit,
          int? newWordSessionSize,
          int? newWordListenCount,
          int? newWordWriteCount,
          int? newWordChooseWordCount,
          int? newWordChooseMeaningCount,
          String? quizJapaneseScript,
          String? themeMode,
          double? srsLevel1IntervalDays,
          double? srsLevel2IntervalDays,
          double? srsLevel3IntervalDays,
          double? srsLevel4IntervalDays,
          double? srsLevel5IntervalDays,
          double? srsLevel6IntervalDays,
          bool? flashcardShowKana,
          bool? flashcardShowRomaji,
          bool? defaultKanaSeeded}) =>
      AppSettings(
        id: id ?? this.id,
        notifyEnabled: notifyEnabled ?? this.notifyEnabled,
        notifyHour: notifyHour ?? this.notifyHour,
        notifyMinute: notifyMinute ?? this.notifyMinute,
        sessionSize: sessionSize ?? this.sessionSize,
        quizDirection: quizDirection ?? this.quizDirection,
        quizListenCount: quizListenCount ?? this.quizListenCount,
        quizReadCount: quizReadCount ?? this.quizReadCount,
        quizWriteCount: quizWriteCount ?? this.quizWriteCount,
        quizChooseWordCount: quizChooseWordCount ?? this.quizChooseWordCount,
        quizChooseMeaningCount:
            quizChooseMeaningCount ?? this.quizChooseMeaningCount,
        quizRetryLimit: quizRetryLimit ?? this.quizRetryLimit,
        newWordSessionSize: newWordSessionSize ?? this.newWordSessionSize,
        newWordListenCount: newWordListenCount ?? this.newWordListenCount,
        newWordWriteCount: newWordWriteCount ?? this.newWordWriteCount,
        newWordChooseWordCount:
            newWordChooseWordCount ?? this.newWordChooseWordCount,
        newWordChooseMeaningCount:
            newWordChooseMeaningCount ?? this.newWordChooseMeaningCount,
        quizJapaneseScript: quizJapaneseScript ?? this.quizJapaneseScript,
        themeMode: themeMode ?? this.themeMode,
        srsLevel1IntervalDays:
            srsLevel1IntervalDays ?? this.srsLevel1IntervalDays,
        srsLevel2IntervalDays:
            srsLevel2IntervalDays ?? this.srsLevel2IntervalDays,
        srsLevel3IntervalDays:
            srsLevel3IntervalDays ?? this.srsLevel3IntervalDays,
        srsLevel4IntervalDays:
            srsLevel4IntervalDays ?? this.srsLevel4IntervalDays,
        srsLevel5IntervalDays:
            srsLevel5IntervalDays ?? this.srsLevel5IntervalDays,
        srsLevel6IntervalDays:
            srsLevel6IntervalDays ?? this.srsLevel6IntervalDays,
        flashcardShowKana: flashcardShowKana ?? this.flashcardShowKana,
        flashcardShowRomaji: flashcardShowRomaji ?? this.flashcardShowRomaji,
        defaultKanaSeeded: defaultKanaSeeded ?? this.defaultKanaSeeded,
      );
  AppSettings copyWithCompanion(SettingsCompanion data) {
    return AppSettings(
      id: data.id.present ? data.id.value : this.id,
      notifyEnabled: data.notifyEnabled.present
          ? data.notifyEnabled.value
          : this.notifyEnabled,
      notifyHour:
          data.notifyHour.present ? data.notifyHour.value : this.notifyHour,
      notifyMinute: data.notifyMinute.present
          ? data.notifyMinute.value
          : this.notifyMinute,
      sessionSize:
          data.sessionSize.present ? data.sessionSize.value : this.sessionSize,
      quizDirection: data.quizDirection.present
          ? data.quizDirection.value
          : this.quizDirection,
      quizListenCount: data.quizListenCount.present
          ? data.quizListenCount.value
          : this.quizListenCount,
      quizReadCount: data.quizReadCount.present
          ? data.quizReadCount.value
          : this.quizReadCount,
      quizWriteCount: data.quizWriteCount.present
          ? data.quizWriteCount.value
          : this.quizWriteCount,
      quizChooseWordCount: data.quizChooseWordCount.present
          ? data.quizChooseWordCount.value
          : this.quizChooseWordCount,
      quizChooseMeaningCount: data.quizChooseMeaningCount.present
          ? data.quizChooseMeaningCount.value
          : this.quizChooseMeaningCount,
      quizRetryLimit: data.quizRetryLimit.present
          ? data.quizRetryLimit.value
          : this.quizRetryLimit,
      newWordSessionSize: data.newWordSessionSize.present
          ? data.newWordSessionSize.value
          : this.newWordSessionSize,
      newWordListenCount: data.newWordListenCount.present
          ? data.newWordListenCount.value
          : this.newWordListenCount,
      newWordWriteCount: data.newWordWriteCount.present
          ? data.newWordWriteCount.value
          : this.newWordWriteCount,
      newWordChooseWordCount: data.newWordChooseWordCount.present
          ? data.newWordChooseWordCount.value
          : this.newWordChooseWordCount,
      newWordChooseMeaningCount: data.newWordChooseMeaningCount.present
          ? data.newWordChooseMeaningCount.value
          : this.newWordChooseMeaningCount,
      quizJapaneseScript: data.quizJapaneseScript.present
          ? data.quizJapaneseScript.value
          : this.quizJapaneseScript,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      srsLevel1IntervalDays: data.srsLevel1IntervalDays.present
          ? data.srsLevel1IntervalDays.value
          : this.srsLevel1IntervalDays,
      srsLevel2IntervalDays: data.srsLevel2IntervalDays.present
          ? data.srsLevel2IntervalDays.value
          : this.srsLevel2IntervalDays,
      srsLevel3IntervalDays: data.srsLevel3IntervalDays.present
          ? data.srsLevel3IntervalDays.value
          : this.srsLevel3IntervalDays,
      srsLevel4IntervalDays: data.srsLevel4IntervalDays.present
          ? data.srsLevel4IntervalDays.value
          : this.srsLevel4IntervalDays,
      srsLevel5IntervalDays: data.srsLevel5IntervalDays.present
          ? data.srsLevel5IntervalDays.value
          : this.srsLevel5IntervalDays,
      srsLevel6IntervalDays: data.srsLevel6IntervalDays.present
          ? data.srsLevel6IntervalDays.value
          : this.srsLevel6IntervalDays,
      flashcardShowKana: data.flashcardShowKana.present
          ? data.flashcardShowKana.value
          : this.flashcardShowKana,
      flashcardShowRomaji: data.flashcardShowRomaji.present
          ? data.flashcardShowRomaji.value
          : this.flashcardShowRomaji,
      defaultKanaSeeded: data.defaultKanaSeeded.present
          ? data.defaultKanaSeeded.value
          : this.defaultKanaSeeded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettings(')
          ..write('id: $id, ')
          ..write('notifyEnabled: $notifyEnabled, ')
          ..write('notifyHour: $notifyHour, ')
          ..write('notifyMinute: $notifyMinute, ')
          ..write('sessionSize: $sessionSize, ')
          ..write('quizDirection: $quizDirection, ')
          ..write('quizListenCount: $quizListenCount, ')
          ..write('quizReadCount: $quizReadCount, ')
          ..write('quizWriteCount: $quizWriteCount, ')
          ..write('quizChooseWordCount: $quizChooseWordCount, ')
          ..write('quizChooseMeaningCount: $quizChooseMeaningCount, ')
          ..write('quizRetryLimit: $quizRetryLimit, ')
          ..write('newWordSessionSize: $newWordSessionSize, ')
          ..write('newWordListenCount: $newWordListenCount, ')
          ..write('newWordWriteCount: $newWordWriteCount, ')
          ..write('newWordChooseWordCount: $newWordChooseWordCount, ')
          ..write('newWordChooseMeaningCount: $newWordChooseMeaningCount, ')
          ..write('quizJapaneseScript: $quizJapaneseScript, ')
          ..write('themeMode: $themeMode, ')
          ..write('srsLevel1IntervalDays: $srsLevel1IntervalDays, ')
          ..write('srsLevel2IntervalDays: $srsLevel2IntervalDays, ')
          ..write('srsLevel3IntervalDays: $srsLevel3IntervalDays, ')
          ..write('srsLevel4IntervalDays: $srsLevel4IntervalDays, ')
          ..write('srsLevel5IntervalDays: $srsLevel5IntervalDays, ')
          ..write('srsLevel6IntervalDays: $srsLevel6IntervalDays, ')
          ..write('flashcardShowKana: $flashcardShowKana, ')
          ..write('flashcardShowRomaji: $flashcardShowRomaji, ')
          ..write('defaultKanaSeeded: $defaultKanaSeeded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        notifyEnabled,
        notifyHour,
        notifyMinute,
        sessionSize,
        quizDirection,
        quizListenCount,
        quizReadCount,
        quizWriteCount,
        quizChooseWordCount,
        quizChooseMeaningCount,
        quizRetryLimit,
        newWordSessionSize,
        newWordListenCount,
        newWordWriteCount,
        newWordChooseWordCount,
        newWordChooseMeaningCount,
        quizJapaneseScript,
        themeMode,
        srsLevel1IntervalDays,
        srsLevel2IntervalDays,
        srsLevel3IntervalDays,
        srsLevel4IntervalDays,
        srsLevel5IntervalDays,
        srsLevel6IntervalDays,
        flashcardShowKana,
        flashcardShowRomaji,
        defaultKanaSeeded
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettings &&
          other.id == this.id &&
          other.notifyEnabled == this.notifyEnabled &&
          other.notifyHour == this.notifyHour &&
          other.notifyMinute == this.notifyMinute &&
          other.sessionSize == this.sessionSize &&
          other.quizDirection == this.quizDirection &&
          other.quizListenCount == this.quizListenCount &&
          other.quizReadCount == this.quizReadCount &&
          other.quizWriteCount == this.quizWriteCount &&
          other.quizChooseWordCount == this.quizChooseWordCount &&
          other.quizChooseMeaningCount == this.quizChooseMeaningCount &&
          other.quizRetryLimit == this.quizRetryLimit &&
          other.newWordSessionSize == this.newWordSessionSize &&
          other.newWordListenCount == this.newWordListenCount &&
          other.newWordWriteCount == this.newWordWriteCount &&
          other.newWordChooseWordCount == this.newWordChooseWordCount &&
          other.newWordChooseMeaningCount == this.newWordChooseMeaningCount &&
          other.quizJapaneseScript == this.quizJapaneseScript &&
          other.themeMode == this.themeMode &&
          other.srsLevel1IntervalDays == this.srsLevel1IntervalDays &&
          other.srsLevel2IntervalDays == this.srsLevel2IntervalDays &&
          other.srsLevel3IntervalDays == this.srsLevel3IntervalDays &&
          other.srsLevel4IntervalDays == this.srsLevel4IntervalDays &&
          other.srsLevel5IntervalDays == this.srsLevel5IntervalDays &&
          other.srsLevel6IntervalDays == this.srsLevel6IntervalDays &&
          other.flashcardShowKana == this.flashcardShowKana &&
          other.flashcardShowRomaji == this.flashcardShowRomaji &&
          other.defaultKanaSeeded == this.defaultKanaSeeded);
}

class SettingsCompanion extends UpdateCompanion<AppSettings> {
  final Value<int> id;
  final Value<bool> notifyEnabled;
  final Value<int> notifyHour;
  final Value<int> notifyMinute;
  final Value<int> sessionSize;
  final Value<String> quizDirection;
  final Value<int> quizListenCount;
  final Value<int> quizReadCount;
  final Value<int> quizWriteCount;
  final Value<int> quizChooseWordCount;
  final Value<int> quizChooseMeaningCount;
  final Value<int> quizRetryLimit;
  final Value<int> newWordSessionSize;
  final Value<int> newWordListenCount;
  final Value<int> newWordWriteCount;
  final Value<int> newWordChooseWordCount;
  final Value<int> newWordChooseMeaningCount;
  final Value<String> quizJapaneseScript;
  final Value<String> themeMode;
  final Value<double> srsLevel1IntervalDays;
  final Value<double> srsLevel2IntervalDays;
  final Value<double> srsLevel3IntervalDays;
  final Value<double> srsLevel4IntervalDays;
  final Value<double> srsLevel5IntervalDays;
  final Value<double> srsLevel6IntervalDays;
  final Value<bool> flashcardShowKana;
  final Value<bool> flashcardShowRomaji;
  final Value<bool> defaultKanaSeeded;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.notifyEnabled = const Value.absent(),
    this.notifyHour = const Value.absent(),
    this.notifyMinute = const Value.absent(),
    this.sessionSize = const Value.absent(),
    this.quizDirection = const Value.absent(),
    this.quizListenCount = const Value.absent(),
    this.quizReadCount = const Value.absent(),
    this.quizWriteCount = const Value.absent(),
    this.quizChooseWordCount = const Value.absent(),
    this.quizChooseMeaningCount = const Value.absent(),
    this.quizRetryLimit = const Value.absent(),
    this.newWordSessionSize = const Value.absent(),
    this.newWordListenCount = const Value.absent(),
    this.newWordWriteCount = const Value.absent(),
    this.newWordChooseWordCount = const Value.absent(),
    this.newWordChooseMeaningCount = const Value.absent(),
    this.quizJapaneseScript = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.srsLevel1IntervalDays = const Value.absent(),
    this.srsLevel2IntervalDays = const Value.absent(),
    this.srsLevel3IntervalDays = const Value.absent(),
    this.srsLevel4IntervalDays = const Value.absent(),
    this.srsLevel5IntervalDays = const Value.absent(),
    this.srsLevel6IntervalDays = const Value.absent(),
    this.flashcardShowKana = const Value.absent(),
    this.flashcardShowRomaji = const Value.absent(),
    this.defaultKanaSeeded = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.notifyEnabled = const Value.absent(),
    this.notifyHour = const Value.absent(),
    this.notifyMinute = const Value.absent(),
    this.sessionSize = const Value.absent(),
    this.quizDirection = const Value.absent(),
    this.quizListenCount = const Value.absent(),
    this.quizReadCount = const Value.absent(),
    this.quizWriteCount = const Value.absent(),
    this.quizChooseWordCount = const Value.absent(),
    this.quizChooseMeaningCount = const Value.absent(),
    this.quizRetryLimit = const Value.absent(),
    this.newWordSessionSize = const Value.absent(),
    this.newWordListenCount = const Value.absent(),
    this.newWordWriteCount = const Value.absent(),
    this.newWordChooseWordCount = const Value.absent(),
    this.newWordChooseMeaningCount = const Value.absent(),
    this.quizJapaneseScript = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.srsLevel1IntervalDays = const Value.absent(),
    this.srsLevel2IntervalDays = const Value.absent(),
    this.srsLevel3IntervalDays = const Value.absent(),
    this.srsLevel4IntervalDays = const Value.absent(),
    this.srsLevel5IntervalDays = const Value.absent(),
    this.srsLevel6IntervalDays = const Value.absent(),
    this.flashcardShowKana = const Value.absent(),
    this.flashcardShowRomaji = const Value.absent(),
    this.defaultKanaSeeded = const Value.absent(),
  });
  static Insertable<AppSettings> custom({
    Expression<int>? id,
    Expression<bool>? notifyEnabled,
    Expression<int>? notifyHour,
    Expression<int>? notifyMinute,
    Expression<int>? sessionSize,
    Expression<String>? quizDirection,
    Expression<int>? quizListenCount,
    Expression<int>? quizReadCount,
    Expression<int>? quizWriteCount,
    Expression<int>? quizChooseWordCount,
    Expression<int>? quizChooseMeaningCount,
    Expression<int>? quizRetryLimit,
    Expression<int>? newWordSessionSize,
    Expression<int>? newWordListenCount,
    Expression<int>? newWordWriteCount,
    Expression<int>? newWordChooseWordCount,
    Expression<int>? newWordChooseMeaningCount,
    Expression<String>? quizJapaneseScript,
    Expression<String>? themeMode,
    Expression<double>? srsLevel1IntervalDays,
    Expression<double>? srsLevel2IntervalDays,
    Expression<double>? srsLevel3IntervalDays,
    Expression<double>? srsLevel4IntervalDays,
    Expression<double>? srsLevel5IntervalDays,
    Expression<double>? srsLevel6IntervalDays,
    Expression<bool>? flashcardShowKana,
    Expression<bool>? flashcardShowRomaji,
    Expression<bool>? defaultKanaSeeded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notifyEnabled != null) 'notify_enabled': notifyEnabled,
      if (notifyHour != null) 'notify_hour': notifyHour,
      if (notifyMinute != null) 'notify_minute': notifyMinute,
      if (sessionSize != null) 'session_size': sessionSize,
      if (quizDirection != null) 'quiz_direction': quizDirection,
      if (quizListenCount != null) 'quiz_listen_count': quizListenCount,
      if (quizReadCount != null) 'quiz_read_count': quizReadCount,
      if (quizWriteCount != null) 'quiz_write_count': quizWriteCount,
      if (quizChooseWordCount != null)
        'quiz_choose_word_count': quizChooseWordCount,
      if (quizChooseMeaningCount != null)
        'quiz_choose_meaning_count': quizChooseMeaningCount,
      if (quizRetryLimit != null) 'quiz_retry_limit': quizRetryLimit,
      if (newWordSessionSize != null)
        'new_word_session_size': newWordSessionSize,
      if (newWordListenCount != null)
        'new_word_listen_count': newWordListenCount,
      if (newWordWriteCount != null) 'new_word_write_count': newWordWriteCount,
      if (newWordChooseWordCount != null)
        'new_word_choose_word_count': newWordChooseWordCount,
      if (newWordChooseMeaningCount != null)
        'new_word_choose_meaning_count': newWordChooseMeaningCount,
      if (quizJapaneseScript != null)
        'quiz_japanese_script': quizJapaneseScript,
      if (themeMode != null) 'theme_mode': themeMode,
      if (srsLevel1IntervalDays != null)
        'srs_level1_interval_days': srsLevel1IntervalDays,
      if (srsLevel2IntervalDays != null)
        'srs_level2_interval_days': srsLevel2IntervalDays,
      if (srsLevel3IntervalDays != null)
        'srs_level3_interval_days': srsLevel3IntervalDays,
      if (srsLevel4IntervalDays != null)
        'srs_level4_interval_days': srsLevel4IntervalDays,
      if (srsLevel5IntervalDays != null)
        'srs_level5_interval_days': srsLevel5IntervalDays,
      if (srsLevel6IntervalDays != null)
        'srs_level6_interval_days': srsLevel6IntervalDays,
      if (flashcardShowKana != null) 'flashcard_show_kana': flashcardShowKana,
      if (flashcardShowRomaji != null)
        'flashcard_show_romaji': flashcardShowRomaji,
      if (defaultKanaSeeded != null) 'default_kana_seeded': defaultKanaSeeded,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<bool>? notifyEnabled,
      Value<int>? notifyHour,
      Value<int>? notifyMinute,
      Value<int>? sessionSize,
      Value<String>? quizDirection,
      Value<int>? quizListenCount,
      Value<int>? quizReadCount,
      Value<int>? quizWriteCount,
      Value<int>? quizChooseWordCount,
      Value<int>? quizChooseMeaningCount,
      Value<int>? quizRetryLimit,
      Value<int>? newWordSessionSize,
      Value<int>? newWordListenCount,
      Value<int>? newWordWriteCount,
      Value<int>? newWordChooseWordCount,
      Value<int>? newWordChooseMeaningCount,
      Value<String>? quizJapaneseScript,
      Value<String>? themeMode,
      Value<double>? srsLevel1IntervalDays,
      Value<double>? srsLevel2IntervalDays,
      Value<double>? srsLevel3IntervalDays,
      Value<double>? srsLevel4IntervalDays,
      Value<double>? srsLevel5IntervalDays,
      Value<double>? srsLevel6IntervalDays,
      Value<bool>? flashcardShowKana,
      Value<bool>? flashcardShowRomaji,
      Value<bool>? defaultKanaSeeded}) {
    return SettingsCompanion(
      id: id ?? this.id,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      sessionSize: sessionSize ?? this.sessionSize,
      quizDirection: quizDirection ?? this.quizDirection,
      quizListenCount: quizListenCount ?? this.quizListenCount,
      quizReadCount: quizReadCount ?? this.quizReadCount,
      quizWriteCount: quizWriteCount ?? this.quizWriteCount,
      quizChooseWordCount: quizChooseWordCount ?? this.quizChooseWordCount,
      quizChooseMeaningCount:
          quizChooseMeaningCount ?? this.quizChooseMeaningCount,
      quizRetryLimit: quizRetryLimit ?? this.quizRetryLimit,
      newWordSessionSize: newWordSessionSize ?? this.newWordSessionSize,
      newWordListenCount: newWordListenCount ?? this.newWordListenCount,
      newWordWriteCount: newWordWriteCount ?? this.newWordWriteCount,
      newWordChooseWordCount:
          newWordChooseWordCount ?? this.newWordChooseWordCount,
      newWordChooseMeaningCount:
          newWordChooseMeaningCount ?? this.newWordChooseMeaningCount,
      quizJapaneseScript: quizJapaneseScript ?? this.quizJapaneseScript,
      themeMode: themeMode ?? this.themeMode,
      srsLevel1IntervalDays:
          srsLevel1IntervalDays ?? this.srsLevel1IntervalDays,
      srsLevel2IntervalDays:
          srsLevel2IntervalDays ?? this.srsLevel2IntervalDays,
      srsLevel3IntervalDays:
          srsLevel3IntervalDays ?? this.srsLevel3IntervalDays,
      srsLevel4IntervalDays:
          srsLevel4IntervalDays ?? this.srsLevel4IntervalDays,
      srsLevel5IntervalDays:
          srsLevel5IntervalDays ?? this.srsLevel5IntervalDays,
      srsLevel6IntervalDays:
          srsLevel6IntervalDays ?? this.srsLevel6IntervalDays,
      flashcardShowKana: flashcardShowKana ?? this.flashcardShowKana,
      flashcardShowRomaji: flashcardShowRomaji ?? this.flashcardShowRomaji,
      defaultKanaSeeded: defaultKanaSeeded ?? this.defaultKanaSeeded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notifyEnabled.present) {
      map['notify_enabled'] = Variable<bool>(notifyEnabled.value);
    }
    if (notifyHour.present) {
      map['notify_hour'] = Variable<int>(notifyHour.value);
    }
    if (notifyMinute.present) {
      map['notify_minute'] = Variable<int>(notifyMinute.value);
    }
    if (sessionSize.present) {
      map['session_size'] = Variable<int>(sessionSize.value);
    }
    if (quizDirection.present) {
      map['quiz_direction'] = Variable<String>(quizDirection.value);
    }
    if (quizListenCount.present) {
      map['quiz_listen_count'] = Variable<int>(quizListenCount.value);
    }
    if (quizReadCount.present) {
      map['quiz_read_count'] = Variable<int>(quizReadCount.value);
    }
    if (quizWriteCount.present) {
      map['quiz_write_count'] = Variable<int>(quizWriteCount.value);
    }
    if (quizChooseWordCount.present) {
      map['quiz_choose_word_count'] = Variable<int>(quizChooseWordCount.value);
    }
    if (quizChooseMeaningCount.present) {
      map['quiz_choose_meaning_count'] =
          Variable<int>(quizChooseMeaningCount.value);
    }
    if (quizRetryLimit.present) {
      map['quiz_retry_limit'] = Variable<int>(quizRetryLimit.value);
    }
    if (newWordSessionSize.present) {
      map['new_word_session_size'] = Variable<int>(newWordSessionSize.value);
    }
    if (newWordListenCount.present) {
      map['new_word_listen_count'] = Variable<int>(newWordListenCount.value);
    }
    if (newWordWriteCount.present) {
      map['new_word_write_count'] = Variable<int>(newWordWriteCount.value);
    }
    if (newWordChooseWordCount.present) {
      map['new_word_choose_word_count'] =
          Variable<int>(newWordChooseWordCount.value);
    }
    if (newWordChooseMeaningCount.present) {
      map['new_word_choose_meaning_count'] =
          Variable<int>(newWordChooseMeaningCount.value);
    }
    if (quizJapaneseScript.present) {
      map['quiz_japanese_script'] = Variable<String>(quizJapaneseScript.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (srsLevel1IntervalDays.present) {
      map['srs_level1_interval_days'] =
          Variable<double>(srsLevel1IntervalDays.value);
    }
    if (srsLevel2IntervalDays.present) {
      map['srs_level2_interval_days'] =
          Variable<double>(srsLevel2IntervalDays.value);
    }
    if (srsLevel3IntervalDays.present) {
      map['srs_level3_interval_days'] =
          Variable<double>(srsLevel3IntervalDays.value);
    }
    if (srsLevel4IntervalDays.present) {
      map['srs_level4_interval_days'] =
          Variable<double>(srsLevel4IntervalDays.value);
    }
    if (srsLevel5IntervalDays.present) {
      map['srs_level5_interval_days'] =
          Variable<double>(srsLevel5IntervalDays.value);
    }
    if (srsLevel6IntervalDays.present) {
      map['srs_level6_interval_days'] =
          Variable<double>(srsLevel6IntervalDays.value);
    }
    if (flashcardShowKana.present) {
      map['flashcard_show_kana'] = Variable<bool>(flashcardShowKana.value);
    }
    if (flashcardShowRomaji.present) {
      map['flashcard_show_romaji'] = Variable<bool>(flashcardShowRomaji.value);
    }
    if (defaultKanaSeeded.present) {
      map['default_kana_seeded'] = Variable<bool>(defaultKanaSeeded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('notifyEnabled: $notifyEnabled, ')
          ..write('notifyHour: $notifyHour, ')
          ..write('notifyMinute: $notifyMinute, ')
          ..write('sessionSize: $sessionSize, ')
          ..write('quizDirection: $quizDirection, ')
          ..write('quizListenCount: $quizListenCount, ')
          ..write('quizReadCount: $quizReadCount, ')
          ..write('quizWriteCount: $quizWriteCount, ')
          ..write('quizChooseWordCount: $quizChooseWordCount, ')
          ..write('quizChooseMeaningCount: $quizChooseMeaningCount, ')
          ..write('quizRetryLimit: $quizRetryLimit, ')
          ..write('newWordSessionSize: $newWordSessionSize, ')
          ..write('newWordListenCount: $newWordListenCount, ')
          ..write('newWordWriteCount: $newWordWriteCount, ')
          ..write('newWordChooseWordCount: $newWordChooseWordCount, ')
          ..write('newWordChooseMeaningCount: $newWordChooseMeaningCount, ')
          ..write('quizJapaneseScript: $quizJapaneseScript, ')
          ..write('themeMode: $themeMode, ')
          ..write('srsLevel1IntervalDays: $srsLevel1IntervalDays, ')
          ..write('srsLevel2IntervalDays: $srsLevel2IntervalDays, ')
          ..write('srsLevel3IntervalDays: $srsLevel3IntervalDays, ')
          ..write('srsLevel4IntervalDays: $srsLevel4IntervalDays, ')
          ..write('srsLevel5IntervalDays: $srsLevel5IntervalDays, ')
          ..write('srsLevel6IntervalDays: $srsLevel6IntervalDays, ')
          ..write('flashcardShowKana: $flashcardShowKana, ')
          ..write('flashcardShowRomaji: $flashcardShowRomaji, ')
          ..write('defaultKanaSeeded: $defaultKanaSeeded')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $VocabularyTable vocabulary = $VocabularyTable(this);
  late final $SrsProgressTable srsProgress = $SrsProgressTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final FolderDao folderDao = FolderDao(this as AppDatabase);
  late final VocabularyDao vocabularyDao = VocabularyDao(this as AppDatabase);
  late final SrsProgressDao srsProgressDao =
      SrsProgressDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [folders, vocabulary, srsProgress, settings];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('folders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('vocabulary', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('vocabulary',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('srs_progress', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  Value<String> color,
  Value<int> createdAt,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<String> color,
  Value<int> createdAt,
});

class $$FoldersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder> {
  $$FoldersTableTableManager(_$AppDatabase db, $FoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FoldersTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FoldersTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              FoldersCompanion(
            id: id,
            name: name,
            description: description,
            color: color,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              FoldersCompanion.insert(
            id: id,
            name: name,
            description: description,
            color: color,
            createdAt: createdAt,
          ),
        ));
}

class $$FoldersTableFilterComposer
    extends FilterComposer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter vocabularyRefs(
      ComposableFilter Function($$VocabularyTableFilterComposer f) f) {
    final $$VocabularyTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.vocabulary,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder, parentComposers) =>
            $$VocabularyTableFilterComposer(ComposerState($state.db,
                $state.db.vocabulary, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $FoldersTable> {
  $$FoldersTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$VocabularyTableCreateCompanionBuilder = VocabularyCompanion Function({
  Value<int> id,
  required int folderId,
  Value<String?> kanji,
  required String kana,
  required String romaji,
  required String meaning,
  Value<String?> pitchAccent,
  Value<String?> example,
  Value<String?> note,
  Value<String?> audioPath,
  Value<bool> isFavorite,
  Value<int> createdAt,
});
typedef $$VocabularyTableUpdateCompanionBuilder = VocabularyCompanion Function({
  Value<int> id,
  Value<int> folderId,
  Value<String?> kanji,
  Value<String> kana,
  Value<String> romaji,
  Value<String> meaning,
  Value<String?> pitchAccent,
  Value<String?> example,
  Value<String?> note,
  Value<String?> audioPath,
  Value<bool> isFavorite,
  Value<int> createdAt,
});

class $$VocabularyTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyTable,
    VocabularyEntry,
    $$VocabularyTableFilterComposer,
    $$VocabularyTableOrderingComposer,
    $$VocabularyTableCreateCompanionBuilder,
    $$VocabularyTableUpdateCompanionBuilder> {
  $$VocabularyTableTableManager(_$AppDatabase db, $VocabularyTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$VocabularyTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$VocabularyTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> folderId = const Value.absent(),
            Value<String?> kanji = const Value.absent(),
            Value<String> kana = const Value.absent(),
            Value<String> romaji = const Value.absent(),
            Value<String> meaning = const Value.absent(),
            Value<String?> pitchAccent = const Value.absent(),
            Value<String?> example = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              VocabularyCompanion(
            id: id,
            folderId: folderId,
            kanji: kanji,
            kana: kana,
            romaji: romaji,
            meaning: meaning,
            pitchAccent: pitchAccent,
            example: example,
            note: note,
            audioPath: audioPath,
            isFavorite: isFavorite,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int folderId,
            Value<String?> kanji = const Value.absent(),
            required String kana,
            required String romaji,
            required String meaning,
            Value<String?> pitchAccent = const Value.absent(),
            Value<String?> example = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> audioPath = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              VocabularyCompanion.insert(
            id: id,
            folderId: folderId,
            kanji: kanji,
            kana: kana,
            romaji: romaji,
            meaning: meaning,
            pitchAccent: pitchAccent,
            example: example,
            note: note,
            audioPath: audioPath,
            isFavorite: isFavorite,
            createdAt: createdAt,
          ),
        ));
}

class $$VocabularyTableFilterComposer
    extends FilterComposer<_$AppDatabase, $VocabularyTable> {
  $$VocabularyTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get kanji => $state.composableBuilder(
      column: $state.table.kanji,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get kana => $state.composableBuilder(
      column: $state.table.kana,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get romaji => $state.composableBuilder(
      column: $state.table.romaji,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get meaning => $state.composableBuilder(
      column: $state.table.meaning,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pitchAccent => $state.composableBuilder(
      column: $state.table.pitchAccent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get example => $state.composableBuilder(
      column: $state.table.example,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get audioPath => $state.composableBuilder(
      column: $state.table.audioPath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $state.db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$FoldersTableFilterComposer(
            ComposerState(
                $state.db, $state.db.folders, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter srsProgressRefs(
      ComposableFilter Function($$SrsProgressTableFilterComposer f) f) {
    final $$SrsProgressTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.srsProgress,
        getReferencedColumn: (t) => t.vocabId,
        builder: (joinBuilder, parentComposers) =>
            $$SrsProgressTableFilterComposer(ComposerState($state.db,
                $state.db.srsProgress, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$VocabularyTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $VocabularyTable> {
  $$VocabularyTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get kanji => $state.composableBuilder(
      column: $state.table.kanji,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get kana => $state.composableBuilder(
      column: $state.table.kana,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get romaji => $state.composableBuilder(
      column: $state.table.romaji,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get meaning => $state.composableBuilder(
      column: $state.table.meaning,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pitchAccent => $state.composableBuilder(
      column: $state.table.pitchAccent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get example => $state.composableBuilder(
      column: $state.table.example,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get audioPath => $state.composableBuilder(
      column: $state.table.audioPath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFavorite => $state.composableBuilder(
      column: $state.table.isFavorite,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $state.db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$FoldersTableOrderingComposer(ComposerState(
                $state.db, $state.db.folders, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SrsProgressTableCreateCompanionBuilder = SrsProgressCompanion
    Function({
  Value<int> id,
  required int vocabId,
  Value<int> level,
  Value<double> intervalDays,
  required int nextReviewAt,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<int?> lastReviewedAt,
});
typedef $$SrsProgressTableUpdateCompanionBuilder = SrsProgressCompanion
    Function({
  Value<int> id,
  Value<int> vocabId,
  Value<int> level,
  Value<double> intervalDays,
  Value<int> nextReviewAt,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<int?> lastReviewedAt,
});

class $$SrsProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SrsProgressTable,
    SrsProgressEntry,
    $$SrsProgressTableFilterComposer,
    $$SrsProgressTableOrderingComposer,
    $$SrsProgressTableCreateCompanionBuilder,
    $$SrsProgressTableUpdateCompanionBuilder> {
  $$SrsProgressTableTableManager(_$AppDatabase db, $SrsProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SrsProgressTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SrsProgressTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> vocabId = const Value.absent(),
            Value<int> level = const Value.absent(),
            Value<double> intervalDays = const Value.absent(),
            Value<int> nextReviewAt = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<int?> lastReviewedAt = const Value.absent(),
          }) =>
              SrsProgressCompanion(
            id: id,
            vocabId: vocabId,
            level: level,
            intervalDays: intervalDays,
            nextReviewAt: nextReviewAt,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewedAt: lastReviewedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int vocabId,
            Value<int> level = const Value.absent(),
            Value<double> intervalDays = const Value.absent(),
            required int nextReviewAt,
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<int?> lastReviewedAt = const Value.absent(),
          }) =>
              SrsProgressCompanion.insert(
            id: id,
            vocabId: vocabId,
            level: level,
            intervalDays: intervalDays,
            nextReviewAt: nextReviewAt,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewedAt: lastReviewedAt,
          ),
        ));
}

class $$SrsProgressTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SrsProgressTable> {
  $$SrsProgressTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get intervalDays => $state.composableBuilder(
      column: $state.table.intervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get nextReviewAt => $state.composableBuilder(
      column: $state.table.nextReviewAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get correctCount => $state.composableBuilder(
      column: $state.table.correctCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get wrongCount => $state.composableBuilder(
      column: $state.table.wrongCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get lastReviewedAt => $state.composableBuilder(
      column: $state.table.lastReviewedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$VocabularyTableFilterComposer get vocabId {
    final $$VocabularyTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vocabId,
        referencedTable: $state.db.vocabulary,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$VocabularyTableFilterComposer(ComposerState($state.db,
                $state.db.vocabulary, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$SrsProgressTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SrsProgressTable> {
  $$SrsProgressTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get intervalDays => $state.composableBuilder(
      column: $state.table.intervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get nextReviewAt => $state.composableBuilder(
      column: $state.table.nextReviewAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get correctCount => $state.composableBuilder(
      column: $state.table.correctCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get wrongCount => $state.composableBuilder(
      column: $state.table.wrongCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get lastReviewedAt => $state.composableBuilder(
      column: $state.table.lastReviewedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$VocabularyTableOrderingComposer get vocabId {
    final $$VocabularyTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.vocabId,
        referencedTable: $state.db.vocabulary,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$VocabularyTableOrderingComposer(ComposerState($state.db,
                $state.db.vocabulary, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<bool> notifyEnabled,
  Value<int> notifyHour,
  Value<int> notifyMinute,
  Value<int> sessionSize,
  Value<String> quizDirection,
  Value<int> quizListenCount,
  Value<int> quizReadCount,
  Value<int> quizWriteCount,
  Value<int> quizChooseWordCount,
  Value<int> quizChooseMeaningCount,
  Value<int> quizRetryLimit,
  Value<int> newWordSessionSize,
  Value<int> newWordListenCount,
  Value<int> newWordWriteCount,
  Value<int> newWordChooseWordCount,
  Value<int> newWordChooseMeaningCount,
  Value<String> quizJapaneseScript,
  Value<String> themeMode,
  Value<double> srsLevel1IntervalDays,
  Value<double> srsLevel2IntervalDays,
  Value<double> srsLevel3IntervalDays,
  Value<double> srsLevel4IntervalDays,
  Value<double> srsLevel5IntervalDays,
  Value<double> srsLevel6IntervalDays,
  Value<bool> flashcardShowKana,
  Value<bool> flashcardShowRomaji,
  Value<bool> defaultKanaSeeded,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<bool> notifyEnabled,
  Value<int> notifyHour,
  Value<int> notifyMinute,
  Value<int> sessionSize,
  Value<String> quizDirection,
  Value<int> quizListenCount,
  Value<int> quizReadCount,
  Value<int> quizWriteCount,
  Value<int> quizChooseWordCount,
  Value<int> quizChooseMeaningCount,
  Value<int> quizRetryLimit,
  Value<int> newWordSessionSize,
  Value<int> newWordListenCount,
  Value<int> newWordWriteCount,
  Value<int> newWordChooseWordCount,
  Value<int> newWordChooseMeaningCount,
  Value<String> quizJapaneseScript,
  Value<String> themeMode,
  Value<double> srsLevel1IntervalDays,
  Value<double> srsLevel2IntervalDays,
  Value<double> srsLevel3IntervalDays,
  Value<double> srsLevel4IntervalDays,
  Value<double> srsLevel5IntervalDays,
  Value<double> srsLevel6IntervalDays,
  Value<bool> flashcardShowKana,
  Value<bool> flashcardShowRomaji,
  Value<bool> defaultKanaSeeded,
});

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    AppSettings,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> notifyEnabled = const Value.absent(),
            Value<int> notifyHour = const Value.absent(),
            Value<int> notifyMinute = const Value.absent(),
            Value<int> sessionSize = const Value.absent(),
            Value<String> quizDirection = const Value.absent(),
            Value<int> quizListenCount = const Value.absent(),
            Value<int> quizReadCount = const Value.absent(),
            Value<int> quizWriteCount = const Value.absent(),
            Value<int> quizChooseWordCount = const Value.absent(),
            Value<int> quizChooseMeaningCount = const Value.absent(),
            Value<int> quizRetryLimit = const Value.absent(),
            Value<int> newWordSessionSize = const Value.absent(),
            Value<int> newWordListenCount = const Value.absent(),
            Value<int> newWordWriteCount = const Value.absent(),
            Value<int> newWordChooseWordCount = const Value.absent(),
            Value<int> newWordChooseMeaningCount = const Value.absent(),
            Value<String> quizJapaneseScript = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<double> srsLevel1IntervalDays = const Value.absent(),
            Value<double> srsLevel2IntervalDays = const Value.absent(),
            Value<double> srsLevel3IntervalDays = const Value.absent(),
            Value<double> srsLevel4IntervalDays = const Value.absent(),
            Value<double> srsLevel5IntervalDays = const Value.absent(),
            Value<double> srsLevel6IntervalDays = const Value.absent(),
            Value<bool> flashcardShowKana = const Value.absent(),
            Value<bool> flashcardShowRomaji = const Value.absent(),
            Value<bool> defaultKanaSeeded = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            notifyEnabled: notifyEnabled,
            notifyHour: notifyHour,
            notifyMinute: notifyMinute,
            sessionSize: sessionSize,
            quizDirection: quizDirection,
            quizListenCount: quizListenCount,
            quizReadCount: quizReadCount,
            quizWriteCount: quizWriteCount,
            quizChooseWordCount: quizChooseWordCount,
            quizChooseMeaningCount: quizChooseMeaningCount,
            quizRetryLimit: quizRetryLimit,
            newWordSessionSize: newWordSessionSize,
            newWordListenCount: newWordListenCount,
            newWordWriteCount: newWordWriteCount,
            newWordChooseWordCount: newWordChooseWordCount,
            newWordChooseMeaningCount: newWordChooseMeaningCount,
            quizJapaneseScript: quizJapaneseScript,
            themeMode: themeMode,
            srsLevel1IntervalDays: srsLevel1IntervalDays,
            srsLevel2IntervalDays: srsLevel2IntervalDays,
            srsLevel3IntervalDays: srsLevel3IntervalDays,
            srsLevel4IntervalDays: srsLevel4IntervalDays,
            srsLevel5IntervalDays: srsLevel5IntervalDays,
            srsLevel6IntervalDays: srsLevel6IntervalDays,
            flashcardShowKana: flashcardShowKana,
            flashcardShowRomaji: flashcardShowRomaji,
            defaultKanaSeeded: defaultKanaSeeded,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> notifyEnabled = const Value.absent(),
            Value<int> notifyHour = const Value.absent(),
            Value<int> notifyMinute = const Value.absent(),
            Value<int> sessionSize = const Value.absent(),
            Value<String> quizDirection = const Value.absent(),
            Value<int> quizListenCount = const Value.absent(),
            Value<int> quizReadCount = const Value.absent(),
            Value<int> quizWriteCount = const Value.absent(),
            Value<int> quizChooseWordCount = const Value.absent(),
            Value<int> quizChooseMeaningCount = const Value.absent(),
            Value<int> quizRetryLimit = const Value.absent(),
            Value<int> newWordSessionSize = const Value.absent(),
            Value<int> newWordListenCount = const Value.absent(),
            Value<int> newWordWriteCount = const Value.absent(),
            Value<int> newWordChooseWordCount = const Value.absent(),
            Value<int> newWordChooseMeaningCount = const Value.absent(),
            Value<String> quizJapaneseScript = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<double> srsLevel1IntervalDays = const Value.absent(),
            Value<double> srsLevel2IntervalDays = const Value.absent(),
            Value<double> srsLevel3IntervalDays = const Value.absent(),
            Value<double> srsLevel4IntervalDays = const Value.absent(),
            Value<double> srsLevel5IntervalDays = const Value.absent(),
            Value<double> srsLevel6IntervalDays = const Value.absent(),
            Value<bool> flashcardShowKana = const Value.absent(),
            Value<bool> flashcardShowRomaji = const Value.absent(),
            Value<bool> defaultKanaSeeded = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            id: id,
            notifyEnabled: notifyEnabled,
            notifyHour: notifyHour,
            notifyMinute: notifyMinute,
            sessionSize: sessionSize,
            quizDirection: quizDirection,
            quizListenCount: quizListenCount,
            quizReadCount: quizReadCount,
            quizWriteCount: quizWriteCount,
            quizChooseWordCount: quizChooseWordCount,
            quizChooseMeaningCount: quizChooseMeaningCount,
            quizRetryLimit: quizRetryLimit,
            newWordSessionSize: newWordSessionSize,
            newWordListenCount: newWordListenCount,
            newWordWriteCount: newWordWriteCount,
            newWordChooseWordCount: newWordChooseWordCount,
            newWordChooseMeaningCount: newWordChooseMeaningCount,
            quizJapaneseScript: quizJapaneseScript,
            themeMode: themeMode,
            srsLevel1IntervalDays: srsLevel1IntervalDays,
            srsLevel2IntervalDays: srsLevel2IntervalDays,
            srsLevel3IntervalDays: srsLevel3IntervalDays,
            srsLevel4IntervalDays: srsLevel4IntervalDays,
            srsLevel5IntervalDays: srsLevel5IntervalDays,
            srsLevel6IntervalDays: srsLevel6IntervalDays,
            flashcardShowKana: flashcardShowKana,
            flashcardShowRomaji: flashcardShowRomaji,
            defaultKanaSeeded: defaultKanaSeeded,
          ),
        ));
}

class $$SettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get notifyEnabled => $state.composableBuilder(
      column: $state.table.notifyEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get notifyHour => $state.composableBuilder(
      column: $state.table.notifyHour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get notifyMinute => $state.composableBuilder(
      column: $state.table.notifyMinute,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sessionSize => $state.composableBuilder(
      column: $state.table.sessionSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get quizDirection => $state.composableBuilder(
      column: $state.table.quizDirection,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizListenCount => $state.composableBuilder(
      column: $state.table.quizListenCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizReadCount => $state.composableBuilder(
      column: $state.table.quizReadCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizWriteCount => $state.composableBuilder(
      column: $state.table.quizWriteCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizChooseWordCount => $state.composableBuilder(
      column: $state.table.quizChooseWordCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizChooseMeaningCount => $state.composableBuilder(
      column: $state.table.quizChooseMeaningCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get quizRetryLimit => $state.composableBuilder(
      column: $state.table.quizRetryLimit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get newWordSessionSize => $state.composableBuilder(
      column: $state.table.newWordSessionSize,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get newWordListenCount => $state.composableBuilder(
      column: $state.table.newWordListenCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get newWordWriteCount => $state.composableBuilder(
      column: $state.table.newWordWriteCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get newWordChooseWordCount => $state.composableBuilder(
      column: $state.table.newWordChooseWordCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get newWordChooseMeaningCount => $state.composableBuilder(
      column: $state.table.newWordChooseMeaningCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get quizJapaneseScript => $state.composableBuilder(
      column: $state.table.quizJapaneseScript,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get themeMode => $state.composableBuilder(
      column: $state.table.themeMode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel1IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel1IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel2IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel2IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel3IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel3IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel4IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel4IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel5IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel5IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get srsLevel6IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel6IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get flashcardShowKana => $state.composableBuilder(
      column: $state.table.flashcardShowKana,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get flashcardShowRomaji => $state.composableBuilder(
      column: $state.table.flashcardShowRomaji,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get defaultKanaSeeded => $state.composableBuilder(
      column: $state.table.defaultKanaSeeded,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get notifyEnabled => $state.composableBuilder(
      column: $state.table.notifyEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get notifyHour => $state.composableBuilder(
      column: $state.table.notifyHour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get notifyMinute => $state.composableBuilder(
      column: $state.table.notifyMinute,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sessionSize => $state.composableBuilder(
      column: $state.table.sessionSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get quizDirection => $state.composableBuilder(
      column: $state.table.quizDirection,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizListenCount => $state.composableBuilder(
      column: $state.table.quizListenCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizReadCount => $state.composableBuilder(
      column: $state.table.quizReadCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizWriteCount => $state.composableBuilder(
      column: $state.table.quizWriteCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizChooseWordCount => $state.composableBuilder(
      column: $state.table.quizChooseWordCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizChooseMeaningCount => $state.composableBuilder(
      column: $state.table.quizChooseMeaningCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get quizRetryLimit => $state.composableBuilder(
      column: $state.table.quizRetryLimit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get newWordSessionSize => $state.composableBuilder(
      column: $state.table.newWordSessionSize,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get newWordListenCount => $state.composableBuilder(
      column: $state.table.newWordListenCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get newWordWriteCount => $state.composableBuilder(
      column: $state.table.newWordWriteCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get newWordChooseWordCount => $state.composableBuilder(
      column: $state.table.newWordChooseWordCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get newWordChooseMeaningCount =>
      $state.composableBuilder(
          column: $state.table.newWordChooseMeaningCount,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get quizJapaneseScript => $state.composableBuilder(
      column: $state.table.quizJapaneseScript,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get themeMode => $state.composableBuilder(
      column: $state.table.themeMode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel1IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel1IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel2IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel2IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel3IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel3IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel4IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel4IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel5IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel5IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get srsLevel6IntervalDays => $state.composableBuilder(
      column: $state.table.srsLevel6IntervalDays,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get flashcardShowKana => $state.composableBuilder(
      column: $state.table.flashcardShowKana,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get flashcardShowRomaji => $state.composableBuilder(
      column: $state.table.flashcardShowRomaji,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get defaultKanaSeeded => $state.composableBuilder(
      column: $state.table.defaultKanaSeeded,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$VocabularyTableTableManager get vocabulary =>
      $$VocabularyTableTableManager(_db, _db.vocabulary);
  $$SrsProgressTableTableManager get srsProgress =>
      $$SrsProgressTableTableManager(_db, _db.srsProgress);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}

mixin _$FolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $VocabularyTable get vocabulary => attachedDatabase.vocabulary;
  $SrsProgressTable get srsProgress => attachedDatabase.srsProgress;
}
mixin _$VocabularyDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $VocabularyTable get vocabulary => attachedDatabase.vocabulary;
  $SrsProgressTable get srsProgress => attachedDatabase.srsProgress;
}
mixin _$SrsProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoldersTable get folders => attachedDatabase.folders;
  $VocabularyTable get vocabulary => attachedDatabase.vocabulary;
  $SrsProgressTable get srsProgress => attachedDatabase.srsProgress;
}
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'8ab73ef1293e27f6de024928c2e888eefcb35e1d';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppDatabaseRef = ProviderRef<AppDatabase>;
String _$folderDaoHash() => r'1f14e57987c854acdd32b76d3b8eb303c9dada72';

/// See also [folderDao].
@ProviderFor(folderDao)
final folderDaoProvider = Provider<FolderDao>.internal(
  folderDao,
  name: r'folderDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$folderDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FolderDaoRef = ProviderRef<FolderDao>;
String _$vocabularyDaoHash() => r'83021b9abe9b441f617b3e6f613253c6526bf0f3';

/// See also [vocabularyDao].
@ProviderFor(vocabularyDao)
final vocabularyDaoProvider = Provider<VocabularyDao>.internal(
  vocabularyDao,
  name: r'vocabularyDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vocabularyDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VocabularyDaoRef = ProviderRef<VocabularyDao>;
String _$srsProgressDaoHash() => r'0bbe1668656ceec93583c91b421eeea5d4bd784b';

/// See also [srsProgressDao].
@ProviderFor(srsProgressDao)
final srsProgressDaoProvider = Provider<SrsProgressDao>.internal(
  srsProgressDao,
  name: r'srsProgressDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$srsProgressDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SrsProgressDaoRef = ProviderRef<SrsProgressDao>;
String _$settingsDaoHash() => r'b9e2e0b95a8aff1ba5be5397ae6429992c5da851';

/// See also [settingsDao].
@ProviderFor(settingsDao)
final settingsDaoProvider = Provider<SettingsDao>.internal(
  settingsDao,
  name: r'settingsDaoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SettingsDaoRef = ProviderRef<SettingsDao>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
