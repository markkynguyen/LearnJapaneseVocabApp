import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({
    required this.dueCount,
    required this.onStartReview,
    super.key,
  });

  final int dueCount;
  final VoidCallback onStartReview;

  @override
  Widget build(BuildContext context) {
    final hasDueWords = dueCount > 0;
    final colors = Theme.of(context).colorScheme;
    final accentColor = hasDueWords ? context.appDanger : context.appSuccess;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasDueWords ? Icons.schedule_rounded : Icons.check_circle,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cần ôn hôm nay',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              hasDueWords ? '$dueCount từ' : 'Tuyệt vời!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasDueWords
                  ? 'Có từ đang chờ bạn ôn lại.'
                  : 'Không có từ cần ôn ngay.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasDueWords ? onStartReview : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu ôn ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
