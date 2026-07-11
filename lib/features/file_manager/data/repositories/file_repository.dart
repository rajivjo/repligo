import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/file_item.dart';

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepository();
});

class FileRepository {
  final Box _settings = Hive.box('settings');

  // Scan directory for PDF files
  Future<List<FileItem>> scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<FileItem> items = [];

    await for (final entity in dir.list(followLinks: false)) {
      final stat = await entity.stat();
      final name = p.basename(entity.path);

      // Skip hidden files
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        items.add(FileItem(
          path: entity.path,
          name: name,
          type: FileType.folder,
          sizeBytes: 0,
          modifiedAt: stat.modified,
        ));
      } else if (entity is File && name.toLowerCase().endsWith('.pdf')) {
        final lastOpened = _settings.get('last_opened_${entity.path}') as String?;
        items.add(FileItem(
          path: entity.path,
          name: name,
          type: FileType.pdf,
          sizeBytes: stat.size,
          modifiedAt: stat.modified,
          lastOpenedAt: lastOpened != null ? DateTime.tryParse(lastOpened) : null,
        ));
      }
    }

    // Sort: folders first, then PDFs by name
    items.sort((a, b) {
      if (a.type != b.type) {
        return a.isFolder ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  // Get all PDF files recursively (for Recent / Search)
  Future<List<FileItem>> getAllPdfs() async {
    final roots = await _getRootDirectories();
    final List<FileItem> all = [];

    for (final root in roots) {
      await _scanRecursive(root, all);
    }

    // Sort by last opened (recent first)
    all.sort((a, b) {
      if (a.lastOpenedAt == null && b.lastOpenedAt == null) return 0;
      if (a.lastOpenedAt == null) return 1;
      if (b.lastOpenedAt == null) return -1;
      return b.lastOpenedAt!.compareTo(a.lastOpenedAt!);
    });

    return all;
  }

  Future<void> _scanRecursive(String dirPath, List<FileItem> results) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    try {
      await for (final entity in dir.list(followLinks: false)) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;

        if (entity is Directory) {
          await _scanRecursive(entity.path, results);
        } else if (entity is File && name.toLowerCase().endsWith('.pdf')) {
          final stat = await entity.stat();
          final lastOpened = _settings.get('last_opened_${entity.path}') as String?;
          results.add(FileItem(
            path: entity.path,
            name: name,
            type: FileType.pdf,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
            lastOpenedAt: lastOpened != null ? DateTime.tryParse(lastOpened) : null,
          ));
        }
      }
    } catch (_) {
      // Permission denied on some system folders — skip
    }
  }

  Future<List<String>> _getRootDirectories() async {
    final List<String> roots = [];
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        // Go up to actual external storage root
        final parts = external.path.split('/');
        final storageIdx = parts.indexOf('Android');
        if (storageIdx > 0) {
          roots.add(parts.sublist(0, storageIdx).join('/'));
        }
      }
      final app = await getApplicationDocumentsDirectory();
      roots.add(app.path);
    } else if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      roots.add(docs.path);
    }
    return roots;
  }

  Future<String> getDefaultDirectory() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final parts = external.path.split('/');
        final idx = parts.indexOf('Android');
        if (idx > 0) return parts.sublist(0, idx).join('/');
      }
    }
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  void markAsOpened(String filePath) {
    _settings.put('last_opened_$filePath', DateTime.now().toIso8601String());
  }

  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await _settings.delete('last_opened_$filePath');
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
