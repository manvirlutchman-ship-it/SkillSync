import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const AppAppBar(
        title: 'Community Posts',
        showBack: false,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷 Tags
            Row(
              children: const [
                _TagChip('For You', isActive: true),
                SizedBox(width: 8),
                _TagChip('Trending'),
                SizedBox(width: 8),
                _TagChip('Skill'),
              ],
            ),

            const SizedBox(height: 16),

            // 🧱 Fake post
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 118, 118, 118),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Header
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'username_here',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 📝 Post content
                  const Text(
                    'Just finished building my first Flutter UI and honestly… this feels powerful.',
                    style: TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 8),

                  // 🖼 Fake image
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ❤️ Actions
                  Row(
                    children: const [
                      Icon(Icons.favorite_border, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Icon(Icons.comment, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Icon(Icons.repeat, color: Colors.white70, size: 20),
                      SizedBox(width: 12),
                      Text(
                        '#Flutter',
                        style: TextStyle(color: Color.fromARGB(255, 242, 255, 1)),
                      ),
                      Spacer(),
                      Icon(Icons.share, color: Colors.white70, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔽 Bottom nav
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3, // Community
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/notifications');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/explore');
              break;
            case 3:
              //already here
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/user_profile');
              break;
          }
        },
      ),
    );
  }
}

//
// 🧩 Tag chip (same style logic as onboarding)
//
class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TagChip(this.label, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black,
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}