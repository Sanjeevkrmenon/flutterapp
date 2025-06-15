import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  String _currentMood = "neutral";
  String _lottieAsset = "assets/neutral.json";
  String _lastRecognized = "";

  // Your backend endpoint:
  final String backendUrl = 'https://your-flask-backend.onrender.com/analyze'; // Replace with your actual URL

  @override
  void initState() {
    super.initState();
    _initAndStartListening();
  }

  // Updated _initAndStartListening method as per your request
  void _initAndStartListening() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) async {
        print("SpeechToText status: $status [isListening: ${_speech.isListening}]");
        if (status == "done" || status == "notListening") {
          if (mounted) setState(() => _isListening = false);
          await Future.delayed(const Duration(milliseconds: 600)); // Safer delay
          print("Restarting listening...");
          if (!_speech.isListening && mounted) { _startListening(); }
        } else if (status == "listening") {
          if (mounted) setState(() => _isListening = true);
        }
      },
      onError: (error) async {
        print("SpeechToText error: $error");
        if (mounted) setState(() => _isListening = false);
        await Future.delayed(const Duration(milliseconds: 1000));
        print("Retrying after error...");
        if (!_speech.isListening && mounted) { _startListening(); }
      },
    );
    if (_speechAvailable && mounted) { _startListening(); }
  }

  // Updated _startListening method as per your request
  void _startListening() async {
    print("[DEBUG]: _startListening called. _isListening: $_isListening, Speech.isListening: ${_speech.isListening}");
    if (!_speechAvailable || _isListening || _speech.isListening || !mounted) return;

    if (mounted) { // Ensure widget is mounted before calling setState
      setState(() => _isListening = true);
    }


    bool success = await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: false, // Only process final results
      onResult: (result) {
        if (!mounted) return; // Check mounted state in callback
        String text = result.recognizedWords.trim();
        print("Heard: $text");
        if (text.isNotEmpty && text != _lastRecognized) {
          setState(() {
            _lastRecognized = text;
          });
          _processTextMood(text);
        }
      },
      // Consider adding localeId if you need specific language support:
      // localeId: 'en_US',
    );

    if (!success && mounted) {
      // If listen call itself fails, reflect that we are not listening.
      setState(() => _isListening = false);
    }
  }


  void _stopListening() async {
    await _speech.stop();
    if (mounted) { // Check if widget is mounted
      setState(() => _isListening = false);
    }
  }

  Future<void> _processTextMood(String text) async {
    if (!mounted) return; // Check mounted before async operation
    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (!mounted) return; // Check mounted after await

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
  void dispose() {
    _speech.stop(); // Ensure speech is stopped
    _speech.cancel(); // Also cancel to release resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Continuous Animated Mood Face",
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                      color: Colors.black, // Background of the Lottie container
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [ // Optional: add some shadow for depth
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
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
                  "Mood: ${_currentMood[0].toUpperCase()}${_currentMood.substring(1)}", // Capitalize mood
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _isListening
                      ? "🎤 Listening..."
                      : _speechAvailable ? "Ready to listen" : "Initializing speech...",
                  style: TextStyle(
                      color: _isListening ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 18, // Increased font size
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                if (_lastRecognized.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Last Heard: "$_lastRecognized"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14), // Increased font size
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}