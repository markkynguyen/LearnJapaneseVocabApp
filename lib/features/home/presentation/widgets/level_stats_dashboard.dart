import 'package:flutter/material.dart';

import '../../../../core/constants/srs_constants.dart';
import '../../../../core/models/app_models.dart';

class LevelStatsDashboard extends StatelessWidget {
  const LevelStatsDashboard({
    required this.stats,
    this.kanjiCount,
    this.radicalCount,
    this.isCharacterStatsLoading = false,
    this.hasCharacterStatsError = false,
    this.title = 'Thống kê học tập của bạn',
    super.key,
  });

  final LevelStats stats;
  final int? kanjiCount;
  final int? radicalCount;
  final bool isCharacterStatsLoading;
  final bool hasCharacterStatsError;
  final String title;

  @override
  Widget build(BuildContext context) {
    final maxCount = [
      for (var level = SrsConstants.minLevel;
          level <= SrsConstants.maxLevel;
          level++)
        stats.countForLevel(level),
    ].fold<int>(0, (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.school_outlined,
                      label: 'Từ đã học',
                      value: '${_formatNumber(stats.learnedWords)} '
                          '/ ${_formatNumber(stats.totalWords)}',
                      semanticValue:
                          '${stats.learnedWords} trên ${stats.totalWords}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.translate_rounded,
                      label: 'Kanji',
                      value: _characterStatValue(kanjiCount),
                      semanticValue: _characterSemanticValue(kanjiCount),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.account_tree_outlined,
                      label: 'Bộ thủ',
                      value: _characterStatValue(radicalCount),
                      semanticValue: _characterSemanticValue(radicalCount),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var level = SrsConstants.minLevel;
                      level <= SrsConstants.maxLevel;
                      level++)
                    Expanded(
                      child: _LevelBar(
                        level: level,
                        count: stats.countForLevel(level),
                        maxCount: maxCount,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Mức độ ghi nhớ từ vựng',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _characterStatValue(int? count) {
    if (count != null) return _formatNumber(count);
    return isCharacterStatsLoading ? '…' : '—';
  }

  String _characterSemanticValue(int? count) {
    if (count != null) return '$count';
    if (isCharacterStatsLoading) return 'đang tải';
    if (hasCharacterStatsError) return 'chưa tải được';
    return 'chưa có thống kê';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.semanticValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String semanticValue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '$label: $semanticValue',
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({
    required this.level,
    required this.count,
    required this.maxCount,
  });

  final int level;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
    final barColor =
        SrsConstants.levelTextColors[level] ?? Theme.of(context).primaryColor;
    final minHeight = count == 0 ? 6.0 : 14.0;
    final height = (minHeight + ratio * 118).clamp(minHeight, 132.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'LV$level',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
