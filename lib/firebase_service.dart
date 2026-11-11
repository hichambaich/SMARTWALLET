import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      
      if (token != null) {
        try {
          final response = await http.post(
            Uri.parse('http://:8553/api/update_fcm_token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': 556, // تثبيت رقم حسابك للتجربة
              'fcm_token': token
            }),
          );
          
          // عرض النتيجة على الشاشة
          _showDialog("نجاح! ✅", "تم إرسال التوكن للسيرفر.\nالرد: ${response.body}");
          
        } catch (e) {
          // عرض الخطأ على الشاشة
          _showDialog("خطأ في الاتصال! ❌", "لم يتم إرسال التوكن.\nالسبب: $e");
        }
      }
    }
  }

  static void _showDialog(String title, String content) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("حسناً"))],
          ),
        );
      }
    });
  }
}

// مفتاح التنقل لعرض النافذة
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
