import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:waste_manager/screens/ilemela/ilemela_map_page.dart';



import '../../../../widgets/custom_drawer.dart';
import '../../login_page.dart';
import 'admin_management.dart';
// import '../../../driver.dart';
import 'ilemela_agent.dart';
import 'ilemela_map_page.dart';
import 'ilemela_stakeholder_page.dart';
// import 'ilemela_waste_aggregators_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_points_page.dart';
import 'ilemela_waste_recyclersCollection_page.dart';
import 'ilemela_waste_recyclers_page.dart';
import 'ilemela_waste_reportMap.dart';
import 'ilemela_waste_reportingCollection.dart';

// class WHOWasteReport extends StatefulWidget {
//   final User? user;
//   final String? reportId; // Add this parameter

//   const WHOWasteReport({
//     Key? key, 
//     required this.user,
//     this.reportId, // Add this to constructor
//   }) : super(key: key);

//   static Route<void> route({User? user, String? reportId}) {
//     return MaterialPageRoute(
//       builder: (context) => WHOWasteReport(
//         user: user,
//         reportId: reportId,
//       ),
//     );
//   }

//   @override
//   _WHOWasteReportState createState() => _WHOWasteReportState();
// }
class WHOWasteReport extends StatefulWidget {
  final User? user;
  final String? reportId;

  const WHOWasteReport({
    Key? key, 
    required this.user,
    this.reportId,
  }) : super(key: key);

  static Route<void> route({User? user, String? reportId}) {
    return MaterialPageRoute(
      builder: (context) => WHOWasteReport(
        user: user,
        reportId: reportId,
      ),
    );
  }

  @override
  _WHOWasteReportState createState() => _WHOWasteReportState();
}

class _WHOWasteReportState extends State<WHOWasteReport> with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _mapController = MapController();

  String? _notificationReportId;
  String? _selectedReportId;
  bool _isLoading = true;
  int _selectedIndex = 9;
  bool _isAdmin = false;
  String _firstName = '';
  List<Marker> _markers = [];
  // Add these to your existing state variables
List<Marker> _driverMarkers = [];
StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
String? _selectedDriverId;

bool _showReminder = false;
List<QueryDocumentSnapshot> _pendingReminders = [];
StreamSubscription<QuerySnapshot>? _reminderListener;


String? _userWard;
String? _userDistrict;


StreamSubscription<QuerySnapshot>? _countListener;
int _reportCount = 0;


  bool _isAgent = false;
  bool _isWardOfficer= false;
  
  // Screen size utilities
  late double screenWidth;
  late double screenHeight;
  late double defaultPadding;
  late double smallPadding;
  late double cardPadding;
  late double headingSize;
  late double bodyTextSize;
  late double smallTextSize;

  // Theme colors
  static const primaryColor = Color(0xFF115937);
  static const gradientColors = [Color(0xFF1E3C2F), Color(0xFF115937)];

  // @override
  // void initState() {
  //   super.initState();
  // //   _initializeNotifications();
  // //   _setupNotificationListeners();
  // //   _loadReports();
  // //    _loadUserData();

  // //       // Check if opened from notification
  // //   _checkInitialNotification();
  // //   // Check for initial reportId from widget
  // //   if (widget.reportId != null) {
  // //     _notificationReportId = widget.reportId;
  // //   }
  // //   if (widget.reportId != null) {
  // //   WidgetsBinding.instance.addPostFrameCallback((_) {
  // //     _navigateToReport(widget.reportId!);
  // //   });
  // // }
  //      WidgetsBinding.instance.addObserver(this);
  //   _initializeApp();
  //    _startDriverTracking(); // Add this line
  //      _startCountListener(); // Add this line

  // }
// @override
// void initState() {
//   super.initState();
//   WidgetsBinding.instance.addObserver(this);
//   _initializeApp();
//   _startDriverTracking();
//   _startCountListener();
//   // Add this line to check reminders when app starts
//   if (_isWardOfficer) {
//     _checkPendingReminders();
//   }
// }

// Update initState to start the listener
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initializeApp();
  _startDriverTracking();
  _startCountListener();
  _startReminderListener(); // Add this line
}




