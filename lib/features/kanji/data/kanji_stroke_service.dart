import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_drawing/path_drawing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../domain/kanji_models.dart';

class StrokeDocument {
  StrokeDocument(this.paths, this.viewBox)
      : _staticSvg = null,
        _staticPathCount = 0;
  StrokeDocument._static(this.viewBox, this._staticSvg, this._staticPathCount)
      : paths = const [];
  final List<Path> paths;
  final Rect viewBox;
  final String? _staticSvg;
  final int _staticPathCount;
  bool get supportsAnimation => _staticSvg == null;
  int get strokeCount => supportsAnimation ? paths.length : _staticPathCount;

  String staticSvgAt(int step) {
    final doc = XmlDocument.parse(_staticSvg!);
    final strokes = doc.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'path')
        .toList();
    for (final path in strokes.skip(step.clamp(0, strokeCount))) {
      path.parent!.children.remove(path);
    }
    return doc.toXmlString();
  }

  factory StrokeDocument.parse(String svg) {
    if (svg.length > 256 * 1024) throw const FormatException('SVG quá lớn.');
    final doc = XmlDocument.parse(svg);
    final root = doc.rootElement;
    if (root.name.local != 'svg') {
      throw const FormatException('Không phải SVG.');
    }
    final box = (root.getAttribute('viewBox') ?? '0 0 109 109')
        .split(RegExp(r'[\s,]+'))
        .map(double.parse)
        .toList();
    if (box.length != 4 ||
        box.any((v) => !v.isFinite) ||
        box[2] <= 0 ||
        box[3] <= 0) {
      throw const FormatException('Khung SVG không hợp lệ.');
    }
    final groups = doc.descendants.whereType<XmlElement>().where(
          (e) =>
              e.name.local == 'g' &&
              (e.getAttribute('id') ?? '').contains('StrokePaths'),
        );
    if (groups.isEmpty) throw const FormatException('Thiếu dữ liệu nét.');
    final viewBox = Rect.fromLTWH(box[0], box[1], box[2], box[3]);
    try {
      for (XmlNode? ancestor = groups.first;
          ancestor is XmlElement;
          ancestor = ancestor.parent) {
        if (ancestor.getAttribute('transform') != null) {
          throw const FormatException('Animation does not support transforms.');
        }
      }
      final paths = <Path>[];
      for (final element in groups.first.descendants.whereType<XmlElement>()) {
        // KanjiVG main SVG uses absolute path coordinates; fail closed on a new
        // transformed format instead of silently drawing misplaced strokes.
        if (element.getAttribute('transform') != null) {
          throw const FormatException('Định dạng biến đổi SVG chưa hỗ trợ.');
        }
        if (element.name.local != 'path') continue;
        final path = parseSvgPathData(element.getAttribute('d') ?? '');
        if (path.computeMetrics().isEmpty) {
          throw const FormatException('Nét rỗng.');
        }
        paths.add(path);
      }
      if (paths.isEmpty || paths.length > 64) {
        throw const FormatException('Số nét không hợp lệ.');
      }
      return StrokeDocument(paths, viewBox);
    } catch (_) {
      return _staticFallback(root, groups.first, viewBox);
    }
  }

  // The general SVG renderer can display transformed paths that our animation
  // parser cannot measure. Rebuild a path-only document: never pass scripts,
  // images, URLs, CSS, foreignObject or other active content to that renderer.
  static StrokeDocument _staticFallback(
    XmlElement root,
    XmlElement strokeGroup,
    Rect box,
  ) {
    var count = 0;
    XmlElement? clean(XmlElement element, bool inStrokes) {
      final name = element.name.local;
      if (!['svg', 'g', 'path'].contains(name)) return null;
      inStrokes = inStrokes || identical(element, strokeGroup);
      if (name == 'path' && !inStrokes) return null;
      final attributes = <XmlAttribute>[];
      final transform = element.getAttribute('transform');
      if (transform != null) {
        attributes.add(XmlAttribute(XmlName('transform'), transform));
      }
      if (name == 'path') {
        final d = element.getAttribute('d');
        if (d == null || d.trim().isEmpty) {
          throw const FormatException('Nét rỗng.');
        }
        if (parseSvgPathData(d).computeMetrics().isEmpty) {
          throw const FormatException('Nét không hợp lệ.');
        }
        count++;
        attributes.add(XmlAttribute(XmlName('d'), d));
      }
      final children = element.childElements
          .map((e) => clean(e, inStrokes))
          .whereType<XmlElement>()
          .toList();
      return XmlElement(
        XmlName(name == 'svg' ? 'g' : name),
        attributes,
        children,
      );
    }

    final drawing = clean(root, false)!;
    if (count < 1 || count > 64) {
      throw const FormatException('Số nét không hợp lệ.');
    }
    final svg = XmlElement(XmlName('svg'), [
      XmlAttribute(XmlName('xmlns'), 'http://www.w3.org/2000/svg'),
      XmlAttribute(
        XmlName('viewBox'),
        '${box.left} ${box.top} ${box.width} ${box.height}',
      ),
      XmlAttribute(XmlName('fill'), 'none'),
      XmlAttribute(XmlName('stroke'), '#000000'),
      XmlAttribute(XmlName('stroke-width'), '3'),
      XmlAttribute(XmlName('stroke-linecap'), 'round'),
      XmlAttribute(XmlName('stroke-linejoin'), 'round'),
    ], [
      drawing,
    ]);
    return StrokeDocument._static(box, svg.toXmlString(), count);
  }
}

