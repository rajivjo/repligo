import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ThumbnailNavigator extends StatefulWidget {
  final String filePath;
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  const ThumbnailNavigator({
    super.key,
    required this.filePath,
    required this.totalPages,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  State<ThumbnailNavigator> createState() => _ThumbnailNavigatorState();
}

class _ThumbnailNavigatorState extends State<ThumbnailNavigator> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentPage());
  }

  @override
  void didUpdateWidget(ThumbnailNavigator old) {
    super.didUpdateWidget(old);
    if (old.currentPage != widget.currentPage) {
      _scrollToCurrentPage();
    }
  }

  void _scrollToCurrentPage() {
    final targetOffset = (widget.currentPage - 1) * 110.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 150,
      color: colorScheme.surfaceVariant.withOpacity(0.9),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: widget.totalPages,
        itemBuilder: (ctx, i) {
          final page = i + 1;
          final isActive = page == widget.currentPage;

          return GestureDetector(
            onTap: () => widget.onPageSelected(page),
            child: Container(
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isActive ? colorScheme.primary : colorScheme.outline,
                  width: isActive ? 2.5 : 0.8,
                ),
                borderRadius: BorderRadius.circular(6),
                color: colorScheme.surface,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      child: PdfPageImage(
                        filePath: widget.filePath,
                        pageNumber: page,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget to render a single PDF page thumbnail
class PdfPageImage extends StatefulWidget {
  final String filePath;
  final int pageNumber;

  const PdfPageImage({super.key, required this.filePath, required this.pageNumber});

  @override
  State<PdfPageImage> createState() => _PdfPageImageState();
}

class _PdfPageImageState extends State<PdfPageImage> {
  PdfPageImage? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      final doc = await PdfDocument.openFile(widget.filePath);
      final page = await doc.getPage(widget.pageNumber);
      final img = await page.render(
        width: 180,
        height: 240,
        format: PdfPageImageFormat.jpeg,
        quality: 60,
      );
      await page.close();
      await doc.close();
      if (mounted) setState(() {
        _image = img;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_image?.bytes != null) {
      return Image.memory(_image!.bytes!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() => const Center(child: Icon(Icons.description_outlined, size: 32));

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}
