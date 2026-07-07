import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jvocab/core/audio/audio_service.dart';
import 'package:jvocab/core/models/app_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('web waits for voices and selects a Japanese voice before speaking',
      () async {
    final tts = _FakeFlutterTts(
      voiceResponses: const [
        [],
        [
          {'name': 'Google 日本語', 'locale': 'ja-JP'},
        ],
      ],
    );
    final service = AudioService(
      tts: tts,
      isWeb: true,
      webVoiceLoadAttempts: 2,
      webVoiceRetryDelay: Duration.zero,
    );
    addTearDown(service.dispose);

    await service.speakText('猫');

    expect(tts.getVoicesCallCount, 2);
    expect(tts.selectedVoice, {
      'name': 'Google 日本語',
      'locale': 'ja-JP',
    });
    expect(tts.language, 'ja-JP');
    expect(tts.spokenTexts, ['猫']);
  });

  test('web reports a useful error when no Japanese voice is available',
      () async {
    final tts = _FakeFlutterTts(
      voiceResponses: const [
        [
          {'name': 'English', 'locale': 'en-US'},
        ],
      ],
    );
    final service = AudioService(
      tts: tts,
      isWeb: true,
      webVoiceLoadAttempts: 1,
      webVoiceRetryDelay: Duration.zero,
    );
    addTearDown(service.dispose);
    final error = service.errorStream.first;

    await service.speakText('猫');

    expect(tts.spokenTexts, isEmpty);
    expect(await error, contains('giọng đọc tiếng Nhật'));
  });
  test('native chooses the best available Japanese voice before speaking',
      () async {
    final tts = _FakeFlutterTts(
      voiceResponses: const [
        [
          {
            'name': 'Basic Japanese',
            'locale': 'ja-JP',
            'quality': 'normal',
            'latency': 'low',
            'network_required': '0',
          },
          {
            'name': 'Google Japanese Network',
            'locale': 'ja-JP',
            'quality': 'very high',
            'latency': 'normal',
            'network_required': '1',
          },
        ],
      ],
    );
    final service = AudioService(tts: tts, isWeb: false);
    addTearDown(service.dispose);

    await service.speakText('猫');

    expect(tts.selectedVoice, {
      'name': 'Google Japanese Network',
      'locale': 'ja-JP',
    });
    expect(tts.language, 'ja-JP');
    expect(tts.spokenTexts, ['猫']);
  });

  test('speaks kana even when kanji is available', () async {
    final tts = _FakeFlutterTts(voiceResponses: const []);
    final service = AudioService(tts: tts, isWeb: false);
    addTearDown(service.dispose);

    await service.speak(
      const VocabularyEntry(
        id: 'vocab-1',
        folderId: 'folder-1',
        kanji: '食べる',
        kana: 'たべる',
        romaji: 'taberu',
        meaning: 'ăn',
        isFavorite: false,
        createdAt: 0,
      ),
    );

    expect(tts.spokenTexts, ['たべる']);
  });
}

class _FakeFlutterTts extends FlutterTts {
  _FakeFlutterTts({required this.voiceResponses});

  final List<List<Map<String, String>>> voiceResponses;
  final List<String> spokenTexts = [];
  int getVoicesCallCount = 0;
  Map<String, String>? selectedVoice;
  String? language;

  @override
  Future<dynamic> get getVoices async {
    if (voiceResponses.isEmpty) {
      return const [];
    }
    final index = getVoicesCallCount < voiceResponses.length
        ? getVoicesCallCount
        : voiceResponses.length - 1;
    getVoicesCallCount++;
    return voiceResponses[index];
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    selectedVoice = Map.of(voice);
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    this.language = language;
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> setPitch(double pitch) async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spokenTexts.add(text);
    return 1;
  }

  @override
  void setStartHandler(VoidCallback callback) {}

  @override
  void setCompletionHandler(VoidCallback callback) {}

  @override
  void setCancelHandler(VoidCallback callback) {}

  @override
  void setErrorHandler(ErrorHandler handler) {}
}
