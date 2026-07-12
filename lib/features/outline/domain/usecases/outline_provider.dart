import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OutlineEntry {
  final String title;
  final int page;
  final int level;

  const OutlineEntry({
    required this.title,
    required this.page,
    required this.level,
  });
}

final pdfOutlineProvider =
    FutureProvider.family<List<OutlineEntry>, String>((ref, filePath) async {
  final bytes = await File(filePath).readAsBytes();
  final document = PdfDocument(inputBytes: bytes);

  final entries = <OutlineEntry>[];
  void walk(PdfBookmarkBase node, int level) {
    for (int i = 0; i < node.count; i++) {
      final bm = node[i];
      final destination = bm.destination;
      if (destination != null) {
        final page = document.pages.indexOf(destination.page) + 1;
        if (page > 0) {
          entries.add(OutlineEntry(title: bm.title, page: page, level: level));
        }
      }
      walk(bm, level + 1);
    }
  }

  walk(document.bookmarks, 0);
  document.dispose();
  return entries;
});
