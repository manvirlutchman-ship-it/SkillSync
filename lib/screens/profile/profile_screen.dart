import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/avatar_image.dart';

import '../../widgets/scalable_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _localLikesOffset = 0;
  bool _hasLikedLocally = false;
  bool _hasLikedFromDb = false;
  bool _isCheckingLikeStatus = true;
  bool _hasInitialized = false; 
  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      final UserModel? user =
          ModalRoute.of(context)?.settings.arguments as UserModel?;
      if (user != null) {
        _checkIfAlreadyLiked(user.id);
      }
      _hasInitialized = true;
    }
  }

  Future<void> _checkIfAlreadyLiked(String viewedUserId) async {
    final liked = await DatabaseService().checkIfLiked(_myId, viewedUserId);
    if (!mounted) return;
    setState(() {
      _hasLikedFromDb = liked;
      _isCheckingLikeStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user =
        ModalRoute.of(context)?.settings.arguments as UserModel?;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error loading profile")));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dbService = DatabaseService();

    final String displayName = user.fullName.isEmpty ? user.username : user.fullName;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.primary, // 🟢 Theme primary
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ScalableText(
          "View Profile",
          baseFontSize: 16,
          style: TextStyle(color: colorScheme.onSurface), // 🟢 Theme Aware
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                    child: ScalableText(
                      displayName,
                      baseFontSize: 30,
                      style: TextStyle(
                        color: colorScheme.onSurface, // 🟢 Theme Aware
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ScalableText(
                    '@${user.username}',
                    baseFontSize: 16,
                    style: TextStyle(
                      color: colorScheme.secondary, // 🟢 Apple Gray
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface, // 🟢 Dynamic Surface
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), // 🟢 Dynamic Shadow
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ScalableText(
                          user.userBio.isNotEmpty ? user.userBio : "No bio provided.",
                          baseFontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: colorScheme.outline.withOpacity(0.2), // 🟢 Theme Aware
                            thickness: 1.5,
                          ),
                        ),
                        _buildLikeSection(user, colorScheme),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: dbService.getUserSkillsWithNames(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.secondary,
                          ),
                        );
                      }

                      final allSkills = snapshot.data ?? [];
                      final teachingSkills = allSkills.where((s) => s['type'] == 'teaching').toList();
                      final learningSkills = allSkills.where((s) => s['type'] == 'learning').toList();

                      return Column(
                        children: [
                          _buildSkillSection("TEACHES", teachingSkills, colorScheme),
                          const SizedBox(height: 32),
                          _buildSkillSection("WANTS TO LEARN", learningSkills, colorScheme),
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

  Widget _buildLikeSection(UserModel user, ColorScheme colorScheme) {
    final bool isLiked = _hasLikedLocally || _hasLikedFromDb;
    final int count = user.likesCount + _localLikesOffset;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScalableText(
          '$count LIKES',
          baseFontSize: 14,
          style: TextStyle(
            color: colorScheme.onSurface, // 🟢 Theme Aware
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        if (_isCheckingLikeStatus)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
          )
        else
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isLiked ? Colors.redAccent : colorScheme.onSurface, // 🟢 Theme Aware
            ),
            onPressed: isLiked || _myId == user.id
                ? null
                : () async {
                    setState(() {
                      _localLikesOffset = 1;
                      _hasLikedLocally = true;
                    });
                    await DatabaseService().likeUser(user.id, _myId);
                  },
          ),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.1),
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
                color: theme.scaffoldBackgroundColor, // 🟢 Seamless merge
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

  Widget _buildSkillSection(String title, List<Map<String, dynamic>> skills, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScalableText(
          title,
          baseFontSize: 11,
          style: TextStyle(
            color: colorScheme.secondary, // 🟢 Theme Aware
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          ScalableText(
            "None added.",
            baseFontSize: 14,
            style: TextStyle(color: colorScheme.secondary),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface, // 🟢 Dynamic Tile
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
          color: colorScheme.onSurface, // 🟢 Dynamic Text
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}