import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/models/userskill_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/widgets/rating_row.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          userProvider.fetchUser(currentUid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final dbService = DatabaseService();

    // Modern Apple Loading Style
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1D1D1F)),
        ),
      );
    }

    final String displayName = user.fullName.trim().isEmpty
        ? user.username
        : user.fullName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple background gray

      // Update the AppBar section of your UserProfileScreen (lib/screens/profile/user_profile_screen.dart)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // 🟢 ADDED: Edit Profile Button (Wrapped for visibility)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), // Frosted background
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF1D1D1F), // Dark Grey
                size: 26,
              ),
              tooltip: 'Edit Profile',
              onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
            ),
          ),

          // Logout Button (Wrapped for consistency)
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), // Frosted background
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1D1D1F), // Dark Grey
                size: 22,
              ),
              tooltip: 'Logout',
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );
                try {
                  context.read<UserProvider>().clearUser();
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ),
        ],
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

                  // Name Section
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Color(0xFF1D1D1F),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username.split('@')[0]}',
                    style: const TextStyle(
                      color: Color(0xFF86868B), // Apple Gray
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio & Rating Card (Soft Apple Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.userBio.isNotEmpty
                              ? user.userBio
                              : "No bio available.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Color(0xFFF5F5F7),
                            thickness: 1.5,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF1D1D1F),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${user.likesCount} LIKES',
                              style: const TextStyle(
                                color: Color(0xFF1D1D1F),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Skills Section
                  FutureBuilder<List<UserSkillModel>>(
                    future: dbService.getUserSkills(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF86868B),
                            ),
                          ),
                        );
                      }
                      final allSkills = snapshot.data ?? [];
                      final teachingSkills = allSkills
                          .where((s) => s.teachingOrLearning == 'teaching')
                          .toList();
                      final learningSkills = allSkills
                          .where((s) => s.teachingOrLearning == 'learning')
                          .toList();

                      return Column(
                        children: [
                          _buildSkillSection("TEACHING", teachingSkills),
                          const SizedBox(height: 32),
                          _buildSkillSection("LEARNING", learningSkills),
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;
          final routes = ['/home', '/notifications', '/explore', '/community'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
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
            color: const Color(0xFFE8E8ED), // Light gray placeholder
            image: user.profileBannerUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user.profileBannerUrl),
                    fit: BoxFit.cover,
                  )
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
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7), // Match background
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: const Color(0xFFE8E8ED),
                  backgroundImage: user.profilePictureUrl.isNotEmpty
                      ? NetworkImage(user.profilePictureUrl)
                      : null,
                  child: user.profilePictureUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF86868B),
                          size: 45,
                        )
                      : null,
                ),
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
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF86868B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (skills.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              "No skills added yet.",
              style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
            ),
          )
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
        borderRadius: BorderRadius.circular(30), // Capsule shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
