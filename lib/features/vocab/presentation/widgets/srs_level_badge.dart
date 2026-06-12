import 'package:flutter/material.dart';

import '../../../../core/constants/srs_constants.dart';

class SrsLevelBadge extends StatelessWidget {
  const SrsLevelBadge({
    required this.level,
    super.key,
  });

  final int level;

  @override
  Widget build(BuildContext context) {
    final background =
        SrsConstants.levelColors[level] ?? SrsConstants.levelColors[1]!;
    final foreground =
        SrsConstants.levelTextColors[level] ?? SrsConstants.levelTextColors[1]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level >= SrsConstants.maxLevel ? 'Lv $level ★' : 'Lv $level',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
