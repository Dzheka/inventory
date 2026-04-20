import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

// ──────────────────────────── Tables ────────────────────────────

class LocalAssets extends Table {
  TextColumn get id => text()();
  TextColumn get inventoryNumber => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get departmentId => integer().nullable()();
  IntColumn get roomId => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get inventoryStatus =>
      text().withDefault(const Constant('not_scanned'))();
  TextColumn get oneCId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastScannedAt => dateTime().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalZones extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalRooms extends Table {
  IntColumn get id => integer()();
  IntColumn get zoneId => integer().nullable()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  IntColumn get floor => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalDepartments extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalAssetCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get assetType => text()();
  IntColumn get parentId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueEntries extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text().nullable()(); // JSON string
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending | failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ──────────────────────────── Database ────────────────────────────

@DriftDatabase(tables: [
  LocalAssets,
  LocalZones,
  LocalRooms,
  LocalDepartments,
  LocalAssetCategories,
  SyncQueueEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Assets
  Future<List<LocalAsset>> getAllAssets() => select(localAssets).get();

  Future<LocalAsset?> getAssetByBarcode(String barcode) =>
      (select(localAssets)..where((t) => t.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<LocalAsset?> getAssetByInventoryNumber(String invNum) =>
      (select(localAssets)..where((t) => t.inventoryNumber.equals(invNum)))
          .getSingleOrNull();

  Future<void> upsertAsset(LocalAssetsCompanion asset) =>
      into(localAssets).insertOnConflictUpdate(asset);

  Future<void> markAssetScanned(String id, String status) =>
      (update(localAssets)..where((t) => t.id.equals(id))).write(
        LocalAssetsCompanion(
          inventoryStatus: Value(status),
          lastScannedAt: Value(DateTime.now()),
          isDirty: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // Sync queue
  Future<List<SyncQueueEntry>> getPendingSyncEntries() =>
      (select(syncQueueEntries)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<void> enqueueSyncEntry(SyncQueueEntriesCompanion entry) =>
      into(syncQueueEntries).insert(entry);

  Future<void> markSyncEntryProcessed(String id) =>
      (delete(syncQueueEntries)..where((t) => t.id.equals(id))).go();

  Future<void> markSyncEntryFailed(String id, String error, int retryCount) =>
      (update(syncQueueEntries)..where((t) => t.id.equals(id))).write(
        SyncQueueEntriesCompanion(
          status: const Value('failed'),
          errorMessage: Value(error),
          retryCount: Value(retryCount),
        ),
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'inventory.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
