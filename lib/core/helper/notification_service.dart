import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../helper/secure_storage_service.dart';
import '../constants.dart';

// 🌟 1.  الخلفية ( Top Level Function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //  تهيئة فايربيس ً لأن التطبيق (Terminated)
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1.  الاستماع في الخلفية (Background & Terminated)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. طلب الصلاحيات من المستخدم
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('🔔 Notification permission granted.');

      // رفع التوكن الحالي
      await uploadFcmToken();

      //  3. تحديث التوكن التلقائي
      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM Token Refreshed: $newToken');
        await uploadFcmToken(forcedToken: newToken);
      });
    }

    // 4. حالة الـ Foreground (التطبيق مفتوح )
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Got a message while in the foreground!');
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Notification'.tr,
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    });

    // 5. حالة الـ Background (التطبيق في الخلفية )
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔓 Notification clicked! Opened app from background.');
      _handleNotificationClick(message);
    });

    //  6. حالة الـ Terminated (التطبيق كان مغلقاً تماماً )
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🚀 App launched from terminated state via notification.');
      _handleNotificationClick(initialMessage);
    }
  }

  //  توجيه المستخدم عند الضغط على الإشعار
  static void _handleNotificationClick(RemoteMessage message) {
    // يمكنك لاحقاً قراءة message.data لتوجيه المستخدم لشاشة معينة
    // حالياً سنوجهه لشاشة المواعيد كافتراضي
    Get.toNamed('/appointments');
  }

  //  رفع التوكن للباك إند
  static Future<void> uploadFcmToken({String? forcedToken}) async {
    try {
      String? fcmToken = forcedToken ?? await _messaging.getToken();
      debugPrint('🔑 🔑 🔑 MY DEVICE FCM TOKEN = $fcmToken');
      if (fcmToken == null) return;

      String userToken = await SecureStorage.getToken();
      if (userToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/user/update-fcm-token'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $userToken',
          'Accept-Language': Get.locale?.languageCode ?? 'en',
        },
        body: {
          'fcm_token': fcmToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM Token synced with Laravel successfully.');
      } else {
        debugPrint('⚠️ Failed to sync FCM Token: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error syncing FCM Token: $e');
    }
  }
}