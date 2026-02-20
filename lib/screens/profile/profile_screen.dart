import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/avatar_image.dart';

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
  bool _hasInitialized = false; // Prevents re-running logic on every build
  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Senior Tip: Grabbing ModalRoute arguments should happen here, not in build.
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
    if (user == null)
      return const Scaffold(body: Center(child: Text("Error loading profile")));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dbService = DatabaseService();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: "Back",
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
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

                  // Name & Handle
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
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      color: Color(0xFF86868B),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio Card
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
                        _buildLikeSection(user),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🛠 THE FIXED SKILLS SECTION (Resolving Names)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    // 🟢 Using the resolved method we added to DatabaseService
                    future: dbService.getUserSkillsWithNames(user.id),
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

                      // Filter the resolved maps by the 'type' key
                      final teachingSkills = allSkills
                          .where((s) => s['type'] == 'teaching')
                          .toList();
                      final learningSkills = allSkills
                          .where((s) => s['type'] == 'learning')
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

  // --- REFACTORED HELPERS ---

  Widget _buildLikeSection(UserModel user) {
    final bool isLiked = _hasLikedLocally || _hasLikedFromDb;
    final int count = user.likesCount + _localLikesOffset;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$count LIKES',
          style: const TextStyle(
            color: Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        if (_isCheckingLikeStatus)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isLiked ? Colors.redAccent : const Color(0xFF1D1D1F),
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

  Widget _buildProfileHeader(UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner
        Container(
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
        // Profile avatar
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
              child: AvatarImage(
                path: user.profilePictureUrl,
                radius: 50, // directly using 50
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<Map<String, dynamic>> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF86868B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
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
            children: skills
                .map((s) => _SkillTile(s['name']))
                .toList(), // 🟢 Pass Resolved Name
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
