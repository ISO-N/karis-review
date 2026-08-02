import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class LocalSettings extends Table {
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get refreshTime => text().withDefault(const Constant('04:00:00'))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class LocalDecks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {id, userId},
  ];
}

class LocalCards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get userId => text()();
  TextColumn get front => text()();
  TextColumn get back => text()();
  IntColumn get stage => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveFamiliar => integer().withDefault(const Constant(0))();
  TextColumn get nextReviewDate => text().nullable()();
  BoolColumn get learningMode => boolean().withDefault(const Constant(false))();
  IntColumn get reentryStage => integer().nullable()();
  IntColumn get learningStep => integer().withDefault(const Constant(0))();
  Int64Column get reviewVersion => int64().withDefault(Constant(BigInt.zero))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {id, userId},
  ];
}

class LocalReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get cardId => text()();
  TextColumn get rating => text()();
  IntColumn get stageBefore => integer()();
  IntColumn get stageAfter => integer()();
  DateTimeColumn get reviewedAt => dateTime()();
  TextColumn get clientRequestId => text().nullable()();
  Int64Column get reviewVersion => int64().withDefault(Constant(BigInt.zero))();
  TextColumn get syncStatus => text().withDefault(const Constant('PENDING'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncMeta extends Table {
  TextColumn get userId => text()();
  TextColumn get email => text().nullable()();
  TextColumn get refreshTime => text().withDefault(const Constant('04:00:00'))();
  DateTimeColumn get lastBootstrapAt => dateTime().nullable()();
  IntColumn get clockOffsetMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    LocalSettings,
    LocalDecks,
    LocalCards,
    LocalReviewLogs,
    SyncMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'karis_review'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
  );
}
