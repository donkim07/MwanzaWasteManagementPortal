import 'dart:convert';
import 'dart:io';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth_users/admin/ilemela/ilemela_map_page.dart';
import 'screens/auth_users/admin/mwanza/map_page.dart';
import 'screens/ilemela/driver.dart';
import 'screens/auth_users/admin/mwanza/waste_reportMap.dart';
import 'screens/auth_users/city_selection_page.dart';
import 'screens/city_selection_page.dart';
import 'firebase_options.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();

// Notification Service

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> handleNotification(RemoteMessage message) async {
    try {
      if (message.data['screen'] == 'WasteReportsMap') {
        final reportId = message.data['reportId'];
        if (reportId != null && navigatorKey.currentState != null) {
          // Add delay to ensure Firebase is initialized
          await Future.delayed(const Duration(milliseconds: 500));
          
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => WasteReportsMap(
                user: FirebaseAuth.instance.currentUser,
                reportId: reportId,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  Future<void> initialize() async {
    // Request permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_updateUserFCMToken);

    // Set up notification channels for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'waste_reports_channel',
        'Waste Reports',
        description: 'Notifications for new waste reports',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Initialize local notifications
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          await handleNotification(RemoteMessage(data: data));
        }
      },
    );

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message
    FirebaseMessaging.onMessageOpenedApp.listen(handleNotification);
    
    // Check for initial message
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await handleNotification(initialMessage);
    }
  }

  Future<void> _updateUserFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
    }
  }

Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message in foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      // Show the notification
      await flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'waste_reports_channel',
            'Waste Reports',
            channelDescription: 'Notifications for new waste reports',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      // If the app is in foreground, optionally handle the navigation directly
      if (message.data['screen'] == 'WasteReportsMap' && 
          message.data['reportId'] != null) {
        await handleNotification(message);
      }
    }
  }
}


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().handleNotification(message);
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

    // Initialize Firebase App Check with Play Integrity
  await FirebaseAppCheck.instance.activate(
    // Use Play Integrity provider instead of the deprecated SafetyNet
    androidProvider: AndroidProvider.playIntegrity,
    // For iOS, use DeviceCheck or AppAttest depending on iOS version
    // appleProvider: AppleProvider.deviceCheck,
  );


  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Analytics
  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  
  // Log app open event
  await analytics.logAppOpen();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(MyApp(analytics: analytics));
}



class MyApp extends StatelessWidget {
  final FirebaseAnalytics analytics;
  
  const MyApp({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Waste Management App',
      debugShowCheckedModeBanner: false,
      
      // Add Firebase Analytics Observer
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const AuthenticationWrapper(),
      onGenerateRoute: (settings) {
        // Track screen views for routes
        if (settings.name != null) {
          analytics.logScreenView(screenName: settings.name);
        }
        
        if (settings.name == '/waste_reports_map') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => WasteReportsMap(
              user: FirebaseAuth.instance.currentUser,
              reportId: args?['reportId'] as String?,
            ),
          );
        }
        return null;
      },
    );
  }
}



class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}









// Update the loading screen to use AnimationController
class WasteManagementLoadingScreen extends StatefulWidget {
  const WasteManagementLoadingScreen({super.key});

  @override
  State<WasteManagementLoadingScreen> createState() => _WasteManagementLoadingScreenState();
}

class _WasteManagementLoadingScreenState extends State<WasteManagementLoadingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C2F), // Dark forest green
              Color(0xFF115937), // Primary green
              Color(0xFF0D7A4F), // Rich emerald
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated recycle icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: const Icon(
                      Icons.recycling,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Loading text
              const Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Custom loading indicator
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Positioned(
                              left: constraints.maxWidth * (_controller.value - 0.3),
                              child: Container(
                                width: constraints.maxWidth * 0.3,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
 
Future<Widget> _getLandingPage(User user) async {
  // Log user login
  await FirebaseAnalytics.instance.logEvent(
    name: 'user_login',
    parameters: {
      'user_id': user.uid,
      'login_time': DateTime.now().toString(),
    },
  );

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (userDoc.exists) {
    final userData = userDoc.data();
    final String role = (userData?['role'] ?? '').toString().toLowerCase();
    final String district = (userData?['district'] ?? '').toString();
    final String ward = (userData?['ward'] ?? '').toString();

    // Update user's last login
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
          'lastLogin': FieldValue.serverTimestamp(),
          'lastLoginDevice': Platform.operatingSystem,
        });

    // Admin routing
    if (role == 'admin') {
      await FirebaseMessaging.instance.subscribeToTopic('admin_notifications');
      return CitySelectionPageUsers(user: user);
    }
    
    // Driver routing
    if (role == 'driver') {
      return DriverDashboardPage(user: user);
    }
    
    // Employee, Agent, and Ward Health Officer routing
    if (role == 'employee' || role == 'agent' || role == 'ward health officer') {
      // Verify district is set
      if (district.isEmpty) {
        print('Warning: District not set for user ${user.uid}');
        return CitySelectionPageUsers(user: user);
      }

      // Subscribe to district notifications
      await FirebaseMessaging.instance.subscribeToTopic(district.toLowerCase().replaceAll(' ', '_'));
      
      // For Ward Health Officer, subscribe to ward notifications
      if (role == 'ward health officer' && ward.isNotEmpty) {
        await FirebaseMessaging.instance.subscribeToTopic(ward.toLowerCase().replaceAll(' ', '_'));
      }

      // Route based on district
      if (district.toLowerCase().contains('mwanza')) {
        return MapPage(user: user);
      } else if (district.toLowerCase().contains('ilemela')) {
        return ilemelaMapPage(user: user);
      }
    }
  }

  // Default fallback
  return const CitySelectionPage();
}


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WasteManagementLoadingScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Widget>(
            future: _getLandingPage(snapshot.data!),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return const WasteManagementLoadingScreen();
              }
              return futureSnapshot.data ?? const CitySelectionPage();
            },
          );
        }
        
        return const CitySelectionPage();
      },
    );
  }
}