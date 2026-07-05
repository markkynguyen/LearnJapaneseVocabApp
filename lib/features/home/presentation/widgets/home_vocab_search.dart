import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/models/app_models.dart';
import '../../../vocab/presentation/widgets/pitch_accent_text.dart';
import '../../../vocab/presentation/widgets/vocabulary_study_card.dart';
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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
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
                      Icon(
                        Icons.folder_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _SuggestionTile(
              result: items[index],
              onTap: () => onSelected(items[index]),
            ),
            if (index < items.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: colors.outlineVariant,
              ),
          ],
        ],
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
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
