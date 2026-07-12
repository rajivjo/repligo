import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../text_reflow/domain/usecases/reflow_provider.dart';

class ReflowSettingsSheet extends ConsumerWidget {
  const ReflowSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.watch(reflowFontSizeProvider);
    final lh = ref.watch(reflowLineHeightProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
              alignment: Alignment.center,
            ),
            const Text('Tetapan Teks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.text_fields, size: 18),
              const SizedBox(width: 8),
              Text('Saiz fon: ${fs.toInt()}pt',
                  style: const TextStyle(fontSize: 14)),
            ]),
            Slider(
              value: fs,
              min: 10,
              max: 28,
              divisions: 18,
              onChanged: (v) =>
                  ref.read(reflowFontSizeProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.format_line_spacing, size: 18),
              const SizedBox(width: 8),
              Text('Jarak baris: ${lh.toStringAsFixed(1)}×',
                  style: const TextStyle(fontSize: 14)),
            ]),
            Slider(
              value: lh,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              onChanged: (v) =>
                  ref.read(reflowLineHeightProvider.notifier).state = v,
            ),
            const SizedBox(height: 8),
            // Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ini adalah contoh teks dengan saiz dan jarak baris yang dipilih. '
                'Text reflow memformat semula kandungan PDF supaya sesuai dengan skrin.',
                style: TextStyle(fontSize: fs, height: lh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
