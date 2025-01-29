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



import '../../../../widgets/custom_drawer.dart';
import '../../login_page.dart';
import 'WHO_waste_reportMap.dart';
import 'admin_management.dart';
// import '../../../driver.dart';
import 'agent.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
import 'waste_aggregators_page.dart';
import 'waste_dealers_page.dart';
import 'waste_points_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_reportMap.dart';
import 'waste_reportingCollection.dart';
// class WasteReportsMap extends StatefulWidget {
//   final User? user;
//   final String? reportId; // Add this parameter

//   const WasteReportsMap({
//     Key? key, 
//     required this.user,
//     this.reportId, // Add this to constructor
//   }) : super(key: key);

//   static Route<void> route({User? user, String? reportId}) {
//     return MaterialPageRoute(
//       builder: (context) => WasteReportsMap(
//         user: user,
//         reportId: reportId,
//       ),
//     );
//   }

//   @override
//   _WasteReportsMapState createState() => _WasteReportsMapState();
// }
class WasteReportsMap extends StatefulWidget {
  final User? user;
  final String? reportId;

  const WasteReportsMap({
    Key? key, 
    required this.user,
    this.reportId,
  }) : super(key: key);

  static Route<void> route({User? user, String? reportId}) {
    return MaterialPageRoute(
      builder: (context) => WasteReportsMap(
        user: user,
        reportId: reportId,
      ),
    );
  }

  @override
  _WasteReportsMapState createState() => _WasteReportsMapState();
}

class _WasteReportsMapState extends State<WasteReportsMap> with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _mapController = MapController();
  bool _showListView = false;
  List<DocumentSnapshot> _documents = [];




  String? _notificationReportId;
  String? _selectedReportId;
  bool _isLoading = true;
  int _selectedIndex = 8;
  bool _isAdmin = false;
  String _firstName = '';
  List<Marker> _markers = [];
  // Add these to your existing state variables
List<Marker> _driverMarkers = [];
StreamSubscription<QuerySnapshot>? _driversStreamSubscription;
String? _selectedDriverId;
  bool _isAgent = false;
  bool _isWardOfficer= false;



StreamSubscription<QuerySnapshot>? _countListener;
int _reportCount = 0;



  
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

  @override
  void initState() {
    super.initState();
  //   _initializeNotifications();
  //   _setupNotificationListeners();
  //   _loadReports();
  //    _loadUserData();

  //       // Check if opened from notification
  //   _checkInitialNotification();
  //   // Check for initial reportId from widget
  //   if (widget.reportId != null) {
  //     _notificationReportId = widget.reportId;
  //   }
  //   if (widget.reportId != null) {
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _navigateToReport(widget.reportId!);
  //   });
  // }
       WidgetsBinding.instance.addObserver(this);
    _initializeApp();
     _startDriverTracking(); // Add this line
       _startCountListener(); // Add this line

  }





Future<void> _initializeApp() async {
    await _initializeNotifications();
    await _setupNotificationListeners();
    await _loadUserData();
    await _loadReports();
    
    // Handle reportId from navigation arguments
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


@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _loadReports();
    }
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


  Future<void> _checkInitialNotification() async {
    // Get any messages which caused the app to open
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleNotificationData(initialMessage.data);
    }
  }
   Future<void> _loadUserData() async {
  try {
    if (widget.user != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.user!.uid)
          .get();
      if (userDoc.exists && mounted) {
        final userRole = userDoc.data()?['role'];
        setState(() {
          _firstName = userDoc.data()?['firstName'] ?? '';
          _isAdmin = userRole == 'admin';
          _isWardOfficer = userRole == 'ward health officer';
          _isAgent = userRole == 'agent';
          _isLoading = false;
        });
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
void _startCountListener() {
  _countListener?.cancel();
  _countListener = _firestore
      .collection('wasteReports')
      .where('type', isEqualTo: 'waste report')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snapshot) {
        setState(() {
          _reportCount = snapshot.docs.length;
          print('Updated report count: $_reportCount'); // Debug print
        });
      });
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


Future<void> _setupNotificationListeners() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      // Optionally refresh the reports list
      _loadReports();
    });

    // Handle background/terminated messages when app is opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });
  }
   void _handleNotificationData(Map<String, dynamic> data) {
    if (data['reportId'] != null) {
      setState(() {
        _notificationReportId = data['reportId'];
      });
      _navigateToReport(data['reportId']);
    }
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
    final reports = await _firestore
        .collection('wasteReports')
        .where('type', isEqualTo: 'waste report') 
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      _documents = reports.docs;
      _markers = reports.docs.map((doc) => _createMarker(doc)).toList();
      _isLoading = false;
    });

    if (_notificationReportId != null) {
      _navigateToReport(_notificationReportId!);
      _notificationReportId = null;
    }
  } catch (e) {
    print('Error loading reports: $e');
    setState(() => _isLoading = false);
  }
}













