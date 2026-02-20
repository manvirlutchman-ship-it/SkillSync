import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skillsync/models/message_model.dart';
import 'package:skillsync/models/user_model.dart'; // 🟢 Added
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
  
  // 🟢 Added to store partner data for the info button
  UserModel? _partner;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  // 🟢 Fetch the partner's profile so we can view it
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.chatName,
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        // 🟢 ADDED: Info Icon in the actions list
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: colorScheme.secondary),
            onPressed: _partner == null 
              ? null // Disable if data hasn't loaded yet
              : () {
                  Navigator.pushNamed(
                    context, 
                    '/profile', 
                    arguments: _partner // Pass the real UserModel
                  );
                },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dbService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error loading messages"));
                
                if (snapshot.hasData) {
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(child: Text("No messages yet. Say hi!", style: TextStyle(color: colorScheme.secondary)));
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
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
            ),
          ),
          _buildInputBar(theme, colorScheme),
        ],
      ),
    );
  }

  // ... (keep the _buildMessageBubble and _buildInputBar exactly as they were)
  Widget _buildMessageBubble(MessageModel msg, bool isMe, ColorScheme colorScheme) {
    final timeString = DateFormat('hh:mm a').format(msg.sentAt);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              style: TextStyle(color: isMe ? Colors.white : colorScheme.onSurface, fontSize: 15, height: 1.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(timeString, style: TextStyle(color: colorScheme.secondary.withOpacity(0.8), fontSize: 10)),
          ),
        ],
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
              minLines: 1, maxLines: 4,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Message...',
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
            ),
          )
        ],
      ),
    );
  }
}