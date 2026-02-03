import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final DatabaseService _db = DatabaseService();

  UserModel? get user => _user;

  // Your teammate will call this after a successful login
  Future<void> fetchUser(String uid) async {
    // We will write a getProfile method in your DatabaseService later
    _user = await _db.getUserProfile(uid); 
    notifyListeners(); // This tells all your screens to refresh with the user's data!
  }

  // You can use this for now to test your screens without Auth!
  void loadMockUser() {
    _user = UserModel(
      id: "1",
      firstName: "Alex (Mock)",
      lastName: "Perera",
      username: "alex@test.com",
      userBio: "I am a mock user for testing",
      profilePictureUrl: "",
      profileBannerUrl: "",
      dateOfBirth: DateTime.now(),
    );
    notifyListeners();
  }
}