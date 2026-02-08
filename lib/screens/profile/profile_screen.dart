import 'package:flutter/material.dart';
import 'package:skillsync/widgets/rating_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access theme colors for consistency
    final theme = Theme.of(context);
    final Color appleSlate = const Color(0xFF1D1D1F);
    final Color appleGray = const Color(0xFF86868B);
    final Color appleBackground = const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: appleBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔝 Banner + Profile Picture (Matching UserProfileScreen)
            _buildProfileHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 55),
                  
                  // Name Section
                  Text(
                    'Username',
                    style: TextStyle(
                      color: appleSlate, 
                      fontSize: 30, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@username_handle',
                    style: TextStyle(
                      color: appleGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons (Accept / Decline)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Accept',
                          color: appleSlate,
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Decline',
                          color: const Color(0xFFE8E8ED), // Light Apple Gray
                          textColor: appleSlate,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bio & Rating Card
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
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Passionate learner, curious mind, and focused on meaningful collaboration. Always looking to sync new skills.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: appleSlate, 
                            fontSize: 15, 
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF5F5F7), thickness: 1.5),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Rating', 
                              style: TextStyle(
                                color: appleGray, 
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )
                            ),
                            const SizedBox(width: 12),
                            const RatingRow(rating: 5),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Skills Section
                  _buildSkillSection("TEACHING", ['Flutter', 'Firebase', 'UI/UX']),
                  const SizedBox(height: 32),
                  _buildSkillSection("LEARNING", ['Python', 'React', 'Java']),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFE8E8ED),
            // Example Banner image:
            // image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
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
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 47,
                  backgroundColor: Color(0xFFE8E8ED),
                  child: Icon(Icons.person_rounded, color: Color(0xFF86868B), size: 45),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection(String title, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title, 
            style: const TextStyle(
              color: Color(0xFF86868B), 
              fontSize: 12, 
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((s) => _SkillTile(s)).toList(),
        ),
      ],
    );
  }
}

// 🔘 Modern Apple-style action button
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Match AppTheme
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// 🧩 Capsule-shaped skill tile
class _SkillTile extends StatelessWidget {
  final String label;
  const _SkillTile(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30), // Capsule
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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