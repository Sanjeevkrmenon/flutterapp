import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'backend/mood_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String currentMood = 'neutral';
  String lottieAsset = 'assets/loona_eyes.json';
  TextEditingController _textController = TextEditingController();

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

  Future<void> analyzeAndSetMood(String text) async {
    String mood = await MoodService.getMood(text);
    updateMood(mood);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 58, 53, 53),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.all(36.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  width: 500,
                  height: 600,
                  child: Center(
                    child: Lottie.asset(
                      lottieAsset,
                      width: 450,
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: 300,
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: "Say something to Loona...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_textController.text.trim().isNotEmpty) {
                      analyzeAndSetMood(_textController.text.trim());
                    }
                  },
                  child: Text('Send to Loona'),
                ),
                SizedBox(height: 8),
                Text(
                  "Current Mood: $currentMood",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
