import 'package:flutter/foundation.dart';

enum FileType { pdf, folder }

@immutable
class FileItem {
  final String path;
  final String name;
  final FileType type;
  final int sizeBytes;
  final DateTime modifiedAt;
  final DateTime? lastOpenedAt;

  const FileItem({
    required this.path,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.modifiedAt,
    this.lastOpenedAt,
  });

  bool get isPdf => type == FileType.pdf;
  bool get isFolder => type == FileType.folder;

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  FileItem copyWith({DateTime? lastOpenedAt}) {
    return FileItem(
      path: path,
      name: name,
      type: type,
      sizeBytes: sizeBytes,
      modifiedAt: modifiedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
