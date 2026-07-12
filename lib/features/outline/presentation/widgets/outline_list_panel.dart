import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/outline_provider.dart';

class OutlineListPanel extends ConsumerWidget {
  final String filePath;
  final ValueChanged<int> onJumpToPage;

  const OutlineListPanel({
    super.key,
    required this.filePath,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outlineAsync = ref.watch(pdfOutlineProvider(filePath));

    return outlineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ralat: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.toc, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('PDF ini tiada kandungan/outline tersedia',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('(bukan semua PDF ada struktur bab/kandungan)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (ctx, i) {
            final entry = entries[i];
            return ListTile(
              dense: true,
              contentPadding:
                  EdgeInsets.fromLTRB(16.0 + 16.0 * entry.level, 0, 16, 0),
              title: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: entry.level == 0 ? 14 : 13,
                  fontWeight:
                      entry.level == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: Text('${entry.page}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () => onJumpToPage(entry.page),
            );
          },
        );
      },
    );
  }
}
