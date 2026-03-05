import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();

  List<Message> messages = [];

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    String userText = controller.text;

    setState(() {
      messages.add(Message(text: userText, isUser: true));
    });

    controller.clear();

    // Simulated Gemini response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add(
          Message(
            text: """
### Example Gemini Response

**This text is bold**

- Bullet point one
- Bullet point two

---
This shows Markdown formatting.
""",
            isUser: false,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];

                return ChatBubble(
                  message: msg.text,
                  isUser: msg.isUser,
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ask something...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}