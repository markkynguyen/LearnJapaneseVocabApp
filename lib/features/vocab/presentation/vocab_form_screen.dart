import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/vocab_form_provider.dart';
import 'widgets/pitch_accent_picker.dart';

class VocabFormScreen extends ConsumerStatefulWidget {
  const VocabFormScreen({
    required this.folderId,
    this.vocabId,
    super.key,
  });

  final int folderId;
  final int? vocabId;

  @override
  ConsumerState<VocabFormScreen> createState() => _VocabFormScreenState();
}

class _VocabFormScreenState extends ConsumerState<VocabFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kanjiController;
  late final TextEditingController _kanaController;
  late final TextEditingController _romajiController;
  late final TextEditingController _meaningController;
  late final TextEditingController _pitchAccentController;
  late final TextEditingController _exampleController;
  late final TextEditingController _noteController;

  bool _didFillInitialValues = false;

  bool get _isEditing => widget.vocabId != null;

  @override
  void initState() {
    super.initState();
    _kanjiController = TextEditingController();
    _kanaController = TextEditingController();
    _romajiController = TextEditingController();
    _meaningController = TextEditingController();
    _pitchAccentController = TextEditingController();
    _exampleController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _kanjiController.dispose();
    _kanaController.dispose();
    _romajiController.dispose();
    _meaningController.dispose();
    _pitchAccentController.dispose();
    _exampleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabId = widget.vocabId;
    final item = vocabId == null
        ? const AsyncValue<VocabWithProgress?>.data(null)
        : ref.watch(vocabFormItemProvider(vocabId));

    return item.when(
      data: (item) {
        if (_isEditing && item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Sửa từ vựng')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không tìm thấy từ vựng cần sửa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appDanger),
                ),
              ),
            ),
          );
        }

        _fillInitialValues(item?.vocab);
        return _VocabFormBody(
          formKey: _formKey,
          isEditing: _isEditing,
          item: item,
          kanjiController: _kanjiController,
          kanaController: _kanaController,
          romajiController: _romajiController,
          meaningController: _meaningController,
          pitchAccentController: _pitchAccentController,
          exampleController: _exampleController,
          noteController: _noteController,
          onSubmit: () => _submit(item?.vocab),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Sửa từ vựng' : 'Thêm từ mới')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Sửa từ vựng' : 'Thêm từ mới')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Không thể tải từ vựng: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appDanger),
            ),
          ),
        ),
      ),
    );
  }

  void _fillInitialValues(VocabularyEntry? vocab) {
    if (_didFillInitialValues || vocab == null) {
      return;
    }

    _kanjiController.text = vocab.kanji ?? '';
    _kanaController.text = vocab.kana;
    _romajiController.text = vocab.romaji;
    _meaningController.text = vocab.meaning;
    _pitchAccentController.text = vocab.pitchAccent ?? '';
    _exampleController.text = vocab.example ?? '';
    _noteController.text = vocab.note ?? '';
    _didFillInitialValues = true;
  }

  Future<void> _submit(VocabularyEntry? existing) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = ref.read(vocabFormControllerProvider.notifier);
    if (existing == null) {
      await controller.create(
        folderId: widget.folderId,
        kanji: _kanjiController.text,
        kana: _kanaController.text,
        romaji: _romajiController.text,
        meaning: _meaningController.text,
        pitchAccent: _pitchAccentController.text,
        example: _exampleController.text,
        note: _noteController.text,
      );
    } else {
      await controller.updateExisting(
        existing: existing,
        kanji: _kanjiController.text,
        kana: _kanaController.text,
        romaji: _romajiController.text,
        meaning: _meaningController.text,
        pitchAccent: _pitchAccentController.text,
        example: _exampleController.text,
        note: _noteController.text,
      );
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(vocabFormControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu từ vựng: ${state.error}')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing == null ? 'Đã thêm từ mới' : 'Đã cập nhật từ'),
      ),
    );
    Navigator.of(context).maybePop();
  }
}

