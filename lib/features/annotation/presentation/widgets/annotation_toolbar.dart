import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/annotation_model.dart';
import '../../domain/usecases/annotation_provider.dart';

class AnnotationToolbar extends ConsumerWidget {
  final String filePath;
  final int page;

  const AnnotationToolbar({
    super.key,
    required this.filePath,
    required this.page,
  });

  static const _overflowTools = {
    AnnotationTool.note,
    AnnotationTool.drawing,
    AnnotationTool.underline,
    AnnotationTool.strikethrough,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(activeColorProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Highlight tool
          _ToolButton(
            icon: Icons.highlight,
            label: 'Highlight',
            active: activeTool == AnnotationTool.highlight,
            color: activeColor,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == AnnotationTool.highlight
                    ? AnnotationTool.none
                    : AnnotationTool.highlight,
          ),
          // Eraser tool
          _ToolButton(
            icon: Icons.auto_fix_off,
            label: 'Pemadam',
            active: activeTool == AnnotationTool.eraser,
            color: activeColor,
            onTap: () => ref.read(activeToolProvider.notifier).state =
                activeTool == AnnotationTool.eraser
                    ? AnnotationTool.none
                    : AnnotationTool.eraser,
          ),
          // Color picker
          GestureDetector(
            onTap: () => _showColorPicker(context, ref, activeColor),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 2),
              ),
            ),
          ),
          // Stroke width (for drawing)
          if (activeTool == AnnotationTool.drawing)
            _StrokeSlider(),
          // Overflow: Nota, Lukis, Garis Bawah, Coret, Padam semua
          _ToolButton(
            icon: Icons.more_horiz,
            label: 'Lagi',
            active: _overflowTools.contains(activeTool),
            color: activeColor,
            onTap: () => _showMoreTools(context, ref, activeTool),
          ),
        ],
      ),
    );
  }

  void _showMoreTools(
      BuildContext context, WidgetRef ref, AnnotationTool activeTool) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildToolTile(
              context: ctx,
              ref: ref,
              icon: Icons.sticky_note_2_outlined,
              label: 'Nota',
              tool: AnnotationTool.note,
              activeTool: activeTool,
            ),
            _buildToolTile(
              context: ctx,
              ref: ref,
              icon: Icons.draw_outlined,
              label: 'Lukis',
              tool: AnnotationTool.drawing,
              activeTool: activeTool,
            ),
            _buildToolTile(
              context: ctx,
              ref: ref,
              icon: Icons.format_underlined,
              label: 'Garis Bawah',
              tool: AnnotationTool.underline,
              activeTool: activeTool,
            ),
            _buildToolTile(
              context: ctx,
              ref: ref,
              icon: Icons.strikethrough_s,
              label: 'Coret',
              tool: AnnotationTool.strikethrough,
              activeTool: activeTool,
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              title: const Text('Padam semua anotasi halaman ini',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmClear(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTile({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required AnnotationTool tool,
    required AnnotationTool activeTool,
  }) {
    final isActive = activeTool == tool;
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: isActive ? primary : null),
      title: Text(label, style: TextStyle(color: isActive ? primary : null)),
      trailing: isActive ? Icon(Icons.check, color: primary) : null,
      onTap: () {
        Navigator.pop(context);
        ref.read(activeToolProvider.notifier).state =
            isActive ? AnnotationTool.none : tool;
      },
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref, Color current) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Warna'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Preset colors
              Wrap(
                spacing: 12,
                children: AnnotationColor.all.map((c) {
                  final isSelected = c.value == current.value;
                  return GestureDetector(
                    onTap: () {
                      ref.read(activeColorProvider.notifier).state = c;
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const Text('Warna lain:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              HueRingPicker(
                pickerColor: current,
                onColorChanged: (c) =>
                    ref.read(activeColorProvider.notifier).state = c,
                enableAlpha: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Anotasi'),
        content: const Text('Padam semua anotasi pada halaman ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(annotationNotifierProvider.notifier)
                  .clearPage(filePath: filePath, page: page);
            },
            child: const Text('Padam'),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: active
            ? BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: 1.5),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 20,
                color: active ? color : colorScheme.onSurfaceVariant),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: active ? color : colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _StrokeSlider extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = ref.watch(drawingStrokeWidthProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.line_weight, size: 16),
        SizedBox(
          width: 80,
          child: Slider(
            value: width,
            min: 1,
            max: 8,
            divisions: 7,
            onChanged: (v) =>
                ref.read(drawingStrokeWidthProvider.notifier).state = v,
          ),
        ),
      ],
    );
  }
}
