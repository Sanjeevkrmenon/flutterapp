import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:lottie/lottie.dart';
import 'package:sentiment_dart/sentiment_dart.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String currentMood = 'neutral';
  String lottieAsset = 'assets/loona_eyes.json';
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void updateMood(String mood) {
    setState(() {
      currentMood = mood;
      if (mood == 'happy') {
        lottieAsset = 'assets/loona_eyes.json';
      } else if (mood == 'angry') {
        lottieAsset = 'assets/loona_eyes_angry.json';
      } else {
        lottieAsset = 'assets/loona_eyes.json';
      }
    });
  }

  void analyzeMoodLocally() {
    final text = _controller.text;
    if (text.isEmpty) return;

    final analysis = Sentiment.analysis(text); // Static method call
    final double score = analysis.score;
    String mood = "neutral";

    if (score > 1) {
      mood = "happy";
    } else if (score < -1) {
      mood = "angry";
    }
    updateMood(mood);
  }

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _controller.text = val.recognizedWords;
          });
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mood Voice App (On-Device)",
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 58, 53, 53),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  width: 300,
                  height: 300,
                  child: Center(
                    child: Lottie.asset(
                      lottieAsset,
                      width: 250,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Current Mood: $currentMood",
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "Type or tap mic to speak...",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        color: Colors.white,
                        iconSize: 32,
                        onPressed: () {
                          if (_isListening) {
                            stopListening();
                          } else {
                            startListening();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: analyzeMoodLocally,
                  child: const Text("Analyze Mood"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
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