import 'package:flutter/material.dart';

import '../../../../core/constants/srs_constants.dart';
import '../../../../core/models/app_models.dart';

class LevelStatsDashboard extends StatelessWidget {
  const LevelStatsDashboard({
    required this.stats,
    this.title = 'Thống kê từ vựng của bạn',
    super.key,
  });

  final LevelStats stats;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
            const SizedBox(height: 16),
            Text(
              'Tổng số từ đã học:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                children: [
                  TextSpan(text: _formatNumber(stats.learnedWords)),
                  TextSpan(
                    text: ' /${_formatNumber(stats.totalWords)}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
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
