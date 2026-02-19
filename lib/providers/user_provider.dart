// user_provider.dart - UPDATED IMPORTS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isFetching = false; // Prevents infinite loops
  final DatabaseService _db = DatabaseService();

  UserModel? get user => _user;
  bool get isFetching => _isFetching;

  Future<void> fetchUser(String uid) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final fetchedUser = await _db.getUserProfile(uid);

      if (fetchedUser == null) {
        // AUTO-REPAIR: If the document is missing, create it now!
        print("!!! Document missing in Firestore. Repairing now... !!!");
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await _db.createUserProfile(uid, authUser.email!);
          _user = await _db.getUserProfile(uid); // Try fetching again
        }
      } else {
        _user = fetchedUser;
      }
    } catch (e) {
      print("!!! ERROR: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    _isFetching = false;
    notifyListeners();
  }

  // Add this getter to your UserProvider class
  bool get needsOnboarding {
    // If user is still loading, we don't know yet (return false to avoid flicker)
    if (_user == null) return false;
    // Only onboard if the explicit flag is false
    return _user!.isOnboarded == false;
  }

  
}
