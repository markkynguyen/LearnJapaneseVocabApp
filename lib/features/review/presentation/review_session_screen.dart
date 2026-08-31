import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/quiz_utils.dart';
import '../../../core/widgets/japanese_quiz_text.dart';
import '../../vocab/presentation/vocab_form_screen.dart';
import '../../vocab/presentation/widgets/pitch_accent_text.dart';
import '../domain/review_models.dart';
import 'providers/review_session_provider.dart';

class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({
    this.folderId,
    this.folderName,
    super.key,
  });

  final String? folderId;
  final String? folderName;

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
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
    final session = ref.watch(reviewSessionControllerProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Đang ôn tập'),
          actions: [
            IconButton(
              tooltip: 'Kết thúc',
              onPressed: () => _confirmExit(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: session.when(
            data: (state) {
              if (state == null) {
                return const _NoReviewState();
              }
              if (state.isFinished) {
                return _ReviewFinishedView(
                  state: state,
                  onDecision: (vocabId, decision) {
                    ref
                        .read(reviewSessionControllerProvider.notifier)
                        .setSrsDecision(vocabId, decision);
                  },
                  onFinish: _finishSession,
                );
              }
              if (state.questions.isEmpty) {
                return const _NoReviewState();
              }
              _scheduleListen(state);
              return _QuestionView(
                state: state,
                answerController: _answerController,
                onSubmitText: () => _submitAnswer(_answerController.text),
                onSubmitChoice: _submitAnswer,
                onForgetWriting: _forgetCurrentWritingQuestion,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Phiên ôn tập bị lỗi: $error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appDanger),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitAnswer(String answer) async {
    final current = ref.read(reviewSessionControllerProvider).valueOrNull;
    final question = current?.currentQuestion;
    if (question == null) {
      return;
    }
    _feedbackOpen = true;
    final feedback =
        ref.read(reviewSessionControllerProvider.notifier).submitAnswer(answer);
    if (feedback == null || !mounted) {
      _feedbackOpen = false;
      return;
    }

    _answerController.clear();
    FocusScope.of(context).unfocus();
    await ref.read(audioServiceProvider).speak(question.item.vocab);
    if (!mounted) {
      return;
    }
    final action = await showDialog<_AnswerFeedbackAction>(
      context: context,
      builder: (_) => _AnswerFeedbackDialog(feedback: feedback),
    );
    _feedbackOpen = false;
    if (!mounted) {
      return;
    }
    if (action == _AnswerFeedbackAction.editVocabulary) {
      await _openVocabEditor(feedback);
      if (!mounted) {
        return;
      }
    }
    final next = ref.read(reviewSessionControllerProvider).valueOrNull;
    if (next != null) {
      _scheduleListen(next);
    }
  }

  Future<void> _forgetCurrentWritingQuestion() async {
    final current = ref.read(reviewSessionControllerProvider).valueOrNull;
    final question = current?.currentQuestion;
    if (question == null || question.type != ReviewQuestionType.write) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu đã quên?'),
        content: const Text(
          'Bạn muốn xem đáp án và đưa từ này vào danh sách cần hạ cấp SRS?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    _feedbackOpen = true;
    final feedback = ref
        .read(reviewSessionControllerProvider.notifier)
        .forgetCurrentWritingQuestion();
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
    final action = await showDialog<_AnswerFeedbackAction>(
      context: context,
      builder: (_) => _AnswerFeedbackDialog(feedback: feedback),
    );
    _feedbackOpen = false;
    if (!mounted) {
      return;
    }
    if (action == _AnswerFeedbackAction.editVocabulary) {
      await _openVocabEditor(feedback);
      if (!mounted) {
        return;
      }
    }
    final next = ref.read(reviewSessionControllerProvider).valueOrNull;
    if (next != null) {
      _scheduleListen(next);
    }
  }

  Future<void> _openVocabEditor(ReviewAnswerFeedback feedback) async {
    final vocab = feedback.question.item.vocab;
    await ref.read(audioServiceProvider).stop();
    if (!mounted) {
      return;
    }
    final result = await context.push<VocabEditResult>(
      AppRoutes.editVocab(vocab.id, folderId: vocab.folderId),
    );
    if (!mounted || result?.changed != true || result?.vocabId != vocab.id) {
      return;
    }

    ref
        .read(reviewSessionControllerProvider.notifier)
        .removeVocabFromCurrentSession(vocab.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật và bỏ từ này khỏi phiên ôn hiện tại.'),
      ),
    );
  }

  void _scheduleListen(ReviewSessionState state) {
    final question = state.currentQuestion;
    if (_feedbackOpen || question?.type != ReviewQuestionType.listen) {
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

  Future<void> _finishSession() async {
    final controller = ref.read(reviewSessionControllerProvider.notifier);
    final summary = await controller.finish();
    if (!mounted) {
      return;
    }
    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy chọn xử lý SRS cho từ sai nhiều.'),
        ),
      );
      return;
    }

    context.go(AppRoutes.reviewResult, extra: summary);
  }

  Future<void> _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát phiên ôn?'),
        content: const Text(
          'Kết quả phiên hiện tại chưa được áp dụng nếu bạn thoát ngay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final sessionFolderId =
          ref.read(reviewSessionControllerProvider).valueOrNull?.folderId;
      await ref.read(audioServiceProvider).stop();
      if (context.mounted) {
        context.go(
          AppRoutes.reviewExit(sessionFolderId ?? widget.folderId),
        );
      }
    }
  }
}

class _QuestionView extends ConsumerWidget {
  const _QuestionView({
    required this.state,
    required this.answerController,
    required this.onSubmitText,
    required this.onSubmitChoice,
    required this.onForgetWriting,
  });

  final ReviewSessionState state;
  final TextEditingController answerController;
  final VoidCallback onSubmitText;
  final ValueChanged<String> onSubmitChoice;
  final VoidCallback onForgetWriting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion!;
    final colors = Theme.of(context).colorScheme;
    final progress = state.totalQuestions == 0
        ? 0.0
        : (state.currentIndex + 1) / state.totalQuestions;
    final isChoiceQuestion = question.choices.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: colors.outline.withValues(alpha: 0.28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.currentIndex + 1}/${state.totalQuestions}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Icon(_iconFor(question.type), size: 18),
                  label: Text(question.type.label),
                ),
                const SizedBox(height: 18),
                if (question.promptJapaneseDisplay case final display?)
                  JapaneseQuizText(text: display)
                else
                  Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                          height: 1.18,
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
                const SizedBox(height: 10),
                Text(
                  _helperText(question),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                if (question.type == ReviewQuestionType.listen) ...[
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      ref.read(audioServiceProvider).speak(question.item.vocab);
                    },
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Nghe lại'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isChoiceQuestion)
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
                  child: _ChoiceLabel(choice: choice),
                ),
              ),
            ),
          )
        else ...[
          TextField(
            controller: answerController,
            minLines: question.type == ReviewQuestionType.write ? 1 : null,
            maxLines: question.type == ReviewQuestionType.write ? 3 : 1,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Câu trả lời',
              hintText: question.type == ReviewQuestionType.write
                  ? 'Nhập từ tiếng Nhật'
                  : 'Nhập đáp án',
              prefixIcon: const Icon(Icons.edit_rounded),
            ),
            onSubmitted: (_) => onSubmitText(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onSubmitText,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Trả lời'),
          ),
          if (question.type == ReviewQuestionType.write) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onForgetWriting,
              icon: const Icon(Icons.visibility_rounded),
              label: const Text('Đã quên'),
            ),
          ],
        ],
      ],
    );
  }

  String _helperText(ReviewQuestion question) {
    switch (question.type) {
      case ReviewQuestionType.listen:
        return 'Audio dùng phát âm tiếng Nhật, đáp án là nghĩa tiếng Việt.';
      case ReviewQuestionType.write:
        return 'Viết từ tiếng Nhật khớp với nghĩa.';
      case ReviewQuestionType.chooseWord:
        return 'Chọn từ tiếng Nhật khớp với nghĩa.';
      case ReviewQuestionType.chooseMeaning:
        return 'Chọn nghĩa tiếng Việt khớp với từ.';
    }
  }

  IconData _iconFor(ReviewQuestionType type) {
    switch (type) {
      case ReviewQuestionType.listen:
        return Icons.hearing_rounded;
      case ReviewQuestionType.write:
        return Icons.edit_rounded;
      case ReviewQuestionType.chooseWord:
        return Icons.translate_rounded;
      case ReviewQuestionType.chooseMeaning:
        return Icons.psychology_alt_rounded;
    }
  }
}

