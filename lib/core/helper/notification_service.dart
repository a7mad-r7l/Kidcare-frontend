import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:kidcare/core/helper/secure_storage_service.dart';

import '../constants.dart';

import '../../controllers/home/home_controller.dart';
import '../../controllers/home/appointments_controller.dart';

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
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().hasUnreadNotifications.value = true;
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("🖱️ تم النقر على الإشعار والتطبيق بالخلفية: ${message.data}");

      String type = message.data['type']?.toString() ?? 'general';
      if (type == 'general' && message.notification?.title != null) {
        type = message.notification!.title!.toLowerCase();
      }
      _handleNotificationClick(type);
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log("🚀 إقلاع التطبيق من الصفر بنقرة إشعار: ${initialMessage.data}");

      String type = initialMessage.data['type']?.toString() ?? 'general';
      if (type == 'general' && initialMessage.notification?.title != null) {
        type = initialMessage.notification!.title!.toLowerCase();
      }
      _handleNotificationClick(type);
    }

    await uploadFcmToken();
  }

  static Future<void> uploadFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        log("🔑 🔑 🔑 MY DEVICE FCM TOKEN = $token");
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

      if (notificationType == 'general') {
        notificationType = notification.title?.toLowerCase() ?? 'general';
      }

      AndroidNotificationChannel targetChannel = _appointmentsChannel;

      if (notificationType.contains('chat')) {
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

  // ─── توجيه الإشعارات ───
  static void _handleNotificationClick(String type) {
    log("🔀 جاري توجيه المريض بناءً على نوع الإشعار: $type");

    final typeLower = type.toLowerCase();

    // 1. إشعارات اللقاحات
    if (typeLower.contains('vaccine')) {
      Get.offAllNamed('/home');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().onVaccinesTabTapped();
        }
      });
      return;
    }

    // 2. إشعارات إلغاء الموعد -> المواعيد السابقة
    if (typeLower.contains('cancel')) {
      Get.delete<AppointmentsController>();
      Get.toNamed('/appointments');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<AppointmentsController>()) {
          Get.find<AppointmentsController>().switchTab(false); // تاب Past
        }
      });
      return;
    }

    // 3. إشعارات الحجز والتذكير والتأكيد -> المواعيد القادمة
    if (typeLower.contains('appointment') ||
        typeLower.contains('reminder') ||
        typeLower.contains('confirm') ||
        typeLower.contains('accept')) {
      Get.delete<AppointmentsController>();
      Get.toNamed('/appointments');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<AppointmentsController>()) {
          Get.find<AppointmentsController>().switchTab(true); // تاب Upcoming
        }
      });
      return;
    }

    Get.toNamed('/home');
  }
}
