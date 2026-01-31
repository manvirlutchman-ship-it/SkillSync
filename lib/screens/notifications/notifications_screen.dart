import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const AppAppBar(
        title: 'Notifications',
        showBack: false,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🧩 Fake Notification 1
            _NotificationCard(
              avatarColor: Colors.blue,
              username: 'FlutterDev',
              message: 'Your post on Flutter tips got 5 new likes!',
              timeAgo: '2h ago',
            ),

            const SizedBox(height: 12),

            // 🧩 Fake Notification 2
            _NotificationCard(
              avatarColor: Colors.purple,
              username: 'SkillSync',
              message: 'You have a new connection request.',
              timeAgo: '5h ago',
            ),

          ],
        ),
      ),

      // 🔽 Bottom nav
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // Notifications tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // already here
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/explore');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/community');
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

// 🧩 Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final Color avatarColor;
  final String username;
  final String message;
  final String timeAgo;

  const _NotificationCard({
    super.key,
    required this.avatarColor,
    required this.username,
    required this.message,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}