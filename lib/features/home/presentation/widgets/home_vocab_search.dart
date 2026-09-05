import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/constants/srs_constants.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/japanese_mixed_text.dart';
import '../../../vocab/presentation/widgets/pitch_accent_text.dart';
import '../../../vocab/presentation/widgets/vocabulary_study_card.dart';
import '../../../vocab/presentation/providers/vocab_list_provider.dart';
import '../providers/home_provider.dart';

class HomeVocabSearch extends ConsumerStatefulWidget {
  const HomeVocabSearch({super.key});

  @override
  ConsumerState<HomeVocabSearch> createState() => _HomeVocabSearchState();
}

class _HomeVocabSearchState extends ConsumerState<HomeVocabSearch> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _input = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(homeVocabSuggestionsProvider(_query));
    final isDebouncing = _input.trim() != _query;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Tra kanji, kana, romaji hoặc nghĩa...',
            suffixIcon: _input.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          onChanged: _onChanged,
        ),
        if (_input.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (isDebouncing)
            const LinearProgressIndicator(minHeight: 2)
          else
            suggestions.when(
              data: (items) => _SuggestionPanel(
                items: items,
                onSelected: _showDetails,
              ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (error, _) => const _SearchMessage(
                icon: Icons.error_outline_rounded,
                message: 'Không thể tìm từ lúc này.',
                isError: true,
              ),
            ),
        ],
      ],
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _input = value);
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _input = '';
      _query = '';
    });
  }

  Future<void> _showDetails(VocabSearchResult result) {
    FocusScope.of(context).unfocus();
    final pageContext = context;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _HomeVocabDetailDialog(
        result: result,
        onEdit: () => pageContext.push(
          AppRoutes.editVocab(
            result.item.vocab.id,
            folderId: result.item.vocab.folderId,
          ),
        ),
      ),
    );
  }
}

class _HomeVocabDetailDialog extends ConsumerStatefulWidget {
  const _HomeVocabDetailDialog({
    required this.result,
    required this.onEdit,
  });

  final VocabSearchResult result;
  final VoidCallback onEdit;

  @override
  ConsumerState<_HomeVocabDetailDialog> createState() =>
      _HomeVocabDetailDialogState();
}

class _HomeVocabDetailDialogState
    extends ConsumerState<_HomeVocabDetailDialog> {
  late int _level;
  bool _isApplyingSrs = false;

  @override
  void initState() {
    super.initState();
    _level = widget.result.item.progress.level;
  }

  bool get _canAdjustSrs => _level >= SrsConstants.minLevel + 1;

  VocabWithProgress get _currentItem => VocabWithProgress(
        vocab: widget.result.item.vocab,
        progress: widget.result.item.progress.copyWith(level: _level),
      );

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.sizeOf(context).height * 0.82,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(Icons.folder_rounded, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Phát âm',
                      onPressed: () => ref
                          .read(audioServiceProvider)
                          .speak(result.item.vocab),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: VocabularyStudyCard(
                    vocab: result.item.vocab,
                    emptyDetailsMessage: null,
                    framed: false,
                  ),
                ),
              ),
              Divider(height: 1, color: colors.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _isApplyingSrs ? null : _openEdit,
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Sửa từ vựng'),
                      ),
                    ),
                    if (_canAdjustSrs) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isApplyingSrs
                                  ? null
                                  : () => _confirmAndApply(_SrsAction.minusOne),
                              icon: const Icon(Icons.trending_down_rounded),
                              label: const Text('Giảm 1 level'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isApplyingSrs
                                  ? null
                                  : () => _confirmAndApply(_SrsAction.reset),
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset về level 1'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEdit() {
    Navigator.of(context).pop();
    widget.onEdit();
  }

  Future<void> _confirmAndApply(_SrsAction action) async {
    final targetLevel =
        action == _SrsAction.minusOne ? _level - 1 : SrsConstants.minLevel;
    final actionLabel =
        action == _SrsAction.minusOne ? 'Giảm 1 level' : 'Reset về level 1';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel?'),
        content: JapaneseMixedText(
          'Từ "${widget.result.item.vocab.kana}" sẽ chuyển từ Lv $_level '
          'về Lv $targetLevel. Lịch ôn sẽ được tính lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isApplyingSrs = true);
    final controller = ref.read(vocabListControllerProvider.notifier);
    if (action == _SrsAction.minusOne) {
      await controller.manualMinus1(_currentItem);
    } else {
      await controller.manualReset(_currentItem);
    }

    if (!mounted) {
      return;
    }
    final update = ref.read(vocabListControllerProvider);
    setState(() => _isApplyingSrs = false);
    if (update.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật level. Hãy thử lại.')),
      );
      return;
    }

    setState(() => _level = targetLevel);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã $actionLabel'.replaceFirst('Reset', 'reset'))),
    );
  }
}

enum _SrsAction { minusOne, reset }

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.items,
    required this.onSelected,
  });

  final List<VocabSearchResult> items;
  final ValueChanged<VocabSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _SearchMessage(
        icon: Icons.search_off_rounded,
        message: 'Không tìm thấy từ phù hợp.',
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: Scrollbar(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: colors.outlineVariant,
            ),
            itemBuilder: (context, index) => _SuggestionTile(
              result: items[index],
              onTap: () => onSelected(items[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.result, required this.onTap});

  final VocabSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vocab = result.item.vocab;
    final colors = Theme.of(context).colorScheme;
    final hasKanji = vocab.kanji?.trim().isNotEmpty == true;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: hasKanji
                      ? Text(
                          vocab.kanji!.trim(),
                          overflow: TextOverflow.ellipsis,
                          locale: AppTypography.japaneseLocale,
                          style: AppTypography.kanji(
                            context,
                            Theme.of(context).textTheme.titleLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : PitchAccentText(
                          kana: vocab.kana,
                          pattern: vocab.pitchAccent,
                          fontSize: 22,
                          overlayAccent: true,
                        ),
                ),
                if (hasKanji) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: PitchAccentText(
                      kana: vocab.kana,
                      pattern: vocab.pitchAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      textColor: colors.onSurfaceVariant,
                      overlayAccent: true,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              vocab.meaning,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    result.folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
