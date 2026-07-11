import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';

// Is current page bookmarked?
final isPageBookmarkedProvider =
    FutureProvider.family<bool, ({String filePath, int page})>((ref, args) async {
  final db = ref.read(appDatabaseProvider);
  return db.isPageBookmarked(args.filePath, args.page);
});

// All bookmarks for a file
final fileBookmarksProvider =
    FutureProvider.family<List<Bookmark>, String>((ref, filePath) async {
  final db = ref.read(appDatabaseProvider);
  return db.getBookmarksForFile(filePath);
});

class BookmarkNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;
  final Ref _ref;

  BookmarkNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  Future<bool> toggle(String filePath, int page, {String label = ''}) async {
    final result = await _db.toggleBookmark(filePath, page, label);
    _ref.invalidate(isPageBookmarkedProvider((filePath: filePath, page: page)));
    _ref.invalidate(fileBookmarksProvider(filePath));
    return result != -1; // true = added, false = removed
  }

  Future<void> delete(int id, String filePath) async {
    await _db.deleteBookmark(id);
    _ref.invalidate(fileBookmarksProvider(filePath));
  }
}

final bookmarkNotifierProvider =
    StateNotifierProvider<BookmarkNotifier, AsyncValue<void>>((ref) {
  return BookmarkNotifier(ref.read(appDatabaseProvider), ref);
});
