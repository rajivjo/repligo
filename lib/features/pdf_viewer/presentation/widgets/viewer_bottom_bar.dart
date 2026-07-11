import 'package:flutter/material.dart';

class ViewerBottomBar extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const ViewerBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  State<ViewerBottomBar> createState() => _ViewerBottomBarState();
}

class _ViewerBottomBarState extends State<ViewerBottomBar> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
  }

  @override
  void didUpdateWidget(ViewerBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      setState(() {
        _sliderValue = widget.currentPage.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Prev page
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: widget.currentPage > 1
                  ? () => widget.onPageChanged(widget.currentPage - 1)
                  : null,
            ),
            // Page number text
            Text(
              '${widget.currentPage}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            // Slider
            Expanded(
              child: Slider(
                value: _sliderValue.clamp(1.0, widget.totalPages.toDouble()),
                min: 1,
                max: widget.totalPages.toDouble(),
                divisions: widget.totalPages > 1 ? widget.totalPages - 1 : 1,
                onChanged: (val) {
                  setState(() => _sliderValue = val);
                },
                onChangeEnd: (val) {
                  widget.onPageChanged(val.round());
                },
              ),
            ),
            // Total pages
            Text(
              '${widget.totalPages}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            // Next page
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: widget.currentPage < widget.totalPages
                  ? () => widget.onPageChanged(widget.currentPage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
