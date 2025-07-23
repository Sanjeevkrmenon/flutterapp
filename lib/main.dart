// lib/main.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';

import 'vosk_manager.dart';
import 'splash_animation.dart';
import 'sign_in_screen.dart';
import 'auth_service.dart';
import 'blinking_eyes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // FOR TESTING: To see the sign-in screen every time, the line below is uncommented.
  await FirebaseAuth.instance.signOut();

  await VoskManager().initVosk();
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({Key? key}) : super(key: key);
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _splashShown = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: _splashShown
          ? StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator()));
          }
          // If user is authenticated, show the minimalist MyApp
          if (snapshot.hasData) {
            return const MyApp();
          }
          // Otherwise, show the standard SignInScreen
          else {
            return SignInScreen(onSignedIn: () {});
          }
        },
      )
          : SplashAnimation(
        onFinish: () {
          if (mounted) {
            setState(() => _splashShown = true);
          }
        },
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final VoskManager _voskManager = VoskManager();
  final AuthService _authService = AuthService();
  SpeechService? _speechService;
  bool _modelReady = false;
  bool _isListening = false;
  String? _error;

  StreamSubscription? _resultSubscription;

  String _currentMood = "neutral";
  String _lastRecognized = "";
  final String backendUrl = 'http://10.25.140.210:5000/api/analyze';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVosk();
  }

  void _initializeVosk() {
    if (mounted) {
      setState(() {
        _modelReady = _voskManager.isInitialized;
        if (_modelReady) {
          _speechService = _voskManager.speechService;
          _subscribeToSpeechEvents();
          _startListening();
        } else {
          _error =
              _voskManager.errorMessage ?? "Vosk model failed to initialize.";
        }
      });
    }
  }

  void _subscribeToSpeechEvents() {
    _resultSubscription?.cancel();
    _resultSubscription = _voskManager.onResultStream?.listen((resultStr) {
      String? text = _extractTextFromResult(resultStr);
      if (text != null && text.trim().isNotEmpty && text.trim() != _lastRecognized.trim()) {
        if (mounted) {
          setState(() => _lastRecognized = text);
          _processTextMood(text);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_speechService == null || _isListening || !_modelReady) return;
    try {
      await _speechService!.start();
      if (mounted) setState(() => _isListening = true);
    } catch (e) {
      if (mounted) setState(() => _error = "Error starting listener: $e");
    }
  }

  Future<void> _stopListening() async {
    if (_speechService == null || !_isListening) return;
    try {
      await _speechService!.stop();
      if (mounted) setState(() => _isListening = false);
    } catch (e) {
      if (mounted) setState(() => _error = "Error stopping listener: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resultSubscription?.cancel();
    _stopListening();
    super.dispose();
  }

  String? _extractTextFromResult(String jsonStr) {
    try {
      return jsonDecode(jsonStr)['text']?.toString();
    } catch (e) {
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
        setState(() => _currentMood = mood);
      }
    } catch (e) {
      print("MyApp: Error talking to backend: $e");
    }
  }

  Color _moodToColor(String mood) {
    switch (mood) {
      case 'happy': return Colors.yellow;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent;

    if (_error != null) {
      mainContent = Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text("Vosk Error: $_error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
      );
    } else if (!_modelReady) {
      mainContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Vosk is initializing...",
              style: TextStyle(color: Colors.white70, fontSize: 20)),
        ],
      );
    } else {
      double squareSize = MediaQuery.of(context).size.width * 0.85;
      mainContent = SizedBox(
        width: squareSize,
        height: squareSize,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlinkingEyes(
              eyeColor: _moodToColor(_currentMood),
              size: squareSize * 0.5,
            ),
            const SizedBox(height: 40),
            Text(
              _currentMood.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              _isListening ? "LISTENING" : "PAUSED",
              style: TextStyle(
                  color: _isListening ? Colors.greenAccent.withOpacity(0.8) : Colors.orangeAccent.withOpacity(0.8),
                  fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.5),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: mainContent),
      floatingActionButton: GestureDetector(
        onLongPress: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: const Color(0xFF212121),
              title: Row(children: const [
                Icon(Icons.logout, color: Colors.redAccent, size: 28),
                SizedBox(width: 12),
                Text("Sign out?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              content: const Text("Are you sure you want to sign out?", style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text("Sign Out"),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );
          if (result == true) {
            await _authService.signOut();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}