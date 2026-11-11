import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

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
      String? token = await messaging.getToken();
      debugPrint(' FCM Token: $token');
      
      if (token != null) {
        // �إرسال التوكن للسيرفر
        try {
          final response = await http.post(
            Uri.parse('https://2.tail7f4de4.ts.net:8443/api/update_fcm_token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': 1, // سيتم ربطه بمعرف المستخدم لاحقاً
              'fcm_token': token
            }),
          );
          debugPrint('✅ Server response: ${response.statusCode}');
        } catch (e) {
          debugPrint('❌ Error sending token to server: $e');
        }
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
  }
}
