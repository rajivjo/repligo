import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../bookmark/domain/usecases/bookmark_provider.dart';

class BookmarkListPanel extends ConsumerWidget {
  final String filePath;
  final ValueChanged<int> onJumpToPage;

  const BookmarkListPanel({
    super.key,
    required this.filePath,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(fileBookmarksProvider(filePath));
    final colorScheme = Theme.of(context).colorScheme;

    return bookmarksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ralat: $e')),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Tiada penanda buku',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Tekan ikon bookmark di toolbar untuk tambah',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (ctx, i) {
            final bm = bookmarks[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  '${bm.pageNumber}',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                bm.label.isEmpty ? 'Halaman ${bm.pageNumber}' : bm.label,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                _formatDate(bm.createdAt),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade300,
                onPressed: () {
                  ref.read(bookmarkNotifierProvider.notifier).delete(bm.id, filePath);
                },
              ),
              onTap: () => onJumpToPage(bm.pageNumber),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
