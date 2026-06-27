import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../import_export/presentation/providers/import_export_provider.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final importExportState = ref.watch(importExportControllerProvider);
    final colors = Theme.of(context).colorScheme;
    final isImportExportBusy = importExportState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: settings.when(
          data: (settings) {
            final selected = settings.themeMode == darkThemeModeValue
                ? ThemeMode.dark
                : ThemeMode.light;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (isImportExportBusy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 14),
                ],
                const _SectionTitle(title: 'Giao diện'),
                const SizedBox(height: 12),
                _ThemeCard(
                  selected: selected,
                  isBusy: false,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .updateThemeMode(value),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Hiển thị trong quiz'),
                const SizedBox(height: 12),
                _QuizScriptCard(
                  selected: settings.quizJapaneseScript,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .updateQuizJapaneseScript(value),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Học từ mới'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _NumberSettingTile(
                        icon: Icons.auto_stories_rounded,
                        title: 'Số từ mới mỗi phiên',
                        subtitle: 'Giới hạn từ 1 đến 100 từ.',
                        value: settings.newWordSessionSize,
                        min: 1,
                        max: 100,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateNewWordSessionSize(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.hearing_rounded,
                        title: 'Nghe',
                        subtitle: 'Số câu nghe cho mỗi từ mới.',
                        value: settings.newWordListenCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateNewWordListenCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.edit_rounded,
                        title: 'Viết',
                        subtitle: 'Số lượt viết chấm điểm cho mỗi từ mới.',
                        value: settings.newWordWriteCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateNewWordWriteCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.translate_rounded,
                        title: 'Chọn từ',
                        subtitle: 'Chọn chữ Nhật theo nghĩa.',
                        value: settings.newWordChooseWordCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateNewWordChooseWordCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.quiz_rounded,
                        title: 'Chọn nghĩa',
                        subtitle: 'Chọn nghĩa theo chữ Nhật.',
                        value: settings.newWordChooseMeaningCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateNewWordChooseMeaningCount(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Phiên ôn tập'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _NumberSettingTile(
                        icon: Icons.fact_check_rounded,
                        title: 'Số từ mỗi phiên',
                        subtitle: 'Giới hạn từ 1 đến 100 từ.',
                        value: settings.sessionSize,
                        min: 1,
                        max: 100,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateSessionSize(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.replay_rounded,
                        title: 'Số lần làm lại câu sai',
                        subtitle: 'Giới hạn từ 0 đến 5 lần.',
                        value: settings.quizRetryLimit,
                        min: 0,
                        max: 5,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateQuizRetryLimit(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Loại câu hỏi ôn tập'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _NumberSettingTile(
                        icon: Icons.hearing_rounded,
                        title: 'Nghe',
                        subtitle: 'Nghe phát âm và chọn nghĩa.',
                        value: settings.quizListenCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateQuizListenCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.edit_rounded,
                        title: 'Viết',
                        subtitle: 'Từ nghĩa tiếng Việt tự viết đáp án Nhật.',
                        value: settings.quizWriteCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateQuizWriteCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.translate_rounded,
                        title: 'Chọn từ',
                        subtitle: 'Từ nghĩa tiếng Việt chọn đáp án Nhật.',
                        value: settings.quizChooseWordCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateQuizChooseWordCount(value),
                      ),
                      const Divider(height: 1),
                      _NumberSettingTile(
                        icon: Icons.quiz_rounded,
                        title: 'Chọn nghĩa',
                        subtitle: 'Từ tiếng Nhật chọn nghĩa tiếng Việt.',
                        value: settings.quizChooseMeaningCount,
                        min: 0,
                        max: 10,
                        onChanged: (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .updateQuizChooseMeaningCount(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Khoảng cách SRS'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      for (var level = 1; level <= 6; level++) ...[
                        _SrsIntervalTile(
                          level: level,
                          days: _srsIntervalForLevel(settings, level),
                          enabled: true,
                          onTap: () => _showSrsIntervalDialog(
                            context,
                            ref,
                            level,
                            _srsIntervalForLevel(settings, level),
                          ),
                        ),
                        if (level < 6) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Nhắc ôn tập'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          Icons.notifications_active_rounded,
                          color: settings.notifyEnabled
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        title: const Text('Nhắc học mỗi ngày'),
                        subtitle: Text(
                          settings.notifyEnabled
                              ? 'Nana App sẽ nhắc bạn lúc ${_formatReminderTime(settings.notifyHour, settings.notifyMinute)}.'
                              : 'Bật để nhận nhắc nhở ôn tập từ vùng nhớ hằng ngày.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        value: settings.notifyEnabled,
                        onChanged: (enabled) async {
                          final messenger = ScaffoldMessenger.of(context);
                          final granted = await ref
                              .read(settingsControllerProvider.notifier)
                              .updateReminderEnabled(enabled);
                          if (!context.mounted) {
                            return;
                          }
                          if (enabled && !granted) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bạn cần cấp quyền thông báo để bật nhắc nhở ôn tập.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: settings.notifyEnabled,
                        leading: const Icon(Icons.schedule_rounded),
                        title: const Text('Giờ nhắc'),
                        subtitle: Text(
                          _formatReminderTime(
                            settings.notifyHour,
                            settings.notifyMinute,
                          ),
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: settings.notifyEnabled
                            ? () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: settings.notifyHour,
                                    minute: settings.notifyMinute,
                                  ),
                                );
                                if (picked == null || !context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(settingsControllerProvider.notifier)
                                    .updateReminderTime(picked);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Dữ liệu'),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        enabled: !isImportExportBusy,
                        leading: const Icon(Icons.upload_file_rounded),
                        title: const Text('Import Excel'),
                        subtitle: Text(
                          'Khôi phục từ file .xlsx đã xuất hoặc file mẫu.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        onTap: !isImportExportBusy
                            ? () => context.push(AppRoutes.settingsImport)
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !isImportExportBusy,
                        leading: const Icon(Icons.ios_share_rounded),
                        title: const Text('Export Excel'),
                        subtitle: Text(
                          'Sao lưu một bộ từ hoặc toàn bộ dữ liệu.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        onTap: !isImportExportBusy
                            ? () => context.push(AppRoutes.settingsExport)
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !isImportExportBusy,
                        leading: const Icon(Icons.description_rounded),
                        title: const Text('Mẫu Excel'),
                        subtitle: Text(
                          'Tạo file mẫu dùng header import của Nana App.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        onTap: !isImportExportBusy
                            ? () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final path = await ref
                                    .read(
                                      importExportControllerProvider.notifier,
                                    )
                                    .exportTemplate();
                                if (!context.mounted || path == null) {
                                  return;
                                }
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Đã tạo mẫu Excel: $path'),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Thông tin'),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Nana App'),
                    subtitle: Text(
                      'Phiên bản 1.0.0+1',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Không thể tải cài đặt: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appDanger),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSrsIntervalDialog(
    BuildContext context,
    WidgetRef ref,
    int level,
    double currentDays,
  ) async {
    final days = await showDialog<double>(
      context: context,
      builder: (context) => _SrsIntervalDialog(
        level: level,
        currentDays: currentDays,
      ),
    );
    if (days == null || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(settingsControllerProvider.notifier)
        .updateSrsInterval(level, days);
    if (!context.mounted) {
      return;
    }

    final state = ref.read(settingsControllerProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? 'Không thể lưu thời gian SRS: ${state.error}'
              : 'Đã lưu thời gian SRS Lv $level.',
        ),
      ),
    );
  }

  double _srsIntervalForLevel(AppSettings settings, int level) {
    return switch (level) {
      1 => settings.srsLevel1IntervalDays,
      2 => settings.srsLevel2IntervalDays,
      3 => settings.srsLevel3IntervalDays,
      4 => settings.srsLevel4IntervalDays,
      5 => settings.srsLevel5IntervalDays,
      6 => settings.srsLevel6IntervalDays,
      _ => settings.srsLevel1IntervalDays,
    };
  }

  String _formatReminderTime(int hour, int minute) {
    final normalizedHour = hour.clamp(0, 23);
    final normalizedMinute = minute.clamp(0, 59);
    return '${normalizedHour.toString().padLeft(2, '0')}:'
        '${normalizedMinute.toString().padLeft(2, '0')}';
  }
}

class _SrsIntervalDialog extends StatefulWidget {
  const _SrsIntervalDialog({
    required this.level,
    required this.currentDays,
  });

  final int level;
  final double currentDays;

  @override
  State<_SrsIntervalDialog> createState() => _SrsIntervalDialogState();
}

class _SrsIntervalDialogState extends State<_SrsIntervalDialog> {
  late bool _useHours;
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _useHours = widget.currentDays < 1;
    _controller = TextEditingController(
      text: _useHours
          ? _trimNumber(widget.currentDays * 24)
          : _trimNumber(widget.currentDays),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Lv ${widget.level}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Giờ')),
              ButtonSegment(value: false, label: Text('Ngày')),
            ],
            selected: {_useHours},
            onSelectionChanged: (value) {
              final parsed = _parseNumber(_controller.text);
              final currentValue = parsed ?? (_useHours ? 2 : 1);
              final newValue =
                  _useHours ? currentValue / 24 : currentValue * 24;
              setState(() {
                _useHours = value.single;
                _errorText = null;
                _controller.text = _trimNumber(newValue);
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              errorText: _errorText,
              labelText: _useHours ? 'Số giờ' : 'Số ngày',
              helperText: 'Có thể nhập số thập phân, ví dụ 2 hoặc 0,5.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final parsed = _parseNumber(_controller.text);
            if (parsed == null || parsed <= 0) {
              setState(() {
                _errorText = 'Vui lòng nhập số lớn hơn 0.';
              });
              return;
            }
            Navigator.of(context).pop(_useHours ? parsed / 24 : parsed);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.selected,
    required this.isBusy,
    required this.onChanged,
  });

  final ThemeMode selected;
  final bool isBusy;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chế độ màu',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chọn màu sáng hoặc tối để nhìn dễ chịu hơn',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('Sáng'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('Tối'),
                  ),
                ],
                selected: {selected},
                onSelectionChanged:
                    isBusy ? null : (value) => onChanged(value.single),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizScriptCard extends StatelessWidget {
  const _QuizScriptCard({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalized = selected == quizScriptKanaValue
        ? quizScriptKanaValue
        : quizScriptKanjiValue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chữ Nhật dùng để hỏi',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: quizScriptKanjiValue,
                    label: Text('Kanji'),
                  ),
                  ButtonSegment(
                    value: quizScriptKanaValue,
                    label: Text('Kana'),
                  ),
                ],
                selected: {normalized},
                onSelectionChanged: (value) => onChanged(value.single),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              normalized == quizScriptKanjiValue
                  ? 'Ưu tiên kanji; từ không có kanji sẽ dùng kana.'
                  : 'Mọi câu hỏi và lựa chọn sẽ dùng kana.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberSettingTile extends StatelessWidget {
  const _NumberSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StepperControl(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  const _StepperControl({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canDecrease = onChanged != null && value > min;
    final canIncrease = onChanged != null && value < max;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Giảm',
            onPressed: canDecrease ? () => onChanged!(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Tăng',
            onPressed: canIncrease ? () => onChanged!(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _SrsIntervalTile extends StatelessWidget {
  const _SrsIntervalTile({
    required this.level,
    required this.days,
    required this.enabled,
    required this.onTap,
  });

  final int level;
  final double days;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      enabled: enabled,
      leading: CircleAvatar(
        backgroundColor: colors.primary.withValues(alpha: 0.12),
        foregroundColor: colors.primary,
        child: Text(
          '$level',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      title: Text('Level $level'),
      subtitle: Text(
        _formatDays(days),
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: enabled ? onTap : null,
    );
  }

  String _formatDays(double days) {
    if (days < 1) {
      final hours = days * 24;
      return 'Sau ${_trim(hours)} giờ';
    }
    return 'Sau ${_trim(days)} ngày';
  }

  String _trim(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
