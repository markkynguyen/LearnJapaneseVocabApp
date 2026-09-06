import 'package:flutter/material.dart';

/// Tiêu đề chung cho các mục trong phần chi tiết Hán tự và Bộ thủ.
class KanjiSectionHeading extends StatelessWidget {
  const KanjiSectionHeading(this.text, {super.key, this.maxLines});

  final String text;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
      );
}
