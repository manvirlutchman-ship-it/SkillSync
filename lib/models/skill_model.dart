import 'package:cloud_firestore/cloud_firestore.dart';

class SkillModel {
  final String id;                // The document ID from Firestore (e.g., "1")
  final String skillCategory;     // "Software Development"
  final String skillName;         // "Flutter Development"
  final String skillSubcategory;  // "Mobile App Development"

  SkillModel({
    required this.id,
    required this.skillCategory,
    required this.skillName,
    required this.skillSubcategory,
  });

  /// Factory to create a SkillModel from a Firestore DocumentSnapshot
  factory SkillModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SkillModel(
      id: doc.id,
      skillCategory: data['skill_category'] ?? '',
      skillName: data['skill_name'] ?? '',
      skillSubcategory: data['skill_subcategory'] ?? '',
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'skill_category': skillCategory,
      'skill_name': skillName,
      'skill_subcategory': skillSubcategory,
    };
  }
}