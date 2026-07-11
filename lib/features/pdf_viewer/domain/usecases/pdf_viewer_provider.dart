import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

// Current page tracking
final currentPageProvider = StateProvider.family<int, String>((ref, filePath) => 1);

// Total pages
final totalPagesProvider = StateProvider.family<int, String>((ref, filePath) => 0);

// Zoom level
final zoomLevelProvider = StateProvider.family<double, String>((ref, filePath) => 1.0);

// UI visibility (toolbar / page indicator)
final uiVisibleProvider = StateProvider.family<bool, String>((ref, filePath) => true);

// Night mode
final nightModeProvider = StateProvider<bool>((ref) => false);

// Page fit mode
enum FitMode { width, page }
final fitModeProvider = StateProvider.family<FitMode, String>((ref, filePath) => FitMode.page);
