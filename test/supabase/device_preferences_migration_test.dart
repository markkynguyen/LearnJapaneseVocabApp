import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device preference migration defaults and restricts Japanese fonts', () {
    final sql = File(
      'supabase/migrations/202609050001_add_japanese_font_preference.sql',
    ).readAsStringSync();

    expect(sql, contains("japanese_font text not null default 'klee_one'"));
    expect(sql, contains("'klee_one', 'biz_udpgothic'"));
  });
}
