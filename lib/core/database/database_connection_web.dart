// ignore_for_file: experimental_member_use

import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final storage = await DriftWebStorage.indexedDbIfSupported('jvocab');
    return WebDatabase.withStorage(storage);
  });
}
