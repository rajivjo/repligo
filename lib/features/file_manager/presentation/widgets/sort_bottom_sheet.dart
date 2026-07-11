import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/file_manager_provider.dart';

void showSortBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => _SortBottomSheet(),
  );
}

class _SortBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(sortByProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Susun mengikut',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 16),
            _SortTile(
              label: 'Nama',
              icon: Icons.sort_by_alpha,
              value: SortBy.name,
              current: current,
              onTap: (v) {
                ref.read(sortByProvider.notifier).state = v;
                Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Tarikh diubah',
              icon: Icons.calendar_today_outlined,
              value: SortBy.date,
              current: current,
              onTap: (v) {
                ref.read(sortByProvider.notifier).state = v;
                Navigator.pop(context);
              },
            ),
            _SortTile(
              label: 'Saiz fail',
              icon: Icons.data_usage_outlined,
              value: SortBy.size,
              current: current,
              onTap: (v) {
                ref.read(sortByProvider.notifier).state = v;
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final SortBy value;
  final SortBy current;
  final void Function(SortBy) onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    final color = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: isSelected ? color : null),
      title: Text(label, style: TextStyle(color: isSelected ? color : null)),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: () => onTap(value),
    );
  }
}
