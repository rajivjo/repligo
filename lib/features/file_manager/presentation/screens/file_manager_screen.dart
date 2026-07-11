import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../data/repositories/file_repository.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/usecases/file_manager_provider.dart';
import '../widgets/file_list_tile.dart';
import '../widgets/file_grid_item.dart';
import '../widgets/sort_bottom_sheet.dart';

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(tabModeProvider.notifier).state =
            _tabController.index == 0 ? TabMode.browse : TabMode.recent;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openFile(FileItem item) {
    if (item.isFolder) {
      ref.read(currentDirectoryProvider.notifier).state = item.path;
    } else {
      ref.read(fileRepositoryProvider).markAsOpened(item.path);
      context.pushNamed('viewer', extra: {
        'filePath': item.path,
        'fileName': item.name,
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = p.basename(path);
      ref.read(fileRepositoryProvider).markAsOpened(path);
      if (mounted) {
        context.pushNamed('viewer', extra: {
          'filePath': path,
          'fileName': name,
        });
      }
    }
  }

  void _navigateUp() {
    final current = ref.read(currentDirectoryProvider);
    if (current != null) {
      final parent = p.dirname(current);
      if (parent != current) {
        ref.read(currentDirectoryProvider.notifier).state = parent;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(viewModeProvider);
    final currentDir = ref.watch(currentDirectoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: currentDir != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateUp,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari PDF...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RepliGo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (currentDir != null)
                    Text(
                      p.basename(currentDir),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(viewMode == ViewMode.list ? Icons.grid_view : Icons.view_list),
            onPressed: () {
              ref.read(viewModeProvider.notifier).state =
                  viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => showSortBottomSheet(context, ref),
          ),
        ],
        bottom: !_isSearching
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.folder_outlined), text: 'Browse'),
                  Tab(icon: Icon(Icons.history), text: 'Recent'),
                ],
              )
            : null,
      ),
      body: _isSearching && searchQuery.isNotEmpty
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBrowseTab(),
                _buildRecentTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickFile,
        icon: const Icon(Icons.add),
        label: const Text('Buka PDF'),
      ),
    );
  }

  Widget _buildBrowseTab() {
    final viewMode = ref.watch(viewModeProvider);
    final filesAsync = ref.watch(directoryFilesProvider);

    return filesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Ralat: $e'),
          ],
        ),
      ),
      data: (files) {
        if (files.isEmpty) {
          return _buildEmptyState(
            icon: Icons.folder_open,
            message: 'Tiada fail PDF dalam folder ini',
            sub: 'Tekan butang + untuk buka PDF',
          );
        }
        return viewMode == ViewMode.list
            ? _buildListView(files)
            : _buildGridView(files);
      },
    );
  }

  Widget _buildRecentTab() {
    final viewMode = ref.watch(viewModeProvider);
    final recentAsync = ref.watch(recentFilesProvider);

    return recentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ralat: $e')),
      data: (files) {
        if (files.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            message: 'Belum ada fail dibuka',
            sub: 'Fail yang dibuka akan muncul di sini',
          );
        }
        return viewMode == ViewMode.list
            ? _buildListView(files)
            : _buildGridView(files);
      },
    );
  }

  Widget _buildSearchResults() {
    final viewMode = ref.watch(viewModeProvider);
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ralat: $e')),
      data: (files) {
        if (files.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            message: 'Tiada hasil ditemui',
            sub: 'Cuba cari dengan kata kunci lain',
          );
        }
        return viewMode == ViewMode.list
            ? _buildListView(files)
            : _buildGridView(files);
      },
    );
  }

  Widget _buildListView(List<FileItem> files) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(directoryFilesProvider);
        ref.invalidate(recentFilesProvider);
      },
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, i) => FileListTile(
          item: files[i],
          onTap: () => _openFile(files[i]),
          onDelete: files[i].isPdf
              ? () => _confirmDelete(files[i])
              : null,
        ),
      ),
    );
  }

  Widget _buildGridView(List<FileItem> files) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(directoryFilesProvider);
        ref.invalidate(recentFilesProvider);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: files.length,
        itemBuilder: (context, i) => FileGridItem(
          item: files[i],
          onTap: () => _openFile(files[i]),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(sub,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(FileItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Fail'),
        content: Text('Nak padam "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Padam'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref.read(fileRepositoryProvider).deleteFile(item.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Fail dipadam' : 'Gagal memadam fail'),
          ),
        );
        ref.invalidate(directoryFilesProvider);
        ref.invalidate(recentFilesProvider);
      }
    }
  }
}
