import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AccessibilityProvider extends ChangeNotifier {
  static const String _textSizeKey = 'text_size';
  static const String _highContrastKey = 'high_contrast';
  static const String _voiceGuidanceKey = 'voice_guidance';
  static const String _hapticFeedbackKey = 'haptic_feedback';

  double _textSize = 3.0;
  bool _highContrast = false;
  bool _voiceGuidance = false;
  bool _hapticFeedback = true;

  double get textSize => _textSize;
  bool get highContrast => _highContrast;
  bool get voiceGuidance => _voiceGuidance;
  bool get hapticFeedback => _hapticFeedback;

  // Calcola il fattore di scala del testo
  double get textScaleFactor => 0.8 + (_textSize * .22);

  // Ottieni il tema appropriato
  ThemeData getTheme(BuildContext context) {
    if (_highContrast) {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
          background: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          titleLarge: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.black;
            }
            return Colors.grey[400];
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.grey[800];
            }
            return Colors.grey[300];
          }),
        ),
      );
    }

    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[100],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Carica le impostazioni salvate
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble(_textSizeKey) ?? 3.0;
    _highContrast = prefs.getBool(_highContrastKey) ?? false;
    _voiceGuidance = prefs.getBool(_voiceGuidanceKey) ?? false;
    _hapticFeedback = prefs.getBool(_hapticFeedbackKey) ?? true;
    notifyListeners();
  }

  // Imposta la dimensione del testo
  Future<void> setTextSize(double size) async {
    _textSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, size);
    notifyListeners();
  }

  // Imposta l'alto contrasto
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  // Imposta la guida vocale
  Future<void> setVoiceGuidance(bool value) async {
    _voiceGuidance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_voiceGuidanceKey, value);

    if (value) {
      // Annuncia l'attivazione della guida vocale
      _speak('Guida vocale attivata');
    }

    notifyListeners();
  }

  // Imposta il feedback tattile
  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, value);

    if (value) {
      HapticFeedback.mediumImpact();
    }

    notifyListeners();
  }

  // Fornisce feedback tattile se abilitato
  void triggerHapticFeedback() {
    if (_hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  // Annuncia un messaggio se la guida vocale è abilitata
  void speak(String message) {
    if (_voiceGuidance) {
      _speak(message);
    }
  }

  final FlutterTts _flutterTts = FlutterTts();
  Future<void> _speak(String message) async {
    await _flutterTts.speak(message);
  }

  AccessibilityProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('it-IT');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
}
