
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
        await http.post(
          Uri.parse('http://100.77.27.80:8553/api/update_fcm_token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': 556, 'fcm_token': token}),
        );
        debugPrint("Token sent successfully to server.");
      } catch (e) {
        debugPrint("Error sending token: $e");
      }
    }
  }
}
