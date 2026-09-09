// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ManufacturersTable extends Manufacturers
    with TableInfo<$ManufacturersTable, Manufacturer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManufacturersTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manufacturers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Manufacturer> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Manufacturer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Manufacturer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $ManufacturersTable createAlias(String alias) {
    return $ManufacturersTable(attachedDatabase, alias);
  }
}

class Manufacturer extends DataClass implements Insertable<Manufacturer> {
  final String id;
  final String name;
  const Manufacturer({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  ManufacturersCompanion toCompanion(bool nullToAbsent) {
    return ManufacturersCompanion(id: Value(id), name: Value(name));
  }

  factory Manufacturer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Manufacturer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Manufacturer copyWith({String? id, String? name}) =>
      Manufacturer(id: id ?? this.id, name: name ?? this.name);
  Manufacturer copyWithCompanion(ManufacturersCompanion data) {
    return Manufacturer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Manufacturer(')
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
      (other is Manufacturer && other.id == this.id && other.name == this.name);
}

class ManufacturersCompanion extends UpdateCompanion<Manufacturer> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rowid;
  const ManufacturersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManufacturersCompanion.insert({
    required String id,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Manufacturer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManufacturersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return ManufacturersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManufacturersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsolesTable extends Consoles with TableInfo<$ConsolesTable, Console> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsolesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _manufacturerIdMeta = const VerificationMeta(
    'manufacturerId',
  );
  @override
  late final GeneratedColumn<String> manufacturerId = GeneratedColumn<String>(
    'manufacturer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES manufacturers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _urlsJsonMeta = const VerificationMeta(
    'urlsJson',
  );
  @override
  late final GeneratedColumn<String> urlsJson = GeneratedColumn<String>(
    'urls_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, manufacturerId, urlsJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consoles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Console> instance, {
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
    if (data.containsKey('manufacturer_id')) {
      context.handle(
        _manufacturerIdMeta,
        manufacturerId.isAcceptableOrUnknown(
          data['manufacturer_id']!,
          _manufacturerIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manufacturerIdMeta);
    }
    if (data.containsKey('urls_json')) {
      context.handle(
        _urlsJsonMeta,
        urlsJson.isAcceptableOrUnknown(data['urls_json']!, _urlsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_urlsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Console map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Console(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manufacturerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer_id'],
      )!,
      urlsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urls_json'],
      )!,
    );
  }

  @override
  $ConsolesTable createAlias(String alias) {
    return $ConsolesTable(attachedDatabase, alias);
  }
}

class Console extends DataClass implements Insertable<Console> {
  final String id;
  final String name;
  final String manufacturerId;
  final String urlsJson;
  const Console({
    required this.id,
    required this.name,
    required this.manufacturerId,
    required this.urlsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['manufacturer_id'] = Variable<String>(manufacturerId);
    map['urls_json'] = Variable<String>(urlsJson);
    return map;
  }

  ConsolesCompanion toCompanion(bool nullToAbsent) {
    return ConsolesCompanion(
      id: Value(id),
      name: Value(name),
      manufacturerId: Value(manufacturerId),
      urlsJson: Value(urlsJson),
    );
  }

  factory Console.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Console(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      manufacturerId: serializer.fromJson<String>(json['manufacturerId']),
      urlsJson: serializer.fromJson<String>(json['urlsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'manufacturerId': serializer.toJson<String>(manufacturerId),
      'urlsJson': serializer.toJson<String>(urlsJson),
    };
  }

  Console copyWith({
    String? id,
    String? name,
    String? manufacturerId,
    String? urlsJson,
  }) => Console(
    id: id ?? this.id,
    name: name ?? this.name,
    manufacturerId: manufacturerId ?? this.manufacturerId,
    urlsJson: urlsJson ?? this.urlsJson,
  );
  Console copyWithCompanion(ConsolesCompanion data) {
    return Console(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      manufacturerId: data.manufacturerId.present
          ? data.manufacturerId.value
          : this.manufacturerId,
      urlsJson: data.urlsJson.present ? data.urlsJson.value : this.urlsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Console(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manufacturerId: $manufacturerId, ')
          ..write('urlsJson: $urlsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, manufacturerId, urlsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Console &&
          other.id == this.id &&
          other.name == this.name &&
          other.manufacturerId == this.manufacturerId &&
          other.urlsJson == this.urlsJson);
}

class ConsolesCompanion extends UpdateCompanion<Console> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> manufacturerId;
  final Value<String> urlsJson;
  final Value<int> rowid;
  const ConsolesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.manufacturerId = const Value.absent(),
    this.urlsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsolesCompanion.insert({
    required String id,
    required String name,
    required String manufacturerId,
    required String urlsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       manufacturerId = Value(manufacturerId),
       urlsJson = Value(urlsJson);
  static Insertable<Console> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? manufacturerId,
    Expression<String>? urlsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (manufacturerId != null) 'manufacturer_id': manufacturerId,
      if (urlsJson != null) 'urls_json': urlsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsolesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? manufacturerId,
    Value<String>? urlsJson,
    Value<int>? rowid,
  }) {
    return ConsolesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      urlsJson: urlsJson ?? this.urlsJson,
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
    if (manufacturerId.present) {
      map['manufacturer_id'] = Variable<String>(manufacturerId.value);
    }
    if (urlsJson.present) {
      map['urls_json'] = Variable<String>(urlsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsolesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('manufacturerId: $manufacturerId, ')
          ..write('urlsJson: $urlsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadableFilesTable extends DownloadableFiles
    with TableInfo<$DownloadableFilesTable, DownloadableFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadableFilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consoleIdMeta = const VerificationMeta(
    'consoleId',
  );
  @override
  late final GeneratedColumn<String> consoleId = GeneratedColumn<String>(
    'console_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES consoles (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _downloadUrlMeta = const VerificationMeta(
    'downloadUrl',
  );
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
    'download_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _torrentFileIndexMeta = const VerificationMeta(
    'torrentFileIndex',
  );
  @override
  late final GeneratedColumn<int> torrentFileIndex = GeneratedColumn<int>(
    'torrent_file_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _torrentMagnetMeta = const VerificationMeta(
    'torrentMagnet',
  );
  @override
  late final GeneratedColumn<String> torrentMagnet = GeneratedColumn<String>(
    'torrent_magnet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    fileName,
    consoleId,
    downloadUrl,
    fileSize,
    fileExtension,
    torrentFileIndex,
    torrentMagnet,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloadable_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadableFile> instance, {
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
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('console_id')) {
      context.handle(
        _consoleIdMeta,
        consoleId.isAcceptableOrUnknown(data['console_id']!, _consoleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_consoleIdMeta);
    }
    if (data.containsKey('download_url')) {
      context.handle(
        _downloadUrlMeta,
        downloadUrl.isAcceptableOrUnknown(
          data['download_url']!,
          _downloadUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadUrlMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    }
    if (data.containsKey('torrent_file_index')) {
      context.handle(
        _torrentFileIndexMeta,
        torrentFileIndex.isAcceptableOrUnknown(
          data['torrent_file_index']!,
          _torrentFileIndexMeta,
        ),
      );
    }
    if (data.containsKey('torrent_magnet')) {
      context.handle(
        _torrentMagnetMeta,
        torrentMagnet.isAcceptableOrUnknown(
          data['torrent_magnet']!,
          _torrentMagnetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadableFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadableFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      consoleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}console_id'],
      )!,
      downloadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_url'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      )!,
      torrentFileIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}torrent_file_index'],
      ),
      torrentMagnet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}torrent_magnet'],
      ),
    );
  }

  @override
  $DownloadableFilesTable createAlias(String alias) {
    return $DownloadableFilesTable(attachedDatabase, alias);
  }
}

class DownloadableFile extends DataClass
    implements Insertable<DownloadableFile> {
  final int id;
  final String name;
  final String fileName;
  final String consoleId;
  final String downloadUrl;
  final int fileSize;
  final String fileExtension;
  final int? torrentFileIndex;
  final String? torrentMagnet;
  const DownloadableFile({
    required this.id,
    required this.name,
    required this.fileName,
    required this.consoleId,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileExtension,
    this.torrentFileIndex,
    this.torrentMagnet,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['file_name'] = Variable<String>(fileName);
    map['console_id'] = Variable<String>(consoleId);
    map['download_url'] = Variable<String>(downloadUrl);
    map['file_size'] = Variable<int>(fileSize);
    map['file_extension'] = Variable<String>(fileExtension);
    if (!nullToAbsent || torrentFileIndex != null) {
      map['torrent_file_index'] = Variable<int>(torrentFileIndex);
    }
    if (!nullToAbsent || torrentMagnet != null) {
      map['torrent_magnet'] = Variable<String>(torrentMagnet);
    }
    return map;
  }

  DownloadableFilesCompanion toCompanion(bool nullToAbsent) {
    return DownloadableFilesCompanion(
      id: Value(id),
      name: Value(name),
      fileName: Value(fileName),
      consoleId: Value(consoleId),
      downloadUrl: Value(downloadUrl),
      fileSize: Value(fileSize),
      fileExtension: Value(fileExtension),
      torrentFileIndex: torrentFileIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(torrentFileIndex),
      torrentMagnet: torrentMagnet == null && nullToAbsent
          ? const Value.absent()
          : Value(torrentMagnet),
    );
  }

  factory DownloadableFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadableFile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fileName: serializer.fromJson<String>(json['fileName']),
      consoleId: serializer.fromJson<String>(json['consoleId']),
      downloadUrl: serializer.fromJson<String>(json['downloadUrl']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      fileExtension: serializer.fromJson<String>(json['fileExtension']),
      torrentFileIndex: serializer.fromJson<int?>(json['torrentFileIndex']),
      torrentMagnet: serializer.fromJson<String?>(json['torrentMagnet']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'fileName': serializer.toJson<String>(fileName),
      'consoleId': serializer.toJson<String>(consoleId),
      'downloadUrl': serializer.toJson<String>(downloadUrl),
      'fileSize': serializer.toJson<int>(fileSize),
      'fileExtension': serializer.toJson<String>(fileExtension),
      'torrentFileIndex': serializer.toJson<int?>(torrentFileIndex),
      'torrentMagnet': serializer.toJson<String?>(torrentMagnet),
    };
  }

  DownloadableFile copyWith({
    int? id,
    String? name,
    String? fileName,
    String? consoleId,
    String? downloadUrl,
    int? fileSize,
    String? fileExtension,
    Value<int?> torrentFileIndex = const Value.absent(),
    Value<String?> torrentMagnet = const Value.absent(),
  }) => DownloadableFile(
    id: id ?? this.id,
    name: name ?? this.name,
    fileName: fileName ?? this.fileName,
    consoleId: consoleId ?? this.consoleId,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    fileSize: fileSize ?? this.fileSize,
    fileExtension: fileExtension ?? this.fileExtension,
    torrentFileIndex: torrentFileIndex.present
        ? torrentFileIndex.value
        : this.torrentFileIndex,
    torrentMagnet: torrentMagnet.present
        ? torrentMagnet.value
        : this.torrentMagnet,
  );
  DownloadableFile copyWithCompanion(DownloadableFilesCompanion data) {
    return DownloadableFile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      consoleId: data.consoleId.present ? data.consoleId.value : this.consoleId,
      downloadUrl: data.downloadUrl.present
          ? data.downloadUrl.value
          : this.downloadUrl,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      torrentFileIndex: data.torrentFileIndex.present
          ? data.torrentFileIndex.value
          : this.torrentFileIndex,
      torrentMagnet: data.torrentMagnet.present
          ? data.torrentMagnet.value
          : this.torrentMagnet,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadableFile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('consoleId: $consoleId, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('torrentFileIndex: $torrentFileIndex, ')
          ..write('torrentMagnet: $torrentMagnet')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fileName,
    consoleId,
    downloadUrl,
    fileSize,
    fileExtension,
    torrentFileIndex,
    torrentMagnet,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadableFile &&
          other.id == this.id &&
          other.name == this.name &&
          other.fileName == this.fileName &&
          other.consoleId == this.consoleId &&
          other.downloadUrl == this.downloadUrl &&
          other.fileSize == this.fileSize &&
          other.fileExtension == this.fileExtension &&
          other.torrentFileIndex == this.torrentFileIndex &&
          other.torrentMagnet == this.torrentMagnet);
}

class DownloadableFilesCompanion extends UpdateCompanion<DownloadableFile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> fileName;
  final Value<String> consoleId;
  final Value<String> downloadUrl;
  final Value<int> fileSize;
  final Value<String> fileExtension;
  final Value<int?> torrentFileIndex;
  final Value<String?> torrentMagnet;
  const DownloadableFilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fileName = const Value.absent(),
    this.consoleId = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.torrentFileIndex = const Value.absent(),
    this.torrentMagnet = const Value.absent(),
  });
  DownloadableFilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String fileName,
    required String consoleId,
    required String downloadUrl,
    this.fileSize = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.torrentFileIndex = const Value.absent(),
    this.torrentMagnet = const Value.absent(),
  }) : name = Value(name),
       fileName = Value(fileName),
       consoleId = Value(consoleId),
       downloadUrl = Value(downloadUrl);
  static Insertable<DownloadableFile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? fileName,
    Expression<String>? consoleId,
    Expression<String>? downloadUrl,
    Expression<int>? fileSize,
    Expression<String>? fileExtension,
    Expression<int>? torrentFileIndex,
    Expression<String>? torrentMagnet,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fileName != null) 'file_name': fileName,
      if (consoleId != null) 'console_id': consoleId,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (fileSize != null) 'file_size': fileSize,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (torrentFileIndex != null) 'torrent_file_index': torrentFileIndex,
      if (torrentMagnet != null) 'torrent_magnet': torrentMagnet,
    });
  }

  DownloadableFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? fileName,
    Value<String>? consoleId,
    Value<String>? downloadUrl,
    Value<int>? fileSize,
    Value<String>? fileExtension,
    Value<int?>? torrentFileIndex,
    Value<String?>? torrentMagnet,
  }) {
    return DownloadableFilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      consoleId: consoleId ?? this.consoleId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      torrentFileIndex: torrentFileIndex ?? this.torrentFileIndex,
      torrentMagnet: torrentMagnet ?? this.torrentMagnet,
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
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (consoleId.present) {
      map['console_id'] = Variable<String>(consoleId.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (torrentFileIndex.present) {
      map['torrent_file_index'] = Variable<int>(torrentFileIndex.value);
    }
    if (torrentMagnet.present) {
      map['torrent_magnet'] = Variable<String>(torrentMagnet.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadableFilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('consoleId: $consoleId, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('torrentFileIndex: $torrentFileIndex, ')
          ..write('torrentMagnet: $torrentMagnet')
          ..write(')'))
        .toString();
  }
}

class $FileTagsTable extends FileTags with TableInfo<$FileTagsTable, FileTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<int> fileId = GeneratedColumn<int>(
    'file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES downloadable_files (id) ON DELETE CASCADE',
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
  );
  @override
  List<GeneratedColumn> get $columns => [fileId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<FileTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fileIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {fileId, tag};
  @override
  FileTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileTag(
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $FileTagsTable createAlias(String alias) {
    return $FileTagsTable(attachedDatabase, alias);
  }
}

class FileTag extends DataClass implements Insertable<FileTag> {
  final int fileId;
  final String tag;
  const FileTag({required this.fileId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_id'] = Variable<int>(fileId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  FileTagsCompanion toCompanion(bool nullToAbsent) {
    return FileTagsCompanion(fileId: Value(fileId), tag: Value(tag));
  }

  factory FileTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileTag(
      fileId: serializer.fromJson<int>(json['fileId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileId': serializer.toJson<int>(fileId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  FileTag copyWith({int? fileId, String? tag}) =>
      FileTag(fileId: fileId ?? this.fileId, tag: tag ?? this.tag);
  FileTag copyWithCompanion(FileTagsCompanion data) {
    return FileTag(
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileTag(')
          ..write('fileId: $fileId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileTag &&
          other.fileId == this.fileId &&
          other.tag == this.tag);
}

class FileTagsCompanion extends UpdateCompanion<FileTag> {
  final Value<int> fileId;
  final Value<String> tag;
  final Value<int> rowid;
  const FileTagsCompanion({
    this.fileId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileTagsCompanion.insert({
    required int fileId,
    required String tag,
    this.rowid = const Value.absent(),
  }) : fileId = Value(fileId),
       tag = Value(tag);
  static Insertable<FileTag> custom({
    Expression<int>? fileId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileId != null) 'file_id': fileId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileTagsCompanion copyWith({
    Value<int>? fileId,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return FileTagsCompanion(
      fileId: fileId ?? this.fileId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileId.present) {
      map['file_id'] = Variable<int>(fileId.value);
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
    return (StringBuffer('FileTagsCompanion(')
          ..write('fileId: $fileId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _catalogFileIdMeta = const VerificationMeta(
    'catalogFileId',
  );
  @override
  late final GeneratedColumn<int> catalogFileId = GeneratedColumn<int>(
    'catalog_file_id',
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
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consoleIdMeta = const VerificationMeta(
    'consoleId',
  );
  @override
  late final GeneratedColumn<String> consoleId = GeneratedColumn<String>(
    'console_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consoleNameMeta = const VerificationMeta(
    'consoleName',
  );
  @override
  late final GeneratedColumn<String> consoleName = GeneratedColumn<String>(
    'console_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _downloadUrlMeta = const VerificationMeta(
    'downloadUrl',
  );
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
    'download_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fileExtensionMeta = const VerificationMeta(
    'fileExtension',
  );
  @override
  late final GeneratedColumn<String> fileExtension = GeneratedColumn<String>(
    'file_extension',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _torrentFileIndexMeta = const VerificationMeta(
    'torrentFileIndex',
  );
  @override
  late final GeneratedColumn<int> torrentFileIndex = GeneratedColumn<int>(
    'torrent_file_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _torrentMagnetMeta = const VerificationMeta(
    'torrentMagnet',
  );
  @override
  late final GeneratedColumn<String> torrentMagnet = GeneratedColumn<String>(
    'torrent_magnet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _destinationUriMeta = const VerificationMeta(
    'destinationUri',
  );
  @override
  late final GeneratedColumn<String> destinationUri = GeneratedColumn<String>(
    'destination_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _destinationLabelMeta = const VerificationMeta(
    'destinationLabel',
  );
  @override
  late final GeneratedColumn<String> destinationLabel = GeneratedColumn<String>(
    'destination_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _savedFileNameMeta = const VerificationMeta(
    'savedFileName',
  );
  @override
  late final GeneratedColumn<String> savedFileName = GeneratedColumn<String>(
    'saved_file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _failureReasonMeta = const VerificationMeta(
    'failureReason',
  );
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
    'failure_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stagingPathMeta = const VerificationMeta(
    'stagingPath',
  );
  @override
  late final GeneratedColumn<String> stagingPath = GeneratedColumn<String>(
    'staging_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    catalogFileId,
    name,
    fileName,
    consoleId,
    consoleName,
    downloadUrl,
    fileSize,
    fileExtension,
    torrentFileIndex,
    torrentMagnet,
    status,
    progress,
    downloadedBytes,
    destinationUri,
    destinationLabel,
    savedFileName,
    failureReason,
    stagingPath,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Download> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('catalog_file_id')) {
      context.handle(
        _catalogFileIdMeta,
        catalogFileId.isAcceptableOrUnknown(
          data['catalog_file_id']!,
          _catalogFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogFileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('console_id')) {
      context.handle(
        _consoleIdMeta,
        consoleId.isAcceptableOrUnknown(data['console_id']!, _consoleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_consoleIdMeta);
    }
    if (data.containsKey('console_name')) {
      context.handle(
        _consoleNameMeta,
        consoleName.isAcceptableOrUnknown(
          data['console_name']!,
          _consoleNameMeta,
        ),
      );
    }
    if (data.containsKey('download_url')) {
      context.handle(
        _downloadUrlMeta,
        downloadUrl.isAcceptableOrUnknown(
          data['download_url']!,
          _downloadUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadUrlMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('file_extension')) {
      context.handle(
        _fileExtensionMeta,
        fileExtension.isAcceptableOrUnknown(
          data['file_extension']!,
          _fileExtensionMeta,
        ),
      );
    }
    if (data.containsKey('torrent_file_index')) {
      context.handle(
        _torrentFileIndexMeta,
        torrentFileIndex.isAcceptableOrUnknown(
          data['torrent_file_index']!,
          _torrentFileIndexMeta,
        ),
      );
    }
    if (data.containsKey('torrent_magnet')) {
      context.handle(
        _torrentMagnetMeta,
        torrentMagnet.isAcceptableOrUnknown(
          data['torrent_magnet']!,
          _torrentMagnetMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('destination_uri')) {
      context.handle(
        _destinationUriMeta,
        destinationUri.isAcceptableOrUnknown(
          data['destination_uri']!,
          _destinationUriMeta,
        ),
      );
    }
    if (data.containsKey('destination_label')) {
      context.handle(
        _destinationLabelMeta,
        destinationLabel.isAcceptableOrUnknown(
          data['destination_label']!,
          _destinationLabelMeta,
        ),
      );
    }
    if (data.containsKey('saved_file_name')) {
      context.handle(
        _savedFileNameMeta,
        savedFileName.isAcceptableOrUnknown(
          data['saved_file_name']!,
          _savedFileNameMeta,
        ),
      );
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
        _failureReasonMeta,
        failureReason.isAcceptableOrUnknown(
          data['failure_reason']!,
          _failureReasonMeta,
        ),
      );
    }
    if (data.containsKey('staging_path')) {
      context.handle(
        _stagingPathMeta,
        stagingPath.isAcceptableOrUnknown(
          data['staging_path']!,
          _stagingPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      catalogFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_file_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      consoleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}console_id'],
      )!,
      consoleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}console_name'],
      )!,
      downloadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_url'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      fileExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_extension'],
      )!,
      torrentFileIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}torrent_file_index'],
      ),
      torrentMagnet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}torrent_magnet'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      destinationUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_uri'],
      )!,
      destinationLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_label'],
      )!,
      savedFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_file_name'],
      )!,
      failureReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_reason'],
      ),
      stagingPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staging_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final int id;

  /// The `DownloadableFiles.id` this download came from, at the time it
  /// started. Not unique and not a foreign key — see the class doc.
  final int catalogFileId;
  final String name;
  final String fileName;
  final String consoleId;
  final String consoleName;
  final String downloadUrl;
  final int fileSize;
  final String fileExtension;
  final int? torrentFileIndex;
  final String? torrentMagnet;

  /// `DownloadStatus.name`, stored as text so adding an enum value later
  /// doesn't renumber existing rows.
  final String status;
  final double progress;
  final int downloadedBytes;

  /// Where the file actually landed. [destinationUri] is the SAF document
  /// tree URI (opaque, for programmatic reopening); [destinationLabel] is the
  /// human-readable path shown in the Downloads screen — "can't see where it
  /// downloaded to" was a direct consequence of storing neither.
  final String destinationUri;
  final String destinationLabel;

  /// The name actually written at the destination, which differs from
  /// [fileName] whenever an archive was auto-extracted.
  final String savedFileName;

  /// Stable, non-sensitive failure reason (see `DownloadFailureReason`) —
  /// never the raw exception, which can carry a magnet/URL.
  final String? failureReason;

  /// Absolute path of the partially-downloaded staging file, so an
  /// interrupted HTTP download resumes from where it stopped instead of
  /// starting over.
  final String stagingPath;
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  const Download({
    required this.id,
    required this.catalogFileId,
    required this.name,
    required this.fileName,
    required this.consoleId,
    required this.consoleName,
    required this.downloadUrl,
    required this.fileSize,
    required this.fileExtension,
    this.torrentFileIndex,
    this.torrentMagnet,
    required this.status,
    required this.progress,
    required this.downloadedBytes,
    required this.destinationUri,
    required this.destinationLabel,
    required this.savedFileName,
    this.failureReason,
    required this.stagingPath,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['catalog_file_id'] = Variable<int>(catalogFileId);
    map['name'] = Variable<String>(name);
    map['file_name'] = Variable<String>(fileName);
    map['console_id'] = Variable<String>(consoleId);
    map['console_name'] = Variable<String>(consoleName);
    map['download_url'] = Variable<String>(downloadUrl);
    map['file_size'] = Variable<int>(fileSize);
    map['file_extension'] = Variable<String>(fileExtension);
    if (!nullToAbsent || torrentFileIndex != null) {
      map['torrent_file_index'] = Variable<int>(torrentFileIndex);
    }
    if (!nullToAbsent || torrentMagnet != null) {
      map['torrent_magnet'] = Variable<String>(torrentMagnet);
    }
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['destination_uri'] = Variable<String>(destinationUri);
    map['destination_label'] = Variable<String>(destinationLabel);
    map['saved_file_name'] = Variable<String>(savedFileName);
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    map['staging_path'] = Variable<String>(stagingPath);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      catalogFileId: Value(catalogFileId),
      name: Value(name),
      fileName: Value(fileName),
      consoleId: Value(consoleId),
      consoleName: Value(consoleName),
      downloadUrl: Value(downloadUrl),
      fileSize: Value(fileSize),
      fileExtension: Value(fileExtension),
      torrentFileIndex: torrentFileIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(torrentFileIndex),
      torrentMagnet: torrentMagnet == null && nullToAbsent
          ? const Value.absent()
          : Value(torrentMagnet),
      status: Value(status),
      progress: Value(progress),
      downloadedBytes: Value(downloadedBytes),
      destinationUri: Value(destinationUri),
      destinationLabel: Value(destinationLabel),
      savedFileName: Value(savedFileName),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      stagingPath: Value(stagingPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Download.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      id: serializer.fromJson<int>(json['id']),
      catalogFileId: serializer.fromJson<int>(json['catalogFileId']),
      name: serializer.fromJson<String>(json['name']),
      fileName: serializer.fromJson<String>(json['fileName']),
      consoleId: serializer.fromJson<String>(json['consoleId']),
      consoleName: serializer.fromJson<String>(json['consoleName']),
      downloadUrl: serializer.fromJson<String>(json['downloadUrl']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      fileExtension: serializer.fromJson<String>(json['fileExtension']),
      torrentFileIndex: serializer.fromJson<int?>(json['torrentFileIndex']),
      torrentMagnet: serializer.fromJson<String?>(json['torrentMagnet']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      destinationUri: serializer.fromJson<String>(json['destinationUri']),
      destinationLabel: serializer.fromJson<String>(json['destinationLabel']),
      savedFileName: serializer.fromJson<String>(json['savedFileName']),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      stagingPath: serializer.fromJson<String>(json['stagingPath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'catalogFileId': serializer.toJson<int>(catalogFileId),
      'name': serializer.toJson<String>(name),
      'fileName': serializer.toJson<String>(fileName),
      'consoleId': serializer.toJson<String>(consoleId),
      'consoleName': serializer.toJson<String>(consoleName),
      'downloadUrl': serializer.toJson<String>(downloadUrl),
      'fileSize': serializer.toJson<int>(fileSize),
      'fileExtension': serializer.toJson<String>(fileExtension),
      'torrentFileIndex': serializer.toJson<int?>(torrentFileIndex),
      'torrentMagnet': serializer.toJson<String?>(torrentMagnet),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'destinationUri': serializer.toJson<String>(destinationUri),
      'destinationLabel': serializer.toJson<String>(destinationLabel),
      'savedFileName': serializer.toJson<String>(savedFileName),
      'failureReason': serializer.toJson<String?>(failureReason),
      'stagingPath': serializer.toJson<String>(stagingPath),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  Download copyWith({
    int? id,
    int? catalogFileId,
    String? name,
    String? fileName,
    String? consoleId,
    String? consoleName,
    String? downloadUrl,
    int? fileSize,
    String? fileExtension,
    Value<int?> torrentFileIndex = const Value.absent(),
    Value<String?> torrentMagnet = const Value.absent(),
    String? status,
    double? progress,
    int? downloadedBytes,
    String? destinationUri,
    String? destinationLabel,
    String? savedFileName,
    Value<String?> failureReason = const Value.absent(),
    String? stagingPath,
    int? createdAt,
    int? updatedAt,
    Value<int?> completedAt = const Value.absent(),
  }) => Download(
    id: id ?? this.id,
    catalogFileId: catalogFileId ?? this.catalogFileId,
    name: name ?? this.name,
    fileName: fileName ?? this.fileName,
    consoleId: consoleId ?? this.consoleId,
    consoleName: consoleName ?? this.consoleName,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    fileSize: fileSize ?? this.fileSize,
    fileExtension: fileExtension ?? this.fileExtension,
    torrentFileIndex: torrentFileIndex.present
        ? torrentFileIndex.value
        : this.torrentFileIndex,
    torrentMagnet: torrentMagnet.present
        ? torrentMagnet.value
        : this.torrentMagnet,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    destinationUri: destinationUri ?? this.destinationUri,
    destinationLabel: destinationLabel ?? this.destinationLabel,
    savedFileName: savedFileName ?? this.savedFileName,
    failureReason: failureReason.present
        ? failureReason.value
        : this.failureReason,
    stagingPath: stagingPath ?? this.stagingPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      id: data.id.present ? data.id.value : this.id,
      catalogFileId: data.catalogFileId.present
          ? data.catalogFileId.value
          : this.catalogFileId,
      name: data.name.present ? data.name.value : this.name,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      consoleId: data.consoleId.present ? data.consoleId.value : this.consoleId,
      consoleName: data.consoleName.present
          ? data.consoleName.value
          : this.consoleName,
      downloadUrl: data.downloadUrl.present
          ? data.downloadUrl.value
          : this.downloadUrl,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileExtension: data.fileExtension.present
          ? data.fileExtension.value
          : this.fileExtension,
      torrentFileIndex: data.torrentFileIndex.present
          ? data.torrentFileIndex.value
          : this.torrentFileIndex,
      torrentMagnet: data.torrentMagnet.present
          ? data.torrentMagnet.value
          : this.torrentMagnet,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      destinationUri: data.destinationUri.present
          ? data.destinationUri.value
          : this.destinationUri,
      destinationLabel: data.destinationLabel.present
          ? data.destinationLabel.value
          : this.destinationLabel,
      savedFileName: data.savedFileName.present
          ? data.savedFileName.value
          : this.savedFileName,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      stagingPath: data.stagingPath.present
          ? data.stagingPath.value
          : this.stagingPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('catalogFileId: $catalogFileId, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('consoleId: $consoleId, ')
          ..write('consoleName: $consoleName, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('torrentFileIndex: $torrentFileIndex, ')
          ..write('torrentMagnet: $torrentMagnet, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('destinationUri: $destinationUri, ')
          ..write('destinationLabel: $destinationLabel, ')
          ..write('savedFileName: $savedFileName, ')
          ..write('failureReason: $failureReason, ')
          ..write('stagingPath: $stagingPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    catalogFileId,
    name,
    fileName,
    consoleId,
    consoleName,
    downloadUrl,
    fileSize,
    fileExtension,
    torrentFileIndex,
    torrentMagnet,
    status,
    progress,
    downloadedBytes,
    destinationUri,
    destinationLabel,
    savedFileName,
    failureReason,
    stagingPath,
    createdAt,
    updatedAt,
    completedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.catalogFileId == this.catalogFileId &&
          other.name == this.name &&
          other.fileName == this.fileName &&
          other.consoleId == this.consoleId &&
          other.consoleName == this.consoleName &&
          other.downloadUrl == this.downloadUrl &&
          other.fileSize == this.fileSize &&
          other.fileExtension == this.fileExtension &&
          other.torrentFileIndex == this.torrentFileIndex &&
          other.torrentMagnet == this.torrentMagnet &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.downloadedBytes == this.downloadedBytes &&
          other.destinationUri == this.destinationUri &&
          other.destinationLabel == this.destinationLabel &&
          other.savedFileName == this.savedFileName &&
          other.failureReason == this.failureReason &&
          other.stagingPath == this.stagingPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<int> id;
  final Value<int> catalogFileId;
  final Value<String> name;
  final Value<String> fileName;
  final Value<String> consoleId;
  final Value<String> consoleName;
  final Value<String> downloadUrl;
  final Value<int> fileSize;
  final Value<String> fileExtension;
  final Value<int?> torrentFileIndex;
  final Value<String?> torrentMagnet;
  final Value<String> status;
  final Value<double> progress;
  final Value<int> downloadedBytes;
  final Value<String> destinationUri;
  final Value<String> destinationLabel;
  final Value<String> savedFileName;
  final Value<String?> failureReason;
  final Value<String> stagingPath;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> completedAt;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.catalogFileId = const Value.absent(),
    this.name = const Value.absent(),
    this.fileName = const Value.absent(),
    this.consoleId = const Value.absent(),
    this.consoleName = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.torrentFileIndex = const Value.absent(),
    this.torrentMagnet = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.destinationUri = const Value.absent(),
    this.destinationLabel = const Value.absent(),
    this.savedFileName = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.stagingPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required int catalogFileId,
    required String name,
    required String fileName,
    required String consoleId,
    this.consoleName = const Value.absent(),
    required String downloadUrl,
    this.fileSize = const Value.absent(),
    this.fileExtension = const Value.absent(),
    this.torrentFileIndex = const Value.absent(),
    this.torrentMagnet = const Value.absent(),
    required String status,
    this.progress = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.destinationUri = const Value.absent(),
    this.destinationLabel = const Value.absent(),
    this.savedFileName = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.stagingPath = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.completedAt = const Value.absent(),
  }) : catalogFileId = Value(catalogFileId),
       name = Value(name),
       fileName = Value(fileName),
       consoleId = Value(consoleId),
       downloadUrl = Value(downloadUrl),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Download> custom({
    Expression<int>? id,
    Expression<int>? catalogFileId,
    Expression<String>? name,
    Expression<String>? fileName,
    Expression<String>? consoleId,
    Expression<String>? consoleName,
    Expression<String>? downloadUrl,
    Expression<int>? fileSize,
    Expression<String>? fileExtension,
    Expression<int>? torrentFileIndex,
    Expression<String>? torrentMagnet,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? downloadedBytes,
    Expression<String>? destinationUri,
    Expression<String>? destinationLabel,
    Expression<String>? savedFileName,
    Expression<String>? failureReason,
    Expression<String>? stagingPath,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (catalogFileId != null) 'catalog_file_id': catalogFileId,
      if (name != null) 'name': name,
      if (fileName != null) 'file_name': fileName,
      if (consoleId != null) 'console_id': consoleId,
      if (consoleName != null) 'console_name': consoleName,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (fileSize != null) 'file_size': fileSize,
      if (fileExtension != null) 'file_extension': fileExtension,
      if (torrentFileIndex != null) 'torrent_file_index': torrentFileIndex,
      if (torrentMagnet != null) 'torrent_magnet': torrentMagnet,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (destinationUri != null) 'destination_uri': destinationUri,
      if (destinationLabel != null) 'destination_label': destinationLabel,
      if (savedFileName != null) 'saved_file_name': savedFileName,
      if (failureReason != null) 'failure_reason': failureReason,
      if (stagingPath != null) 'staging_path': stagingPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadsCompanion copyWith({
    Value<int>? id,
    Value<int>? catalogFileId,
    Value<String>? name,
    Value<String>? fileName,
    Value<String>? consoleId,
    Value<String>? consoleName,
    Value<String>? downloadUrl,
    Value<int>? fileSize,
    Value<String>? fileExtension,
    Value<int?>? torrentFileIndex,
    Value<String?>? torrentMagnet,
    Value<String>? status,
    Value<double>? progress,
    Value<int>? downloadedBytes,
    Value<String>? destinationUri,
    Value<String>? destinationLabel,
    Value<String>? savedFileName,
    Value<String?>? failureReason,
    Value<String>? stagingPath,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? completedAt,
  }) {
    return DownloadsCompanion(
      id: id ?? this.id,
      catalogFileId: catalogFileId ?? this.catalogFileId,
      name: name ?? this.name,
      fileName: fileName ?? this.fileName,
      consoleId: consoleId ?? this.consoleId,
      consoleName: consoleName ?? this.consoleName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      torrentFileIndex: torrentFileIndex ?? this.torrentFileIndex,
      torrentMagnet: torrentMagnet ?? this.torrentMagnet,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      destinationUri: destinationUri ?? this.destinationUri,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      savedFileName: savedFileName ?? this.savedFileName,
      failureReason: failureReason ?? this.failureReason,
      stagingPath: stagingPath ?? this.stagingPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (catalogFileId.present) {
      map['catalog_file_id'] = Variable<int>(catalogFileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (consoleId.present) {
      map['console_id'] = Variable<String>(consoleId.value);
    }
    if (consoleName.present) {
      map['console_name'] = Variable<String>(consoleName.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileExtension.present) {
      map['file_extension'] = Variable<String>(fileExtension.value);
    }
    if (torrentFileIndex.present) {
      map['torrent_file_index'] = Variable<int>(torrentFileIndex.value);
    }
    if (torrentMagnet.present) {
      map['torrent_magnet'] = Variable<String>(torrentMagnet.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (destinationUri.present) {
      map['destination_uri'] = Variable<String>(destinationUri.value);
    }
    if (destinationLabel.present) {
      map['destination_label'] = Variable<String>(destinationLabel.value);
    }
    if (savedFileName.present) {
      map['saved_file_name'] = Variable<String>(savedFileName.value);
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (stagingPath.present) {
      map['staging_path'] = Variable<String>(stagingPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('catalogFileId: $catalogFileId, ')
          ..write('name: $name, ')
          ..write('fileName: $fileName, ')
          ..write('consoleId: $consoleId, ')
          ..write('consoleName: $consoleName, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileExtension: $fileExtension, ')
          ..write('torrentFileIndex: $torrentFileIndex, ')
          ..write('torrentMagnet: $torrentMagnet, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('destinationUri: $destinationUri, ')
          ..write('destinationLabel: $destinationLabel, ')
          ..write('savedFileName: $savedFileName, ')
          ..write('failureReason: $failureReason, ')
          ..write('stagingPath: $stagingPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ManufacturersTable manufacturers = $ManufacturersTable(this);
  late final $ConsolesTable consoles = $ConsolesTable(this);
  late final $DownloadableFilesTable downloadableFiles =
      $DownloadableFilesTable(this);
  late final $FileTagsTable fileTags = $FileTagsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    manufacturers,
    consoles,
    downloadableFiles,
    fileTags,
    downloads,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'manufacturers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('consoles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'consoles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('downloadable_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'downloadable_files',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('file_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ManufacturersTableCreateCompanionBuilder =
    ManufacturersCompanion Function({
      required String id,
      required String name,
      Value<int> rowid,
    });
typedef $$ManufacturersTableUpdateCompanionBuilder =
    ManufacturersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rowid,
    });

final class $$ManufacturersTableReferences
    extends BaseReferences<_$AppDatabase, $ManufacturersTable, Manufacturer> {
  $$ManufacturersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ConsolesTable, List<Console>> _consolesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.consoles,
    aliasName: 'manufacturers__id__consoles__manufacturer_id',
  );

  $$ConsolesTableProcessedTableManager get consolesRefs {
    final manager = $$ConsolesTableTableManager(
      $_db,
      $_db.consoles,
    ).filter((f) => f.manufacturerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_consolesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ManufacturersTableFilterComposer
    extends Composer<_$AppDatabase, $ManufacturersTable> {
  $$ManufacturersTableFilterComposer({
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

  Expression<bool> consolesRefs(
    Expression<bool> Function($$ConsolesTableFilterComposer f) f,
  ) {
    final $$ConsolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consoles,
      getReferencedColumn: (t) => t.manufacturerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsolesTableFilterComposer(
            $db: $db,
            $table: $db.consoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ManufacturersTableOrderingComposer
    extends Composer<_$AppDatabase, $ManufacturersTable> {
  $$ManufacturersTableOrderingComposer({
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
}

class $$ManufacturersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManufacturersTable> {
  $$ManufacturersTableAnnotationComposer({
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

  Expression<T> consolesRefs<T extends Object>(
    Expression<T> Function($$ConsolesTableAnnotationComposer a) f,
  ) {
    final $$ConsolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consoles,
      getReferencedColumn: (t) => t.manufacturerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsolesTableAnnotationComposer(
            $db: $db,
            $table: $db.consoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ManufacturersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManufacturersTable,
          Manufacturer,
          $$ManufacturersTableFilterComposer,
          $$ManufacturersTableOrderingComposer,
          $$ManufacturersTableAnnotationComposer,
          $$ManufacturersTableCreateCompanionBuilder,
          $$ManufacturersTableUpdateCompanionBuilder,
          (Manufacturer, $$ManufacturersTableReferences),
          Manufacturer,
          PrefetchHooks Function({bool consolesRefs})
        > {
  $$ManufacturersTableTableManager(_$AppDatabase db, $ManufacturersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManufacturersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManufacturersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManufacturersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManufacturersCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => ManufacturersCompanion.insert(
                id: id,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ManufacturersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({consolesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (consolesRefs) db.consoles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (consolesRefs)
                    await $_getPrefetchedData<
                      Manufacturer,
                      $ManufacturersTable,
                      Console
                    >(
                      currentTable: table,
                      referencedTable: $$ManufacturersTableReferences
                          ._consolesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ManufacturersTableReferences(
                            db,
                            table,
                            p0,
                          ).consolesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.manufacturerId == item.id,
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

typedef $$ManufacturersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManufacturersTable,
      Manufacturer,
      $$ManufacturersTableFilterComposer,
      $$ManufacturersTableOrderingComposer,
      $$ManufacturersTableAnnotationComposer,
      $$ManufacturersTableCreateCompanionBuilder,
      $$ManufacturersTableUpdateCompanionBuilder,
      (Manufacturer, $$ManufacturersTableReferences),
      Manufacturer,
      PrefetchHooks Function({bool consolesRefs})
    >;
typedef $$ConsolesTableCreateCompanionBuilder =
    ConsolesCompanion Function({
      required String id,
      required String name,
      required String manufacturerId,
      required String urlsJson,
      Value<int> rowid,
    });
typedef $$ConsolesTableUpdateCompanionBuilder =
    ConsolesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> manufacturerId,
      Value<String> urlsJson,
      Value<int> rowid,
    });

final class $$ConsolesTableReferences
    extends BaseReferences<_$AppDatabase, $ConsolesTable, Console> {
  $$ConsolesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ManufacturersTable _manufacturerIdTable(_$AppDatabase db) => db
      .manufacturers
      .createAlias('consoles__manufacturer_id__manufacturers__id');

  $$ManufacturersTableProcessedTableManager get manufacturerId {
    final $_column = $_itemColumn<String>('manufacturer_id')!;

    final manager = $$ManufacturersTableTableManager(
      $_db,
      $_db.manufacturers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_manufacturerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DownloadableFilesTable, List<DownloadableFile>>
  _downloadableFilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.downloadableFiles,
        aliasName: 'consoles__id__downloadable_files__console_id',
      );

  $$DownloadableFilesTableProcessedTableManager get downloadableFilesRefs {
    final manager = $$DownloadableFilesTableTableManager(
      $_db,
      $_db.downloadableFiles,
    ).filter((f) => f.consoleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _downloadableFilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConsolesTableFilterComposer
    extends Composer<_$AppDatabase, $ConsolesTable> {
  $$ConsolesTableFilterComposer({
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

  ColumnFilters<String> get urlsJson => $composableBuilder(
    column: $table.urlsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$ManufacturersTableFilterComposer get manufacturerId {
    final $$ManufacturersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manufacturerId,
      referencedTable: $db.manufacturers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManufacturersTableFilterComposer(
            $db: $db,
            $table: $db.manufacturers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> downloadableFilesRefs(
    Expression<bool> Function($$DownloadableFilesTableFilterComposer f) f,
  ) {
    final $$DownloadableFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadableFiles,
      getReferencedColumn: (t) => t.consoleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadableFilesTableFilterComposer(
            $db: $db,
            $table: $db.downloadableFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConsolesTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsolesTable> {
  $$ConsolesTableOrderingComposer({
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

  ColumnOrderings<String> get urlsJson => $composableBuilder(
    column: $table.urlsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$ManufacturersTableOrderingComposer get manufacturerId {
    final $$ManufacturersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manufacturerId,
      referencedTable: $db.manufacturers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManufacturersTableOrderingComposer(
            $db: $db,
            $table: $db.manufacturers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsolesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsolesTable> {
  $$ConsolesTableAnnotationComposer({
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

  GeneratedColumn<String> get urlsJson =>
      $composableBuilder(column: $table.urlsJson, builder: (column) => column);

  $$ManufacturersTableAnnotationComposer get manufacturerId {
    final $$ManufacturersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.manufacturerId,
      referencedTable: $db.manufacturers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ManufacturersTableAnnotationComposer(
            $db: $db,
            $table: $db.manufacturers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> downloadableFilesRefs<T extends Object>(
    Expression<T> Function($$DownloadableFilesTableAnnotationComposer a) f,
  ) {
    final $$DownloadableFilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.downloadableFiles,
          getReferencedColumn: (t) => t.consoleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DownloadableFilesTableAnnotationComposer(
                $db: $db,
                $table: $db.downloadableFiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$ConsolesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsolesTable,
          Console,
          $$ConsolesTableFilterComposer,
          $$ConsolesTableOrderingComposer,
          $$ConsolesTableAnnotationComposer,
          $$ConsolesTableCreateCompanionBuilder,
          $$ConsolesTableUpdateCompanionBuilder,
          (Console, $$ConsolesTableReferences),
          Console,
          PrefetchHooks Function({
            bool manufacturerId,
            bool downloadableFilesRefs,
          })
        > {
  $$ConsolesTableTableManager(_$AppDatabase db, $ConsolesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsolesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsolesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsolesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> manufacturerId = const Value.absent(),
                Value<String> urlsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsolesCompanion(
                id: id,
                name: name,
                manufacturerId: manufacturerId,
                urlsJson: urlsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String manufacturerId,
                required String urlsJson,
                Value<int> rowid = const Value.absent(),
              }) => ConsolesCompanion.insert(
                id: id,
                name: name,
                manufacturerId: manufacturerId,
                urlsJson: urlsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConsolesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({manufacturerId = false, downloadableFilesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (downloadableFilesRefs) db.downloadableFiles,
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
                        if (manufacturerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.manufacturerId,
                                    referencedTable: $$ConsolesTableReferences
                                        ._manufacturerIdTable(db),
                                    referencedColumn: $$ConsolesTableReferences
                                        ._manufacturerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (downloadableFilesRefs)
                        await $_getPrefetchedData<
                          Console,
                          $ConsolesTable,
                          DownloadableFile
                        >(
                          currentTable: table,
                          referencedTable: $$ConsolesTableReferences
                              ._downloadableFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConsolesTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadableFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.consoleId == item.id,
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

typedef $$ConsolesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsolesTable,
      Console,
      $$ConsolesTableFilterComposer,
      $$ConsolesTableOrderingComposer,
      $$ConsolesTableAnnotationComposer,
      $$ConsolesTableCreateCompanionBuilder,
      $$ConsolesTableUpdateCompanionBuilder,
      (Console, $$ConsolesTableReferences),
      Console,
      PrefetchHooks Function({bool manufacturerId, bool downloadableFilesRefs})
    >;
typedef $$DownloadableFilesTableCreateCompanionBuilder =
    DownloadableFilesCompanion Function({
      Value<int> id,
      required String name,
      required String fileName,
      required String consoleId,
      required String downloadUrl,
      Value<int> fileSize,
      Value<String> fileExtension,
      Value<int?> torrentFileIndex,
      Value<String?> torrentMagnet,
    });
typedef $$DownloadableFilesTableUpdateCompanionBuilder =
    DownloadableFilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> fileName,
      Value<String> consoleId,
      Value<String> downloadUrl,
      Value<int> fileSize,
      Value<String> fileExtension,
      Value<int?> torrentFileIndex,
      Value<String?> torrentMagnet,
    });

final class $$DownloadableFilesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DownloadableFilesTable,
          DownloadableFile
        > {
  $$DownloadableFilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ConsolesTable _consoleIdTable(_$AppDatabase db) =>
      db.consoles.createAlias('downloadable_files__console_id__consoles__id');

  $$ConsolesTableProcessedTableManager get consoleId {
    final $_column = $_itemColumn<String>('console_id')!;

    final manager = $$ConsolesTableTableManager(
      $_db,
      $_db.consoles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_consoleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FileTagsTable, List<FileTag>> _fileTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.fileTags,
    aliasName: 'downloadable_files__id__file_tags__file_id',
  );

  $$FileTagsTableProcessedTableManager get fileTagsRefs {
    final manager = $$FileTagsTableTableManager(
      $_db,
      $_db.fileTags,
    ).filter((f) => f.fileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fileTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DownloadableFilesTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadableFilesTable> {
  $$DownloadableFilesTableFilterComposer({
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

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => ColumnFilters(column),
  );

  $$ConsolesTableFilterComposer get consoleId {
    final $$ConsolesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consoleId,
      referencedTable: $db.consoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsolesTableFilterComposer(
            $db: $db,
            $table: $db.consoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> fileTagsRefs(
    Expression<bool> Function($$FileTagsTableFilterComposer f) f,
  ) {
    final $$FileTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileTags,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileTagsTableFilterComposer(
            $db: $db,
            $table: $db.fileTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadableFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadableFilesTable> {
  $$DownloadableFilesTableOrderingComposer({
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

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConsolesTableOrderingComposer get consoleId {
    final $$ConsolesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consoleId,
      referencedTable: $db.consoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsolesTableOrderingComposer(
            $db: $db,
            $table: $db.consoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadableFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadableFilesTable> {
  $$DownloadableFilesTableAnnotationComposer({
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

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => column,
  );

  $$ConsolesTableAnnotationComposer get consoleId {
    final $$ConsolesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.consoleId,
      referencedTable: $db.consoles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsolesTableAnnotationComposer(
            $db: $db,
            $table: $db.consoles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> fileTagsRefs<T extends Object>(
    Expression<T> Function($$FileTagsTableAnnotationComposer a) f,
  ) {
    final $$FileTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fileTags,
      getReferencedColumn: (t) => t.fileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FileTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.fileTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadableFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadableFilesTable,
          DownloadableFile,
          $$DownloadableFilesTableFilterComposer,
          $$DownloadableFilesTableOrderingComposer,
          $$DownloadableFilesTableAnnotationComposer,
          $$DownloadableFilesTableCreateCompanionBuilder,
          $$DownloadableFilesTableUpdateCompanionBuilder,
          (DownloadableFile, $$DownloadableFilesTableReferences),
          DownloadableFile,
          PrefetchHooks Function({bool consoleId, bool fileTagsRefs})
        > {
  $$DownloadableFilesTableTableManager(
    _$AppDatabase db,
    $DownloadableFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadableFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadableFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadableFilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> consoleId = const Value.absent(),
                Value<String> downloadUrl = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<int?> torrentFileIndex = const Value.absent(),
                Value<String?> torrentMagnet = const Value.absent(),
              }) => DownloadableFilesCompanion(
                id: id,
                name: name,
                fileName: fileName,
                consoleId: consoleId,
                downloadUrl: downloadUrl,
                fileSize: fileSize,
                fileExtension: fileExtension,
                torrentFileIndex: torrentFileIndex,
                torrentMagnet: torrentMagnet,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String fileName,
                required String consoleId,
                required String downloadUrl,
                Value<int> fileSize = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<int?> torrentFileIndex = const Value.absent(),
                Value<String?> torrentMagnet = const Value.absent(),
              }) => DownloadableFilesCompanion.insert(
                id: id,
                name: name,
                fileName: fileName,
                consoleId: consoleId,
                downloadUrl: downloadUrl,
                fileSize: fileSize,
                fileExtension: fileExtension,
                torrentFileIndex: torrentFileIndex,
                torrentMagnet: torrentMagnet,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadableFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({consoleId = false, fileTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (fileTagsRefs) db.fileTags],
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
                    if (consoleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.consoleId,
                                referencedTable:
                                    $$DownloadableFilesTableReferences
                                        ._consoleIdTable(db),
                                referencedColumn:
                                    $$DownloadableFilesTableReferences
                                        ._consoleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fileTagsRefs)
                    await $_getPrefetchedData<
                      DownloadableFile,
                      $DownloadableFilesTable,
                      FileTag
                    >(
                      currentTable: table,
                      referencedTable: $$DownloadableFilesTableReferences
                          ._fileTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DownloadableFilesTableReferences(
                            db,
                            table,
                            p0,
                          ).fileTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.fileId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DownloadableFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadableFilesTable,
      DownloadableFile,
      $$DownloadableFilesTableFilterComposer,
      $$DownloadableFilesTableOrderingComposer,
      $$DownloadableFilesTableAnnotationComposer,
      $$DownloadableFilesTableCreateCompanionBuilder,
      $$DownloadableFilesTableUpdateCompanionBuilder,
      (DownloadableFile, $$DownloadableFilesTableReferences),
      DownloadableFile,
      PrefetchHooks Function({bool consoleId, bool fileTagsRefs})
    >;
typedef $$FileTagsTableCreateCompanionBuilder =
    FileTagsCompanion Function({
      required int fileId,
      required String tag,
      Value<int> rowid,
    });
typedef $$FileTagsTableUpdateCompanionBuilder =
    FileTagsCompanion Function({
      Value<int> fileId,
      Value<String> tag,
      Value<int> rowid,
    });

final class $$FileTagsTableReferences
    extends BaseReferences<_$AppDatabase, $FileTagsTable, FileTag> {
  $$FileTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DownloadableFilesTable _fileIdTable(_$AppDatabase db) => db
      .downloadableFiles
      .createAlias('file_tags__file_id__downloadable_files__id');

  $$DownloadableFilesTableProcessedTableManager get fileId {
    final $_column = $_itemColumn<int>('file_id')!;

    final manager = $$DownloadableFilesTableTableManager(
      $_db,
      $_db.downloadableFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FileTagsTableFilterComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  $$DownloadableFilesTableFilterComposer get fileId {
    final $$DownloadableFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.downloadableFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadableFilesTableFilterComposer(
            $db: $db,
            $table: $db.downloadableFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  $$DownloadableFilesTableOrderingComposer get fileId {
    final $$DownloadableFilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fileId,
      referencedTable: $db.downloadableFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadableFilesTableOrderingComposer(
            $db: $db,
            $table: $db.downloadableFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FileTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileTagsTable> {
  $$FileTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$DownloadableFilesTableAnnotationComposer get fileId {
    final $$DownloadableFilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.fileId,
          referencedTable: $db.downloadableFiles,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DownloadableFilesTableAnnotationComposer(
                $db: $db,
                $table: $db.downloadableFiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$FileTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FileTagsTable,
          FileTag,
          $$FileTagsTableFilterComposer,
          $$FileTagsTableOrderingComposer,
          $$FileTagsTableAnnotationComposer,
          $$FileTagsTableCreateCompanionBuilder,
          $$FileTagsTableUpdateCompanionBuilder,
          (FileTag, $$FileTagsTableReferences),
          FileTag,
          PrefetchHooks Function({bool fileId})
        > {
  $$FileTagsTableTableManager(_$AppDatabase db, $FileTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> fileId = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FileTagsCompanion(fileId: fileId, tag: tag, rowid: rowid),
          createCompanionCallback:
              ({
                required int fileId,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => FileTagsCompanion.insert(
                fileId: fileId,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FileTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fileId = false}) {
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
                    if (fileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fileId,
                                referencedTable: $$FileTagsTableReferences
                                    ._fileIdTable(db),
                                referencedColumn: $$FileTagsTableReferences
                                    ._fileIdTable(db)
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

typedef $$FileTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FileTagsTable,
      FileTag,
      $$FileTagsTableFilterComposer,
      $$FileTagsTableOrderingComposer,
      $$FileTagsTableAnnotationComposer,
      $$FileTagsTableCreateCompanionBuilder,
      $$FileTagsTableUpdateCompanionBuilder,
      (FileTag, $$FileTagsTableReferences),
      FileTag,
      PrefetchHooks Function({bool fileId})
    >;
typedef $$DownloadsTableCreateCompanionBuilder =
    DownloadsCompanion Function({
      Value<int> id,
      required int catalogFileId,
      required String name,
      required String fileName,
      required String consoleId,
      Value<String> consoleName,
      required String downloadUrl,
      Value<int> fileSize,
      Value<String> fileExtension,
      Value<int?> torrentFileIndex,
      Value<String?> torrentMagnet,
      required String status,
      Value<double> progress,
      Value<int> downloadedBytes,
      Value<String> destinationUri,
      Value<String> destinationLabel,
      Value<String> savedFileName,
      Value<String?> failureReason,
      Value<String> stagingPath,
      required int createdAt,
      required int updatedAt,
      Value<int?> completedAt,
    });
typedef $$DownloadsTableUpdateCompanionBuilder =
    DownloadsCompanion Function({
      Value<int> id,
      Value<int> catalogFileId,
      Value<String> name,
      Value<String> fileName,
      Value<String> consoleId,
      Value<String> consoleName,
      Value<String> downloadUrl,
      Value<int> fileSize,
      Value<String> fileExtension,
      Value<int?> torrentFileIndex,
      Value<String?> torrentMagnet,
      Value<String> status,
      Value<double> progress,
      Value<int> downloadedBytes,
      Value<String> destinationUri,
      Value<String> destinationLabel,
      Value<String> savedFileName,
      Value<String?> failureReason,
      Value<String> stagingPath,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int?> completedAt,
    });

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
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

  ColumnFilters<int> get catalogFileId => $composableBuilder(
    column: $table.catalogFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consoleId => $composableBuilder(
    column: $table.consoleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consoleName => $composableBuilder(
    column: $table.consoleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationUri => $composableBuilder(
    column: $table.destinationUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationLabel => $composableBuilder(
    column: $table.destinationLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedFileName => $composableBuilder(
    column: $table.savedFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stagingPath => $composableBuilder(
    column: $table.stagingPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
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

  ColumnOrderings<int> get catalogFileId => $composableBuilder(
    column: $table.catalogFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consoleId => $composableBuilder(
    column: $table.consoleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consoleName => $composableBuilder(
    column: $table.consoleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationUri => $composableBuilder(
    column: $table.destinationUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationLabel => $composableBuilder(
    column: $table.destinationLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedFileName => $composableBuilder(
    column: $table.savedFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stagingPath => $composableBuilder(
    column: $table.stagingPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get catalogFileId => $composableBuilder(
    column: $table.catalogFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get consoleId =>
      $composableBuilder(column: $table.consoleId, builder: (column) => column);

  GeneratedColumn<String> get consoleName => $composableBuilder(
    column: $table.consoleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileExtension => $composableBuilder(
    column: $table.fileExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get torrentFileIndex => $composableBuilder(
    column: $table.torrentFileIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get torrentMagnet => $composableBuilder(
    column: $table.torrentMagnet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationUri => $composableBuilder(
    column: $table.destinationUri,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationLabel => $composableBuilder(
    column: $table.destinationLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get savedFileName => $composableBuilder(
    column: $table.savedFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureReason => $composableBuilder(
    column: $table.failureReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stagingPath => $composableBuilder(
    column: $table.stagingPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
          Download,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> catalogFileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> consoleId = const Value.absent(),
                Value<String> consoleName = const Value.absent(),
                Value<String> downloadUrl = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<int?> torrentFileIndex = const Value.absent(),
                Value<String?> torrentMagnet = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String> destinationUri = const Value.absent(),
                Value<String> destinationLabel = const Value.absent(),
                Value<String> savedFileName = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<String> stagingPath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
              }) => DownloadsCompanion(
                id: id,
                catalogFileId: catalogFileId,
                name: name,
                fileName: fileName,
                consoleId: consoleId,
                consoleName: consoleName,
                downloadUrl: downloadUrl,
                fileSize: fileSize,
                fileExtension: fileExtension,
                torrentFileIndex: torrentFileIndex,
                torrentMagnet: torrentMagnet,
                status: status,
                progress: progress,
                downloadedBytes: downloadedBytes,
                destinationUri: destinationUri,
                destinationLabel: destinationLabel,
                savedFileName: savedFileName,
                failureReason: failureReason,
                stagingPath: stagingPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int catalogFileId,
                required String name,
                required String fileName,
                required String consoleId,
                Value<String> consoleName = const Value.absent(),
                required String downloadUrl,
                Value<int> fileSize = const Value.absent(),
                Value<String> fileExtension = const Value.absent(),
                Value<int?> torrentFileIndex = const Value.absent(),
                Value<String?> torrentMagnet = const Value.absent(),
                required String status,
                Value<double> progress = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String> destinationUri = const Value.absent(),
                Value<String> destinationLabel = const Value.absent(),
                Value<String> savedFileName = const Value.absent(),
                Value<String?> failureReason = const Value.absent(),
                Value<String> stagingPath = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> completedAt = const Value.absent(),
              }) => DownloadsCompanion.insert(
                id: id,
                catalogFileId: catalogFileId,
                name: name,
                fileName: fileName,
                consoleId: consoleId,
                consoleName: consoleName,
                downloadUrl: downloadUrl,
                fileSize: fileSize,
                fileExtension: fileExtension,
                torrentFileIndex: torrentFileIndex,
                torrentMagnet: torrentMagnet,
                status: status,
                progress: progress,
                downloadedBytes: downloadedBytes,
                destinationUri: destinationUri,
                destinationLabel: destinationLabel,
                savedFileName: savedFileName,
                failureReason: failureReason,
                stagingPath: stagingPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
      Download,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ManufacturersTableTableManager get manufacturers =>
      $$ManufacturersTableTableManager(_db, _db.manufacturers);
  $$ConsolesTableTableManager get consoles =>
      $$ConsolesTableTableManager(_db, _db.consoles);
  $$DownloadableFilesTableTableManager get downloadableFiles =>
      $$DownloadableFilesTableTableManager(_db, _db.downloadableFiles);
  $$FileTagsTableTableManager get fileTags =>
      $$FileTagsTableTableManager(_db, _db.fileTags);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
