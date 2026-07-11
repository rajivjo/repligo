import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

// User font size preference
final reflowFontSizeProvider = StateProvider<double>((ref) => 16.0);

// User line height preference
final reflowLineHeightProvider = StateProvider<double>((ref) => 1.6);

// Extracted text per page cache
final _textCacheProvider = StateProvider<Map<String, Map<int, String>>>(
    (ref) => {});

// Text for a specific page
final pageTextProvider =
    FutureProvider.family<String, ({String filePath, int page})>((ref, args) async {
  // Check cache first
  final cache = ref.read(_textCacheProvider);
  final fileCache = cache[args.filePath];
  if (fileCache != null && fileCache.containsKey(args.page)) {
    return fileCache[args.page]!;
  }

  // Extract from PDF
  try {
    final bytes = await File(args.filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    if (args.page < 1 || args.page > document.pages.count) {
      document.dispose();
      return '';
    }

    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText(startPageIndex: args.page - 1, endPageIndex: args.page - 1);
    document.dispose();

    // Update cache
    final newCache = Map<String, Map<int, String>>.from(cache);
    newCache[args.filePath] = Map<int, String>.from(fileCache ?? {})
      ..[args.page] = text;
    ref.read(_textCacheProvider.notifier).state = newCache;

    return text;
  } catch (e) {
    return 'Ralat mengekstrak teks: $e';
  }
});

// Reading progress for reflow mode
final reflowPageProvider =
    StateProvider.family<int, String>((ref, filePath) => 1);

// Is reflow mode active
final reflowModeActiveProvider =
    StateProvider.family<bool, String>((ref, filePath) => false);
