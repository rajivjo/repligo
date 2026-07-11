import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/annotation_repository.dart';
import '../../domain/entities/annotation_model.dart';

// Active annotation tool
enum AnnotationTool { none, highlight, note, drawing, eraser }

final activeToolProvider = StateProvider<AnnotationTool>(
    (ref) => AnnotationTool.none);

final activeColorProvider = StateProvider<Color>(
    (ref) => AnnotationColor.yellow);

final drawingStrokeWidthProvider = StateProvider<double>((ref) => 3.0);

// Annotations for a specific page
final pageAnnotationsProvider =
    FutureProvider.family<List<Annotation>, ({String filePath, int page})>(
        (ref, args) async {
  final repo = ref.read(annotationRepositoryProvider);
  return repo.getForPage(args.filePath, args.page);
});

// All annotations for a file (for the annotation list panel)
final fileAnnotationsProvider =
    FutureProvider.family<List<Annotation>, String>((ref, filePath) async {
  final repo = ref.read(annotationRepositoryProvider);
  return repo.getAll(filePath);
});

// Notifier for annotation actions
class AnnotationNotifier extends StateNotifier<AsyncValue<void>> {
  final AnnotationRepository _repo;
  final Ref _ref;

  AnnotationNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> addHighlight({
    required String filePath,
    required int page,
    required Rect rect,
    required Size pageSize,
    String? selectedText,
  }) async {
    final color = _ref.read(activeColorProvider);
    await _repo.addHighlight(
      filePath: filePath,
      page: page,
      rect: rect,
      pageSize: pageSize,
      color: color,
      selectedText: selectedText,
    );
    _ref.invalidate(pageAnnotationsProvider((filePath: filePath, page: page)));
    _ref.invalidate(fileAnnotationsProvider(filePath));
  }

  Future<void> addNote({
    required String filePath,
    required int page,
    required Offset position,
    required Size pageSize,
    required String content,
  }) async {
    final color = _ref.read(activeColorProvider);
    await _repo.addNote(
      filePath: filePath,
      page: page,
      position: position,
      pageSize: pageSize,
      content: content,
      color: color,
    );
    _ref.invalidate(pageAnnotationsProvider((filePath: filePath, page: page)));
    _ref.invalidate(fileAnnotationsProvider(filePath));
  }

  Future<void> addDrawing({
    required String filePath,
    required int page,
    required String pathJson,
    required Rect bounds,
    required Size pageSize,
  }) async {
    final color = _ref.read(activeColorProvider);
    await _repo.addDrawing(
      filePath: filePath,
      page: page,
      pathJson: pathJson,
      color: color,
      bounds: bounds,
      pageSize: pageSize,
    );
    _ref.invalidate(pageAnnotationsProvider((filePath: filePath, page: page)));
    _ref.invalidate(fileAnnotationsProvider(filePath));
  }

  Future<void> delete(int id, String filePath, int page) async {
    await _repo.delete(id);
    _ref.invalidate(pageAnnotationsProvider((filePath: filePath, page: page)));
    _ref.invalidate(fileAnnotationsProvider(filePath));
  }
}

final annotationNotifierProvider =
    StateNotifierProvider<AnnotationNotifier, AsyncValue<void>>((ref) {
  return AnnotationNotifier(ref.read(annotationRepositoryProvider), ref);
});
