import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/annotation_model.dart';
import '../../domain/usecases/annotation_provider.dart';

class AnnotationOverlay extends ConsumerStatefulWidget {
  final String filePath;
  final int pageNumber;
  final Size pageSize;

  const AnnotationOverlay({
    super.key,
    required this.filePath,
    required this.pageNumber,
    required this.pageSize,
  });

  @override
  ConsumerState<AnnotationOverlay> createState() => _AnnotationOverlayState();
}

class _AnnotationOverlayState extends ConsumerState<AnnotationOverlay> {
  // Drawing state
  List<Offset> _currentStroke = [];
  List<List<Offset>> _completedStrokes = [];
  Offset? _dragStart;
  Offset? _dragCurrent;

  void _onPanStart(DragStartDetails d) {
    final tool = ref.read(activeToolProvider);
    if (tool == AnnotationTool.drawing) {
      setState(() => _currentStroke = [d.localPosition]);
    } else if (tool == AnnotationTool.highlight) {
      setState(() {
        _dragStart = d.localPosition;
        _dragCurrent = d.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final tool = ref.read(activeToolProvider);
    if (tool == AnnotationTool.drawing) {
      setState(() => _currentStroke.add(d.localPosition));
    } else if (tool == AnnotationTool.highlight) {
      setState(() => _dragCurrent = d.localPosition);
    }
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    final tool = ref.read(activeToolProvider);
    final notifier = ref.read(annotationNotifierProvider.notifier);

    if (tool == AnnotationTool.drawing && _currentStroke.isNotEmpty) {
      final strokes = [..._completedStrokes, _currentStroke];
      final allPoints = strokes.expand((s) => s).toList();
      final minX = allPoints.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
      final minY = allPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final maxX = allPoints.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
      final maxY = allPoints.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
      final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
      final pathJson = jsonEncode(
        strokes.map((s) => s.map((p) => {'x': p.dx, 'y': p.dy}).toList()).toList(),
      );
      await notifier.addDrawing(
        filePath: widget.filePath,
        page: widget.pageNumber,
        pathJson: pathJson,
        bounds: bounds,
        pageSize: widget.pageSize,
      );
      setState(() {
        _currentStroke = [];
        _completedStrokes = [];
      });
    } else if (tool == AnnotationTool.highlight &&
        _dragStart != null &&
        _dragCurrent != null) {
      final rect = Rect.fromPoints(_dragStart!, _dragCurrent!);
      if (rect.width > 10 && rect.height > 5) {
        await notifier.addHighlight(
          filePath: widget.filePath,
          page: widget.pageNumber,
          rect: rect,
          pageSize: widget.pageSize,
        );
      }
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = ref.watch(activeToolProvider);
    final annotationsAsync = ref.watch(
      pageAnnotationsProvider((filePath: widget.filePath, page: widget.pageNumber)),
    );
    final strokeColor = ref.watch(activeColorProvider);
    final strokeWidth = ref.watch(drawingStrokeWidthProvider);

    return IgnorePointer(
      ignoring: tool == AnnotationTool.none,
      child: GestureDetector(
        onPanStart: tool != AnnotationTool.none ? _onPanStart : null,
        onPanUpdate: tool != AnnotationTool.none ? _onPanUpdate : null,
        onPanEnd: tool != AnnotationTool.none ? _onPanEnd : null,
        onTapUp: tool == AnnotationTool.note ? _onTapForNote : null,
        child: CustomPaint(
          painter: _AnnotationPainter(
            annotations: annotationsAsync.valueOrNull ?? [],
            pageSize: widget.pageSize,
            currentStroke: _currentStroke,
            completedStrokes: _completedStrokes,
            dragStart: _dragStart,
            dragCurrent: _dragCurrent,
            activeTool: tool,
            strokeColor: strokeColor,
            strokeWidth: strokeWidth,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Future<void> _onTapForNote(TapUpDetails d) async {
    final content = await _showNoteDialog();
    if (content == null || content.isEmpty) return;
    await ref.read(annotationNotifierProvider.notifier).addNote(
          filePath: widget.filePath,
          page: widget.pageNumber,
          position: d.localPosition,
          pageSize: widget.pageSize,
          content: content,
        );
  }

  Future<String?> _showNoteDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Nota'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Tulis nota anda...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<Annotation> annotations;
  final Size pageSize;
  final List<Offset> currentStroke;
  final List<List<Offset>> completedStrokes;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final AnnotationTool activeTool;
  final Color strokeColor;
  final double strokeWidth;

  _AnnotationPainter({
    required this.annotations,
    required this.pageSize,
    required this.currentStroke,
    required this.completedStrokes,
    required this.dragStart,
    required this.dragCurrent,
    required this.activeTool,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / pageSize.width;
    final scaleY = size.height / pageSize.height;

    // Draw saved annotations
    for (final ann in annotations) {
      final color = AnnotationColor.fromHex(ann.color);
      final rect = Rect.fromLTWH(
        ann.x * size.width,
        ann.y * size.height,
        ann.width * size.width,
        ann.height * size.height,
      );

      if (ann.type == 'highlight') {
        canvas.drawRect(rect, Paint()..color = color.withOpacity(0.35));
      } else if (ann.type == 'note') {
        final center = rect.center;
        canvas.drawCircle(center, 12, Paint()..color = color.withOpacity(0.8));
        final textPainter = TextPainter(
          text: const TextSpan(
              text: '✎', style: TextStyle(fontSize: 14, color: Colors.white)),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      } else if (ann.type == 'drawing' && ann.content != null) {
        _drawSavedPath(canvas, ann.content!, color, size);
      }
    }

    // Live highlight drag
    if (activeTool == AnnotationTool.highlight &&
        dragStart != null &&
        dragCurrent != null) {
      final rect = Rect.fromPoints(dragStart!, dragCurrent!);
      canvas.drawRect(rect, Paint()..color = strokeColor.withOpacity(0.35));
      canvas.drawRect(
          rect,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    // Live drawing strokes
    final drawPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in completedStrokes) {
      _drawStroke(canvas, stroke, drawPaint);
    }
    if (currentStroke.length > 1) {
      _drawStroke(canvas, currentStroke, drawPaint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawSavedPath(Canvas canvas, String json, Color color, Size size) {
    try {
      final raw = jsonDecode(json) as List;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final stroke in raw) {
        final pts = (stroke as List)
            .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
            .toList();
        _drawStroke(canvas, pts, paint);
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(_AnnotationPainter old) => true;
}