// Add this method to start tracking drivers
void _startDriverTracking() {
  _driversStreamSubscription = _firestore
      .collection('driver_sessions')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .listen((snapshot) {
    _updateDriverMarkers(snapshot.docs);
  });
}

void _updateDriverMarkers(List<QueryDocumentSnapshot> driverDocs) async {
  List<Marker> newMarkers = [];

  for (var doc in driverDocs) {
    final data = doc.data() as Map<String, dynamic>;
    final driverId = data['driverId'] as String;
    final location = data['location'] as Map<String, dynamic>?;
    
    if (location != null) {
      // Get driver's user data
      final userDoc = await _firestore.collection('users').doc(driverId).get();
      final userData = userDoc.data();
      
      if (userData != null) {
        final point = LatLng(
          location['latitude'] as double,
          location['longitude'] as double,
        );

        newMarkers.add(
          Marker(
            key: Key('driver_$driverId'),
            point: point,
            width: 60,
            height: 60,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('wasteReports')
                  .where('driverId', isEqualTo: driverId)
                  .where('status', isEqualTo: 'picked')
                  .snapshots(),
              builder: (context, snapshot) {
                final activePickups = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return GestureDetector(
                  onTap: () => _showDriverDetails(
                    driverId,
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
                          Icons.local_shipping,
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
                            // decoration: const BoxDecoration(
                            //   color: Colors.green,
                            //   shape: BoxShape.circle,
                            // ),
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
  String driverId,
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
          // Driver Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF115937).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
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
                      'Driver ID: ${driverId.substring(0, 8)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Status indicator now shows if they're actively working or paused
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('driver_sessions')
                    .where('driverId', isEqualTo: driverId)
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
                .collection('driver_work_days')
                .doc('${driverId}_$dateId')
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
          
          // Pickups Information
          Row(
            children: [
              // Real-time active pickups
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('wasteReports')
                      .where('driverId', isEqualTo: driverId)
                      .where('status', isEqualTo: 'picked')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final activeCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return _buildStatCard(
                      'Active Pickups',
                      activeCount.toString(),
                      Icons.local_shipping,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Total pickups for the day
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                  .collection('pickupLogs')
                  .where('driverId', isEqualTo: driverId)
                  .where('sessionId', isEqualTo: sessionData['sessionId'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return _buildStatCard(
                        'Total Pickups',
                        '...',
                        Icons.history,
                      );
                    }
                    
                    final totalPickups = snapshot.data!.docs.length;
                    return _buildStatCard(
                      'Total Pickups',
                      totalPickups.toString(),
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


















Future<void> _showAssignDriverBottomSheet(String reportId) async {
  try {
    final driversSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();

    final today = DateTime.now();
    final dateId = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    final activeSessions = await _firestore
        .collection('driver_sessions')
        .where('isActive', isEqualTo: true)
        .where('dateId', isEqualTo: dateId)
        .get();

    final activeDriverIds = activeSessions.docs.map((doc) => doc.data()['driverId'] as String).toSet();

    final drivers = driversSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': '${data['firstName'] ?? 'Unknown'} ${data['lastName'] ?? 'Driver'}',
        'isActive': activeDriverIds.contains(doc.id),
      };
    }).toList();

    if (!mounted) return;

    String? selectedDriverId; // Moved outside StatefulBuilder

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) { // Renamed setState to setSheetState for clarity
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
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

                // Header
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
                        'Assign Driver',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Driver List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final isSelected = selectedDriverId == driver['id'];

                      return InkWell( // Changed to InkWell for better touch feedback
                        onTap: () {
                          setSheetState(() { // Use setSheetState instead of setState
                            selectedDriverId = driver['id'] as String;
                            print('Selected driver: ${driver['name']}'); // Debug print
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
                                  color: (driver['isActive'] as bool)
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: (driver['isActive'] as bool)
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
                                      driver['name'] as String,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      (driver['isActive'] as bool)
                                          ? 'Currently Active'
                                          : 'Not Active',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: (driver['isActive'] as bool)
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

                // Assign Button
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: ElevatedButton(
                    // Inside the onPressed of the Assign Button, replace the success case with this:
onPressed: selectedDriverId == null
    ? null
    : () async {
        try {
          final selectedDriver = drivers.firstWhere(
            (d) => d['id'] == selectedDriverId,
          );

          await _firestore
              .collection('wasteReports')
              .doc(reportId)
              .update({
            'newStatus': 'assigned',
            'assignedDriver': selectedDriverId,
            'assignedDriverName': selectedDriver['name'],
            'assignedAt': FieldValue.serverTimestamp(),
            'assignedBy': widget.user?.uid,
          });

          // Close only the assign driver bottom sheet
          Navigator.pop(context);
          
          // Refresh the markers
          _loadReports();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Driver assigned successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error assigning driver: $e',
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
                      'Assign Driver',
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
          'Error loading drivers: $e',
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
  print('Creating marker for location: $location');

  // Default location if null (you can adjust these coordinates as needed)
  const defaultLat = -2.5164;
  const defaultLng = 32.9016;

  // Safely get latitude and longitude with null checking
  final latitude = location?['latitude'];
  final longitude = location?['longitude'];

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

// void _showReportDetailsBottomSheet(DocumentSnapshot doc) {
//   final data = doc.data() as Map<String, dynamic>;
  
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => Container(
//       height: MediaQuery.of(context).size.height * 0.85,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(screenWidth * 0.05),
//         ),
//       ),
//       child: Column(
//         children: [
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
                          label: const Text('Assign Driver'),
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
 

                  // Action Button
                  // Padding(
                  //   padding: EdgeInsets.all(screenWidth * 0.04),
                  //   child: ElevatedButton.icon(
                  //     onPressed: () {
                  //       Navigator.pop(context);
                  //       _markAsSolved(doc.id);
                  //     },
                  //     icon: const Icon(Icons.check),
                  //     label: const Text('Mark as Solved'),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.green,
                  //       foregroundColor: Colors.white,
                  //       minimumSize: Size(double.infinity, screenHeight * 0.06),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),

          if (data['status'] == 'pending')
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRemindWHOBottomSheet(context, doc.id);
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Remind Ward Health Officer'),
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
                          Icon(
                            _showListView ? Icons.list : Icons.location_on,
                            color: Color(0xFF115937)
                          ),
                          SizedBox(width: smallPadding),
                          Text(
                            _showListView ? 'List View' : 'Map View',
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
                        Text(
                          '${_markers.length}',
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
            'Waste Reports',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Toggle view button
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _showListView ? Icons.map : Icons.list,
                  color: Colors.white,
                ),
              ),
              onPressed: () => setState(() => _showListView = !_showListView),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
      body: Container(
        color: Colors.white,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _showListView
                ? WasteReportsList(
                    reports: _documents,
                    user: widget.user,
                    onReportTap: (doc) => _showReportDetailsBottomSheet(doc),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(-2.5164, 32.9016),
                          initialZoom: 12.0,
                          minZoom: 6.0,
                          maxZoom: 18.0,
                          onTap: (_, __) {
                            setState(() => _selectedReportId = null);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                              ..._markers,
                              ..._driverMarkers
                            ],
                          ),
                        ],
                      ),
                      // Other existing map controls...
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









// Add the WHO reminder bottom sheet method

// void _showRemindWHOBottomSheet(BuildContext context, String reportId) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (context) => Container(
//       height: MediaQuery.of(context).size.height * 0.7,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(
//           top: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         children: [
//           Container(
//             margin: const EdgeInsets.symmetric(vertical: 15),
//             width: 60,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
          
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF115937).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Icon(
//                     Icons.notifications_active,
//                     color: Color(0xFF115937),
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Remind Ward Health Officer',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               // Changed query to show all WHOs
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .where('role', isEqualTo: 'ward health officer')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 final officers = snapshot.data!.docs;
                
//                 if (officers.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.person_off,
//                           size: 64,
//                           color: Colors.grey[400],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No Ward Health Officers found',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 // Stream to get active sessions
//                 return StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('who_sessions')
//                       .where('isActive', isEqualTo: true)
//                       .snapshots(),
//                   builder: (context, sessionSnapshot) {
//                     // Get active WHO IDs
//                     final activeWHOIds = sessionSnapshot.hasData
//                         ? sessionSnapshot.data!.docs
//                             .map((doc) => doc['whoId'] as String)
//                             .toSet()
//                         : <String>{};

//                     return ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: officers.length,
//                       itemBuilder: (context, index) {
//                         final officer = officers[index].data() as Map<String, dynamic>;
//                         final officerId = officers[index].id;
//                         final isActive = activeWHOIds.contains(officerId);
                        
//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             side: BorderSide(
//                               color: Colors.grey.shade200,
//                             ),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               children: [
//                                 Stack(
//                                   children: [
//                                     Container(
//                                       width: 50,
//                                       height: 50,
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFF115937).withOpacity(0.1),
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(
//                                         Icons.person,
//                                         color: Color(0xFF115937),
//                                       ),
//                                     ),
//                                     // Active status indicator
//                                     Positioned(
//                                       right: 0,
//                                       bottom: 0,
//                                       child: Container(
//                                         width: 14,
//                                         height: 14,
//                                         decoration: BoxDecoration(
//                                           color: isActive ? Colors.green : Colors.grey,
//                                           shape: BoxShape.circle,
//                                           border: Border.all(
//                                             color: Colors.white,
//                                             width: 2,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         '${officer['firstName']} ${officer['lastName']}',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Row(
//                                         children: [
//                                           Icon(
//                                             Icons.location_on,
//                                             size: 14,
//                                             color: Colors.grey[600],
//                                           ),
//                                           const SizedBox(width: 4),
//                                           Text(
//                                             officer['ward'] ?? 'No ward assigned',
//                                             style: TextStyle(
//                                               color: Colors.grey[600],
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 8,
//                                               vertical: 2,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: isActive
//                                                   ? Colors.green.withOpacity(0.1)
//                                                   : Colors.grey.withOpacity(0.1),
//                                               borderRadius: BorderRadius.circular(12),
//                                             ),
//                                             child: Text(
//                                               isActive ? 'Active' : 'Offline',
//                                               style: TextStyle(
//                                                 color: isActive ? Colors.green : Colors.grey,
//                                                 fontSize: 12,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 ElevatedButton(
//                                   onPressed: () => _sendWHOReminder(
//                                     context,
//                                     officers[index].id,
//                                     reportId,
//                                   ),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF115937),
//                                     foregroundColor: Colors.white,
//                                     elevation: 0,
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 12,
//                                     ),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: const [
//                                       Icon(Icons.notifications_active, size: 18),
//                                       SizedBox(width: 8),
//                                       Text('Remind'),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }



void _showRemindWHOBottomSheet(BuildContext context, String reportId) {
  // Get screen dimensions
  final screenSize = MediaQuery.of(context).size;
  final screenWidth = screenSize.width;
  final screenHeight = screenSize.height;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
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
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: const Color(0xFF115937).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: const Color(0xFF115937),
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    'Remind Ward Health Officer',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Officers List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'ward health officer')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final officers = snapshot.data!.docs;
                
                if (officers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: screenWidth * 0.15,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'No Ward Health Officers found',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('who_sessions')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, sessionSnapshot) {
                    final activeWHOIds = sessionSnapshot.hasData
                        ? sessionSnapshot.data!.docs
                            .map((doc) => doc['whoId'] as String)
                            .toSet()
                        : <String>{};

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      itemCount: officers.length,
                      itemBuilder: (context, index) {
                        final officer = officers[index].data() as Map<String, dynamic>;
                        final officerId = officers[index].id;
                        final isActive = activeWHOIds.contains(officerId);
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Row(
                              children: [
                                // Profile icon with status
                                SizedBox(
                                  width: screenWidth * 0.12,
                                  height: screenWidth * 0.12,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF115937).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          color: const Color(0xFF115937),
                                          size: screenWidth * 0.06,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: screenWidth * 0.03,
                                          height: screenWidth * 0.03,
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                
                                // Officer details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${officer['firstName']} ${officer['lastName']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.04,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: screenHeight * 0.005),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: screenWidth * 0.035,
                                            color: Colors.grey[600],
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Expanded(
                                            child: Text(
                                              officer['ward'] ?? 'No ward assigned',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: screenWidth * 0.035,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Status and Remind button
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenHeight * 0.004,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Offline',
                                        style: TextStyle(
                                          color: isActive ? Colors.green : Colors.grey,
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    SizedBox(
                                      height: screenHeight * 0.04,
                                      child: ElevatedButton(
                                        onPressed: () => _sendWHOReminder(
                                          context,
                                          officers[index].id,
                                          reportId,
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF115937),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.03,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.notifications_active,
                                              size: screenWidth * 0.04,
                                              color: const Color.fromARGB(255, 186, 198, 192),

                                            ),
                                            SizedBox(width: screenWidth * 0.01),
                                            Text(
                                              'Remind',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.035,
                                                color: const Color.fromARGB(255, 223, 227, 225),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}



// Add the method to send reminders
Future<void> _sendWHOReminder(BuildContext context, String whoId, String reportId) async {
  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Get WHO's FCM token
    final whoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(whoId)
        .get();
    
    final fcmToken = whoDoc.data()?['fcmToken'];
    
    if (fcmToken != null) {
      // Create a notification record
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'userId': whoId,
        'reportId': reportId,
        'type': 'who_reminder',
        'title': 'New Waste Report Reminder',
        'body': 'You have a pending waste report that needs attention',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update the report
      await FirebaseFirestore.instance
          .collection('wasteReports')
          .doc(reportId)
          .update({
        'whoReminded': true,
        'whoRemindedAt': FieldValue.serverTimestamp(),
        'whoId': whoId,
      });

      // Close loading indicator and bottom sheet
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close bottom sheet

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // Close loading indicator
    Navigator.pop(context);
    
    print('Error sending reminder: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sending reminder: $e'),
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
      page = MapPage(user: widget.user);
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
      page = AgentDashboardPage(user: widget.user);
      break;
      // case 9:
      // page = DriverDashboardPage(user: widget.user);
      // break;
    case 6:
      page = UsersManagementPage(user: widget.user);
      break;
    default:
      page = MapPage(user: widget.user);
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
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _mapController.dispose();
  _driversStreamSubscription?.cancel();
  _countListener?.cancel(); // Add this line
  super.dispose();
}
}


// Add these new widgets
class WasteReportsList extends StatelessWidget {
  final List<DocumentSnapshot> reports;
  final User? user;
  final Function(DocumentSnapshot) onReportTap;

  const WasteReportsList({
    Key? key,
    required this.reports,
    required this.user,
    required this.onReportTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending waste reports found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index].data() as Map<String, dynamic>;
        return ReportCard(
          report: report,
          reportDoc: reports[index],
          onTap: () => onReportTap(reports[index]),
        ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
        );
      },
    );
  }
}

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final DocumentSnapshot reportDoc;
  final VoidCallback onTap;

  const ReportCard({
    Key? key,
    required this.report,
    required this.reportDoc,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115937).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
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
                          report['reporterName'] ?? 'Unknown Reporter',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report['district']} - ${report['ward']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: report['status'] == 'pending'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report['status'] ?? 'Unknown',
                      style: TextStyle(
                        color: report['status'] == 'pending'
                            ? Colors.orange[800]
                            : Colors.green[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (report['imageUrl'] != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    report['imageUrl'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Reported ${timeago.format((report['reportedAt'] as Timestamp).toDate())}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
