import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// MODELS & SERVICES
import 'package:skillsync/models/conversation_model.dart'; // 🟢 FIX 1: Import added
import 'package:skillsync/services/database_service.dart'; // 🟢 FIX 2: Import added
import 'package:skillsync/providers/user_provider.dart';

// SCREENS & WIDGETS
import 'package:skillsync/screens/chat/chat_screen.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🟢 FIX 3: Define the DatabaseService instance here
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Fetch user profile on arrival
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => Navigator.pushNamed(context, '/matching'),
      ),

      // 💬 REAL-TIME Chat list from Firestore
      body: currentUser == null 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<ConversationModel>>(
            stream: _dbService.getMyConversations(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error loading chats: ${snapshot.error}"));
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 60, color: colorScheme.secondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        "No conversations yet.\nGo match with someone!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.secondary, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conv = conversations[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatName: "Skill Partner", // Later we can fetch the specific name
                              conversationId: conv.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                              child: Icon(Icons.person_rounded, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Skill Match",
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tap to start chatting",
                                    style: TextStyle(
                                      color: colorScheme.secondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.secondary.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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