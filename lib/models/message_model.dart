import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id; // The document ID from Firestore
  final String content; // "Hello Sara..."
  final String conversationId; // Extracted ID from /Conversation/1
  final bool isRead; // false
  final String messageType; // "text"
  final String senderId; // Extracted ID from /User/1
  final DateTime sentAt; // Converted from Timestamp

  MessageModel({
    required this.id,
    required this.content,
    required this.conversationId,
    required this.isRead,
    required this.messageType,
    required this.senderId,
    required this.sentAt,
  });

  /// Factory to create a MessageModel from a Firestore DocumentSnapshot
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MessageModel(
      id: doc.id,
      content: data['content'] ?? '',
      // Extracting IDs from References
      conversationId: data['conversation_id'] is DocumentReference
          ? (data['conversation_id'] as DocumentReference).id
          : '',
      senderId: data['sender_id'] is DocumentReference
          ? (data['sender_id'] as DocumentReference).id
          : '',
      isRead: data['is_read'] ?? false,
      messageType: data['message_type'] ?? 'text',

      // 🟢 THE FIX: Check if it's a Timestamp. If null, use current time.
      sentAt: data['sent_at'] is Timestamp
          ? (data['sent_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Method to convert the model back to a Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'conversation_id': FirebaseFirestore.instance.doc(
        'Conversation/$conversationId',
      ),
      'is_read': isRead,
      'message_type': messageType,
      'sender_id': FirebaseFirestore.instance.doc('User/$senderId'),
      'sent_at': Timestamp.fromDate(sentAt),
    };
  }
}
