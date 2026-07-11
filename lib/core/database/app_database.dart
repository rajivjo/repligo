import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get type => text()();
  TextColumn get color => text().withDefault(const Constant('#FFFF00'))();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  TextColumn get content => text().nullable()();
  TextColumn get selectedText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  IntColumn get pageNumber => integer()();
  TextColumn get label => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ReadingProgress extends Table {
  TextColumn get filePath => text()();
  IntColumn get currentPage => integer().withDefault(const Constant(1))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  RealColumn get scrollOffset => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastReadAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {filePath};
}

@DriftDatabase(tables: [Annotations, Bookmarks, ReadingProgress])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Annotation>> getAnnotationsForPage(String filePath, int page) =>
      (select(annotations)
            ..where((a) => a.filePath.equals(filePath) & a.pageNumber.equals(page)))
          .get();

  Future<List<Annotation>> getAllAnnotationsForFile(String filePath) =>
      (select(annotations)..where((a) => a.filePath.equals(filePath))).get();

  Future<int> insertAnnotation(AnnotationsCompanion entry) =>
      into(annotations).insert(entry);

  Future<bool> updateAnnotation(Annotation entry) =>
      update(annotations).replace(entry);

  Future<int> deleteAnnotation(int id) =>
      (delete(annotations)..where((a) => a.id.equals(id))).go();

  Future<int> deleteAllAnnotationsForFile(String filePath) =>
      (delete(annotations)..where((a) => a.filePath.equals(filePath))).go();

  Future<List<Bookmark>> getBookmarksForFile(String filePath) =>
      (select(bookmarks)
            ..where((b) => b.filePath.equals(filePath))
            ..orderBy([(b) => OrderingTerm(expression: b.pageNumber)]))
          .get();

  Future<bool> isPageBookmarked(String fp, int page) async {
    final result = await (select(bookmarks)
          ..where((b) => b.filePath.equals(fp) & b.pageNumber.equals(page)))
        .getSingleOrNull();
    return result != null;
  }

  Future<int> toggleBookmark(String fp, int page) async {
    final existing = await (select(bookmarks)
          ..where((b) => b.filePath.equals(fp) & b.pageNumber.equals(page)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(bookmarks)..where((b) => b.id.equals(existing.id))).go();
      return -1;
    } else {
      return into(bookmarks).insert(BookmarksCompanion.insert(
        filePath: fp,
        pageNumber: page,
        label: const Value(''),
      ));
    }
  }

  Future<int> deleteBookmark(int id) =>
      (delete(bookmarks)..where((b) => b.id.equals(id))).go();

  Future<ReadingProgressData?> getProgress(String fp) =>
      (select(readingProgress)..where((r) => r.filePath.equals(fp)))
          .getSingleOrNull();

  Future<void> saveProgress(String fp, int page, int total, {double offset = 0}) =>
      into(readingProgress).insertOnConflictUpdate(ReadingProgressCompanion.insert(
        filePath: fp,
        currentPage: Value(page),
        totalPages: Value(total),
        scrollOffset: Value(offset),
        lastReadAt: Value(DateTime.now()),
      ));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'repligo.db'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
