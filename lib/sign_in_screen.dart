// lib/sign_in_screen.dart

import 'package:flutter/material.dart';
import 'auth_service.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const SignInScreen({required this.onSignedIn, Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;
  String? _error;

  // Handles Google Sign-In
  void _handleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userCredential = await _authService.signInWithGoogle();
      // The onSignedIn callback is handled by the StreamBuilder in main.dart,
      // so we don't strictly need to call it here if we let the stream update the UI.
      // However, keeping it doesn't hurt.
      if (userCredential != null) {
        // widget.onSignedIn(); // This can be removed if StreamBuilder handles all navigation
      } else {
        if (mounted) {
          setState(() => _error = "Sign in was cancelled.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = "An error occurred during sign in.");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Handles Anonymous (Guest) Sign-In
  void _handleGuestSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signInAnonymously();
      // As above, StreamBuilder will handle the UI update.
      // widget.onSignedIn();
    } catch (e) {
      if (mounted) {
        setState(() => _error = "Could not sign in as guest.");
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo or an icon here
            // Icon(Icons.shield_moon, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Parabot",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _handleSignIn,
              icon: Image.asset('assets/google_logo.png', height: 24.0), // Assuming you have a google logo asset
              label: const Text("Sign in with Google"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _handleGuestSignIn,
              child: const Text(
                "Continue as Guest",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}