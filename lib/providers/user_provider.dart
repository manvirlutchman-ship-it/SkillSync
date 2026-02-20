import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isFetching = false; 
  final DatabaseService _db = DatabaseService();

  UserModel? get user => _user;
  bool get isFetching => _isFetching;

  Future<void> fetchUser(String uid) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final fetchedUser = await _db.getUserProfile(uid);

      if (fetchedUser == null) {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          await _db.createUserProfile(uid, authUser.email!);
          _user = await _db.getUserProfile(uid); 
        }
      } else {
        _user = fetchedUser;
      }
    } catch (e) {
      debugPrint("Provider Fetch Error: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  // 🟢 SENIOR FIX: The local update must be final
  void updateLocalUser(UserModel updatedUser) {
    _user = updatedUser;
    notifyListeners(); 
  }

  void clearUser() {
    _user = null;
    _isFetching = false;
    notifyListeners();
  }

  bool get needsOnboarding {
    if (_user == null) return false;
    return _user!.isOnboarded == false;
  }
}