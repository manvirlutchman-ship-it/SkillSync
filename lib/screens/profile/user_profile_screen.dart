import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/models/userskill_model.dart';
import 'package:skillsync/models/user_model.dart';
// Note: Ensure your rating_row and bottom_nav are also accessible
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

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Center(
          child: Semantics(
            label: 'Loading profile data',
            child: const CircularProgressIndicator(color: Color(0xFF1D1D1F)),
          ),
        ),
      );
    }

    final String displayName =
        user.fullName.trim().isEmpty ? user.username : user.fullName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              // Meets 48x48 tap target via IconButton default constraints
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF1D1D1F),
                size: 26,
              ),
              tooltip: 'Edit Profile',
              onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF1D1D1F),
                size: 22,
              ),
              tooltip: 'Logout',
              onPressed: () async {
                _showLogoutDialog(context);
              },
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        // Allows content to scroll when text is scaled up
        child: Column(
          children: [
            _buildProfileHeader(user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  // Header semantics for screen readers
                  Semantics(
                    header: true,
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Color(0xFF1D1D1F),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.username.split('@')[0]}',
                    style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBioCard(user),
                  const SizedBox(height: 32),
                  _buildSkillsSection(dbService, user.id),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Semantics(
          label: 'Logging out',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
    try {
      context.read<UserProvider>().clearUser();
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.signOut().then((_) {
        if (context.mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildProfileHeader(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: 'Profile banner image',
          image: true,
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8ED),
              image: user.profileBannerUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.profileBannerUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: -45,
          left: 0,
          right: 0,
          child: Center(
            child: Semantics(
              label: 'Profile picture of ${user.fullName}',
              image: true,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F7),
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
        ),
      ],
    );
  }

  Widget _buildBioCard(UserModel user) {
    return Container(
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
            user.userBio.isNotEmpty ? user.userBio : "No bio available.",
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
            child: Divider(color: Color(0xFFF5F5F7), thickness: 1.5),
          ),
          Semantics(
            // Combines the icon and text into one meaningful label for screen readers
            label: '${user.likesCount} total likes received',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFF1D1D1F), size: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(DatabaseService dbService, String userId) {
    return FutureBuilder<List<UserSkillModel>>(
      future: dbService.getUserSkills(userId),
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
            _buildSkillGroup("TEACHING", teachingSkills),
            const SizedBox(height: 32),
            _buildSkillGroup("LEARNING", learningSkills),
          ],
        );
      },
    );
  }

  Widget _buildSkillGroup(String title, List<UserSkillModel> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Semantics(
            header: true,
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
    return Semantics(
      label: 'Skill: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
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
      ),
    );
  }
}