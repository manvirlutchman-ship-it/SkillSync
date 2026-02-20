// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/models/notification_model.dart';
import 'package:skillsync/services/database_service.dart';
import 'package:skillsync/widgets/app_appbar.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get the current user ID from our Provider
    final uid = context.watch<UserProvider>().user?.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const AppAppBar(title: 'Notifications', showBack: false),
      body: uid == null
          ? Semantics(
              label: "Loading user data",
              child: const Center(child: CircularProgressIndicator()),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Notification')
                  .where(
                    'user_id',
                    isEqualTo: FirebaseFirestore.instance.doc('User/$uid'),
                  )
                  .where(
                    'read_at',
                    isNull: true,
                  ) 
                  .orderBy('created_at', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                // 1. Check for errors
                if (snapshot.hasError) {
                  debugPrint("!!! FIRESTORE ERROR: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Query Error: Check terminal for index link or rules.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                    ),
                  );
                }

                // 2. Handle Waiting State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Semantics(
                    label: "Loading notifications",
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                // 3. Handle Empty State
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No notifications yet",
                      // Ensure text is readable and announced
                      style: TextStyle(
                        fontSize: 16, 
                        color: colorScheme.onSurface.withOpacity(0.6)
                      ),
                    ),
                  );
                }

                // 4. Build List
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    try {
                      final notify = NotificationModel.fromFirestore(
                        docs[index],
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _NotificationCard(
                          notification: notify,
                          onTap: () {
                            // 1️⃣ Mark as read in background
                            DatabaseService().markNotificationAsRead(notify.id);

                            if (notify.type == 'match') {
                              // 2️⃣ Navigate to matching with match ID
                              Navigator.pushNamed(
                                context,
                                '/matching',
                                arguments: notify.referenceId,
                              );
                            }
                          },
                        ),
                      );
                    } catch (e) {
                      debugPrint("Error parsing notification: $e");
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          final routes = [
            '/home',
            '/notifications',
            '/explore',
            '/community',
            '/user_profile',
          ];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const _NotificationCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final bool isUnread = notification.readAt == null;
    final String title = _buildTitle(notification);
    final String subtitle = _buildSubtitle(notification);

    // Group Semantics: "Unread, New Match, Related to match 123..."
    // This prevents the screen reader from treating the icon and text as separate focusable items.
    return MergeSemantics(
      child: Semantics(
        button: true, // Identifies this card as clickable
        label: isUnread ? "Unread notification: $title" : "Notification: $title",
        hint: "Double tap to view details",
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: onTap,
            title: Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
            // The visual dot is purely decorative; the status is now in the semantic label.
            trailing: isUnread
                ? ExcludeSemantics(
                    child: Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  String _buildTitle(NotificationModel n) {
    switch (n.type) {
      case 'match':
        return "New Match!";
      case 'comment':
        return "New Comment";
      default:
        return "Notification";
    }
  }

  String _buildSubtitle(NotificationModel n) {
    return "Related to ${n.referencePath} (${n.referenceId})\n"
        "Created at: ${n.createdAt}";
  }
}