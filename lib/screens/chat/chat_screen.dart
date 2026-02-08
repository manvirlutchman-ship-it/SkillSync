import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String chatName;

  const ChatScreen({super.key, required this.chatName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Fake messages
    final List<Map<String, String>> messages = const [
      {'sender': 'me', 'text': 'Hey there! How’s it going?'},
      {'sender': 'them', 'text': 'Hi! All good. You?'},
      {'sender': 'me', 'text': 'Pretty good, working on a project.'},
      {'sender': 'them', 'text': 'Nice! Need any help?'},
      {'sender': 'me', 'text': 'Maybe later, thanks!'},
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // Apple-style back button
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          chatName,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // 💬 Chat messages area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender'] == 'me';
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      // Me: Slate (Primary), Them: White
                      color: isMe ? colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16), // Consistent Squircle
                      boxShadow: isMe 
                        ? [] 
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isMe ? Colors.white : colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ⌨️ Modern Input Bar
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34, top: 12), // Extra bottom padding for iOS feel
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.6)),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor, // Light gray fill
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Send Button
                GestureDetector(
                  onTap: () {
                    // Logic to send message
                  },
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}