// Future<void> _initializeApp() async {
//     await _initializeNotifications();
//     await _setupNotificationListeners();
//     await _loadUserData();
//     await _loadReports();
    
//     // Handle reportId from navigation arguments
//     if (widget.reportId != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         _handleReportId(widget.reportId!);
//       });
//     }
//   }
Future<void> _initializeApp() async {
  await _initializeNotifications();
  await _setupNotificationListeners();
  await _loadUserData(); // This will call _checkPendingReminders after setting _isWardOfficer
  await _loadReports();
  
  // Add this explicit check after everything is initialized
  if (_isWardOfficer && mounted) {
    print('Checking reminders after app initialization');
    await _checkPendingReminders();
  }
  
  if (widget.reportId != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReportId(widget.reportId!);
    });
  }
}
Future<void> _handleReportId(String reportId) async {
    try {
      // First load the report data
      final reportDoc = await _firestore
          .collection('wasteReports')
          .doc(reportId)
          .get();

      if (!reportDoc.exists) {
        print('Report not found: $reportId');
        return;
      }

      final data = reportDoc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>;
      final point = LatLng(
        location['latitude'] as double,
        location['longitude'] as double,
      );

      // Move map to location
      _mapController.move(point, 15.0);

      // Set selected report and show bottom sheet
      setState(() {
        _selectedReportId = reportId;
      });

      // Delay bottom sheet to allow map movement to complete
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _showReportDetailsBottomSheet(reportDoc);
      }
    } catch (e) {
      print('Error handling report ID: $e');
    }
  }


// @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // Refresh data when app is resumed
//       _loadReports();
//     }
//   }

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // Refresh data when app is resumed
    _loadReports();
    // Add this line to check reminders when app resumes
    if (_isWardOfficer) {
      _checkPendingReminders();
    }
  }
}


void _startReminderListener() {
  if (!_isWardOfficer || widget.user == null) return;

  _reminderListener = _firestore
      .collection('notifications')
      .where('userId', isEqualTo: widget.user!.uid)
      .where('type', isEqualTo: 'who_reminder')
      .where('read', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.docChanges.any((change) => change.type == DocumentChangeType.added)) {
          // Show reminder dialog for new notifications
          _showReminderDialog(snapshot.docs);
        }
      });
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    defaultPadding = screenWidth * 0.04;
    smallPadding = screenWidth * 0.02;
    cardPadding = screenWidth * 0.035;
    headingSize = screenWidth * 0.045;
    bodyTextSize = screenWidth * 0.032;
    smallTextSize = screenWidth * 0.028;
  }


  // Future<void> _checkInitialNotification() async {
  //   // Get any messages which caused the app to open
  //   RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  //   if (initialMessage != null) {
  //     _handleNotificationData(initialMessage.data);
  //   }
  // }
  // Update initial notification check
Future<void> _checkInitialNotification() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    if (_isWardOfficer) {
      final reportData = initialMessage.data;
      if (reportData['ward'] != _userWard || reportData['district'] != _userDistrict) {
        return; // Skip notifications for other wards
      }
    }
    _handleNotificationData(initialMessage.data);
  }
}


// Add this new function to check and show reminders
// Future<void> _checkPendingReminders() async {
//   if (!_isWardOfficer || widget.user == null) return;

//   try {
//     final reminders = await _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: widget.user!.uid)
//         .where('type', isEqualTo: 'who_reminder')
//         .where('read', isEqualTo: false)
//         .get();

//     if (reminders.docs.isNotEmpty) {
//       setState(() {
//         _pendingReminders = reminders.docs;
//         _showReminder = true;
//       });

//       // Show reminder dialog
//       if (mounted) {
//         _showReminderDialog();
//       }
//     }
//   } catch (e) {
//     print('Error checking reminders: $e');
//   }
// }
Future<void> _checkPendingReminders() async {
  print('Checking reminders for WHO: ${widget.user!.uid}');
  print('Is user WHO? $_isWardOfficer');
  
  if (widget.user == null) {
    print('No user found');
    return;
  }

  try {
    final reminders = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: widget.user!.uid)
        .where('type', isEqualTo: 'who_reminder')
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    print('Found ${reminders.docs.length} unread reminders'); // Debug print

    if (reminders.docs.isNotEmpty) {
      print('About to show dialog for ${reminders.docs.length} reminders'); // Debug print
      // Ensure we're on the main thread when showing the dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showReminderDialog(reminders.docs);
        }
      });
    } else {
      print('No unread reminders found');
    }
  } catch (e) {
    print('Error checking reminders: $e');
  }
}

