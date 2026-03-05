import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isUser
            ? Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              )
            : MarkdownBody(
                data: message,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 15),
                ),
              ),
      ),
    );
  }
}