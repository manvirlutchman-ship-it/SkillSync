import 'package:flutter/material.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple Light Gray (F5F5F7)
      appBar: const AppAppBar(
        title: 'Notifications',
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Section Title (Apple Style)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'RECENT',
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // 🧩 Fake Notification 1: Like
          _NotificationCard(
            icon: Icons.favorite_rounded,
            iconColor: Colors.redAccent,
            username: 'FlutterDev',
            message: 'Your post on Flutter tips got 5 new likes!',
            timeAgo: '2h ago',
            isUnread: true,
          ),

          const SizedBox(height: 12),

          // 🧩 Fake Notification 2: Connection
          _NotificationCard(
            icon: Icons.person_add_rounded,
            iconColor: Colors.blueAccent,
            username: 'SkillSync Team',
            message: 'You have a new connection request from Sarah.',
            timeAgo: '5h ago',
          ),

          const SizedBox(height: 12),

          // 🧩 Fake Notification 3: Achievement
          _NotificationCard(
            icon: Icons.emoji_events_rounded,
            iconColor: Colors.orangeAccent,
            username: 'System',
            message: 'Congrats! You reached Level 2 in Dart proficiency.',
            timeAgo: 'Yesterday',
          ),
        ],
      ),

      // 🔽 Bottom nav
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // Alerts/Notifications tab
        onTap: (index) {
          if (index == 1) return;
          final routes = ['/home', '/notifications', '/explore', '/community', '/user_profile'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

// 🧩 Premium Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String username;
  final String message;
  final String timeAgo;
  final bool isUnread;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.username,
    required this.message,
    required this.timeAgo,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Consistent Squircle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Circle instead of just a color
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.primary.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w600,
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