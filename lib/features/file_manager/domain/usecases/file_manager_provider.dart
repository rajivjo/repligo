import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/file_repository.dart';
import '../entities/file_item.dart';

// Current directory path
final currentDirectoryProvider = StateProvider<String?>((ref) => null);

// Sort options
enum SortBy { name, date, size }
final sortByProvider = StateProvider<SortBy>((ref) => SortBy.name);

// View mode
enum ViewMode { list, grid }
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Active tab
enum TabMode { browse, recent }
final tabModeProvider = StateProvider<TabMode>((ref) => TabMode.browse);

// Files in current directory
final directoryFilesProvider = FutureProvider.autoDispose<List<FileItem>>((ref) async {
  final repo = ref.read(fileRepositoryProvider);
  final dir = ref.watch(currentDirectoryProvider);
  final sortBy = ref.watch(sortByProvider);

  String targetDir;
  if (dir == null) {
    targetDir = await repo.getDefaultDirectory();
    // Update the provider with default dir
    Future.microtask(() {
      ref.read(currentDirectoryProvider.notifier).state = targetDir;
    });
  } else {
    targetDir = dir;
  }

  var items = await repo.scanDirectory(targetDir);

  // Apply sort
  switch (sortBy) {
    case SortBy.name:
      items.sort((a, b) {
        if (a.type != b.type) return a.isFolder ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      break;
    case SortBy.date:
      items.sort((a, b) {
        if (a.type != b.type) return a.isFolder ? -1 : 1;
        return b.modifiedAt.compareTo(a.modifiedAt);
      });
      break;
    case SortBy.size:
      items.sort((a, b) {
        if (a.type != b.type) return a.isFolder ? -1 : 1;
        return b.sizeBytes.compareTo(a.sizeBytes);
      });
      break;
  }

  return items;
});

// Recent PDFs
final recentFilesProvider = FutureProvider.autoDispose<List<FileItem>>((ref) async {
  final repo = ref.read(fileRepositoryProvider);
  final all = await repo.getAllPdfs();
  return all.where((f) => f.lastOpenedAt != null).take(50).toList();
});

// Search results
final searchResultsProvider = FutureProvider.autoDispose<List<FileItem>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];

  final repo = ref.read(fileRepositoryProvider);
  final all = await repo.getAllPdfs();
  return all.where((f) => f.name.toLowerCase().contains(query)).toList();
});
