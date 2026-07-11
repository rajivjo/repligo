import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/file_item.dart';

class FileListTile extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const FileListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('d MMM yyyy').format(item.modifiedAt);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: item.isFolder
              ? colorScheme.secondaryContainer
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          item.isFolder ? Icons.folder_rounded : Icons.picture_as_pdf_rounded,
          color: item.isFolder
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        item.isFolder ? dateStr : '${item.sizeFormatted}  •  $dateStr',
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      trailing: onDelete != null
          ? PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'delete') onDelete?.call();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Padam', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert, size: 20),
            )
          : null,
    );
  }
}
