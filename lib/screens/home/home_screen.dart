import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillsync/providers/user_provider.dart';
import 'package:skillsync/screens/chat/chat_screen.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> chats = [
    {
      'name': 'Alice',
      'message': 'Hey, are you free tomorrow?',
      'time': '10:24 AM',
      'avatar': 'A',
    },
    {
      'name': 'Bob',
      'message': 'I finished the project!',
      'time': '9:50 AM',
      'avatar': 'B',
    },
    {
      'name': 'Charlie',
      'message': 'Let’s meet at 6?',
      'time': 'Yesterday',
      'avatar': 'C',
    },
    {
      'name': 'Dana',
      'message': 'Good job on the presentation!',
      'time': 'Yesterday',
      'avatar': 'D',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        final provider = context.read<UserProvider>();
        if (provider.user == null) {
          provider.fetchUser(authUser.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Apple F5F5F7
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // Left aligned for modern iOS look
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Messages',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),

      // ➕ Themed Floating Action Button
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: colorScheme.primary, // Slate
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => Navigator.pushNamed(context, '/matching'),
      ),

      // 💬 Chat List (Themed Cards)
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatName: chat['name']!),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Consistent Squircle
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      child: Text(
                        chat['avatar']!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat['name']!,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chat['message']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          chat['time']!,
                          style: TextStyle(
                            color: colorScheme.secondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Unread indicator example
                        if (index == 0)
                          Container(
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent, // Standard iOS notification blue
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          final routes = ['/home', '/notifications', '/explore', '/community', '/user_profile'];
          Navigator.pushReplacementNamed(context, routes[index]);
        },
      ),
    );
  }
}