class _ChoiceLabel extends StatelessWidget {
  const _ChoiceLabel({required this.choice});

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
            fontWeight: FontWeight.w400,
            fontSize: 26,
          ),
      secondaryStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

enum _AnswerFeedbackAction { editVocabulary }

class _AnswerFeedbackDialog extends ConsumerWidget {
  const _AnswerFeedbackDialog({required this.feedback});

  final ReviewAnswerFeedback feedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final feedback = this.feedback;
    final vocab = feedback.question.item.vocab;
    final statusColor = feedback.wasForgotten
        ? colors.primary
        : feedback.isCorrect
            ? context.appSuccess
            : context.appDanger;
    final statusIcon = feedback.wasForgotten
        ? Icons.visibility_rounded
        : feedback.isCorrect
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;
    final statusText = feedback.wasForgotten
        ? 'Đã quên'
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
                      statusText,
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w400,
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
                  _JapaneseDetailLine(label: 'Đáp án đúng', value: answer)
                else
                  _DetailLine(
                    label: 'Đáp án đúng',
                    value: feedback.question.expectedAnswer,
                  ),
                if (!feedback.wasForgotten &&
                    !feedback.isCorrect &&
                    feedback.answer.trim().isNotEmpty)
                  _DetailLine(
                    label: 'Bạn trả lời',
                    value: feedback.answer.trim(),
                  ),
                if (vocab.example?.trim().isNotEmpty ?? false)
                  _DetailLine(label: 'Ví dụ', value: vocab.example!.trim()),
                if (vocab.note?.trim().isNotEmpty ?? false)
                  _DetailLine(label: 'Ghi chú', value: vocab.note!.trim()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context)
                            .pop(_AnswerFeedbackAction.editVocabulary),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Sửa từ vựng'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Tiếp tục'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JapaneseDetailLine extends StatelessWidget {
  const _JapaneseDetailLine({
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
              fontWeight: FontWeight.w400,
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
          Text(value, style: const TextStyle(height: 1.35, fontSize: 17)),
        ],
      ),
    );
  }
}

