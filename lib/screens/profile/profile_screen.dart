import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/models/userskill_model.dart';
import 'package:skillsync/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int localLikesOffset = 0;
  bool hasLikedLocally = false;

  bool hasLikedFromDb = false;
  bool isCheckingLikeStatus = true;
  final String myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _checkIfAlreadyLiked(String viewedUserId) async {
    final liked = await DatabaseService().checkIfLiked(myId, viewedUserId);

    if (!mounted) return;

    setState(() {
      hasLikedFromDb = liked;
      isCheckingLikeStatus = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 EXTRACT THE USER DATA passed from MatchingScreen
    final UserModel? user =
        ModalRoute.of(context)?.settings.arguments as UserModel?;

    // Handle case where argument is missing (though unlikely in flow)
    if (user == null) return const Scaffold(body: Center(child: Text("Error loading profile")));

    if (isCheckingLikeStatus) {
      _checkIfAlreadyLiked(user.id);
    }
    final dbService = DatabaseService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: "Back",
          button: true,
          child: IconButton(
            tooltip: "Back",
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text("View Profile"),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(user),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  
                  // Name Header
                  Semantics(
                    header: true,
                    child: Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1D1D1F),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Username
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 16,
                    ),
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
                              : "No bio provided.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1D1D1F),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: Color(0xFFF5F5F7),
                            thickness: 1.5,
                          ),
                        ),
                        
                        // 🟢 Interactive Like Area with Accessibility
                        _buildLikeSection(user),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🛠 Public Skills Section
                  FutureBuilder<List<UserSkillModel>>(
                    future: dbService.getUserSkills(user.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Semantics(
                          label: "Loading skills",
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildLikeSection(UserModel user) {
    final bool isLiked = hasLikedLocally || hasLikedFromDb;
    final int count = user.likesCount + localLikesOffset;

    // Merge Semantics so the button and the count are read together
    // e.g. "Like user, currently 5 likes, button"
    return MergeSemantics(
      child: Semantics(
        label: "Like user. Currently $count likes.",
        button: true,
        enabled: !isLiked && !isCheckingLikeStatus,
        stateDescription: isLiked ? "Liked" : "Not liked",
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Exclude text from individual reading since it's in the parent label
            ExcludeSemantics(
              child: Text(
                '$count LIKES',
                style: const TextStyle(
                  color: Color(0xFF1D1D1F),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 12),

            if (isCheckingLikeStatus)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                // Ensure target size
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: isLiked ? "Liked" : "Like User",
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  color: isLiked ? Colors.redAccent : const Color(0xFF1D1D1F),
                ),
                onPressed: isLiked
                    ? null
                    : () async {
                        if (myId == user.id) return;

                        setState(() {
                          localLikesOffset = 1;
                          hasLikedLocally = true;
                        });

                        await DatabaseService().likeUser(user.id, myId);
                      },
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
        // Decorative Banner - Exclude from Semantics
        ExcludeSemantics(
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
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F7),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: user.profilePictureUrl.isNotEmpty
                    ? NetworkImage(user.profilePictureUrl)
                    : null,
                // Accessible label for profile picture
                child: Semantics(
                  label: "Profile picture of ${user.username}",
                  image: true,
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
        // Semantic Header
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF86868B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          const Text(
            "None added.",
            style: TextStyle(color: Color(0xFF86868B), fontSize: 14),
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
    // Skills are usually read as text, simple Container is fine
    // Semantics will read the child text automatically.
    return Container(
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
    );
  }
}