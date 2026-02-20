import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String userBio;
  final String profilePictureUrl;
  final String profileBannerUrl;
  final DateTime dateOfBirth;
  final bool isOnboarded;
  final int likesCount; // 🟢 Added

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.userBio,
    required this.profilePictureUrl,
    required this.profileBannerUrl,
    required this.dateOfBirth,
    required this.isOnboarded,
    required this.likesCount, // 🟢 Added
  });

  String get fullName => '$firstName $lastName'.trim().isEmpty ? username : '$firstName $lastName';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      id: doc.id,
      username: data['username']?.toString() ?? '',
      firstName: data['first_name']?.toString() ?? '',
      lastName: data['last_name']?.toString() ?? '',
      userBio: data['user_bio']?.toString() ?? '',
      profilePictureUrl: data['profile_picture_url']?.toString() ?? '',
      profileBannerUrl: data['profile_banner_url']?.toString() ?? '',
      isOnboarded: data['is_onboarded'] == true,
      likesCount: (data['likes_count'] ?? 0).toInt(), // 🟢 Null-safe parse
      dateOfBirth: data['date_of_birth'] is Timestamp
          ? (data['date_of_birth'] as Timestamp).toDate()
          : DateTime(2000, 1, 1),
    );
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? userBio,
    bool? isOnboarded,
    int? likesCount, // 🟢 Added
  }) {
    return UserModel(
      id: id,
      username: username,
      dateOfBirth: dateOfBirth,
      profilePictureUrl: profilePictureUrl,
      profileBannerUrl: profileBannerUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      userBio: userBio ?? this.userBio,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      likesCount: likesCount ?? this.likesCount, // 🟢 Added
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'user_bio': userBio,
      'profile_picture_url': profilePictureUrl,
      'profile_banner_url': profileBannerUrl,
      'date_of_birth': Timestamp.fromDate(dateOfBirth),
      'is_onboarded': isOnboarded,
      'likes_count': likesCount, // 🟢 Added
    };
  }
}