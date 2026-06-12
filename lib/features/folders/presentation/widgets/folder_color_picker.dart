import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class FolderColorPicker extends StatelessWidget {
  const FolderColorPicker({
    required this.selectedColor,
    required this.onChanged,
    super.key,
  });

  final String selectedColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.folderPresets.map((color) {
        final hex = colorToHex(color);
        final selected = hex == selectedColor;

        return Tooltip(
          message: hex,
          child: InkResponse(
            onTap: () => onChanged(hex),
            radius: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.onSurface : colors.outline,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  static String colorToHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
