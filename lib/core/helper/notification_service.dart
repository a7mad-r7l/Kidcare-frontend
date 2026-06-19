import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kidcare/core/helper/secure_storage_service.dart';

import '../constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log("📩 إشعار جديد في الخلفية (Background/Terminated): ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _appointmentsChannel =
      AndroidNotificationChannel(
        'appointments_channel', // channelId
        'Appointments Notifications', // channelName
        description: 'This channel is used for appointments updates.',
        importance: Importance.max,
        playSound: true,
      );

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'chat_channel', // channelId
        'Chat Notifications', // channelName
        description: 'This channel is used for direct doctor chats.',
        importance: Importance.max,
        playSound: true,
      );

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log("🔔 تم منح صلاحيات الإشعارات بنجاح من قبل المستخدم.");
    }

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_appointmentsChannel);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_chatChannel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNotificationClick(response.payload!);
        }
      },
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("📥 استلام إشعار حي والتطبيق مفتوح: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🖱️ تم النقر على الإشعار والتطبيق بالخلفية: ${message.data}");
      if (message.data.containsKey('type')) {
        _handleNotificationClick(message.data['type'].toString());
      }
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && initialMessage.data.containsKey('type')) {
      log("🚀 أقع التطبيق من الصفر بنقرة إشعار: ${initialMessage.data}");
      _handleNotificationClick(initialMessage.data['type'].toString());
    }

    await _getAndPrintFCMToken();
  }

  static Future<void> _getAndPrintFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        log("🔑 🔑 🔑 MY DEVICE FCM TOKEN = $token");

        // 🌟 إرسال التوكن إلى السيرفر
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      log("❌ فشل توليد الـ FCM Token: $e");
    }
  }

  static Future<void> _saveTokenToBackend(String fcmToken) async {
    try {
      String userToken = await SecureStorage.getToken();

      if (userToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/parent/save-fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        log("✅ تم حفظ الـ FCM Token في الباك إند بنجاح!");
      } else {
        log("⚠️ فشل حفظ التوكن في الباك إند: ${response.body}");
      }
    } catch (e) {
      log("❌ خطأ أثناء إرسال التوكن للسيرفر: $e");
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String notificationType = message.data['type']?.toString() ?? 'general';
      AndroidNotificationChannel targetChannel = _appointmentsChannel;

      if (notificationType == 'chat') {
        targetChannel = _chatChannel;
      }

      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            targetChannel.id,
            targetChannel.name,
            channelDescription: targetChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
            playSound: true,
          ),
        ),
        payload: notificationType,
      );
    }
  }

  static void _handleNotificationClick(String type) {
    log("🔀 جاري توجيه المستخدم بناءً على نوع الإشعار: $type");

    switch (type) {
      case 'appointment_accepted':
      case 'appointment_rejected':
      case 'appointment_reminder':
        Get.toNamed('/appointments');
        break;
      default:
        Get.toNamed('/home');
        break;
    }
  }
}
