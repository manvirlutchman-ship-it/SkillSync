import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillsync/models/message_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';

import '../../widgets/scalable_text.dart';

class ChatScreen extends StatefulWidget {
  final String chatName;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.chatName,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  UserModel? _partner;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    final partner = await _dbService.getChatPartner(widget.conversationId, currentUserId);
    if (mounted) {
      setState(() {
        _partner = partner;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await _dbService.sendMessage(widget.conversationId, currentUserId, text);
    } catch (e) {
      debugPrint("Error sending message: $e");
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
        // 🟢 THEME FIX: Use surface instead of Colors.white
        backgroundColor: colorScheme.surface,
        elevation: isDark ? 0 : 0.5,
        centerTitle: true,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: ScalableText(
          widget.chatName,
          baseFontSize: 17,
          style: TextStyle(
            color: colorScheme.primary, 
            fontWeight: FontWeight.bold, 
            fontSize: 17
          ),
        ),
        actions: [
          Semantics(
            label: 'View Profile',
            button: true,
            enabled: _partner != null,
            child: IconButton(
              tooltip: 'View Profile',
              icon: Icon(Icons.info_outline_rounded, color: colorScheme.secondary),
              onPressed: _partner == null 
                ? null 
                : () {
                    Navigator.pushNamed(
                      context, 
                      '/profile', 
                      arguments: _partner 
                    );
                  },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dbService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading messages",
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }
                
                if (snapshot.hasData) {
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: ScalableText(
                        "No messages yet. Say hi!", 
                        baseFontSize: 15,
                        style: TextStyle(color: colorScheme.secondary)
                      )
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _buildMessageBubble(msg, isMe, colorScheme, isDark);
                    },
                  );
                }
                return Semantics(
                  label: "Loading chat history",
                  child: Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2))
                );
              },
            ),
          ),
          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, ColorScheme colorScheme, bool isDark) {
    final timeString = DateFormat('hh:mm a').format(msg.sentAt);
    final senderLabel = isMe ? "You" : widget.chatName;

    return MergeSemantics(
      child: Semantics(
        label: "$senderLabel said: ${msg.content}, at $timeString",
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  // 🟢 THEME FIX: Sent uses Primary, Received uses Surface
                  color: isMe ? colorScheme.primary : colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: isMe 
                    ? [] 
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), 
                          blurRadius: 10, 
                          offset: const Offset(0, 4),
                        )
                      ],
                ),
                child: ScalableText(
                  msg.content,
                  baseFontSize: 15,
                  style: TextStyle(
                    // 🟢 THEME FIX: Sent text uses onPrimary, Received uses onSurface
                    color: isMe ? colorScheme.onPrimary : colorScheme.onSurface, 
                    fontSize: 15, 
                    height: 1.3
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: ExcludeSemantics(
                  child: ScalableText(
                    timeString, 
                    baseFontSize: 10,
                    style: TextStyle(color: colorScheme.secondary.withOpacity(0.8))
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34, top: 12),
      decoration: BoxDecoration(
        // 🟢 THEME FIX: Use surface instead of Colors.white
        color: colorScheme.surface, 
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.5))
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1, 
              maxLines: 4, 
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              // 🟢 THEME FIX: Explicitly use onSurface for text
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: colorScheme.secondary.withOpacity(0.7)),
                filled: true,
                // Scaffold background color provides good contrast for the input field
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24), 
                  borderSide: BorderSide.none
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Semantics(
            button: true,
            label: "Send message",
            child: GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                color: Colors.transparent, 
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary,
                  // 🟢 THEME FIX: Icon uses onPrimary (Black in dark, White in light)
                  child: Icon(Icons.arrow_upward_rounded, color: colorScheme.onPrimary, size: 22),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}