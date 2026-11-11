import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    // تهيئة Firebase
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // طلب إذن الإشعارات (ضروري جداً لأندرويد 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // الحصول على الـ Token الخاص بالهاتف
      String? token = await messaging.getToken();
      debugPrint(' FCM Token: $token'); 
      
      // �ملاحظة: لاحقاً سنقوم بإرسال هذا الـ Token إلى الباك إند (Python) لحفظه
    }

    // الاستماع للإشعارات أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }
}
