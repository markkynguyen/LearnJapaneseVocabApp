import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_models.dart';

part 'audio_service.g.dart';

class AudioService {
  AudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  final _playingController = StreamController<bool>.broadcast();
  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Stream<bool> get playingStream => _playingController.stream;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _tts.setStartHandler(() => _setPlaying(true));
    _tts.setCompletionHandler(() => _setPlaying(false));
    _tts.setCancelHandler(() => _setPlaying(false));
    _tts.setErrorHandler((_) => _setPlaying(false));

    await _setJapaneseLanguage();
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  Future<void> speak(VocabularyEntry vocab) {
    final text = (vocab.kanji?.trim().isNotEmpty ?? false)
        ? vocab.kanji!.trim()
        : vocab.kana.trim();
    return speakText(text);
  }

  Future<void> speakText(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    await initialize();
    await _tts.stop();
    await _tts.speak(trimmedText);
  }

  Future<void> stop() async {
    await _tts.stop();
    _setPlaying(false);
  }

  Future<void> dispose() async {
    await stop();
    await _playingController.close();
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
}

@Riverpod(keepAlive: true)
AudioService audioService(AudioServiceRef ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
}
