import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/quiz_utils.dart';
import '../../../core/widgets/japanese_quiz_text.dart';
import '../../../core/widgets/japanese_mixed_text.dart';
import '../../vocab/presentation/widgets/pitch_accent_text.dart';
import '../domain/learning_models.dart';
import 'providers/learning_provider.dart';

class LearningSessionScreen extends ConsumerStatefulWidget {
  const LearningSessionScreen({super.key});

  @override
  ConsumerState<LearningSessionScreen> createState() =>
      _LearningSessionScreenState();
}

class _LearningSessionScreenState extends ConsumerState<LearningSessionScreen> {
  late final TextEditingController _answerController;
  bool _feedbackOpen = false;
  String? _lastListenToken;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(learningControllerProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz từ mới'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Thoát',
              onPressed: _exit,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: session.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Quiz bị lỗi: $error')),
            data: (state) {
              if (state == null) {
                return const Center(child: Text('Chưa có phiên học.'));
              }
              if (state.isFinished) {
                return _ApplyingLearningView(isApplying: state.isApplying);
              }
              _scheduleListen(state);
              return _LearningQuestionView(
                state: state,
                answerController: _answerController,
                onSubmitText: () => _submit(_answerController.text),
                onSubmitChoice: _submit,
                onRevealHint: () =>
                    ref.read(learningControllerProvider.notifier).revealHint(),
              );
            },
          ),
        ),
      ),
    );
  }

  void _scheduleListen(LearningSessionState state) {
    final question = state.currentQuestion;
    if (_feedbackOpen || question?.type != LearningQuestionType.listen) {
      return;
    }
    final token =
        '${state.currentIndex}-${question!.item.vocab.id}-${question.retryCount}';
    if (_lastListenToken == token) {
      return;
    }
    _lastListenToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_feedbackOpen) {
        ref.read(audioServiceProvider).speak(question.item.vocab);
      }
    });
  }

  Future<void> _submit(String answer) async {
    final before = ref.read(learningControllerProvider).valueOrNull;
    final question = before?.currentQuestion;
    if (question == null) {
      return;
    }
    _feedbackOpen = true;
    final feedback =
        ref.read(learningControllerProvider.notifier).submitAnswer(answer);
    _answerController.clear();
    if (feedback == null || !mounted) {
      _feedbackOpen = false;
      return;
    }
    FocusScope.of(context).unfocus();
    await ref.read(audioServiceProvider).speak(question.item.vocab);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => _LearningFeedbackDialog(feedback: feedback),
    );
    _feedbackOpen = false;
    if (!mounted) {
      return;
    }
    final next = ref.read(learningControllerProvider).valueOrNull;
    if (next == null) {
      return;
    }
    if (next.isFinished) {
      await _finish();
      return;
    }
    _scheduleListen(next);
  }

  Future<void> _finish() async {
    final summary =
        await ref.read(learningControllerProvider.notifier).finish();
    if (!mounted || summary == null) {
      return;
    }
    context.go(AppRoutes.learningResult, extra: summary);
  }

  void _exit() {
    final folderId = ref.read(learningControllerProvider).valueOrNull?.folderId;
    context.go(
      folderId == null ? AppRoutes.home : AppRoutes.folderVocab(folderId),
    );
  }
}

class _LearningQuestionView extends ConsumerWidget {
  const _LearningQuestionView({
    required this.state,
    required this.answerController,
    required this.onSubmitText,
    required this.onSubmitChoice,
    required this.onRevealHint,
  });

  final LearningSessionState state;
  final TextEditingController answerController;
  final VoidCallback onSubmitText;
  final ValueChanged<String> onSubmitChoice;
  final VoidCallback onRevealHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion!;
    final colors = Theme.of(context).colorScheme;
    final progress = state.questions.isEmpty
        ? 0.0
        : (state.currentIndex + 1) / state.questions.length;
    final showHint = question.isGuided || question.hintUsed;
    final isChoice = question.choices.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      children: [
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(label: Text(question.type.label)),
                const SizedBox(height: 14),
                if (question.promptJapaneseDisplay case final display?)
                  JapaneseQuizText(text: display)
                else
                  Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                        ),
                  ),
                if (question.item.vocab.note?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    question.item.vocab.note!.trim(),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
                if (showHint) ...[
                  const SizedBox(height: 14),
                  Text('Gợi ý', style: TextStyle(color: colors.primary)),
                  JapaneseQuizText(
                    text: question.japaneseDisplay,
                    primaryStyle:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 32,
                            ),
                  ),
                ],
                if (question.type == LearningQuestionType.listen) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => ref
                        .read(audioServiceProvider)
                        .speak(question.item.vocab),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Nghe lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (isChoice)
          ...question.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => onSubmitChoice(choice.value),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _LearningChoiceLabel(choice: choice),
                ),
              ),
            ),
          )
        else ...[
          TextField(
            controller: answerController,
            decoration: InputDecoration(
              labelText: question.isGuided ? 'Viết lại từ mẫu' : 'Câu trả lời',
            ),
            onSubmitted: (_) => onSubmitText(),
          ),
          if (question.type == LearningQuestionType.write &&
              !question.hintUsed) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRevealHint,
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Gợi ý'),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onSubmitText,
            icon: const Icon(Icons.check_rounded),
            label: Text(question.isGuided ? 'Đã viết xong' : 'Trả lời'),
          ),
        ],
      ],
    );
  }
}

