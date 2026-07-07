import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_models.dart';

part 'audio_service.g.dart';

class AudioService {
  AudioService({
    FlutterTts? tts,
    bool? isWeb,
    int webVoiceLoadAttempts = 10,
    Duration webVoiceRetryDelay = const Duration(milliseconds: 200),
  })  : _tts = tts ?? FlutterTts(),
        _isWeb = isWeb ?? kIsWeb,
        _webVoiceLoadAttempts = webVoiceLoadAttempts,
        _webVoiceRetryDelay = webVoiceRetryDelay;

  final FlutterTts _tts;
  final bool _isWeb;
  final int _webVoiceLoadAttempts;
  final Duration _webVoiceRetryDelay;
  final _playingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  Future<void>? _initialization;
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Stream<bool> get playingStream => _playingController.stream;

  Stream<String> get errorStream => _errorController.stream;

  Future<void> initialize() {
    if (_isInitialized) {
      return Future.value();
    }
    return _initialization ??= _initialize().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    _tts.setStartHandler(() => _setPlaying(true));
    _tts.setCompletionHandler(() => _setPlaying(false));
    _tts.setCancelHandler(() => _setPlaying(false));
    _tts.setErrorHandler((error) {
      _setPlaying(false);
      _reportError('Không thể phát âm: ${_errorDetail(error)}');
    });

    if (_isWeb) {
      await _setJapaneseWebVoice();
    } else {
      await _setBestJapaneseNativeVoice();
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  Future<void> prepare() async {
    try {
      await initialize();
    } catch (error) {
      _reportError(_friendlyError(error));
    }
  }

  Future<void> speak(VocabularyEntry vocab) {
    return speakText(vocab.kana.trim());
  }

  Future<void> speakText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    try {
      await initialize();
      await _tts.stop();
      final result = await _tts.speak(trimmedText);
      if (result == 0 || result == false) {
        throw StateError('TTS từ chối yêu cầu phát âm.');
      }
    } catch (error) {
      _setPlaying(false);
      _reportError(_friendlyError(error));
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _setPlaying(false);
  }

  Future<void> dispose() async {
    await stop();
    await _playingController.close();
    await _errorController.close();
  }

  Future<void> _setJapaneseWebVoice() async {
    for (var attempt = 0; attempt < _webVoiceLoadAttempts; attempt++) {
      final voices = await _readVoices();
      final voice = _findJapaneseVoice(voices);
      if (voice != null) {
        await _tts.setVoice({
          'name': voice.name,
          'locale': voice.locale,
        });
        await _tts.setLanguage(voice.locale);
        return;
      }
      if (attempt + 1 < _webVoiceLoadAttempts) {
        await Future<void>.delayed(_webVoiceRetryDelay);
      }
    }
    throw const _AudioInitializationException(
      'Trình duyệt chưa tải được giọng đọc tiếng Nhật. '
      'Hãy kiểm tra gói giọng Japanese và tải lại trang.',
    );
  }

  Future<List<_TtsVoice>> _readVoices() async {
    final rawVoices = await _tts.getVoices;
    if (rawVoices is! List) return const [];

    return [
      for (final rawVoice in rawVoices)
        if (rawVoice is Map)
          _TtsVoice(
            name: '${rawVoice['name'] ?? ''}'.trim(),
            locale: '${rawVoice['locale'] ?? ''}'.trim(),
            quality: '${rawVoice['quality'] ?? ''}'.trim(),
            latency: '${rawVoice['latency'] ?? ''}'.trim(),
            networkRequired:
                '${rawVoice['network_required'] ?? ''}'.trim() == '1',
            features: '${rawVoice['features'] ?? ''}'.trim(),
          ),
    ]
        .where((voice) => voice.name.isNotEmpty && voice.locale.isNotEmpty)
        .toList();
  }

  _TtsVoice? _findJapaneseVoice(List<_TtsVoice> voices) {
    final japaneseVoices = voices
        .where((voice) => voice.locale.toLowerCase().startsWith('ja'))
        .toList();
    if (japaneseVoices.isEmpty) return null;

    japaneseVoices.sort((a, b) => _voiceScore(b).compareTo(_voiceScore(a)));
    return japaneseVoices.first;
  }

  int _voiceScore(_TtsVoice voice) {
    final locale = voice.locale.toLowerCase();
    final name = voice.name.toLowerCase();
    final features = voice.features.toLowerCase();
    var score = locale == 'ja-jp' ? 200 : 100;

    score += switch (voice.quality.toLowerCase()) {
      'very high' => 80,
      'high' => 60,
      'normal' => 20,
      'low' => -40,
      'very low' => -80,
      _ => 0,
    };

    score += switch (voice.latency.toLowerCase()) {
      'very low' => 10,
      'low' => 8,
      'normal' => 4,
      'high' => -4,
      'very high' => -8,
      _ => 0,
    };

    if (voice.networkRequired) score += 15;
    if (name.contains('google')) score += 10;
    if (name.contains('neural') ||
        name.contains('wavenet') ||
        name.contains('premium') ||
        name.contains('enhanced')) {
      score += 10;
    }
    if (features.contains('notinstalled')) score -= 200;

    return score;
  }

  Future<void> _setBestJapaneseNativeVoice() async {
    final voices = await _readVoices();
    final voice = _findJapaneseVoice(voices);
    if (voice != null) {
      final result = await _tts.setVoice({
        'name': voice.name,
        'locale': voice.locale,
      });
      if (result == 1 || result == true) {
        await _tts.setLanguage(voice.locale);
        return;
      }
    }

    await _setJapaneseLanguage();
  }

  Future<void> _setJapaneseLanguage() async {
    final result = await _tts.setLanguage('ja-JP');
    if (result == 1 || result == true) {
      return;
    }

    await _tts.setLanguage('ja');
  }

  void _setPlaying(bool value) {
    if (_isPlaying == value || _playingController.isClosed) {
      return;
    }

    _isPlaying = value;
    _playingController.add(value);
  }

  void _reportError(String message) {
    if (!_errorController.isClosed) {
      _errorController.add(message);
    }
  }

  String _friendlyError(Object error) {
    if (error is _AudioInitializationException) return error.message;
    return 'Không thể phát âm. ${_errorDetail(error)}';
  }

  String _errorDetail(Object? error) {
    final detail = error?.toString().trim() ?? '';
    return detail.isEmpty ? 'Trình duyệt không cung cấp chi tiết lỗi.' : detail;
  }
}

class _TtsVoice {
  const _TtsVoice({
    required this.name,
    required this.locale,
    this.quality = '',
    this.latency = '',
    this.networkRequired = false,
    this.features = '',
  });

  final String name;
  final String locale;
  final String quality;
  final String latency;
  final bool networkRequired;
  final String features;
}

class _AudioInitializationException implements Exception {
  const _AudioInitializationException(this.message);

  final String message;
}

final audioErrorProvider = StreamProvider<String>((ref) {
  return ref.watch(audioServiceProvider).errorStream;
});

final audioPreparationProvider = FutureProvider<void>((ref) {
  return ref.watch(audioServiceProvider).prepare();
});

@Riverpod(keepAlive: true)
AudioService audioService(AudioServiceRef ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
}
