// lib/vosk_manager.dart

import 'dart:async';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';

class VoskManager {
  // --- Singleton Pattern ---
  // This ensures there is only ONE instance of VoskManager throughout the entire app.
  static final VoskManager _instance = VoskManager._internal();
  factory VoskManager() => _instance;
  VoskManager._internal();

  // --- Private State ---
  final _vosk = VoskFlutterPlugin.instance();
  SpeechService? _speechService;
  Recognizer? _recognizer; // Kept private to control access
  bool _initialized = false;
  String? errorMessage;

  // --- Public Getters ---
  // Provide safe, read-only access to the manager's state.
  bool get isInitialized => _initialized;
  SpeechService? get speechService => _speechService;
  Recognizer? get recognizer => _recognizer; // Public getter for the recognizer
  Stream<String>? get onPartialStream => _speechService?.onPartial();
  Stream<String>? get onResultStream => _speechService?.onResult();

  /// Initializes the Vosk model and SpeechService.
  /// Designed to be called only ONCE at the start of the app.
  Future<void> initVosk() async {
    if (_initialized) {
      print("VoskManager: Already initialized. Skipping.");
      return;
    }
    try {
      print("VoskManager: Loading Vosk model...");
      // Ensure 'assets/models/vosk.zip' exists and is listed in your pubspec.yaml
      final modelPath = await ModelLoader().loadFromAssets('assets/models/vosk.zip');
      print("VoskManager: Model extracted to $modelPath");

      final model = await _vosk.createModel(modelPath);
      print("VoskManager: Model loaded!");

      _recognizer = await _vosk.createRecognizer(model: model, sampleRate: 16000);
      print("VoskManager: Recognizer created.");

      _speechService = await _vosk.initSpeechService(_recognizer!);
      print("VoskManager: SpeechService initialized.");

      _initialized = true; // Mark as ready only after all steps succeed.

    } catch (e, st) {
      // If any step fails, capture the error.
      errorMessage = "Vosk Initialization Error: $e";
      _initialized = false;
      print("VoskManager: FAILED to initialize. Error: $e\nStackTrace: $st");
    }
  }

  /// Public method to start speech recognition.
  Future<void> startListening() async {
    await _speechService?.start();
  }

  /// Public method to stop speech recognition.
  Future<void> stopListening() async {
    await _speechService?.stop();
  }
}