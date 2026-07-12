import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/reflow_provider.dart';

class TextReflowScreen extends ConsumerWidget {
  final String filePath;
  final String fileName;
  final int initialPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const TextReflowScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.initialPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(reflowPageProvider(filePath));
    final fontSize = ref.watch(reflowFontSizeProvider);
    final lineHeight = ref.watch(reflowLineHeightProvider);
    final textAsync = ref.watch(
        pageTextProvider((filePath: filePath, page: currentPage)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fileName.replaceAll('.pdf', ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Mod Teks — Halaman $currentPage / $totalPages',
                style: const TextStyle(fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Saiz & Jarak Teks',
            onPressed: () => _showSettingsSheet(context, ref, fontSize, lineHeight),
          ),
        ],
      ),
      body: Column(
        children: [
          // Text content
          Expanded(
            child: textAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Mengekstrak teks...'),
                  ],
                ),
              ),
              error: (e, _) => Center(child: Text('$e')),
              data: (text) {
                if (text.trim().isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_snippet_outlined,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('Halaman ini tiada teks boleh diextract',
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        const Text(
                            '(mungkin gambar atau PDF imbasan)',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    text.trim(),
                    style: TextStyle(
                      fontSize: fontSize,
                      height: lineHeight,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),

          // Page navigation bar
          _ReflowNavBar(
            currentPage: currentPage,
            totalPages: totalPages,
            filePath: filePath,
            onPageChanged: (p) {
              ref.read(reflowPageProvider(filePath).notifier).state = p;
              onPageChanged(p);
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(
      BuildContext context, WidgetRef ref, double fontSize, double lineHeight) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ReflowSettingsSheet(
        fontSize: fontSize,
        lineHeight: lineHeight,
      ),
    );
  }
}

class _ReflowNavBar extends ConsumerWidget {
  final int currentPage;
  final int totalPages;
  final String filePath;
  final ValueChanged<int> onPageChanged;

  const _ReflowNavBar({
    required this.currentPage,
    required this.totalPages,
    required this.filePath,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: currentPage > 1 ? () => onPageChanged(1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed:
                  currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            ),
            Expanded(
              child: Slider(
                value: currentPage.toDouble(),
                min: 1,
                max: totalPages.toDouble(),
                divisions: totalPages > 1 ? totalPages - 1 : 1,
                label: 'Hal. $currentPage',
                onChanged: (v) => onPageChanged(v.round()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(currentPage + 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed:
                  currentPage < totalPages ? () => onPageChanged(totalPages) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflowSettingsSheet extends ConsumerWidget {
  final double fontSize;
  final double lineHeight;

  const _ReflowSettingsSheet({
    required this.fontSize,
    required this.lineHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(reflowFontSizeProvider);
    final lh = ref.watch(reflowLineHeightProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.center,
            ),
            const Text('Tetapan Teks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.text_fields, size: 18),
              const SizedBox(width: 8),
              Text('Saiz fon: ${fs.toInt()}pt',
                  style: const TextStyle(fontSize: 14)),
            ]),
            Slider(
              value: fs,
              min: 10,
              max: 28,
              divisions: 18,
              onChanged: (v) =>
                  ref.read(reflowFontSizeProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.format_line_spacing, size: 18),
              const SizedBox(width: 8),
              Text('Jarak baris: ${lh.toStringAsFixed(1)}×',
                  style: const TextStyle(fontSize: 14)),
            ]),
            Slider(
              value: lh,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              onChanged: (v) =>
                  ref.read(reflowLineHeightProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ini adalah contoh teks dengan saiz dan jarak baris yang dipilih. '
                'Text reflow memformat semula kandungan PDF supaya sesuai dengan skrin.',
                style: TextStyle(fontSize: fs, height: lh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
