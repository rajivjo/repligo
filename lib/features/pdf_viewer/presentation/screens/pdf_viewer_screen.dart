import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/database/app_database.dart';
import '../../../annotation/domain/usecases/annotation_provider.dart';
import '../../../annotation/presentation/widgets/annotation_overlay.dart';
import '../../../annotation/presentation/widgets/annotation_toolbar.dart';
import '../../../annotation/presentation/widgets/annotation_list_panel.dart';
import '../../../bookmark/domain/usecases/bookmark_provider.dart';
import '../../../bookmark/presentation/widgets/bookmark_list_panel.dart';
import '../../../outline/domain/usecases/outline_provider.dart';
import '../../../outline/presentation/widgets/outline_list_panel.dart';
import '../../../search/presentation/screens/pdf_search_screen.dart';
import '../../../text_reflow/domain/usecases/reflow_provider.dart';
import '../../domain/usecases/pdf_viewer_provider.dart';
import '../widgets/page_indicator.dart';
import '../widgets/reflow_settings_sheet.dart';
import '../widgets/viewer_bottom_bar.dart';
import '../widgets/thumbnail_navigator.dart';

enum SidePanel { none, bookmarks, annotations, outline }

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  late PdfControllerPinch _pdfController;
  bool _isLoading = true;
  String? _error;
  bool _showThumbnails = false;
  bool _reflowMode = false;
  SidePanel _sidePanel = SidePanel.none;
  late Size _pageSize;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageSize = const Size(595, 842);
    _initPdf();
  }

  void _initPdf() {
    try {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.filePath),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreProgress() async {
    final db = ref.read(appDatabaseProvider);
    final progress = await db.getProgress(widget.filePath);
    if (progress != null && progress.currentPage > 1 && mounted) {
      _pdfController.animateToPage(
        pageNumber: progress.currentPage,
        duration: Duration.zero,
        curve: Curves.linear,
      );
      ref.read(currentPageProvider(widget.filePath).notifier).state =
          progress.currentPage;
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleUI() {
    final current = ref.read(uiVisibleProvider(widget.filePath));
    ref.read(uiVisibleProvider(widget.filePath).notifier).state = !current;
  }

  void _goToPage(int page) {
    final total = ref.read(totalPagesProvider(widget.filePath));
    if (page >= 1 && page <= total) {
      _pdfController.animateToPage(
        pageNumber: page,
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }
  }

  Future<void> _saveProgress(int page) async {
    final total = ref.read(totalPagesProvider(widget.filePath));
    await ref.read(appDatabaseProvider).saveProgress(widget.filePath, page, total);
  }

  Future<void> _toggleBookmark(int page) async {
    final notifier = ref.read(bookmarkNotifierProvider.notifier);
    final added = await notifier.toggle(widget.filePath, page);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? 'Penanda ditambah' : 'Penanda dialih keluar'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiVisible = ref.watch(uiVisibleProvider(widget.filePath));
    final nightMode = ref.watch(nightModeProvider);
    final currentPage = ref.watch(currentPageProvider(widget.filePath));
    final totalPages = ref.watch(totalPagesProvider(widget.filePath));
    final activeTool = ref.watch(activeToolProvider);
    final isBookmarked = ref.watch(
        isPageBookmarkedProvider((filePath: widget.filePath, page: currentPage)));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: nightMode ? const Color(0xFF1A1A1A) : Colors.grey.shade700,
      extendBodyBehindAppBar: true,
      appBar: uiVisible
          ? AppBar(
              backgroundColor: colorScheme.surface.withOpacity(0.95),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fileName.replaceAll('.pdf', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (totalPages > 0)
                    Text('$currentPage / $totalPages halaman',
                        style: const TextStyle(fontSize: 11)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Cari dalam PDF',
                  onPressed: totalPages > 0
                      ? () => _openSearch(currentPage, totalPages)
                      : null,
                ),
                isBookmarked.when(
                  data: (bookmarked) => IconButton(
                    icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
                    tooltip: bookmarked ? 'Buang penanda' : 'Tambah penanda',
                    color: bookmarked ? colorScheme.primary : null,
                    onPressed: () => _toggleBookmark(currentPage),
                  ),
                  loading: () => const IconButton(
                      onPressed: null, icon: Icon(Icons.bookmark_border)),
                  error: (_, __) => const SizedBox(),
                ),
                IconButton(
                  icon: const Icon(Icons.wrap_text),
                  tooltip: _reflowMode ? 'Paparan PDF biasa' : 'Mod Teks Reflow',
                  color: _reflowMode ? colorScheme.primary : null,
                  onPressed: totalPages > 0
                      ? () => setState(() => _reflowMode = !_reflowMode)
                      : null,
                ),
                if (_reflowMode)
                  IconButton(
                    icon: const Icon(Icons.text_fields),
                    tooltip: 'Saiz & Jarak Teks',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => const ReflowSettingsSheet(),
                    ),
                  ),
                IconButton(
                  icon: Icon(nightMode
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_round),
                  tooltip: nightMode ? 'Mod siang' : 'Mod malam',
                  onPressed: () =>
                      ref.read(nightModeProvider.notifier).state = !nightMode,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () =>
                      _showMoreOptions(context, currentPage, totalPages),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: activeTool == AnnotationTool.none ? _toggleUI : null,
        child: Stack(
          children: [
            if (_error != null)
              _buildErrorWidget()
            else if (_reflowMode)
              _buildReflowView(currentPage)
            else if (nightMode)
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -1, 0, 0, 0, 255,
                  0, -1, 0, 0, 255,
                  0, 0, -1, 0, 255,
                  0, 0, 0, 1, 0,
                ]),
                child: _buildPdfView(),
              )
            else
              _buildPdfView(),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _error == null && !_reflowMode && totalPages > 0)
              Positioned.fill(
                child: AnnotationOverlay(
                  filePath: widget.filePath,
                  pageNumber: currentPage,
                  pageSize: _pageSize,
                ),
              ),
            if (!uiVisible && totalPages > 0)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: PageIndicator(current: currentPage, total: totalPages),
                ),
              ),
            if (_showThumbnails && totalPages > 0 && uiVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ThumbnailNavigator(
                  filePath: widget.filePath,
                  totalPages: totalPages,
                  currentPage: currentPage,
                  onPageSelected: _goToPage,
                ),
              ),
            if (_sidePanel != SidePanel.none)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _buildSidePanel(currentPage),
              ),
          ],
        ),
      ),
      bottomNavigationBar: uiVisible
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_reflowMode)
                  AnnotationToolbar(filePath: widget.filePath, page: currentPage),
                if (totalPages > 0)
                  ViewerBottomBar(
                    currentPage: currentPage,
                    totalPages: totalPages,
                    onPageChanged: _goToPage,
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildPdfView() {
    return PdfViewPinch(
      controller: _pdfController,
      onDocumentLoaded: (doc) async {
        setState(() => _isLoading = false);
        ref.read(totalPagesProvider(widget.filePath).notifier).state =
            doc.pagesCount;
        final page = await doc.getPage(1);
        setState(() {
          _pageSize = Size(page.width, page.height);
        });
        await page.close();
        await _restoreProgress();
      },
      onDocumentError: (error) {
        setState(() {
          _isLoading = false;
          _error = error.toString();
        });
      },
      onPageChanged: (page) {
        ref.read(currentPageProvider(widget.filePath).notifier).state = page;
        _saveProgress(page);
      },
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, error) => Center(
          child: Text(error.toString(),
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Gagal membuka PDF',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_error!,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSidePanel(int currentPage) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: Text(switch (_sidePanel) {
              SidePanel.bookmarks => 'Penanda Buku',
              SidePanel.outline => 'Kandungan',
              _ => 'Anotasi',
            }),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _sidePanel = SidePanel.none),
              ),
            ],
          ),
          Expanded(
            child: switch (_sidePanel) {
              SidePanel.bookmarks => BookmarkListPanel(
                  filePath: widget.filePath,
                  onJumpToPage: (p) {
                    _goToPage(p);
                    setState(() => _sidePanel = SidePanel.none);
                  },
                ),
              SidePanel.outline => OutlineListPanel(
                  filePath: widget.filePath,
                  onJumpToPage: (p) {
                    _goToPage(p);
                    setState(() => _sidePanel = SidePanel.none);
                  },
                ),
              _ => AnnotationListPanel(
                  filePath: widget.filePath,
                  onJumpToPage: (p) {
                    _goToPage(p);
                    setState(() => _sidePanel = SidePanel.none);
                  },
                ),
            },
          ),
        ],
      ),
    );
  }

  void _openSearch(int currentPage, int totalPages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfSearchScreen(
          filePath: widget.filePath,
          totalPages: totalPages,
          onJumpToPage: _goToPage,
        ),
      ),
    );
  }

  Widget _buildReflowView(int page) {
    final fontSize = ref.watch(reflowFontSizeProvider);
    final lineHeight = ref.watch(reflowLineHeightProvider);
    final uiVisible = ref.watch(uiVisibleProvider(widget.filePath));
    final textAsync =
        ref.watch(pageTextProvider((filePath: widget.filePath, page: page)));
    final topInset =
        MediaQuery.of(context).padding.top + (uiVisible ? 76.0 : 12.0);

    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: textAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Mengekstrak teks...'),
              ],
            ),
          ),
          error: (e, _) => Center(child: Text('$e')),
          data: (text) {
            if (text.trim().isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.text_snippet_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('Halaman ini tiada teks boleh diextract',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    const Text('(mungkin gambar atau PDF imbasan)',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, topInset, 20, 40),
              child: SelectableText(
                text.trim(),
                style: TextStyle(
                  fontSize: fontSize,
                  height: lineHeight,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, int currentPage, int totalPages) {
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
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Lihat penanda buku'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _sidePanel =
                    _sidePanel == SidePanel.bookmarks
                        ? SidePanel.none
                        : SidePanel.bookmarks);
              },
            ),
            ListTile(
              leading: const Icon(Icons.highlight),
              title: const Text('Lihat anotasi'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _sidePanel =
                    _sidePanel == SidePanel.annotations
                        ? SidePanel.none
                        : SidePanel.annotations);
              },
            ),
            ListTile(
              leading: const Icon(Icons.toc),
              title: const Text('Lihat kandungan (TOC)'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _sidePanel = _sidePanel == SidePanel.outline
                    ? SidePanel.none
                    : SidePanel.outline);
              },
            ),
            ListTile(
              leading: Icon(_showThumbnails ? Icons.grid_off : Icons.grid_view),
              title: Text(_showThumbnails
                  ? 'Sembunyi thumbnail'
                  : 'Lihat thumbnail'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _showThumbnails = !_showThumbnails);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Kongsi PDF'),
              onTap: () {
                Navigator.pop(ctx);
                Share.shareXFiles([XFile(widget.filePath)],
                    subject: widget.fileName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.first_page),
              title: const Text('Halaman pertama'),
              onTap: () {
                Navigator.pop(ctx);
                _goToPage(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.last_page),
              title: const Text('Halaman terakhir'),
              onTap: () {
                Navigator.pop(ctx);
                _goToPage(totalPages);
              },
            ),
            ListTile(
              leading: const Icon(Icons.input),
              title: const Text('Pergi ke halaman...'),
              onTap: () {
                Navigator.pop(ctx);
                _showGoToPageDialog(totalPages);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoToPageDialog(int total) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pergi ke halaman'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1 – $total',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) Navigator.pop(ctx, page);
            },
            child: const Text('Pergi'),
          ),
        ],
      ),
    );
    if (result != null) _goToPage(result);
  }
}