void _showReminderDialog(List<QueryDocumentSnapshot> reminders) {
  print('Showing reminder dialog'); // Debug print
  if (!mounted) {
    print('Widget not mounted, cannot show dialog');
    return;
  }

  // Force run on main thread
  Future.microtask(() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('Building dialog widget'); // Debug print
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF115937).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFF115937),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'New Reports',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF115937),
                      child: Icon(Icons.warning_amber, color: Colors.white),
                    ),
                    title: Text(
                      reminder['title'] ?? 'New Report',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(reminder['body'] ?? ''),
                    onTap: () async {
                      await _firestore
                          .collection('notifications')
                          .doc(reminders[index].id)
                          .update({'read': true});
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      
                      if (reminder['reportId'] != null) {
                        _navigateToReport(reminder['reportId']);
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Mark all as read
                  for (var doc in reminders) {
                    await _firestore
                        .collection('notifications')
                        .doc(doc.id)
                        .update({'read': true});
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF115937),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep Unread',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => print('Dialog closed')); // Debug print
  });
}
// // Add this function to show the reminder dialog
// void _showReminderDialog() {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.amber[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.notifications_active,
//               color: Colors.amber,
//             ),
//           ),
//           const SizedBox(width: 10),
//           const Text('Pending Reports'),
//         ],
//       ),
//       content: SizedBox(
//         width: double.maxFinite,
//         child: ListView.builder(
//           shrinkWrap: true,
//           itemCount: _pendingReminders.length,
//           itemBuilder: (context, index) {
//             final reminder = _pendingReminders[index].data() as Map<String, dynamic>;
//             return ListTile(
//               leading: const Icon(Icons.warning_amber_rounded),
//               title: Text(reminder['title'] ?? 'New Report'),
//               subtitle: Text(reminder['body'] ?? ''),
//               onTap: () {
//                 // Navigate to the specific report
//                 if (reminder['reportId'] != null) {
//                   Navigator.pop(context);
//                   _navigateToReport(reminder['reportId']);
//                 }
//                 // Mark reminder as read
//                 _firestore
//                     .collection('notifications')
//                     .doc(_pendingReminders[index].id)
//                     .update({'read': true});
//               },
//             );
//           },
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Close'),
//         ),
//       ],
//     ),
//   );
// }
// @override
// void didChangeAppLifecycleState(AppLifecycleState state) {
//   if (state == AppLifecycleState.resumed) {
//     // Refresh data when app is resumed
//     _loadReports();
//     // Add this line to check reminders when app resumes
//     if (_isWardOfficer) {
//       _checkPendingReminders();
//     }
//   }
// }
// Future<void> _loadUserData() async {
//   try {
//     if (widget.user != null) {
//       final userDoc = await _firestore
//           .collection('users')
//           .doc(widget.user!.uid)
//           .get();
          
//       if (userDoc.exists && mounted) {
//         final userData = userDoc.data()!;
//         final userRole = userData['role'];
        
