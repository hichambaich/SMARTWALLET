import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    
    if (token != null) {
      try {
        // استخدام الـ IP المباشر
        final response = await http.post(
          Uri.parse('http://100.77.27.80:8553/api/update_fcm_token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': 556, 'fcm_token': token}),
        );
        
        _showDialog("نجاح! ✅", "تم إرسال التوكن.\nالرد: ${response.body}");
      } catch (e) {
        _showDialog("خطأ في الاتصال! ❌", "السبب: $e");
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
