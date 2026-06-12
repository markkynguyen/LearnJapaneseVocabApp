import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/app.dart';
import 'package:jvocab/core/database/app_database.dart';
import 'package:jvocab/features/home/presentation/providers/home_provider.dart';
import 'package:jvocab/features/settings/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('shows home shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          greetingProvider.overrideWith((ref) => 'Chao buoi sáng'),
          totalDueCountProvider.overrideWith((ref) => Stream.value(0)),
          totalLevelStatsProvider.overrideWith(
            (ref) => Stream.value(
              const LevelStats(totalWords: 0, levelCounts: {}),
            ),
          ),
          folderSummariesProvider.overrideWith((ref) => Stream.value([])),
          themeModeProvider.overrideWith((ref) => ThemeMode.light),
        ],
        child: const JVocabApp(),
      ),
    );

    await tester.pump();

    expect(find.text('Chao buoi sáng!'), findsOneWidget);
    expect(find.text('Các bộ từ'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