//         setState(() {
//           _firstName = userData['firstName'] ?? '';
//           _isAdmin = userRole == 'admin';
//           _isWardOfficer = userRole == 'ward health officer';
//           _isAgent = userRole == 'agent';
//           _userWard = userData['ward'];
//           _userDistrict = userData['district'];
//           _isLoading = false;
//         });
//       }
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading user data: $e')),
//       );
//     }
//   }
// }
Future<void> _loadUserData() async {
  try {
    if (widget.user != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.user!.uid)
          .get();
          
      if (userDoc.exists && mounted) {
        final userData = userDoc.data()!;
        final userRole = userData['role'];
        
        setState(() {
          _firstName = userData['firstName'] ?? '';
          _isAdmin = userRole == 'admin';
          _isWardOfficer = userRole == 'ward health officer';
          _isAgent = userRole == 'agent';
          _userWard = userData['ward'];
          _userDistrict = userData['district'];
          _isLoading = false;
        });

        // Add this - Check reminders after confirming user is WHO
        if (_isWardOfficer) {
          await _checkPendingReminders();
        }
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }
}



// Add this method
// void _startCountListener() {
//   _countListener?.cancel();
//   _countListener = _firestore
//       .collection('wasteReports')
//       .where('type', isEqualTo: 'waste report')
//       .where('status', isEqualTo: 'pending')
//       .snapshots()
//       .listen((snapshot) {
//         setState(() {
//           _reportCount = snapshot.docs.length;
//           print('Updated report count: $_reportCount'); // Debug print
//         });
//       });
// }
void _startCountListener() {
  _countListener?.cancel();

  try {
    Query countQuery = _firestore.collection('wasteReports')
        .where('status', isEqualTo: 'pending');

    if (_isWardOfficer && _userWard != null && _userDistrict != null) {
      // Filter by district first
      countQuery = countQuery.where('district', isEqualTo: _userDistrict);
      
      // Listen to the filtered query
      _countListener = countQuery.snapshots().listen((snapshot) {
        // Filter by ward in memory
        final wardReports = snapshot.docs.where(
          (doc) 
          // => doc.data()['ward'] == _userWard
            {
      final data = doc.data()as Map<String, dynamic>?;
      return data != null && data['ward'] == _userWard;
    },
        ).length;
        
        setState(() {
          _reportCount = wardReports;
          print('Updated report count for ward $_userWard: $_reportCount');
        });
      });
    } else {
      // For non-ward officers, count all pending reports
      _countListener = countQuery.snapshots().listen((snapshot) {
        setState(() {
          _reportCount = snapshot.docs.length;
          print('Updated total report count: $_reportCount');
        });
      });
    }
  } catch (e) {
    print('Error in count listener: $e');
  }
}






  Future<void> _initializeNotifications() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          final payloadData = Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              json.decode(details.payload!)
            )
          );
          _handleNotificationData(payloadData);
        }
      },
    );

    // Update FCM token for current user
    await _updateFCMToken();
  }
Future<void> _updateFCMToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && widget.user != null) {
        await _firestore
            .collection('users')
            .doc(widget.user!.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }


   void _handleNotificationData(Map<String, dynamic> data) {
    if (data['reportId'] != null) {
      setState(() {
        _notificationReportId = data['reportId'];
      });
      _navigateToReport(data['reportId']);
    }
  }


Future<void> _setupNotificationListeners() async {
  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // Check if the notification is for the ward health officer's assigned ward
    if (_isWardOfficer) {
      final reportData = message.data;
      if (reportData['ward'] != _userWard || reportData['district'] != _userDistrict) {
        return; // Skip notifications for other wards
      }
    }
    
    _showLocalNotification(message);
    _loadReports();
  });

  // Handle background/terminated messages when app is opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (_isWardOfficer) {
      final reportData = message.data;
      if (reportData['ward'] != _userWard || reportData['district'] != _userDistrict) {
        return; // Skip notifications for other wards
      }
    }
    _handleNotificationData(message.data);
  });
}

  
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'waste_reports_channel',
      'Waste Reports',
      channelDescription: 'Notifications for new waste reports',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigPictureStyleInformation(
        FilePathAndroidBitmap(await _downloadAndSaveImage(
          message.notification?.android?.imageUrl ?? message.data['imageUrl']
        )),
        largeIcon: FilePathAndroidBitmap(await _downloadAndSaveImage(
          message.notification?.android?.imageUrl ?? message.data['imageUrl']
        )),
      ),
    );

    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'New Waste Report',
      message.notification?.body ?? 'A new area needs attention',
      platformChannelSpecifics,
      payload: json.encode(message.data),
    );
  }

Future<String> _downloadAndSaveImage(String? imageUrl) async {
    if (imageUrl == null) return '';

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'notification_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = '${directory.path}/$fileName';

    final response = await http.get(Uri.parse(imageUrl));
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    return filePath;
  }
  

