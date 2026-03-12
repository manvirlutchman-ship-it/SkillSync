import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/services/auth_service.dart';
import 'package:skillsync/models/userskill_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/widgets/avatar_image.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

import '../../widgets/scalable_text.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final dbService = DatabaseService();

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Semantics(
            label: 'Loading profile data',
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    final String displayName = user.fullName.trim().isEmpty
        ? user.username
        : user.fullName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          /// EDIT PROFILE
          _buildAppBarAction(
            icon: Icons.edit_note_rounded,
            size: 26,
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
            colorScheme: colorScheme,
          ),

          /// SETTINGS
          _buildAppBarAction(
            icon: Icons.settings_rounded,
            size: 22,
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            colorScheme: colorScheme,
          ),

          /// LOGOUT
          _buildAppBarAction(
            icon: Icons.logout_rounded,
            size: 22,
            tooltip: 'Logout',
            isLast: true,
            onPressed: () => _showLogoutDialog(context),
            colorScheme: colorScheme,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user, theme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  Semantics(
                    header: true,
                    child:ScalableText(
                      displayName,
                      baseFontSize: 30,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ScalableText(
                    '@${user.username.split('@')[0]}',
                    baseFontSize: 16,
                      fontWeight: FontWeight.w500,
                    
                  ),
                  const SizedBox(height: 24),
                  _buildBioCard(user, colorScheme, isDark),
                  const SizedBox(height: 32),
                  _buildSkillsSection(dbService, user.id, colorScheme),
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

  /// Helper to build consistent themed circular actions for the transparent AppBar
  Widget _buildAppBarAction({
    required IconData icon,
    required double size,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(right: isLast ? 20 : 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.85),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: colorScheme.onSurface, size: size),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Semantics(
          label: 'Logging out',
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      ),
    );
    try {
      context.read<UserProvider>().clearUser();
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.signOut().then((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.2),
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
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: AvatarImage(
                path: user.profilePictureUrl,
                radius: 50,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard(UserModel user, ColorScheme colorScheme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ScalableText(
            user.userBio.isNotEmpty ? user.userBio : "No bio available.",
            textAlign: TextAlign.center,
            baseFontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: colorScheme.outline.withOpacity(0.2), thickness: 1.5),
          ),
          Semantics(
            label: '${user.likesCount} total likes received',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                ScalableText(
                  '${user.likesCount} LIKES',
                  baseFontSize: 14,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
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

  Widget _buildSkillsSection(DatabaseService dbService, String userId, ColorScheme colorScheme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: dbService.getUserSkillsWithNames(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.secondary,
              ),
            ),
          );
        }

        final allSkills = snapshot.data ?? [];
        final teachingSkills = allSkills.where((s) => s['type'] == 'teaching').toList();
        final learningSkills = allSkills.where((s) => s['type'] == 'learning').toList();

        return Column(
          children: [
            _buildSkillSection("TEACHING", teachingSkills, colorScheme),
            const SizedBox(height: 32),
            _buildSkillSection("LEARNING", learningSkills, colorScheme),
          ],
        );
      },
    );
  }

  Widget _buildSkillSection(String title, List<Map<String, dynamic>> skills, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ScalableText(
              title,
              baseFontSize: 11,
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        if (skills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: ScalableText(
              "No skills added yet.",
              baseFontSize: 14,
              style: TextStyle(color: colorScheme.secondary),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills.map((s) => _SkillTile(s['name'])).toList(),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Skill: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ScalableText(
          label,
          baseFontSize: 14,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}