abstract interface class StrokeCache {
  Future<String?> read(String key);
  Future<void> write(String key, String svg);
  Future<void> remove(String key);
}

/// SharedPreferences maps to native persistent storage and browser storage.
/// Public SVG only; bounded at 2 MiB. A quota failure never blocks the viewer.
class PersistentStrokeCache implements StrokeCache {
  static const prefix = 'kanjivg.v1.';
  Future<void> _writes = Future.value();
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);
  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }

  @override
  Future<void> write(String key, String svg) {
    final operation = _writes.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      final keys = preferences.getStringList('${prefix}order') ?? [];
      keys.remove(key);
      keys.add(key);
      await preferences.setString(key, svg);
      var bytes = keys.fold<int>(
        0,
        (sum, k) => sum + (preferences.getString(k)?.length ?? 0) * 2,
      );
      while (
          (bytes > 2 * 1024 * 1024 || keys.length > 100) && keys.length > 1) {
        final oldest = keys.removeAt(0);
        bytes -= (preferences.getString(oldest)?.length ?? 0) * 2;
        await preferences.remove(oldest);
      }
      await preferences.setStringList('${prefix}order', keys);
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}

class KanjiStrokeService {
  KanjiStrokeService({
    required this.client,
    required this.cache,
    required this.version,
  });
  final http.Client client;
  final StrokeCache cache;
  final String version;
  final _memory = <String, StrokeDocument>{};
  final _inFlight = <String, Future<StrokeDocument>>{};

  String cacheKey(String character) {
    final codes = character.runes.toList();
    if (codes.length != 1 || !isKanjiCodePoint(codes.single)) {
      throw const FormatException('Chữ Hán không hợp lệ.');
    }
    return '${PersistentStrokeCache.prefix}$version.${codes.single.toRadixString(16).padLeft(5, '0')}';
  }

  Future<StrokeDocument> load(String character) async {
    final key = cacheKey(character);
    final memory = _memory.remove(key);
    if (memory != null) {
      _memory[key] = memory;
      return memory;
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final future = _load(character, key);
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<StrokeDocument> _load(String character, String key) async {
    try {
      final cached = await cache.read(key);
      if (cached != null) {
        final parsed = StrokeDocument.parse(cached);
        _remember(key, parsed);
        return parsed;
      }
    } catch (_) {
      try {
        await cache.remove(key);
      } catch (_) {}
    }
    final file = character.runes.single.toRadixString(16).padLeft(5, '0');
    final uri = Uri.https(
      'cdn.jsdelivr.net',
      '/gh/KanjiVG/kanjivg@$version/kanji/$file.svg',
    );
    final response = await client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('Không tải được nét (${response.statusCode}).');
    }
    final svg = utf8.decode(response.bodyBytes);
    final parsed = StrokeDocument.parse(svg);
    _remember(key, parsed);
    try {
      await cache.write(key, svg);
    } catch (_) {}
    return parsed;
  }

  void _remember(String key, StrokeDocument parsed) {
    _memory[key] = parsed;
    while (_memory.length > 64) {
      _memory.remove(_memory.keys.first);
    }
  }
}

final kanjiStrokeServiceProvider =
    FutureProvider<KanjiStrokeService>((ref) async {
  final sources =
      jsonDecode(await rootBundle.loadString('assets/kanji/sources.json'))
          as Map<String, dynamic>;
  final client = http.Client();
  ref.onDispose(client.close);
  return KanjiStrokeService(
    client: client,
    cache: PersistentStrokeCache(),
    version: sources['kanjivg_commit'] as String,
  );
});
final kanjiStrokesProvider =
    FutureProvider.autoDispose.family<StrokeDocument, String>(
  (ref, character) async =>
      (await ref.watch(kanjiStrokeServiceProvider.future)).load(character),
);
