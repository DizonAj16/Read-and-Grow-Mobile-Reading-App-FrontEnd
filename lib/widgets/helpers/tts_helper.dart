import 'dart:async';
import 'dart:ui';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef HighlightCallback = void Function(int index);
typedef CompletionCallback = void Function();

class TTSHelper {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  double _rate = 0.5;
  double _pitch = 1.0;
  String _voiceName = '';
  bool _isMale = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final prefs = await SharedPreferences.getInstance();
    _rate = prefs.getDouble('tts_rate') ?? 0.5;
    _pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    _voiceName = prefs.getString('tts_voice') ?? '';
    _isMale = prefs.getBool('tts_is_male') ?? false;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);

    // If saved voice exists, use it; otherwise assign by gender
    if (_voiceName.isNotEmpty) {
      await _setVoiceByName(_voiceName);
    } else {
      await setGender(_isMale);
    }
  }

  Future<void> reinitialize() async {
    _isInitialized = false;
    await init();
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    final voices = await _tts.getVoices;
    return List<Map<String, String>>.from(
      voices,
    ).where((v) => v['locale']?.startsWith('en') ?? false).toList();
  }

  Future<void> _setVoiceByName(String name) async {
    final voices = await getAvailableVoices();
    final match = voices.firstWhere((v) => v['name'] == name, orElse: () => {});

    if (match.isNotEmpty) {
      await _tts.setVoice({"name": match['name']!, "locale": match['locale']!});
      _voiceName = match['name']!;
    }
  }

  Future<void> setGender(bool isMale) async {
    final voices = await getAvailableVoices();

    // Try matching by gender key
    Map<String, String>? match = voices.firstWhere(
      (v) => v['gender']?.toLowerCase() == (isMale ? 'male' : 'female'),
      orElse: () => {},
    );

    // Fallback: Try matching by name containing 'male'/'female'
    if (match.isEmpty) {
      match = voices.firstWhere(
        (v) =>
            (v['name']?.toLowerCase().contains(isMale ? 'male' : 'female')) ??
            false,
        orElse: () => voices.isNotEmpty ? voices.first : {},
      );
    }

    if (match.isNotEmpty) {
      _voiceName = match['name'] ?? '';
      _isMale = isMale;
      await _tts.setVoice({"name": match['name']!, "locale": match['locale']!});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_voice', _voiceName);
      await prefs.setBool('tts_is_male', _isMale);
    }
  }

  String get voiceName => _voiceName;
  double get rate => _rate;
  double get pitch => _pitch;
  bool get isMale => _isMale;

  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(_rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', _rate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', _pitch);
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (text.trim().isEmpty) return;

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    await _tts.speak(text);
  }

  Future<void> speakList(
    List<String> texts, {
    HighlightCallback? onHighlight,
    VoidCallback? onComplete,
    VoidCallback? onStart,
  }) async {
    if (texts.isEmpty) {
      onComplete?.call();
      return;
    }

    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];

      onHighlight?.call(i);
      onStart?.call();

      final completer = Completer<void>();

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        if (!completer.isCompleted) completer.complete();
      });
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (!completer.isCompleted) completer.complete();
      });

      await _tts.speak(text);
      await completer.future;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _clearHandlers();
    onHighlight?.call(-1);
    onComplete?.call();
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<bool> isSpeaking() async => _isSpeaking;

  void _clearHandlers() {
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((_) {});
    _tts.setStartHandler(() {});
    _tts.setCancelHandler(() {});
  }

  void dispose() {
    _clearHandlers();
    _tts.stop();
  }
}
