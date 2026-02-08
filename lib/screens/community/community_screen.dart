import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple Gray (F5F5F7)
      appBar: const AppAppBar(
        title: 'Community',
        showBack: false,
      ),
      body: SingleChildScrollView( // Added scrolling for the feed
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏷 Filter Tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    _TagChip('For You', isActive: true),
                    SizedBox(width: 8),
                    _TagChip('Trending'),
                    SizedBox(width: 8),
                    _TagChip('Skill Swap'),
                    SizedBox(width: 8),
                    _TagChip('Project Help'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🧱 Apple-Style Post Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface, // Pure White
                  borderRadius: BorderRadius.circular(16), // Consistent Squircle
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.scaffoldBackgroundColor,
                          child: Icon(Icons.person_rounded, color: colorScheme.secondary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'alex_dev',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '2 hours ago',
                              style: TextStyle(
                                color: colorScheme.secondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.more_horiz_rounded, color: colorScheme.secondary),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 📝 Post content
                    Text(
                      'Just finished building my first Flutter UI and honestly… this feels powerful. Looking for a mentor in Backend logic! 🚀',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🖼 Media Placeholder
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.image_outlined, color: colorScheme.secondary.withOpacity(0.3), size: 40),
                    ),

                    const SizedBox(height: 16),

                    // ❤️ Actions
                    Row(
                      children: [
                        _PostAction(Icons.favorite_outline_rounded, '24'),
                        const SizedBox(width: 20),
                        _PostAction(Icons.chat_bubble_outline_rounded, '12'),
                        const SizedBox(width: 20),
                        _PostAction(Icons.repeat_rounded, '5'),
                        const Spacer(),
                        Text(
                          '#Flutter',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          final routes = ['/home', '/notifications', '/explore', '/social', '/user_profile'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

// 🧩 Helper: Tag chips (Apple Capsule Style)
class _TagChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TagChip(this.label, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(30), // Capsule shape
        boxShadow: [
          if (!isActive)
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
        border: isActive ? null : Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : colorScheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// 🧩 Helper: Action buttons
class _PostAction extends StatelessWidget {
  final IconData icon;
  final String count;

  const _PostAction(this.icon, this.count);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colorScheme.secondary, size: 20),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(color: colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}