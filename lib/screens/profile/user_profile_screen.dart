import 'package:flutter/material.dart';
import 'package:skillsync/widgets/rating_row.dart';
import 'package:skillsync/widgets/bottom_nav.dart'; // <-- import bottom nav

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // 🔝 No appbar needed since no back button
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔝 Banner + profile
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.white,
                  ),

                  // ❌ Removed back button here

                  Positioned(
                    bottom: -40,
                    left: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color.fromARGB(255, 47, 49, 53),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // 👤 Username
              const Text(
                'Your Username',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // 📝 Bio
              const Text('Bio', style: TextStyle(color: Colors.white70)),

              const SizedBox(height: 6),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This is where your bio will appear. Here, you can briefly tell users about yourself.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),

              const SizedBox(height: 20),

              // ⭐ Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Rating', style: TextStyle(color: Colors.white)),
                  SizedBox(width: 8),
                  RatingRow(rating: 4),
                ],
              ),

              const SizedBox(height: 24),

              // 🛠 Skills
              const Text(
                'Skills',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 4.5,
                  children: const [
                    _SkillTile('Flutter'),
                    _SkillTile('Firebase'),
                    _SkillTile('UI/UX'),
                    _SkillTile('Python'),
                    _SkillTile('React'),
                    _SkillTile('Java'),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // 🔽 Bottom nav
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Profile tab
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
              Navigator.pushReplacementNamed(context, '/community');
              break;
            case 4:
              //already here
              break;
          }
        },
      ),
    );
  }
}

// 🧩 Minimal skill rectangle
class _SkillTile extends StatelessWidget {
  final String label;
  const _SkillTile(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}