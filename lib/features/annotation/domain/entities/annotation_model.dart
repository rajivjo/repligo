import 'dart:ui';

enum AnnotationType { highlight, note, drawing }

class AnnotationColor {
  static const yellow = Color(0xFFFFEB3B);
  static const green  = Color(0xFF4CAF50);
  static const blue   = Color(0xFF2196F3);
  static const pink   = Color(0xFFE91E63);
  static const orange = Color(0xFFFF9800);

  static const all = [yellow, green, blue, pink, orange];

  static String toHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static Color fromHex(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

/// Normalised rectangle (0.0–1.0 relative to page dimensions)
class NormRect {
  final double x, y, width, height;
  const NormRect(this.x, this.y, this.width, this.height);

  Rect toRect(Size pageSize) => Rect.fromLTWH(
        x * pageSize.width,
        y * pageSize.height,
        width * pageSize.width,
        height * pageSize.height,
      );

  factory NormRect.fromRect(Rect rect, Size pageSize) => NormRect(
        rect.left / pageSize.width,
        rect.top / pageSize.height,
        rect.width / pageSize.width,
        rect.height / pageSize.height,
      );
}
