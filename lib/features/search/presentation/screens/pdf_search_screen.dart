import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SearchResult {
  final int pageNumber;
  final String context;
  final int matchIndex;

  const SearchResult({
    required this.pageNumber,
    required this.context,
    required this.matchIndex,
  });
}

class PdfSearchScreen extends ConsumerStatefulWidget {
  final String filePath;
  final int totalPages;
  final ValueChanged<int> onJumpToPage;

  const PdfSearchScreen({
    super.key,
    required this.filePath,
    required this.totalPages,
    required this.onJumpToPage,
  });

  @override
  ConsumerState<PdfSearchScreen> createState() => _PdfSearchScreenState();
}

class _PdfSearchScreenState extends ConsumerState<PdfSearchScreen> {
  final _controller = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';
  bool _caseSensitive = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty || query == _lastQuery) return;
    setState(() {
      _isSearching = true;
      _results = [];
      _lastQuery = query;
    });

    try {
      final bytes = await File(widget.filePath).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final List<SearchResult> results = [];

      for (int p = 0; p < document.pages.count; p++) {
        final text = extractor.extractText(startPageIndex: p, endPageIndex: p);
        if (text.isEmpty) continue;

        final searchIn = _caseSensitive ? text : text.toLowerCase();
        final searchFor = _caseSensitive ? query : query.toLowerCase();

        int idx = 0;
        int matchIdx = 0;
        while ((idx = searchIn.indexOf(searchFor, idx)) != -1) {
          // Extract context (50 chars either side)
          final start = (idx - 50).clamp(0, text.length);
          final end = (idx + query.length + 50).clamp(0, text.length);
          final context = (start > 0 ? '...' : '') +
              text.substring(start, end).trim() +
              (end < text.length ? '...' : '');

          results.add(SearchResult(
            pageNumber: p + 1,
            context: context,
            matchIndex: matchIdx,
          ));
          idx += searchFor.length;
          matchIdx++;
          if (results.length >= 200) break; // limit
        }
        if (results.length >= 200) break;
      }

      document.dispose();
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari dalam PDF...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _lastQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: _controller.text.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => _search(_controller.text),
          ),
          IconButton(
            icon: Icon(
              Icons.format_size,
              color: _caseSensitive
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: 'Beza huruf besar/kecil',
            onPressed: () {
              setState(() {
                _caseSensitive = !_caseSensitive;
                _lastQuery = ''; // force re-search
              });
              if (_controller.text.isNotEmpty) _search(_controller.text);
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Mencari...'),
          ],
        ),
      );
    }

    if (_controller.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Taip untuk mencari dalam PDF',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_results.isEmpty && _lastQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('"${_controller.text}" tidak dijumpai',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_results.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              children: [
                Text('${_results.length} keputusan ditemui',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                if (_results.length >= 200) ...[
                  const SizedBox(width: 6),
                  const Text('(had 200)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = _results[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '${r.pageNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: _HighlightedText(
                  text: r.context,
                  query: _controller.text,
                  caseSensitive: _caseSensitive,
                ),
                subtitle: Text('Halaman ${r.pageNumber}',
                    style: const TextStyle(fontSize: 11)),
                onTap: () {
                  widget.onJumpToPage(r.pageNumber);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final bool caseSensitive;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.caseSensitive,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);

    final searchIn = caseSensitive ? text : text.toLowerCase();
    final searchFor = caseSensitive ? query : query.toLowerCase();
    final List<TextSpan> spans = [];

    int start = 0;
    int idx;
    while ((idx = searchIn.indexOf(searchFor, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.6),
          fontWeight: FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
        children: spans,
      ),
    );
  }
}
