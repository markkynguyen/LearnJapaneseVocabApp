import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/folders/presentation/folder_form_screen.dart';
import '../../features/folders/presentation/folder_list_screen.dart';
import '../../features/folders/presentation/providers/folder_provider.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/import_export/presentation/excel_export_screen.dart';
import '../../features/import_export/presentation/excel_import_screen.dart';
import '../../features/learning/domain/learning_models.dart';
import '../../features/learning/presentation/learning_preview_screen.dart';
import '../../features/learning/presentation/learning_result_screen.dart';
import '../../features/learning/presentation/learning_session_screen.dart';
import '../../features/review/domain/review_models.dart';
import '../../features/review/presentation/review_result_screen.dart';
import '../../features/review/presentation/review_session_screen.dart';
import '../../features/review/presentation/review_setup_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/vocab/presentation/flashcard_screen.dart';
import '../../features/vocab/presentation/vocab_form_screen.dart';
import '../../features/vocab/presentation/vocab_list_screen.dart';
import '../database/app_database.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.folders,
            builder: (context, state) => const FolderListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const FolderFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return _FolderFormRoute(
                    folderId: id,
                    folder:
                        state.extra is Folder ? state.extra! as Folder : null,
                  );
                },
              ),
              GoRoute(
                path: ':id/vocab',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _RouteErrorScreen(
                      message: 'Folder không hợp lệ.',
                    );
                  }
                  return VocabListScreen(folderId: id);
                },
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const _RouteErrorScreen(
                          message: 'Folder khong hop le.',
                        );
                      }
                      return VocabFormScreen(folderId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: ':id/flashcards',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  if (id == null) {
                    return const _RouteErrorScreen(
                      message: 'Folder không hợp lệ.',
                    );
                  }
                  return FlashcardScreen(folderId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.review,
            builder: (context, state) {
              final folderId =
                  int.tryParse(state.uri.queryParameters['folderId'] ?? '');
              final favoritesOnly =
                  state.uri.queryParameters['favoritesOnly'] == '1';
              return ReviewSetupScreen(
                folderId: folderId,
                favoritesOnly: favoritesOnly,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.reviewSession,
            builder: (context, state) => const ReviewSessionScreen(),
          ),
          GoRoute(
            path: AppRoutes.reviewResult,
            builder: (context, state) {
              final summary = state.extra;
              if (summary is! ReviewResultSummary) {
                return const _RouteErrorScreen(
                  message: 'Không có kết quả ôn tập để hiển thị.',
                );
              }
              return ReviewResultScreen(summary: summary);
            },
          ),
          GoRoute(
            path: '/learning/folder/:folderId',
            builder: (context, state) {
              final folderId =
                  int.tryParse(state.pathParameters['folderId'] ?? '');
              if (folderId == null) {
                return const _RouteErrorScreen(
                  message: 'Bộ từ không hợp lệ.',
                );
              }
              return LearningPreviewScreen(
                folderId: folderId,
                request: state.extra is LearningPreviewRequest
                    ? state.extra! as LearningPreviewRequest
                    : const LearningPreviewRequest(),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.learningSession,
            builder: (context, state) => const LearningSessionScreen(),
          ),
          GoRoute(
            path: AppRoutes.learningResult,
            builder: (context, state) {
              final summary = state.extra;
              if (summary is! LearningResultSummary) {
                return const _RouteErrorScreen(
                  message: 'Không có kết quả học để hiển thị.',
                );
              }
              return LearningResultScreen(summary: summary);
            },
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'import',
                builder: (context, state) => const ExcelImportScreen(),
              ),
              GoRoute(
                path: 'export',
                builder: (context, state) => const ExcelExportScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/vocab/:id/edit',
            builder: (context, state) {
              final vocabId = int.tryParse(state.pathParameters['id'] ?? '');
              final folderId =
                  int.tryParse(state.uri.queryParameters['folderId'] ?? '');
              if (vocabId == null || folderId == null) {
                return const _RouteErrorScreen(
                  message: 'Từ vựng hoặc folder không hợp lệ.',
                );
              }
              return VocabFormScreen(folderId: folderId, vocabId: vocabId);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(
      message: 'Không tìm thấy màn hình: ${state.uri}',
    ),
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (_hideNavigation(location)) {
      return child;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
            case 1:
              context.go(AppRoutes.folders);
            case 2:
              context.go(AppRoutes.settings);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Thư viện',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  bool _hideNavigation(String location) {
    return location.startsWith(AppRoutes.review) ||
        location.startsWith('/learning');
  }

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.settings)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.folders) ||
        location.startsWith('/vocab')) {
      return 1;
    }
    return 0;
  }
}

class _FolderFormRoute extends ConsumerWidget {
  const _FolderFormRoute({
    required this.folderId,
    this.folder,
  });

  final int? folderId;
  final Folder? folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = folder;
    if (existing != null) {
      return FolderFormScreen(folder: existing);
    }

    final id = folderId;
    if (id == null) {
      return const _RouteErrorScreen(message: 'Folder không hợp lệ.');
    }

    final folderAsync = ref.watch(folderByIdProvider(id));
    return folderAsync.when(
      data: (folder) {
        if (folder == null) {
          return const _RouteErrorScreen(message: 'Không tìm thấy bộ từ.');
        }
        return FolderFormScreen(folder: folder);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _RouteErrorScreen(
        message: 'Không thể tải bộ từ: $error',
      ),
    );
  }
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ve trang chu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
