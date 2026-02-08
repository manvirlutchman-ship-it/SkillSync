import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // The document ID from Firestore (Auth UID)
  final DateTime dateOfBirth; // Converted from Timestamp
  final String firstName; // "Alex"
  final String lastName; // "Perera"
  final String profileBannerUrl; // "https://example.com/..."
  final String profilePictureUrl; // "https://example.com/..."
  final String userBio; // "Software engineering student..."
  final String username; // "alex.perera@example.com"

  UserModel({
    required this.id,
    required this.dateOfBirth,
    required this.firstName,
    required this.lastName,
    required this.profileBannerUrl,
    required this.profilePictureUrl,
    required this.userBio,
    required this.username,
  });

  /// Helper getter to show the full name in the UI without extra logic
  String get fullName => '$firstName $lastName';

  /// Factory to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      id: doc.id,
      // Use 'is Timestamp' check to prevent the 'Null' subtype error
      dateOfBirth: data['date_of_birth'] is Timestamp
          ? (data['date_of_birth'] as Timestamp).toDate()
          : DateTime(2000, 1, 1), // Default value if missing
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      profileBannerUrl: data['profile_banner_url'] ?? '',
      profilePictureUrl: data['profile_picture_url'] ?? '',
      userBio: data['user_bio'] ?? '',
      username: data['username'] ?? '',
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'date_of_birth': Timestamp.fromDate(dateOfBirth),
      'first_name': firstName,
      'last_name': lastName,
      'profile_banner_url': profileBannerUrl,
      'profile_picture_url': profilePictureUrl,
      'user_bio': userBio,
      'username': username,
    };
  }
}