void _navigateToReport(String reportId) {
    setState(() => _selectedReportId = reportId);
    
    // Find the marker with this report ID
    final reportMarker = _markers.firstWhere(
      (marker) => marker.key == Key(reportId),
      orElse: () => _markers.first,
    );

    // Move map to the report location
    _mapController.move(reportMarker.point, 15.0);

    // Show report details after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final reportDoc = _firestore
            .collection('wasteReports')
            .doc(reportId)
            .get()
            .then((doc) {
              if (doc.exists) {
                _showReportDetailsBottomSheet(doc);
              }
            });
      }
    });
  }
 

Future<void> _loadReports() async {
  setState(() => _isLoading = true);
  try {
    Query reportsQuery = _firestore
        .collection('wasteReports')
        .where('status', isEqualTo: 'pending');

    // If user is a ward health officer, filter by their assigned ward
    if (_isWardOfficer && _userWard != null && _userDistrict != null) {
      reportsQuery = reportsQuery
          .where('ward', isEqualTo: _userWard);
    }

    final reports = await reportsQuery.get();
    print('Found ${reports.docs.length} reports');

    final newMarkers = reports.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      
      if (location == null) {
        print('Warning: No location data for report ${doc.id}');
        return null;
      }

      final latitude = location['latitude'];
      final longitude = location['longitude'];
      
      if (latitude == null || longitude == null) {
        print('Warning: Invalid coordinates for report ${doc.id}');
        return null;
      }

      return _createMarker(doc);
    }).where((marker) => marker != null).cast<Marker>().toList();

    setState(() {
      _markers = newMarkers;
      _isLoading = false;
    });

  } catch (e) {
    print('Error loading reports: $e');
    setState(() => _isLoading = false);
  }
}












// Add this method to start tracking drivers
// Update the _startDriverTracking method name and content:
void _startDriverTracking() {
  _driversStreamSubscription = _firestore
      .collection('agent_sessions') // Changed from 'driver_sessions'
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen((snapshot) {
    _updateDriverMarkers(snapshot.docs);
  });
}


