import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/home_provider.dart';
import 'widgets/home_vocab_search.dart';
import 'widgets/level_stats_dashboard.dart';
import 'widgets/review_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);
    final totalDueCount = ref.watch(totalDueCountProvider);
    final totalLevelStats = ref.watch(totalLevelStatsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalDueCountProvider);
            ref.invalidate(totalLevelStatsProvider);
            await Future<void>.delayed(const Duration(milliseconds: 250));
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      totalDueCount.when(
                        data: (count) => Text(
                          'Hôm nay bạn có $count từ cần ôn',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        loading: () => Text(
                          'Đang tải số từ cần ôn...',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        error: (_, __) => Text(
                          'Chưa thể tải số từ cần ôn.',
                          style: TextStyle(color: context.appDanger),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const HomeVocabSearch(),
                      const SizedBox(height: 18),
                      totalLevelStats.when(
                        data: (stats) => LevelStatsDashboard(stats: stats),
                        loading: () => const _LoadingCard(),
                        error: (error, _) => _ErrorCard(message: '$error'),
                      ),
                      const SizedBox(height: 18),
                      totalDueCount.when(
                        data: (count) => ReviewSummaryCard(
                          dueCount: count,
                          onStartReview: () => context.push(AppRoutes.review),
                        ),
                        loading: () => const _LoadingCard(),
                        error: (error, _) => _ErrorCard(message: '$error'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: TextStyle(color: context.appDanger),
        ),
      ),
    );
  }
}
