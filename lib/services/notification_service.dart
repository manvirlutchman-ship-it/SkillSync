import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  return Future.value();
}

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<QuerySnapshot>? _notificationListener;
  StreamSubscription<QuerySnapshot>? _messageListener;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'skillsync_high_importance',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (!kIsWeb) {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        const ios = DarwinInitializationSettings();
        const initSettings = InitializationSettings(android: android, iOS: ios);
        await _flutterLocalNotificationsPlugin.initialize(initSettings);

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification != null) {
          await _showLocalBanner(
            notification.hashCode,
            notification.title ?? 'SkillSync',
            notification.body ?? '',
          );
        }
      });

      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    } catch (e) {
      debugPrint('NotificationService.initialize error: $e');
    }
  }

  // ─── NOTIFICATIONS LISTENER ───────────────────────────────────────────────

  void startListeningForNewNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notificationListener?.cancel();

    final listenStartTime = Timestamp.now();

    _notificationListener = FirebaseFirestore.instance
        .collection('Notification')
        .where('user_id',
            isEqualTo: FirebaseFirestore.instance.doc('User/$uid'))
        .where('read_at', isNull: true)
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          // Skip anything that existed before we started listening
          final createdAt = data['created_at'] as Timestamp?;
          if (createdAt == null || createdAt.compareTo(listenStartTime) <= 0) continue;

          final type = data['type'] as String? ?? '';
          final title = type == 'match' ? 'New Match! 🎉' : 'New Comment';

          _showLocalBanner(
            change.doc.id.hashCode,
            title,
            'Tap to view details',
          );
        }
      }
    }, onError: (e) {
      debugPrint('Notification listener error: $e');
    });
  }

  // ─── MESSAGES LISTENER ────────────────────────────────────────────────────

  void startListeningForNewMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _messageListener?.cancel();

    final listenStartTime = Timestamp.now();

    FirebaseFirestore.instance
        .collection('Conversation')
        .where('participant_ids', arrayContains: uid)
        .get()
        .then((convSnapshot) {
      if (convSnapshot.docs.isEmpty) return;

      final conversationIds = convSnapshot.docs.map((d) => d.id).toList();
      final batch = conversationIds.take(10).toList();

      _messageListener = FirebaseFirestore.instance
          .collection('Message')
          .where(
            'conversation_id',
            whereIn: batch
                .map((id) => FirebaseFirestore.instance.doc('Conversation/$id'))
                .toList(),
          )
          .orderBy('sent_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;

            // Skip anything that existed before we started listening
            final sentAt = data['sent_at'] as Timestamp?;
            if (sentAt == null || sentAt.compareTo(listenStartTime) <= 0) continue;

            // Skip messages sent by the current user
            final sender = data['sender_id'];
            final senderId = sender is DocumentReference
                ? sender.id
                : sender.toString();
            if (senderId == uid) continue;

            final content = data['content'] as String? ?? 'New message';

            _showLocalBanner(
              change.doc.id.hashCode,
              'New message 💬',
              content,
            );
          }
        }
      }, onError: (e) {
        debugPrint('Message listener error: $e');
      });
    }).catchError((e) {
      debugPrint('Failed to fetch conversations: $e');
    });
  }

  // ─── STOP ALL LISTENERS ───────────────────────────────────────────────────

  void stopListening() {
    _notificationListener?.cancel();
    _notificationListener = null;
    _messageListener?.cancel();
    _messageListener = null;
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Future<void> _showLocalBanner(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'skillsync_high_importance',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(id, title, body, details);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .update({'fcmToken': token});
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<AuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true);
    return settings.authorizationStatus;
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }
}