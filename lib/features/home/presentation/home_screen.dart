import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../kanji/presentation/providers/kanji_providers.dart';
import 'providers/home_provider.dart';
import 'widgets/home_vocab_search.dart';
import 'widgets/level_stats_dashboard.dart';
import 'widgets/review_summary_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDueCount = ref.watch(totalDueCountProvider);
    final totalLevelStats = ref.watch(totalLevelStatsProvider);
    final kanjiStats = ref.watch(kanjiSnapshotProvider);
    final kanjiOverview = kanjiStats.valueOrNull?.overview;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(totalDueCountProvider);
            ref.invalidate(totalLevelStatsProvider);
            ref.invalidate(kanjiSnapshotProvider);
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
                      const HomeVocabSearch(),
                      const SizedBox(height: 18),
                      totalLevelStats.when(
                        data: (stats) => LevelStatsDashboard(
                          stats: stats,
                          kanjiCount: kanjiOverview?.kanjiCount,
                          radicalCount: kanjiOverview?.radicalCount,
                          isCharacterStatsLoading:
                              kanjiOverview == null && kanjiStats.isLoading,
                          hasCharacterStatsError:
                              kanjiOverview == null && kanjiStats.hasError,
                        ),
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
