import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/annotation_model.dart';

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  return AnnotationRepository(ref.read(appDatabaseProvider));
});

class AnnotationRepository {
  final AppDatabase _db;
  AnnotationRepository(this._db);

  Future<List<Annotation>> getForPage(String filePath, int page) =>
      _db.getAnnotationsForPage(filePath, page);

  Future<List<Annotation>> getAll(String filePath) =>
      _db.getAllAnnotationsForFile(filePath);

  Future<int> addHighlight({
    required String filePath,
    required int page,
    required Rect rect,
    required Size pageSize,
    required Color color,
    String? selectedText,
  }) {
    final norm = NormRect.fromRect(rect, pageSize);
    return _db.insertAnnotation(AnnotationsCompanion.insert(
      filePath: filePath,
      pageNumber: page,
      type: 'highlight',
      color: Value(AnnotationColor.toHex(color)),
      x: norm.x,
      y: norm.y,
      width: norm.width,
      height: norm.height,
      selectedText: Value(selectedText),
    ));
  }

  Future<int> addNote({
    required String filePath,
    required int page,
    required Offset position,
    required Size pageSize,
    required String content,
    required Color color,
  }) {
    final normX = position.dx / pageSize.width;
    final normY = position.dy / pageSize.height;
    return _db.insertAnnotation(AnnotationsCompanion.insert(
      filePath: filePath,
      pageNumber: page,
      type: 'note',
      color: Value(AnnotationColor.toHex(color)),
      x: normX,
      y: normY,
      width: 0.05,
      height: 0.05,
      content: Value(content),
    ));
  }

  Future<int> addDrawing({
    required String filePath,
    required int page,
    required String pathJson,
    required Color color,
    required Rect bounds,
    required Size pageSize,
  }) {
    final norm = NormRect.fromRect(bounds, pageSize);
    return _db.insertAnnotation(AnnotationsCompanion.insert(
      filePath: filePath,
      pageNumber: page,
      type: 'drawing',
      color: Value(AnnotationColor.toHex(color)),
      x: norm.x,
      y: norm.y,
      width: norm.width,
      height: norm.height,
      content: Value(pathJson),
    ));
  }

  Future<int> delete(int id) => _db.deleteAnnotation(id);

  Future<int> deleteAllForFile(String filePath) =>
      _db.deleteAllAnnotationsForFile(filePath);
}