class _VocabFormBody extends ConsumerWidget {
  const _VocabFormBody({
    required this.formKey,
    required this.isEditing,
    required this.item,
    required this.kanjiController,
    required this.kanaController,
    required this.romajiController,
    required this.meaningController,
    required this.pitchAccentController,
    required this.exampleController,
    required this.noteController,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isEditing;
  final VocabWithProgress? item;
  final TextEditingController kanjiController;
  final TextEditingController kanaController;
  final TextEditingController romajiController;
  final TextEditingController meaningController;
  final TextEditingController pitchAccentController;
  final TextEditingController exampleController;
  final TextEditingController noteController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(vocabFormControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: controllerState.isLoading ? null : onSubmit,
                icon: controllerState.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ),
        ],
        title: Text(isEditing ? 'Sửa từ vựng' : 'Thêm từ mới'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _PreviewCard(
                kanjiController: kanjiController,
                kanaController: kanaController,
                romajiController: romajiController,
                meaningController: meaningController,
              ),
              const SizedBox(height: 18),
              const _SectionLabel(text: 'Thông tin chính'),
              const SizedBox(height: 10),
              TextFormField(
                controller: kanjiController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kanji',
                  hintText: 'VD: 食べる',
                  prefixIcon: Icon(Icons.translate_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: kanaController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kana *',
                  hintText: 'VD: たべる',
                  prefixIcon: Icon(Icons.text_fields_rounded),
                ),
                validator: (value) => _required(value, 'Vui lòng nhập kana'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: romajiController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Romaji *',
                  hintText: 'VD: taberu',
                  prefixIcon: Icon(Icons.abc_rounded),
                ),
                validator: (value) => _required(value, 'Vui lòng nhập romaji'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: meaningController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nghĩa *',
                  hintText: 'VD: ăn',
                  prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                ),
                validator: (value) => _required(value, 'Vui lòng nhập nghĩa'),
              ),
              const SizedBox(height: 22),
              const _SectionLabel(text: 'Thông tin bổ sung'),
              const SizedBox(height: 10),
              PitchAccentPicker(
                kanaController: kanaController,
                pitchAccentController: pitchAccentController,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: exampleController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Ví dụ',
                  hintText: 'VD: 朝ご飯を食べます。',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Đồng nghĩa, sắc thái, mẹo nhớ, lưu ý dùng từ...',
                  alignLabelWithHint: true,
                  helperText: 'Tùy chọn, dùng để lưu ý cá nhân khi học.',
                  helperStyle: TextStyle(color: colors.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: controllerState.isLoading ? null : onSubmit,
                  icon: controllerState.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(isEditing ? 'Lưu thay đổi' : 'Thêm từ'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value, String message) {
    if ((value ?? '').trim().isEmpty) {
      return message;
    }
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _PreviewCard extends StatefulWidget {
  const _PreviewCard({
    required this.kanjiController,
    required this.kanaController,
    required this.romajiController,
    required this.meaningController,
  });

  final TextEditingController kanjiController;
  final TextEditingController kanaController;
  final TextEditingController romajiController;
  final TextEditingController meaningController;

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_onChanged);
    }
    super.dispose();
  }

  List<TextEditingController> get _controllers => [
        widget.kanjiController,
        widget.kanaController,
        widget.romajiController,
        widget.meaningController,
      ];

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = widget.kanjiController.text.trim().isNotEmpty
        ? widget.kanjiController.text.trim()
        : widget.kanaController.text.trim().isNotEmpty
            ? widget.kanaController.text.trim()
            : 'Từ mới';
    final subtitle = [
      widget.kanaController.text.trim(),
      widget.romajiController.text.trim(),
    ].where((value) => value.isNotEmpty).join(' • ');
    final meaning = widget.meaningController.text.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    meaning.isEmpty ? 'Nghĩa sẽ hiển thị tại đây' : meaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: meaning.isEmpty
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                      fontWeight:
                          meaning.isEmpty ? FontWeight.w400 : FontWeight.w700,
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
}
