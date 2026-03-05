import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  final String _apiKey = "AIzaSyDYNBduGrovsKSXlxLWoKx3PwUTO6scyck";

  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await _callGemini(text);

      setState(() {
        _messages.add(_ChatMessage(text: "", isUser: false));
      });

      await _typeWriterEffect(response);
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
            text: "Error connecting to AI. Please try again.",
            isUser: false));
      });
    }

    setState(() {
      _isLoading = false;
    });

    _scrollToBottom();
  }

Future<void> _typeWriterEffect(String fullText) async {
  int index = _messages.length - 1;

  const int charsPerTick = 12; // how many characters appear each frame
  const Duration delay = Duration(milliseconds: 10);

  int current = 0;

  while (current < fullText.length) {
    await Future.delayed(delay);

    final next = (current + charsPerTick).clamp(0, fullText.length);

    setState(() {
      _messages[index].text = fullText.substring(0, next);
    });

    current = next;

    _scrollToBottom();
  }
}

  Future<String> _callGemini(String prompt) async {
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      throw Exception("Gemini error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: isDark ? 0 : 0.5,
        title: Text(
          "AI Assistant",
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.primary),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      "Start chatting with Gemini AI!",
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildBubble(msg, colorScheme, isDark);
                    },
                  ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AI is thinking...",
                    style: TextStyle(color: colorScheme.secondary),
                  )
                ],
              ),
            ),

          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildBubble(
      _ChatMessage msg, ColorScheme colorScheme, bool isDark) {
    return Align(
      alignment:
          msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color:
                msg.isUser ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: msg.isUser
                ? []
                : [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: msg.isUser
              ? Text(
                  msg.text,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 15,
                  ),
                )
              : MarkdownBody(
                  data: msg.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                    h3: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    strong: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInputBar(
      ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(
          left: 16, right: 16, bottom: 34, top: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                colorScheme.outline.withOpacity(isDark ? 0.2 : 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Ask Gemini...",
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primary,
              child: Icon(
                Icons.arrow_upward_rounded,
                color: colorScheme.onPrimary,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;

  _ChatMessage({
    required this.text,
    required this.isUser,
  });
}