import 'package:flutter/material.dart';

import '../../../../core/pitch_accent/pitch_accent_utils.dart';

class PitchAccentPicker extends StatefulWidget {
  const PitchAccentPicker({
    required this.kanaController,
    required this.pitchAccentController,
    super.key,
  });

  final TextEditingController kanaController;
  final TextEditingController pitchAccentController;

  @override
  State<PitchAccentPicker> createState() => _PitchAccentPickerState();
}

class _PitchAccentPickerState extends State<PitchAccentPicker> {
  @override
  void initState() {
    super.initState();
    widget.kanaController.addListener(_syncPattern);
    widget.pitchAccentController.addListener(_onPatternChanged);
    _syncPattern();
  }

  @override
  void dispose() {
    widget.kanaController.removeListener(_syncPattern);
    widget.pitchAccentController.removeListener(_onPatternChanged);
    super.dispose();
  }

  void _syncPattern() {
    final next = resizePitchPattern(
      widget.pitchAccentController.text,
      widget.kanaController.text,
    );
    if (widget.pitchAccentController.text != next) {
      widget.pitchAccentController.text = next;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onPatternChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggle(int index) {
    final pattern = resizePitchPattern(
      widget.pitchAccentController.text,
      widget.kanaController.text,
    );
    if (index < 0 || index >= pattern.length) {
      return;
    }
    final chars = pattern.split('');
    chars[index] = chars[index] == 'H' ? 'L' : 'H';
    widget.pitchAccentController.text = chars.join();
  }

  @override
  Widget build(BuildContext context) {
    final kana = widget.kanaController.text.trim();
    final units = splitKanaMora(kana);
    final pattern = resizePitchPattern(widget.pitchAccentController.text, kana);
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pitch accent',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (units.isEmpty)
              Text(
                'Nhập kana để chọn mora High.',
                style: TextStyle(color: colors.onSurfaceVariant),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < units.length; i++)
                    _PitchToggle(
                      text: units[i],
                      isHigh: pattern[i] == 'H',
                      onTap: () => _toggle(i),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              'Chạm vào mora để bật/tắt High. Các mora không chọn là Low.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchToggle extends StatelessWidget {
  const _PitchToggle({
    required this.text,
    required this.isHigh,
    required this.onTap,
  });

  final String text;
  final bool isHigh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: isHigh
              ? colors.primary.withValues(alpha: 0.12)
              : colors.surfaceContainerHighest.withValues(alpha: 0.45),
          border: Border.all(
            color: isHigh ? colors.primary : colors.outline,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: isHigh ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              isHigh ? 'H' : 'L',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isHigh ? colors.primary : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
