import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/review_session_provider.dart';

class ReviewSetupScreen extends ConsumerWidget {
  const ReviewSetupScreen({
    this.folderId,
    this.folderName,
    this.favoritesOnly = false,
    super.key,
  });

  final int? folderId;
  final String? folderName;
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsDao = ref.watch(settingsDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ôn tập'),
        leading: folderId == null
            ? null
            : IconButton(
                tooltip: 'Trở về bộ từ',
                onPressed: () => context.go(AppRoutes.folderVocab(folderId!)),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([
            ref.watch(srsProgressDaoProvider).getDueCount(
                  folderId: folderId,
                  favoritesOnly: favoritesOnly,
                ),
            settingsDao.getSettings(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải phiên ôn: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appDanger),
                  ),
                ),
              );
            }

            final dueCount = snapshot.data![0] as int;
            final appSettings = snapshot.data![1] as AppSettings;
            final totalTypes = appSettings.quizListenCount +
                appSettings.quizWriteCount +
                appSettings.quizChooseWordCount +
                appSettings.quizChooseMeaningCount;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          favoritesOnly
                              ? Icons.favorite_rounded
                              : Icons.school_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 34,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _description(dueCount),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _InfoTile(
                  icon: Icons.format_list_numbered_rounded,
                  title: 'Số từ mỗi phiên',
                  value: '${appSettings.sessionSize}',
                ),
                _InfoTile(
                  icon: Icons.quiz_rounded,
                  title: 'Số dạng câu hỏi',
                  value: totalTypes == 0 ? 'Mặc định đọc' : '$totalTypes',
                ),
                _InfoTile(
                  icon: Icons.replay_rounded,
                  title: 'Retry câu sai',
                  value: '${appSettings.quizRetryLimit} lần',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _startReview(context, ref),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    favoritesOnly ? 'Bắt đầu ôn yêu thích' : 'Bắt đầu ôn tập',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String get _title {
    if (favoritesOnly) {
      return 'Ôn từ yêu thích';
    }
    return folderName ?? 'Ôn tất cả bộ từ';
  }

  String _description(int dueCount) {
    if (favoritesOnly) {
      if (dueCount > 0) {
        return 'Có $dueCount từ yêu thích đang đến hạn. Nếu chưa đủ phiên, app sẽ thêm các từ yêu thích lâu chưa ôn nhất.';
      }
      return 'Chưa có từ yêu thích đến hạn. Bạn vẫn có thể luyện các từ yêu thích lâu chưa ôn nhất.';
    }
    if (dueCount > 0) {
      return 'Có $dueCount từ đang đến hạn. Nếu chưa đủ phiên, app sẽ thêm các từ lâu chưa ôn nhất.';
    }
    return 'Chưa có từ đến hạn. Bạn vẫn có thể luyện thêm với các từ lâu chưa ôn nhất.';
  }

  Future<void> _startReview(BuildContext context, WidgetRef ref) async {
    await ref.read(reviewSessionControllerProvider.notifier).start(
          folderId: folderId,
          favoritesOnly: favoritesOnly,
        );

    if (!context.mounted) {
      return;
    }

    final state = ref.read(reviewSessionControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu: ${state.error}')),
      );
      return;
    }

    context.push(AppRoutes.reviewSession);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
