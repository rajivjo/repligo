import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/file_manager/presentation/screens/file_manager_screen.dart';
import '../features/pdf_viewer/presentation/screens/pdf_viewer_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const FileManagerScreen(),
      ),
      GoRoute(
        path: '/viewer',
        name: 'viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PdfViewerScreen(
            filePath: extra['filePath'] as String,
            fileName: extra['fileName'] as String,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak dijumpai: ${state.error}'),
      ),
    ),
  );
});
