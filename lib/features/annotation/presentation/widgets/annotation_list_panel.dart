import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/annotation_model.dart';
import '../../domain/usecases/annotation_provider.dart';

class AnnotationListPanel extends ConsumerWidget {
  final String filePath;
  final ValueChanged<int> onJumpToPage;

  const AnnotationListPanel({
    super.key,
    required this.filePath,
    required this.onJumpToPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationsAsync = ref.watch(fileAnnotationsProvider(filePath));

    return annotationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ralat: $e')),
      data: (annotations) {
        if (annotations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.highlight_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text('Tiada anotasi lagi',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Guna toolbar untuk highlight, nota, atau lukis',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        // Group by page
        final Map<int, List<Annotation>> byPage = {};
        for (final a in annotations) {
          byPage.putIfAbsent(a.pageNumber, () => []).add(a);
        }
        final sortedPages = byPage.keys.toList()..sort();

        return ListView.builder(
          itemCount: sortedPages.length,
          itemBuilder: (ctx, i) {
            final page = sortedPages[i];
            final pageAnns = byPage[page]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Halaman $page',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                ...pageAnns.map((a) => _AnnotationTile(
                      annotation: a,
                      onTap: () => onJumpToPage(a.pageNumber),
                      onDelete: () {
                        ref.read(annotationNotifierProvider.notifier).delete(
                            a.id, a.filePath, a.pageNumber);
                      },
                    )),
              ],
            );
          },
        );
      },
    );
  }
}

class _AnnotationTile extends StatelessWidget {
  final Annotation annotation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnnotationTile({
    required this.annotation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AnnotationColor.fromHex(annotation.color);
    IconData icon;
    String typeLabel;
    String preview;

    switch (annotation.type) {
      case 'highlight':
        icon = Icons.highlight;
        typeLabel = 'Highlight';
        preview = annotation.selectedText ?? '(tiada teks dipilih)';
        break;
      case 'note':
        icon = Icons.sticky_note_2_outlined;
        typeLabel = 'Nota';
        preview = annotation.content ?? '';
        break;
      case 'underline':
        icon = Icons.format_underlined;
        typeLabel = 'Garis Bawah';
        preview = annotation.selectedText ?? '(tiada teks dipilih)';
        break;
      case 'strikethrough':
        icon = Icons.strikethrough_s;
        typeLabel = 'Coret';
        preview = annotation.selectedText ?? '(tiada teks dipilih)';
        break;
      default:
        icon = Icons.draw_outlined;
        typeLabel = 'Lukisan';
        preview = 'Freehand drawing';
    }

    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(typeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        color: Colors.red.shade300,
      ),
    );
  }
}
