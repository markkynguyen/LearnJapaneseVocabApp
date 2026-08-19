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
}) {
  return {
    'id': id,
    'folder_id': folderId,
    'kanji': '食べる',
    'kana': 'たべる',
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
