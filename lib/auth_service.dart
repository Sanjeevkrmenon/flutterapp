// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getter for the current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google (your existing method)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to be caught by the UI
    } catch (e) {
      print("Generic Sign-in Error: $e");
      rethrow; // Re-throw to be caught by the UI
    }
  }

  // --- NEW METHOD for Guest Sign-In ---
  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      print("Firebase Anonymous Auth Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to be caught by the UI
    } catch (e) {
      print("Generic Anonymous Sign-in Error: $e");
      rethrow; // Re-throw to be caught by the UI
    }
  }

  // --- MODIFIED signOut Method ---
  Future<void> signOut() async {
    // Check if the current user is anonymous before trying to sign out of Google.
    // This prevents an error when a guest user signs out.
    if (currentUser != null && !currentUser!.isAnonymous) {
      await _googleSignIn.signOut();
    }
    // Always sign out from Firebase.
    await _auth.signOut();
  }
}