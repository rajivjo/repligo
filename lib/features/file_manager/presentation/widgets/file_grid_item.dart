import 'package:flutter/material.dart';
import '../../domain/entities/file_item.dart';

class FileGridItem extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;

  const FileGridItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: item.isFolder
                    ? colorScheme.secondaryContainer
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
              ),
              child: Center(
                child: Icon(
                  item.isFolder
                      ? Icons.folder_rounded
                      : Icons.picture_as_pdf_rounded,
                  size: 48,
                  color: item.isFolder
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          if (item.isPdf)
            Text(
              item.sizeFormatted,
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
