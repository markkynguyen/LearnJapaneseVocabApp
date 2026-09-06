import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('home vocab search filters on the server before applying result limit',
      () async {
    final server = await _SearchServer.start([
      _row(
        id: 'vocab-101',
        folderId: 'folder-1',
        romaji: 'taberu',
        meaning: 'ăn',
      ),
    ]);
    addTearDown(server.close);

    final client = SupabaseClient(
      server.supabaseUrl,
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final results = await CloudStore(client).searchAllVocab('taberu', limit: 4);
    final requestUri = await server.lastRequestUri;

    expect(results, hasLength(1));
    expect(results.single.item.vocab.id, 'vocab-101');
    expect(results.single.folder.name, 'Động từ N5');
    expect(requestUri.path, '/rest/v1/vocabulary');
    expect(requestUri.queryParameters['limit'], '4');
    expect(
      requestUri.queryParameters['or'],
      contains('romaji.ilike."%taberu%"'),
    );
    expect(
      requestUri.queryParameters['or'],
      contains('meaning.ilike."%taberu%"'),
    );
  });

  test('Kanji vocabulary lookup filters under RLS and reads every page',
      () async {
    final server = await _PagingServer.start([
      _row(
        id: 'vocab-1',
        folderId: 'folder-paused',
        romaji: 'ane',
        meaning: 'chị gái',
        kanji: '姉',
        kana: 'あね',
      ),
      _row(
        id: 'vocab-2',
        folderId: 'folder-2',
        romaji: 'shimai',
        meaning: 'chị em',
        kanji: '姉妹',
        kana: 'しまい',
      ),
      _row(
        id: 'vocab-3',
        folderId: 'folder-3',
        romaji: 'oneesan',
        meaning: 'chị',
        kanji: 'お姉さん',
        kana: 'おねえさん',
      ),
    ]);
    addTearDown(server.close);
    final client = SupabaseClient(
      server.supabaseUrl,
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final results = await CloudStore(client).getVocabContainingKanji(
      '姉',
      pageSize: 2,
    );

    expect(results.map((vocab) => vocab.id), [
      'vocab-1',
      'vocab-2',
      'vocab-3',
    ]);
    expect(server.requests, hasLength(2));
    expect(server.requests.first.uri.path, '/rest/v1/vocabulary');
    expect(server.requests.first.uri.queryParameters['kanji'], 'like.%姉%');
    expect(
      server.requests.first.uri.queryParameters,
      isNot(contains('folders.is_study_paused')),
    );
    expect(server.requests.first.uri.queryParameters['offset'], '0');
    expect(server.requests.first.uri.queryParameters['limit'], '2');
    expect(server.requests.last.uri.queryParameters['offset'], '2');
    expect(server.requests.last.uri.queryParameters['limit'], '2');
  });

  test('Kanji catalog lookup batches and deduplicates characters', () async {
    final server = await _SearchServer.start([
      _kanjiRow('姉', on: ['シ'], kun: ['あね']),
      _kanjiRow('妹', on: ['マイ'], kun: ['いもうと']),
    ]);
    addTearDown(server.close);
    final client = SupabaseClient(
      server.supabaseUrl,
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final rows = await CloudStore(client).getKanjiByCharacters(['妹', '姉', '姉']);
    final requestUri = await server.lastRequestUri;
    final filter = requestUri.queryParameters['character'];

    expect(rows.map((row) => row['character']), ['姉', '妹']);
    expect(filter, startsWith('in.('));
    expect(filter, contains('姉'));
    expect(filter, contains('妹'));
  });

  test('related Kanji lookup filters by both radical family and form',
      () async {
    final server = await _SearchServer.start([
      {'kanji_id': '休'.runes.single},
    ]);
    addTearDown(server.close);
    final client = SupabaseClient(
      server.supabaseUrl,
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    final ids = await CloudStore(client).getKanjiIdsForRadicalForm(9, '亻');
    final requestUri = await server.lastRequestUri;

    expect(ids, {'休'.runes.single});
    expect(requestUri.path, '/rest/v1/kanji_components');
    expect(requestUri.queryParameters['radical_id'], 'eq.9');
    expect(requestUri.queryParameters['component_form'], 'eq.亻');
  });
}

class _SearchServer {
  _SearchServer(this._server, this._rows);

  final HttpServer _server;
  final List<Map<String, dynamic>> _rows;
  final _requestCompleter = Completer<Uri>();

  Future<Uri> get lastRequestUri => _requestCompleter.future;
  String get supabaseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_SearchServer> start(List<Map<String, dynamic>> rows) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final searchServer = _SearchServer(server, rows);
    searchServer._listen();
    return searchServer;
  }

  Future<void> close() => _server.close(force: true);

  void _listen() {
    _server.listen((request) async {
      if (!_requestCompleter.isCompleted) {
        _requestCompleter.complete(request.uri);
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(_rows));
      await request.response.close();
    });
  }
}

Map<String, dynamic> _row({
  required String id,
  required String folderId,
  required String romaji,
  required String meaning,
  String kanji = '食べる',
  String kana = 'たべる',
}) {
  return {
    'id': id,
    'folder_id': folderId,
    'kanji': kanji,
    'kana': kana,
    'romaji': romaji,
    'meaning': meaning,
    'pitch_accent': 'HHL',
    'example': null,
    'note': null,
    'is_favorite': false,
    'created_at': '2026-08-19T00:00:00Z',
    'updated_at': '2026-08-19T00:00:00Z',
    'folders': {
      'id': folderId,
      'name': 'Động từ N5',
      'description': null,
      'color': '#6366F1',
      'created_at': '2026-08-19T00:00:00Z',
      'updated_at': '2026-08-19T00:00:00Z',
    },
    'srs_progress': {
      'vocab_id': id,
      'level': 1,
      'interval_days': 1,
      'next_review_at': '2026-08-20T00:00:00Z',
      'correct_count': 0,
      'wrong_count': 0,
      'last_reviewed_at': null,
      'updated_at': '2026-08-19T00:00:00Z',
    },
  };
}

Map<String, dynamic> _kanjiRow(
  String character, {
  required List<String> on,
  required List<String> kun,
}) =>
    {
      'id': character.runes.single,
      'character': character,
      'han_viet': null,
      'onyomi': on,
      'kunyomi': kun,
      'meaning_vi': null,
      'meaning_en': 'test',
      'stroke_count': 1,
      'grade': 1,
      'primary_radical_id': 1,
      'translation_reviewed': false,
    };

class _PagingRequest {
  const _PagingRequest(this.uri);
  final Uri uri;
}

class _PagingServer {
  _PagingServer(this._server, this._rows);

  final HttpServer _server;
  final List<Map<String, dynamic>> _rows;
  final requests = <_PagingRequest>[];
  var _page = 0;

  String get supabaseUrl => 'http://127.0.0.1:${_server.port}';

  static Future<_PagingServer> start(List<Map<String, dynamic>> rows) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final pagingServer = _PagingServer(server, rows);
    pagingServer._listen();
    return pagingServer;
  }

  Future<void> close() => _server.close(force: true);

  void _listen() {
    _server.listen((request) async {
      requests.add(_PagingRequest(request.uri));
      final start = _page * 2;
      final end = (start + 2 < _rows.length) ? start + 2 : _rows.length;
      final responseRows = _rows.sublist(start, end);
      _page++;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(responseRows));
      await request.response.close();
    });
  }
}
