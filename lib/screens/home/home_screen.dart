import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../matching/matching_screen.dart';
import 'package:skillsync/widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, String>> chats = [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,

      // 🚫 No back button
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Home'),
        backgroundColor: Colors.deepPurple,
      ),

      // ➕ Matching screen
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
        onPressed: () {
  Navigator.pushNamed(context, '/matching');
},

      ),

      // 💬 Chat list
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(chatName: chat['name']!),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      chat['avatar']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chat['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat['message']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    chat['time']!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // already on home
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
              Navigator.pushReplacementNamed(context, '/user_profile');
              break;
          }
        },
      ),
    );
  }
}
