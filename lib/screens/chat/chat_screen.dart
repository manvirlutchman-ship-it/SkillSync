import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillsync/models/message_model.dart';
import 'package:skillsync/models/user_model.dart';
import 'package:skillsync/services/database_service.dart';

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
    // Keep focus on the text field after sending for rapid messaging
    // FocusScope.of(context).requestFocus(_focusNode); 
    
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        // Ensure Back button is accessible
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.chatName,
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          // Ensure Info button is accessible
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
                  return const Center(child: Text("Error loading messages"));
                }
                
                if (snapshot.hasData) {
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        "No messages yet. Say hi!", 
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
                      return _buildMessageBubble(msg, isMe, colorScheme);
                    },
                  );
                }
                return Semantics(
                  label: "Loading chat history",
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2))
                );
              },
            ),
          ),
          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, ColorScheme colorScheme) {
    final timeString = DateFormat('hh:mm a').format(msg.sentAt);
    
    // Accessibility: Determine who sent the message for the screen reader
    final senderLabel = isMe ? "You" : widget.chatName;

    // MergeSemantics combines the message text and time into one read-out
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
                // Ensure width constraints allow for text scaling
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isMe ? colorScheme.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: isMe ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Text(
                  msg.content,
                  // Scale text is handled automatically by Flutter, but ensure fontSize is reasonable
                  style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface, fontSize: 15, height: 1.3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                // Exclude this specific Text widget from semantics because it's already covered by the parent MergeSemantics
                child: ExcludeSemantics(
                  child: Text(timeString, style: TextStyle(color: colorScheme.secondary.withOpacity(0.8), fontSize: 10))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 34, top: 12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.5)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1, 
              maxLines: 4, // Allows text field to grow if user increases font size
              textInputAction: TextInputAction.send, // Keyboard shows "Send" button
              onSubmitted: (_) => _sendMessage(),
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Message...',
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Send Button
          Semantics(
            button: true,
            label: "Send message",
            enabled: true, // Could bind to _messageController.text.isNotEmpty if state was managed
            child: GestureDetector(
              onTap: _sendMessage,
              // Wrap in container to ensure minimum touch target size (48x48)
              // The visual circle is 44px (radius 22), so we add transparent padding
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                color: Colors.transparent, // Ensures the whole 48x48 area is tappable
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}