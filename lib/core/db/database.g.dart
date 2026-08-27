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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ManufacturersTable manufacturers = $ManufacturersTable(this);
  late final $ConsolesTable consoles = $ConsolesTable(this);
  late final $DownloadableFilesTable downloadableFiles =
      $DownloadableFilesTable(this);
  late final $FileTagsTable fileTags = $FileTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    manufacturers,
    consoles,
    downloadableFiles,
    fileTags,
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
}