class _LearningChoiceLabel extends StatelessWidget {
  const _LearningChoiceLabel({required this.choice});

  final QuizChoice choice;

  @override
  Widget build(BuildContext context) {
    final display = choice.japaneseDisplay;
    if (display == null) {
      return Text(
        choice.value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 22,
            ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return JapaneseQuizText(
      text: display,
      primaryStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 26,
          ),
      secondaryStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _LearningFeedbackDialog extends ConsumerWidget {
  const _LearningFeedbackDialog({required this.feedback});
  final LearningAnswerFeedback feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocab = feedback.question.item.vocab;
    final colors = Theme.of(context).colorScheme;
    final statusColor = !feedback.wasGraded
        ? colors.primary
        : feedback.isCorrect
            ? context.appSuccess
            : context.appDanger;
    final statusIcon = !feedback.wasGraded
        ? Icons.visibility_rounded
        : feedback.isCorrect
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;
    final message = !feedback.wasGraded
        ? 'Đáp án'
        : feedback.isCorrect
            ? 'Chính xác'
            : 'Chưa đúng';

    return SafeArea(
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 10),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Phát âm',
                      onPressed: () =>
                          ref.read(audioServiceProvider).speak(vocab),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (vocab.kanji?.trim().isNotEmpty == true) ...[
                  Text(
                    vocab.kanji!.trim(),
                    locale: AppTypography.japaneseLocale,
                    style: AppTypography.kanji(
                      context,
                      Theme.of(context).textTheme.headlineMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                PitchAccentReading(
                  kana: vocab.kana,
                  pattern: vocab.pitchAccent,
                  romaji: vocab.romaji,
                  fontSize: vocab.kanji?.trim().isNotEmpty == true ? 22 : 30,
                  textColor: colors.onSurfaceVariant,
                ),
                const SizedBox(height: 14),
                if (feedback.question.expectedJapaneseDisplay
                    case final answer?)
                  _LearningJapaneseFeedbackDetail(
                    label: 'Đáp án đúng',
                    value: answer,
                  )
                else
                  _LearningFeedbackDetail(
                    label: 'Đáp án đúng',
                    value: feedback.question.expectedAnswer,
                  ),
                if (feedback.wasGraded &&
                    !feedback.isCorrect &&
                    feedback.answer.trim().isNotEmpty)
                  _LearningFeedbackDetail(
                    label: 'Bạn trả lời',
                    value: feedback.answer.trim(),
                  ),
                if (vocab.example?.trim().isNotEmpty == true)
                  _LearningFeedbackDetail(
                    label: 'Ví dụ',
                    value: vocab.example!.trim(),
                    usesJapaneseTypography: true,
                  ),
                if (vocab.note?.trim().isNotEmpty == true)
                  _LearningFeedbackDetail(
                    label: 'Ghi chú',
                    value: vocab.note!.trim(),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tiếp tục'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningJapaneseFeedbackDetail extends StatelessWidget {
  const _LearningJapaneseFeedbackDetail({
    required this.label,
    required this.value,
  });

  final String label;
  final QuizJapaneseText value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          JapaneseQuizText(
            text: value,
            primaryStyle: const TextStyle(
              height: 1.35,
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
            secondaryStyle: TextStyle(
              color: colors.onSurfaceVariant,
              height: 1.3,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningFeedbackDetail extends StatelessWidget {
  const _LearningFeedbackDetail({
    required this.label,
    required this.value,
    this.usesJapaneseTypography = false,
  });

  final String label;
  final String value;
  final bool usesJapaneseTypography;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          if (usesJapaneseTypography)
            JapaneseMixedText(
              value,
              style: const TextStyle(height: 1.35, fontSize: 17),
            )
          else
            Text(value, style: const TextStyle(height: 1.35, fontSize: 17)),
        ],
      ),
    );
  }
}

class _ApplyingLearningView extends StatelessWidget {
  const _ApplyingLearningView({required this.isApplying});

  final bool isApplying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isApplying)
            const CircularProgressIndicator()
          else
            Icon(
              Icons.pending_actions_rounded,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
          const SizedBox(height: 14),
          Text(
            isApplying ? 'Đang lưu kết quả...' : 'Đang chuẩn bị kết quả...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
