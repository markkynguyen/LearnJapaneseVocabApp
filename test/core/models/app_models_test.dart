import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';

void main() {
  test('folder model reads study pause flag and defaults to active', () {
    final paused = Folder.fromJson({
      'id': 'folder-1',
      'name': 'N5',
      'color': '#6366F1',
      'is_study_paused': true,
      'created_at': '2026-07-05T00:00:00Z',
    });
    final active = Folder.fromJson({
      'id': 'folder-2',
      'name': 'N4',
      'color': '#22C55E',
      'created_at': '2026-07-05T00:00:00Z',
    });

    expect(paused.isStudyPaused, isTrue);
    expect(active.isStudyPaused, isFalse);
  });

  test('cloud models convert timestamptz fields to Unix seconds', () {
    final progress = SrsProgressEntry.fromJson({
      'vocab_id': 'vocab-1',
      'level': 3,
      'interval_days': 2.0,
      'next_review_at': '2026-07-05T00:00:00Z',
      'correct_count': 4,
      'wrong_count': 1,
      'last_reviewed_at': '2026-07-04T00:00:00Z',
      'updated_at': '2026-07-05T00:00:00Z',
    });

    expect(progress.vocabId, 'vocab-1');
    expect(progress.level, 3);
    expect(progress.nextReviewAt, 1783209600);
    expect(progress.lastReviewedAt, 1783123200);
    expect(progress.toCloudJson()['next_review_at'], contains('2026-07-05'));
  });
}
