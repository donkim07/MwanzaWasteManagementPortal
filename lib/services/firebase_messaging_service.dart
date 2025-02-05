
// Second file: services/firebase_messaging_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../screens/auth_users/admin/mwanza/waste_reportMap.dart';

class FirebaseMessagingService {
  final BuildContext context;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  FirebaseMessagingService(this.context);

  Future<void> initialize() async {
    // Request permission for notifications
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.payload != null) {
          // Navigate to waste reports map
          Navigator.pushNamed(
            context, 
            '/waste_reports_map',
            arguments: details.payload // This will be the reportId
          );
        }
      },
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['screen'] == WasteReportsMap) {
        Navigator.pushNamed(
          context, 
          '/waste_reports_map',
          arguments: message.data['reportId']
        );
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'waste_reports_channel',
      'Waste Reports',
      channelDescription: 'Notifications for new waste reports',
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: FilePathAndroidBitmap(message.notification?.android?.imageUrl ?? ''),
      styleInformation: BigPictureStyleInformation(
        FilePathAndroidBitmap(message.notification?.android?.imageUrl ?? ''),
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data['reportId'],
    );
  }

  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}