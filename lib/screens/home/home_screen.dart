import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// MODELS & SERVICES
import 'package:skillsync/models/conversation_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';
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
  final DatabaseService _dbService = DatabaseService();
  
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        final provider = context.read<UserProvider>();
        await provider.fetchUser(authUser.uid);

        if (provider.needsOnboarding && mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/onboarding_current',
            (route) => false,
          );
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
          // Semantic Header for navigation
          child: Semantics(
            header: true,
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
      ),

      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: colorScheme.primary,
        tooltip: "Start a new match", // Accessibility label for long-press/hover
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        onPressed: () => Navigator.pushNamed(context, '/matching'),
      ),

      // 💬 REAL-TIME Chat list from Firestore
      body: currentUser == null 
        ? Semantics(
            label: "Loading user data",
            child: const Center(child: CircularProgressIndicator())
          )
        : StreamBuilder<List<ConversationModel>>(
            stream: _dbService.getMyConversations(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Semantics(
                  label: "Loading conversations",
                  child: const Center(child: CircularProgressIndicator())
                );
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
                      // Exclude decorative icon
                      ExcludeSemantics(
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 60, color: colorScheme.secondary.withOpacity(0.3)),
                      ),
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
                  return _ChatTile(
                    conversation: conv,
                    currentUserId: currentUser.uid,
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

class _ChatTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;

  const _ChatTile({required this.conversation, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final theme = Theme.of(context);

    return FutureBuilder<UserModel?>(
      future: dbService.getChatPartner(conversation.id, currentUserId),
      builder: (context, snapshot) {
        // Skeleton loader semantics
        if (!snapshot.hasData) {
          return Semantics(
            label: "Loading chat details",
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }

        final partner = snapshot.data!;
        final String displayName = partner.fullName.trim().isEmpty 
            ? partner.username 
            : partner.fullName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          // Merge Semantics to make the whole card read as one meaningful button
          child: MergeSemantics(
            child: Semantics(
              button: true,
              label: "Chat with $displayName",
              hint: "Double tap to open conversation",
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatName: displayName,
                        conversationId: conversation.id,
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
                      // Exclude semantics here because the name is read in the label
                      ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFF5F5F7),
                          backgroundImage: partner.profilePictureUrl.isNotEmpty 
                              ? NetworkImage(partner.profilePictureUrl) 
                              : null,
                          child: partner.profilePictureUrl.isEmpty 
                              ? Icon(Icons.person_rounded, color: theme.colorScheme.primary) 
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to start chatting",
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Decorative arrow, exclude from reading
                      ExcludeSemantics(
                        child: Icon(Icons.arrow_forward_ios_rounded, 
                            size: 14, 
                            color: theme.colorScheme.secondary.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}