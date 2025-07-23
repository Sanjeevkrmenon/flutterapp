import 'dart:convert';
import 'dart:io'; // Ensure this import is present at the top level

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;

// Vosk imports
import 'package:vosk_flutter_2/vosk_flutter_2.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Vosk objects
  final _vosk = VoskFlutterPlugin.instance();
  final _modelLoader = ModelLoader();

  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool _modelReady = false;
  bool _isListening = false;
  String _currentMood = "neutral";
  String _lottieAsset = "assets/neutral.json";
  String _lastRecognized = "";
  String? _error;

  // Your backend endpoint:
  final String backendUrl = 'https://your-flask-backend.onrender.com/analyze'; // Replace as needed

  @override
  void initState() {
    super.initState();
    _initVosk();
  }

  // Initialize Vosk, model, recognizer, and speech service with error handling.
  Future<void> _initVosk() async {
    try {
      // You must unzip the model in assets/models/ or use .zip with .loadFromAssets
      print("LOADING MODEL FROM ASSET..."); // Debug print
      // Current usage: Loading from a .zip file. If you intended to load an unzipped directory,
      // change 'assets/models/a.zip' to 'assets/models/a/' or 'assets/models/a'
      final modelPath = await _modelLoader.loadFromAssets('assets/models/vosk.zip');
      print("MODEL EXTRACTED TO: $modelPath"); // Debug print

      // Debugging: List extracted files and folders - ADDED HERE
      print('DEBUG: Contents of $modelPath');
      final dir = Directory(modelPath);
      if (await dir.exists()) {
        dir.listSync().forEach((entity) => print('  ${entity.path}'));
      } else {
        print('Directory does not exist!');
      }
      // End of Debugging block

      // ************* NEXT DEBUGGING STEP ADDED HERE *************
      print('EXTRACTED MODEL DIR: $modelPath'); // Use modelPath as it holds the extracted directory path
      final files = Directory(modelPath).listSync(recursive: true);
      for (var f in files) {
        print('  ${f.path}');
      }
      // **********************************************************

      final model = await _vosk.createModel(modelPath);
      print("MODEL LOADED!"); // Debug print

      _recognizer = await _vosk.createRecognizer(model: model, sampleRate: 16000);

      // For Android devices
      _speechService = await _vosk.initSpeechService(_recognizer!);

      // Listen to Vosk partial/final results
      _speechService!.onPartial().listen((partial) {
        // Optionally show live partial results if you want.
      });

      _speechService!.onResult().listen((resultStr) {
        // resultStr is JSON, ex: {"text":"hello world"}
        String? text = _extractTextFromResult(resultStr);
        if (text != null && text.trim().isNotEmpty && text.trim() != _lastRecognized.trim()) {
          setState(() => _lastRecognized = text!);
          _processTextMood(text!);
        }
      });

      setState(() => _modelReady = true);

      // Start listening right away
      await _startListening();
    } catch (e, st) { // Catching stack trace for better debugging
      print("MODEL LOAD FAILED: $e\n$st"); // Debug print
      setState(() => _error = "$e\n$st"); // Update error state with stack trace
    }
  }

  // Vosk start/stop listening
  Future<void> _startListening() async {
    if (_speechService == null || _isListening) return;
    await _speechService!.start();
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    if (_speechService == null || !_isListening) return;
    await _speechService!.stop();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  /// Extract 'text' from Vosk recognizer JSON result like {"text":"hello world"}
  String? _extractTextFromResult(String jsonStr) {
    try {
      final Map parsed = jsonDecode(jsonStr);
      return parsed['text']?.toString();
    } catch (e) {
      print("Failed to parse Vosk result: $e");
      return null;
    }
  }

  Future<void> _processTextMood(String text) async {
    if (!mounted) return;
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String mood = data['mood'] ?? 'neutral';
        setState(() {
          _currentMood = mood;
          _lottieAsset = _moodToAsset(mood);
        });
      } else {
        print("Backend error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error talking to backend: $e");
    }
  }

  String _moodToAsset(String mood) {
    switch (mood) {
      case 'happy':
        return 'assets/happy.json';
      case 'sad':
        return 'assets/sad.json';
      case 'angry':
        return 'assets/angry.json';
      default:
        return 'assets/neutral.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Continuous Animated Mood Face",
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _error != null
              ? Text("Error: $_error",
              style: const TextStyle(color: Colors.redAccent, fontSize: 18))
              : !_modelReady
              ? const Text("Loading Vosk model...", style: TextStyle(color: Colors.white, fontSize: 20))
              : SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(36),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.blueAccent.withOpacity(0.5),
                    //     blurRadius: 15,
                    //     spreadRadius: 2,
                    //   )
                    // ]
                  ),
                  width: 300,
                  height: 300,
                  child: Center(
                    child: Lottie.asset(
                      _lottieAsset,
                      height: 250,
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Mood: ${_currentMood[0].toUpperCase()}${_currentMood.substring(1)}",
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _isListening
                      ? "🎤 Listening (Vosk)..."
                      : "Ready",
                  style: TextStyle(
                      color: _isListening ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                if (_lastRecognized.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Last Heard: "$_lastRecognized"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                // Optionally: Add a manual start/stop listening button
              ],
            ),
          ),
        ),
      ),
    );
  }
}