class _ReviewFinishedView extends StatelessWidget {
  const _ReviewFinishedView({
    required this.state,
    required this.onDecision,
    required this.onFinish,
  });

  final ReviewSessionState state;
  final void Function(String vocabId, ReviewSrsDecision decision) onDecision;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final decisionWords = state.srsDecisionWords;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag_rounded, color: colors.primary, size: 34),
                const SizedBox(height: 12),
                Text(
                  'Hoàn thành phiên ôn',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đúng ${state.correctAnswers} • Sai ${state.wrongAnswers}',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (decisionWords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Cần xử lý SRS',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          ...decisionWords.map(
            (result) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PitchAccentReading(
                      kana: result.item.vocab.kana,
                      pattern: result.item.vocab.pitchAccent,
                      romaji: result.item.vocab.romaji,
                      fontSize: 24,
                      textColor: colors.onSurface,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sai ${result.wrongAnswers} lần. Chọn cách điều chỉnh level.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: SegmentedButton<ReviewSrsDecision>(
                        segments: const [
                          ButtonSegment(
                            value: ReviewSrsDecision.minusOne,
                            icon: Icon(Icons.trending_down_rounded),
                            label: Text('Giảm 1 level'),
                          ),
                          ButtonSegment(
                            value: ReviewSrsDecision.reset,
                            icon: Icon(Icons.restart_alt_rounded),
                            label: Text('Reset Lv 1'),
                          ),
                        ],
                        selected: {
                          result.srsDecision ?? ReviewSrsDecision.minusOne,
                        },
                        onSelectionChanged: (value) => onDecision(
                          result.item.vocab.id,
                          value.single,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: state.isApplying ? null : onFinish,
          icon: state.isApplying
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: const Text('Áp dụng kết quả'),
        ),
      ],
    );
  }
}

class _NoReviewState extends StatelessWidget {
  const _NoReviewState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 44, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Chưa có từ để ôn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy thêm từ vựng trước khi bắt đầu phiên ôn tập.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
