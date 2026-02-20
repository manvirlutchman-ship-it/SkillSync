import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// 1. We alias the import as 'gsi' to avoid naming conflicts
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:skillsync/services/database_service.dart'; 

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 2. We use the 'gsi' prefix to call the real GoogleSignIn class
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(); 

  // Watch the user state (logged in or out)
  Stream<User?> get user => _auth.authStateChanges();

  // GOOGLE SIGN IN METHOD
  Future<String?> signInWithGoogle() async {
    try {
      // 3. Trigger the Google account picker using alias
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user closes the popup without selecting an account
      if (googleUser == null) return "canceled";

      // 4. Obtain the auth details using alias
      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 5. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      await _auth.signInWithCredential(credential);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint("!!! GOOGLE LOGIN ERROR: $e");
      return "An unexpected error occurred during Google Sign-In.";
    }
  }

  // SIGN UP (Existing)
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGIN (Existing)
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGOUT (Updated to clear Google session too)
  Future<void> signOut() async {
    try {
      // 6. Clear Google account selection using alias
      await _googleSignIn.signOut(); 
      await _auth.signOut();         
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }

  //Delete Auth Account
  Future<String?> deleteAccount() async {
    try {
      // 🟢 Force a refresh of the current user instance
      User? user = FirebaseAuth.instance.currentUser; 
      
      if (user != null) {
        final String uid = user.uid;
        debugPrint("!!! Attempting to delete UID: $uid !!!");

        // 1. Clean up Firestore data (profiles, etc.)
        await DatabaseService().deleteUserData(uid);
        
        // 2. Delete the Auth account
        await user.delete();
        
        debugPrint("!!! Deletion successful !!!");
        return "success";
      } else {
        debugPrint("!!! Deletion Failed: currentUser is null !!!");
        return "User session not found.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') return "reauthenticate";
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}