// Update the _updateDriverMarkers method:
void _updateDriverMarkers(List<QueryDocumentSnapshot> agentDocs) async { // Changed parameter name
  List<Marker> newMarkers = [];

  for (var doc in agentDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final agentId = data['agentId'] as String; // Changed from 'driverId'
    final location = data['location'] as Map<String, dynamic>?;
    
    if (location != null) {
      final userDoc = await _firestore.collection('users').doc(agentId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        final point = LatLng(
          location['latitude'] as double,
          location['longitude'] as double,
        );

        newMarkers.add(
          Marker(
            key: Key('agent_$agentId'), // Changed from 'driver_'
            point: point,
            width: 60,
            height: 60,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('wasteReports')
                  .where('agentId', isEqualTo: agentId) // Changed from 'driverId'
                  .where('status', isEqualTo: 'picked')
                  .snapshots(),
              builder: (context, snapshot) {
                final activePickups = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return GestureDetector(
                  onTap: () => _showDriverDetails(
                    agentId, // Changed from driverId
                    userData,
                    data,
                    activePickups,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF115937),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person, // Changed from local_shipping
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      if (activePickups > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              activePickups.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  setState(() {
    _driverMarkers = newMarkers;
  });
}



void _showDriverDetails(
  String agentId,  // Changed from driverId
  Map<String, dynamic> userData,
  Map<String, dynamic> sessionData,
  int activePickups,
) {
  final dateId = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Agent Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF115937).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,  // Changed from person to reflect agent
                  color: Color(0xFF115937),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userData['firstName']} ${userData['lastName']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Agent ID: ${agentId.substring(0, 8)}',  // Changed from Driver ID
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator shows if they're actively working or paused
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('agent_sessions')  // Changed from driver_sessions
                    .where('agentId', isEqualTo: agentId)  // Changed from driverId
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final isWorking = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isWorking ? Colors.green : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isWorking ? 'Working' : 'Paused',
                      style: TextStyle(
                        color: isWorking ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Work Time Information
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('agent_work_days')  // Changed from driver_work_days
                .doc('${agentId}_$dateId')  // Changed from driverId
                .snapshots(),
            builder: (context, workDaySnapshot) {
              if (!workDaySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final workDayData = workDaySnapshot.data?.data() as Map<String, dynamic>?;
              if (workDayData == null) {
                return _buildStatCard(
                  'Work Status',
                  'Not Started Today',
                  Icons.access_time,
                );
              }

              final initialStartTime = (workDayData['initialStartTime'] as Timestamp).toDate();
              final totalWorkDuration = DateTime.now().difference(initialStartTime);
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Started At',
                          '${initialStartTime.hour.toString().padLeft(2, '0')}:${initialStartTime.minute.toString().padLeft(2, '0')}',
                          Icons.play_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Total Time',
                          '${totalWorkDuration.inHours}h ${totalWorkDuration.inMinutes.remainder(60)}m',
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Collections Information
          Row(
            children: [
              // Real-time active collections
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('wasteReports')
                      .where('agentId', isEqualTo: agentId)  // Changed from driverId
                      .where('status', isEqualTo: 'picked')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final activeCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatCard(
                      'Active Collections',  // Changed from Active Pickups
                      activeCount.toString(),
                      Icons.assignment,  // Changed from local_shipping
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Total collections for the day
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                    .collection('collectionLogs')  // Changed from pickupLogs
                    .where('agentId', isEqualTo: agentId)  // Changed from driverId
                    .where('sessionId', isEqualTo: sessionData['sessionId'])
                    .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildStatCard(
                        'Total Collections',  // Changed from Total Pickups
                        '...',
                        Icons.history,
                      );
                    }
                    
                    final totalCollections = snapshot.data!.docs.length;
                    return _buildStatCard(
                      'Total Collections',  // Changed from Total Pickups
                      totalCollections.toString(),
                      Icons.history,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatCard(String title, String value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF115937)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

















// Update the _showAssignDriverBottomSheet method to handle agents instead:
Future<void> _showAssignDriverBottomSheet(String reportId) async {
  try {
    // Change query to look for agents instead of drivers
    final driversSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'agent') // Changed from 'driver'
        .get();

    final today = DateTime.now();
    final dateId = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    // Update to use agent_sessions instead of driver_sessions
    final activeSessions = await _firestore
        .collection('agent_sessions') // Changed from 'driver_sessions'
        .where('isActive', isEqualTo: true)
        .where('dateId', isEqualTo: dateId)
        .get();

    final activeAgentIds = activeSessions.docs.map((doc) => doc.data()['agentId'] as String).toSet(); // Changed from 'driverId'

    final agents = driversSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': '${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? 'Agent'}', // Changed "Driver" to "Agent"
        'isActive': activeAgentIds.contains(doc.id),
      };
    }).toList();

    if (!mounted) return;

    String? selectedAgentId; // Changed from selectedDriverId

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
            ),
            child: Column(
              children: [
                // Handle bar remains the same
                Container(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                  width: screenWidth * 0.15,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Update header to reference agents
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: primaryColor,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Text(
                        'Assign Agent', // Changed from "Assign Driver"
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Update agent list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    itemCount: agents.length,
                    itemBuilder: (context, index) {
                      final agent = agents[index]; // Changed from driver
                      final isSelected = selectedAgentId == agent['id'];

                      return InkWell(
                        onTap: () {
                          setSheetState(() {
                            selectedAgentId = agent['id'] as String;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[50],
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: (agent['isActive'] as bool)
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: (agent['isActive'] as bool)
                                      ? Colors.green
                                      : Colors.grey,
                                  size: screenWidth * 0.05,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agent['name'] as String,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      (agent['isActive'] as bool)
                                          ? 'Currently Active'
                                          : 'Not Active',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: (agent['isActive'] as bool)
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: primaryColor,
                                  size: screenWidth * 0.06,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Update assignment button
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: ElevatedButton(
                    onPressed: selectedAgentId == null
                        ? null
                        : () async {
                            try {
                              final selectedAgent = agents.firstWhere(
                                (a) => a['id'] == selectedAgentId,
                              );

                              await _firestore
                                  .collection('wasteReports')
                                  .doc(reportId)
                                  .update({
                                'status': 'assigned',
                                'assignedAgent': selectedAgentId, // Changed from assignedDriver
                                'assignedAgentName': selectedAgent['name'], // Changed from assignedDriverName
                                'assignedAt': FieldValue.serverTimestamp(),
                                'assignedBy': widget.user?.uid,
                              });

                              Navigator.pop(context);
                              _loadReports();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Agent assigned successfully', // Changed from "Driver assigned successfully"
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error assigning agent: $e', // Changed from "Error assigning driver"
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: Size(double.infinity, screenHeight * 0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Assign Agent', // Changed from "Assign Driver"
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error loading agents: $e', // Changed from "Error loading drivers"
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}







Marker _createMarker(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  final location = data['location'] as Map<String, dynamic>?;
  print('Creating marker for report ${doc.id}');
  print('Location data: $location');

  // Default location if null (you can adjust these coordinates)
  const defaultLat = -2.5164;
  const defaultLng = 32.9016;

  // Safely get latitude and longitude with null checking
  final latitude = location?['latitude'];
  final longitude = location?['longitude'];

  print('Raw latitude: $latitude');
  print('Raw longitude: $longitude');

  // Convert to double, handling various data types
  double lat = defaultLat;
  double lng = defaultLng;

  if (latitude != null) {
    lat = (latitude is double) 
        ? latitude 
        : (latitude is int) 
            ? latitude.toDouble() 
            : double.tryParse(latitude.toString()) ?? defaultLat;
  }

  if (longitude != null) {
    lng = (longitude is double) 
        ? longitude 
        : (longitude is int) 
            ? longitude.toDouble() 
            : double.tryParse(longitude.toString()) ?? defaultLng;
  }

  print('Final latitude: $lat');
  print('Final longitude: $lng');

  final point = LatLng(lat, lng);

  return Marker(
    key: Key(doc.id),
    width: screenWidth * 0.08,
    height: screenWidth * 0.08,
    point: point,
    child: GestureDetector(
      onTap: () {
        setState(() {
          _selectedReportId = _selectedReportId == doc.id ? null : doc.id;
        });

        _mapController.move(point, 15.0);
        _showReportDetailsBottomSheet(doc);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_selectedReportId == doc.id)
            Positioned(
              bottom: screenHeight * 0.09,
              child: Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(232, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(1, 0, 0, 0).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data['district'] ?? 'Unknown District'} - ${data['ward'] ?? 'Unknown Ward'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Reported ${timeago.format((data['reportedAt'] as Timestamp).toDate())}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Image.asset(
            'assets/images/red_flag.png',
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
          ),
        ],
      ),
    ),
  );
}

void _showReportDetailsBottomSheet(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.05),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            width: screenWidth * 0.15,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: primaryColor,
                            size: screenWidth * 0.06,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waste Report Details',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Reported ${timeago.format(data['reportedAt'].toDate())}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image
                  if (data['imageUrl'] != null)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(data['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),

                  // Details
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      children: [
                        _buildDetailRow('Reporter', data['reporterName'], Icons.person_outline),
                        _buildDetailRow('District', data['district'], Icons.location_city),
                        _buildDetailRow('Ward', data['ward'], Icons.map_outlined),
                        _buildDetailRow('Street', data['street'], Icons.add_road),
                      ],
                    ),
                  ),

                     if (data['status'] == 'pending')
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAssignDriverBottomSheet(doc.id);
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Assign Agent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, screenHeight * 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
 

                  
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildDetailRow(String label, String value, IconData icon) {
  return Container(
    margin: EdgeInsets.only(bottom: screenHeight * 0.015),
    padding: EdgeInsets.all(screenWidth * 0.03),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: screenWidth * 0.05,
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: screenWidth * 0.035,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Future<void> _markAsSolved(String reportId) async {
    try {
      await _firestore.collection('wasteReports').doc(reportId).update({
        'status': 'solved',
        'solvedAt': FieldValue.serverTimestamp(),
        'solvedBy': widget.user?.uid,
      });

      setState(() {
        _markers.removeWhere((marker) => marker.key == Key(reportId));
        _selectedReportId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as solved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking report as solved: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final defaultPadding = screenWidth * 0.04;
  final smallPadding = screenWidth * 0.02;
  final headingSize = screenWidth * 0.045;
  final smallTextSize = screenWidth * 0.028;

  return Scaffold(
    backgroundColor: const Color(0xFF1E3C2F),
    drawer: CustomDrawer(
      firstName: _firstName,
      isAdmin: _isAdmin,
      isAgent: _isAgent,
      isWardOfficer: _isWardOfficer,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      user: widget.user,
    ),
    body: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFF1E3C2F),
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E3C2F),
                    Color(0xFF115937),
                  ],
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: const Color(0xFF115937)),
                          SizedBox(width: smallPadding),
                          Text(
                            'Map View',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: smallTextSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: smallPadding),
                  Container(
                    padding: EdgeInsets.all(smallPadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115937).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red[400],
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: smallPadding / 2),
                        // Text(
                        //   '${_markers.length}',
                        //   style: TextStyle(
                        //     color: const Color(0xFF115937),
                        //     fontWeight: FontWeight.bold,
                        //     fontSize: headingSize,
                        //   ),
                        // ),
                        Text(
  '$_reportCount',
  style: TextStyle(
    color: const Color(0xFF115937),
    fontWeight: FontWeight.bold,
    fontSize: headingSize,
  ),
),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          title: const Text(
            'Waste Reports Map',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
                  FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(-2.5164, 32.9016),
          initialZoom: 12.0,
          minZoom: 6.0,
          maxZoom: 18.0,
          onTap: (_, __) {
            // Clear selection when tapping on map
            setState(() {
              _selectedReportId = null;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
            retinaMode: MediaQuery.of(context).devicePixelRatio > 1.0,
          ),
          // MarkerLayer(markers: _markers),
            MarkerLayer(
            markers: [
              ..._markers,      // Waste report markers
              ..._driverMarkers // Driver markers
            ],
          ),
        ],
      ),

            // Map controls
            Positioned(
              right: defaultPadding,
              bottom: defaultPadding + MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                 
                  SizedBox(height: smallPadding),
                  FloatingActionButton.small(
                    onPressed: _getCurrentLocation,
                    heroTag: 'location',
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(defaultPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF115937),
                          ),
                          SizedBox(height: defaultPadding),
                          Text(
                            'Loading reports...',
                            style: TextStyle(fontSize: smallTextSize),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting current location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  


void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
  Navigator.of(context).pop();
  
  Widget page;
  switch (index) {
    case 0:
      page = ilemelaMapPage(user: widget.user);
      break;
    case 1:
      page = WastePointsListPage(user: widget.user);
      break;
    case 2:
      page = WasteDealersListPage(user: widget.user);
      break;
    case 4:
      page = WasteRecyclersListPage(user: widget.user);
      break;
     case 5:
      page = StakeholdersListPage(user: widget.user);
      break;
      case 7:
      page = WasteReportPage(user: widget.user);
      break;
      case 8:
      page = WasteReportsMap(user: widget.user, reportId: null,);
      break;
      case 9:
      page = WHOWasteReport(user: widget.user, reportId: null,);
      break;
      case 10:
      page = IlemelaAgentDashboardPage(user: widget.user);
      break;
      // case 9:
      // page = DriverDashboardPage(user: widget.user);
      // break;
    case 6:
      page = UsersManagementPage(user: widget.user);
      break;
    default:
      page = ilemelaMapPage(user: widget.user);
  }
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}


// @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _mapController.dispose();
//       _driversStreamSubscription?.cancel();
//     super.dispose();
//   }
// @override
// void dispose() {
//   WidgetsBinding.instance.removeObserver(this);
//   _mapController.dispose();
//   _driversStreamSubscription?.cancel();
//   _countListener?.cancel(); // Add this line
//   super.dispose();
// }
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _mapController.dispose();
  _driversStreamSubscription?.cancel();
  _countListener?.cancel();
  _reminderListener?.cancel(); // Add this line
  super.dispose();
}
}
