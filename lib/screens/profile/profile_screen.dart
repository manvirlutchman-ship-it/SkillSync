import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/models/userskill_model.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/rating_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🟢 EXTRACT THE USER DATA passed from MatchingScreen
    final UserModel user = ModalRoute.of(context)!.settings.arguments as UserModel;
    final dbService = DatabaseService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("View Profile"),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  Text(
                    user.fullName.isEmpty ? user.username : user.fullName,
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(color: Color(0xFF86868B), fontSize: 16),
                  ),

                  const SizedBox(height: 24),

                  // Public Bio Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.userBio.isNotEmpty ? user.userBio : "No bio provided.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 15, height: 1.5),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF5F5F7), thickness: 1.5),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Rating', style: TextStyle(color: Color(0xFF86868B), fontWeight: FontWeight.w600)),
                            SizedBox(width: 12),
                            RatingRow(rating: 5),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🛠 Public Skills Section
                  FutureBuilder<List<UserSkillModel>>(
                    future: dbService.getUserSkills(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      final allSkills = snapshot.data ?? [];
                      final teachingSkills = allSkills.where((s) => s.teachingOrLearning == 'teaching').toList();
                      final learningSkills = allSkills.where((s) => s.teachingOrLearning == 'learning').toList();

                      return Column(
                        children: [
                          _buildSkillSection("TEACHES", teachingSkills),
                          const SizedBox(height: 32),
                          _buildSkillSection("WANTS TO LEARN", learningSkills),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE8E8ED),
            image: user.profileBannerUrl.isNotEmpty 
                ? DecorationImage(image: NetworkImage(user.profileBannerUrl), fit: BoxFit.cover)
                : null,
          ),
        ),
        Positioned(
          bottom: -45,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Color(0xFFF5F5F7), shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: user.profilePictureUrl.isNotEmpty ? NetworkImage(user.profilePictureUrl) : null,
                child: user.profilePictureUrl.isEmpty ? const Icon(Icons.person_rounded, color: Color(0xFF86868B), size: 45) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<UserSkillModel> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF86868B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          const Text("None added.", style: TextStyle(color: Color(0xFF86868B), fontSize: 14))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills.map((s) => _SkillTile(s.skillId)).toList(),
          ),
      ],
    );
  }
}

class _SkillTile extends StatelessWidget {
  final String label;
  const _SkillTile(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}