import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart' hide ServiceStatus;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../widgets/custom_drawer_non.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
import 'waste_dealers_page.dart';
import 'waste_points_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_reportingCollection.dart';


class DriverDashboardPage extends StatefulWidget {
  final User? user;
  const DriverDashboardPage({Key? key, required this.user}) : super(key: key);

  @override
  _DriverDashboardPageState createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();
  final LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
    FlutterLocalNotificationsPlugin();
  bool _showDumpSites = false;

  int _selectedIndex = 7; // For waste dRIV tab
    String? _userRole; // Add this to track user role

  // double? _currentHeading; // Store the current compass heading
  Position? _currentPosition;
  List<Marker> _markers = [];
  List<Marker> _dumpMarkers = [];
  List<CircleMarker> _geofenceCircles = [];
  List<CircleMarker> _dumpGeofenceCircles = [];
// Add to your state variables
// Set<String> _notifiedPoints = {}; // Track points we've already notified about
// bool _isTracking = false;
  List<Map<String, dynamic>> _nearbyPoints = [];
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot>? _reportsStream;
  List<Map<String, dynamic>> _nearbyDumpPoints = [];
  // Set<String> _completedPickups = {}; // Track completed pickups
  // Set<String> _completedDumps = {}; // Track completed dumps
  // bool _hasActivePickup = false; // Track if driver has picked up waste
  // String? _activePickupId; // Track the ID of currently picked waste
  List<String> _activePickups = []; // Track multiple active pickups
  bool _isWorking = false;
  String? _currentSessionId;
  // DateTime? _sessionStartTime;
  Timer? _workEndCheckTimer;
  bool _canCollectWaste = false;

    // Add new variables for time tracking
  Duration _totalWorkTime = Duration.zero;
  DateTime? _sessionStartTime;
  String? _currentDateId;

 DateTime? _initialStartTime; // When driver first started working
  bool _hasStartedToday = false;
// Add these new variables in _DriverDashboardPageState
List<String> _assignedReports = []; // Track reports assigned to this driver
StreamSubscription<QuerySnapshot>? _assignedReportsStream;
Set<String> _pendingNotifications = {}; // Add this for tracking pending notifications



    double _currentHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassStream;





  // Improved notification tracking
  final Map<String, bool> _notifiedPoints = {};
  final Map<String, DateTime> _lastNotificationTime = {};
  static const Duration NOTIFICATION_COOLDOWN = Duration(minutes: 1);
  bool _initialLocationCheck = false;

  // Screen size utilities
  late double screenWidth;
  late double screenHeight;
  late double defaultPadding;
  late double smallPadding;


  // Constants for geofence radiuses (in meters)
  // TODO: Change these values for production:
  // - PICKUP_RADIUS should be 200 meters
  // - DUMP_RADIUS should be 100 meters
  static const double PICKUP_RADIUS = 200.0; // Currently 10m for testing
  static const double DUMP_RADIUS = 150.0;   // Currently 10m for testing





  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _initializeNotifications();
    _initializeLocation();
    _initializeCompass();
    _startAssignedReportsStream();
            _checkUserRole(); // Add this

  }

void _initializeCompass() {
    if (FlutterCompass.events == null) {
      _showErrorSnackBar('Device does not have sensors for compass');
      return;
    }

    _compassStream = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() {
          _currentHeading = event.heading!;
        });
      }
    });
  }

//  Add this method to check user role
  Future<void> _checkUserRole() async {
    if (widget.user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(widget.user!.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          setState(() {
            _userRole = userDoc.data()?['role'];
          });
        }
      } catch (e) {
        print('Error checking user role: $e');
      }
    }
  }
Future<void> _checkExistingSession() async {
    try {
      final now = DateTime.now();
      if (now.hour < 6) {
        setState(() => _canCollectWaste = false);
        return;
      }

      // Create a date ID in format YYYY-MM-DD
      final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      _currentDateId = dateId;

      // Check if driver has already started work today
      final workDayDoc = await _firestore
          .collection('driver_work_days')
          .doc('${widget.user?.uid}_$dateId')
          .get();

      if (workDayDoc.exists) {
        // Driver has already started work today
        setState(() {
          _hasStartedToday = true;
          _initialStartTime = workDayDoc.data()?['initialStartTime'].toDate();
        });

        // Check for active session
        final sessionsQuery = await _firestore
            .collection('driver_sessions')
            .where('driverId', isEqualTo: widget.user?.uid)
            .where('isActive', isEqualTo: true)
            .get();

        if (sessionsQuery.docs.isNotEmpty) {
          final session = sessionsQuery.docs.first;
          setState(() {
            _isWorking = true;
            _currentSessionId = session.id;
            _sessionStartTime = session['startTime'].toDate();
            _canCollectWaste = true;
          });
          _startWorkEndCheck();
        } else {
          // No active session but has started today - show continue dialog
          _showContinueWorkDialog();
        }
      } else {
        // First time starting today
        _showInitialWorkStartDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Error checking work session: $e');
    }
  }




Future<void> _showInitialWorkStartDialog() async {
    final now = DateTime.now();
    if (now.hour < 6) {
      _showErrorSnackBar('Work hours are between 6 AM and 12 AM');
      setState(() => _canCollectWaste = false);
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Work Day'),
          content: const Text(
            'Would you like to start your work day? You can pause and continue throughout the day until midnight.',
          ),
          actions: [
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Start Working'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _initialWorkStart();
    } else {
      setState(() => _canCollectWaste = false);
    }
  }
  Future<void> _showContinueWorkDialog() async {
    if (_initialStartTime == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final hoursWorked = DateTime.now().difference(_initialStartTime!).inHours;
        
        return AlertDialog(
          title: const Text('Continue Working?'),
          content: Text(
            'You started your work day at ${_formatTime(_initialStartTime!)}\n'
            'Would you like to continue working?',
          ),
          actions: [
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Continue Working'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _startWorkSession();
    } else {
      setState(() => _canCollectWaste = false);
    }
  }

Future<void> _initialWorkStart() async {
    try {
      final now = DateTime.now();
      
      // Create work day document
      await _firestore
          .collection('driver_work_days')
          .doc('${widget.user?.uid}_$_currentDateId')
          .set({
        'driverId': widget.user?.uid,
        'dateId': _currentDateId,
        'initialStartTime': now,
        'isActive': true,
      });

      setState(() {
        _hasStartedToday = true;
        _initialStartTime = now;
      });

      // Start the first session
      await _startWorkSession();
    } catch (e) {
      _showErrorSnackBar('Error starting work day: $e');
    }
  }





  void _startWorkEndCheck() {
    _workEndCheckTimer?.cancel();
    _workEndCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      
      // Check for midnight auto-end
      if (now.hour == 0 && now.minute == 0) {
        _endWorkSession(autoEnd: true);
        return;
      }

      // Show reminder dialog after 6 PM
      if (now.hour >= 18 && !_hasShownEndDayPrompt) {
        _showEndDayPrompt();
      }
    });
  }

  bool _hasShownEndDayPrompt = false;

  Future<void> _showEndDayPrompt() async {
    if (!mounted || _hasShownEndDayPrompt) return;
    
    _hasShownEndDayPrompt = true;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Work Day?'),
          content: const Text(
            'It\'s after 6 PM. Would you like to end your work day?',
          ),
          actions: [
            TextButton(
              child: const Text('Continue Working'),
              onPressed: () {
                Navigator.of(context).pop(false);
                // Reset the prompt flag after an hour
                Future.delayed(const Duration(hours: 1), () {
                  _hasShownEndDayPrompt = false;
                });
              },
            ),
            ElevatedButton(
              child: const Text('End Work Day'),
              onPressed: () {
                Navigator.of(context).pop(true);
                _endWorkSession();
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _endWorkSession();
    }
  }

  // Future<void> _showWorkStartDialog() async {
  //   final now = DateTime.now();
  //   if (now.hour < 6) {
  //     _showErrorSnackBar('Work hours are between 6 AM and 12 AM');
  //     setState(() => _canCollectWaste = false);
  //     return;
  //   }

  //   final result = await showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Start Working?'),
  //         content: const Text(
  //           'Would you like to start your work day? This will enable waste collection.',
  //         ),
  //         actions: [
  //           TextButton(
  //             child: const Text('Not Now'),
  //             onPressed: () => Navigator.of(context).pop(false),
  //           ),
  //           ElevatedButton(
  //             child: const Text('Start Working'),
  //             onPressed: () => Navigator.of(context).pop(true),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (result == true) {
  //     await _startWorkSession();
  //   } else {
  //     setState(() => _canCollectWaste = false);
  //   }
  // }
  // Modify _showWorkStartDialog to check for pending assignments
Future<void> _showWorkStartDialog() async {
  final now = DateTime.now();
  if (now.hour < 6) {
    _showErrorSnackBar('Work hours are between 6 AM and 12 AM');
    setState(() => _canCollectWaste = false);
    return;
  }

  // Check for pending assignments
  final assignedReports = await _firestore
      .collection('wasteReports')
      .where('newStatus', isEqualTo: 'assigned')
      .where('assignedDriverId', isEqualTo: widget.user?.uid)
      .get();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Start Working?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Would you like to start your work day? This will enable waste collection.',
            ),
            if (assignedReports.docs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'You have ${assignedReports.docs.length} assigned collection${assignedReports.docs.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Starting work will show these on your map',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Not Now'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text('Start Working'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (result == true) {
    await _startWorkSession();
    // Show any pending assignment notifications
    for (var doc in assignedReports.docs) {
      _showAssignmentNotification(doc);
    }
  } else {
    setState(() => _canCollectWaste = false);
  }
}

  Future<void> _endWorkSession({bool autoEnd = false}) async {
    try {
      if (_currentSessionId != null) {
        await _firestore.collection('driver_sessions').doc(_currentSessionId).update({
          'isActive': false,
          'endTime': DateTime.now(),
          'endLocation': {
            'latitude': _currentPosition?.latitude,
            'longitude': _currentPosition?.longitude,
          }
        });

        _workEndCheckTimer?.cancel();
        
        setState(() {
          _isWorking = false;
          _currentSessionId = null;
          _sessionStartTime = null;
          _canCollectWaste = false;
        });

        if (autoEnd) {
          _showSuccessSnackBar('Work session automatically ended at midnight');
        } else {
          _showSuccessSnackBar('Work session ended successfully');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error ending work session: $e');
    }
  }
//  Future<void> _startWorkSession() async {
//     try {
//       final now = DateTime.now();
//       final sessionId = '${widget.user?.uid}-${now.millisecondsSinceEpoch}';
      
//       await _firestore.collection('driver_sessions').doc(sessionId).set({
//         'driverId': widget.user?.uid,
//         'startTime': now,
//         'isActive': true,
//         'dateId': _currentDateId,
//         'location': {
//           'latitude': _currentPosition?.latitude,
//           'longitude': _currentPosition?.longitude,
//         }
//       });

//       setState(() {
//         _isWorking = true;
//         _currentSessionId = sessionId;
//         _sessionStartTime = now;
//         _canCollectWaste = true;
//       });

//       _startWorkEndCheck();
//       _showSuccessSnackBar('Work session started');
//     } catch (e) {
//       _showErrorSnackBar('Error starting work session: $e');
//     }
//   }
// Update _startWorkSession to check for assignments immediately after starting
Future<void> _startWorkSession() async {
  try {
    final now = DateTime.now();
    final sessionId = '${widget.user?.uid}-${now.millisecondsSinceEpoch}';
    
    await _firestore.collection('driver_sessions').doc(sessionId).set({
      'driverId': widget.user?.uid,
      'startTime': now,
      'isActive': true,
      'dateId': _currentDateId,
      'location': {
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      }
    });

    setState(() {
      _isWorking = true;
      _currentSessionId = sessionId;
      _sessionStartTime = now;
      _canCollectWaste = true;
    });

    // Check for existing assignments right after starting work
    await _checkExistingAssignments();

    _startWorkEndCheck();
    _showSuccessSnackBar('Work session started');
  } catch (e) {
    _showErrorSnackBar('Error starting work session: $e');
  }
}

// Add this new method to start listening for assigned reports
// void _startAssignedReportsStream() {
//   _assignedReportsStream = _firestore
//       .collection('wasteReports')
//       .where('newStatus', isEqualTo: 'assigned')
//       .where('assignedDriverId', isEqualTo: widget.user?.uid)
//       .snapshots()
//       .listen((snapshot) {
//     final newAssignedReports = snapshot.docs.map((doc) => doc.id).toList();
    
//     // Check for new assignments
//     for (var reportId in newAssignedReports) {
//       if (!_assignedReports.contains(reportId)) {
//         // This is a new assignment
//         _showAssignmentNotification(snapshot.docs.firstWhere((doc) => doc.id == reportId));
//       }
//     }
    
//     setState(() {
//       _assignedReports = newAssignedReports;
//     });
//   });
// }
// Modify _startAssignedReportsStream to handle immediate notifications better
void _startAssignedReportsStream() {
  // First do an initial check for any existing assignments
  _checkExistingAssignments();

  _assignedReportsStream = _firestore
      .collection('wasteReports')
      .where('status', isEqualTo: 'assigned')
      .where('assignedDriverId', isEqualTo: widget.user?.uid)
      .snapshots()
      .listen((snapshot) {
    final newAssignedReports = snapshot.docs.map((doc) => doc.id).toList();
    
    // Check for new assignments by comparing with current list
    for (var doc in snapshot.docs) {
      if (!_assignedReports.contains(doc.id)) {
        // This is a new assignment
        _showAssignmentNotification(doc);
      }
    }
    
    setState(() {
      _assignedReports = newAssignedReports;
    });
  });
}
// Add this new method to check existing assignments
Future<void> _checkExistingAssignments() async {
  try {
    final assignedReports = await _firestore
        .collection('wasteReports')
        .where('status', isEqualTo: 'assigned')
        .where('assignedDriverId', isEqualTo: widget.user?.uid)
        .get();

    if (assignedReports.docs.isNotEmpty) {
      for (var doc in assignedReports.docs) {
        _showAssignmentNotification(doc);
      }
    }
  } catch (e) {
    print('Error checking existing assignments: $e');
  }
}


// // Add this method to show assignment notifications
// void _showAssignmentNotification(DocumentSnapshot report) {
//   if (!_isWorking) {
//     // Store the notification for when they start working
//     _pendingNotifications.add(report.id);
//     return;
//   }

//   final data = report.data() as Map<String, dynamic>;
//   final location = data['location'] as Map<String, dynamic>;
//   final address = '${data['street']}, ${data['ward']}, ${data['district']}';

//   _showProximityAlert(
//     'New Waste Collection Assignment',
//     'You have been assigned to collect waste at $address',
//     false
//   );
// }

// Add this method to show assignment notifications
void _showAssignmentNotification(DocumentSnapshot report) {
  final data = report.data() as Map<String, dynamic>;
  final location = '${data['street']}, ${data['ward']}, ${data['district']}';

  // Show local notification
  _showLocalNotification(
    'New Waste Collection Assignment',
    'You have been assigned to collect waste at $location',
  );

  // Show in-app notification dialog
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment, color: Colors.blue[700]),
            ),
            const SizedBox(width: 12),
            const Text('New Assignment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have been assigned to collect waste at:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Center map on assigned location
              _mapController.move(
                LatLng(
                  data['location']['latitude'],
                  data['location']['longitude'],
                ),
                15,
              );
            },
            child: const Text('View on Map'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}


//  Add this helper method for local notifications
Future<void> _showLocalNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'assignments',
    'Waste Assignments',
    channelDescription: 'Notifications for new waste collection assignments',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
    color: Color(0xFF115937),
  );

  const notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecond,
    title,
    body,
    notificationDetails,
  );
}







  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }






   Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _currentHeading = position.heading; // Initialize heading
        _isLoading = false;
      });

      _startLocationTracking();
      _startWasteReportsStream();
      _loadDumpingAreas();

    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }
Future<void> _initializeNotifications() async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iOSInitialize = DarwinInitializationSettings();
    const initializationsSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  }


void _showProximityAlert(String title, String body, bool isDumpSite) async {
    // Long vibration pattern
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    // Show local notification
    var androidDetails = AndroidNotificationDetails(
      'proximity_alerts',
      'Proximity Alerts',
      channelDescription: 'Alerts when near pickup or dump points',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Long vibration pattern
    );

    const iOSDetails = DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );

    var notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );

    // Show in-app popup
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        backgroundColor: isDumpSite ? Colors.red.shade50 : Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }






 void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _currentHeading = position.heading; // Update heading
        });

        if (_markers.isNotEmpty) {
          _checkNearbyPoints(position);
        }

        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      },
      onError: (error) => _showErrorSnackBar(error.toString()),
    );
  }


  void _onPositionUpdate(Position position) {
    setState(() {
      _currentPosition = position;
    });

    if (_markers.isNotEmpty) {
      _checkNearbyPoints(position);
    }

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      _mapController.camera.zoom,
    );
  }


// void _startWasteReportsStream() {
//     _reportsStream = _firestore
//         .collection('wasteReports')
//         .snapshots()
//         .listen((snapshot) {
//       List<Marker> markers = [];
//       List<CircleMarker> circles = [];
//       _activePickups = []; // Reset active pickups list

//       for (var doc in snapshot.docs) {
//         final data = doc.data();
//         final status = data['status'];
//         final type = data['type'] ?? 'waste point'; // Default to 'waste point' if not specified
//         final location = data['location'];
//         final position = LatLng(
//           location['latitude'],
//           location['longitude'],
//         );

//         // Only show pending reports and any picked report by current driver
//         if (status == 'pending' || (status == 'picked' && data['driverId'] == widget.user?.uid)) {
//           markers.add(
//             Marker(
//               width: 60,
//               height: 60,
//               point: position,
//               child: GestureDetector(
//                 onTap: () => _showReportDetails(doc.id, data),
//                 child: Stack(
//                   children: [
//                     Icon(
//                       status == 'pending' ? Icons.delete_outline : Icons.local_shipping,
//                       color: status == 'pending' ? Colors.green : Colors.orange,

//                       // color: Colors.green,
//                       size: 30,
//                     ),
//                     // Add flag only for pending waste reports
//                     if (status == 'pending' && type == 'waste report')
//                       Positioned(
//                         right: 0,
//                         top: 0,
//                         child: Image.asset(
//                           'assets/images/red_flag.png',
//                           width: 15,
//                           height: 15,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           );

//           circles.add(
//             CircleMarker(
//               point: position,
//               radius: 200,
//               color: Colors.green.withOpacity(0.1),
//               borderColor: Colors.green,
//               borderStrokeWidth: 2,
//               useRadiusInMeter: true,
//             ),
//           );
          
//           // Update active pickups list for picked waste
//           if (status == 'picked' && data['driverId'] == widget.user?.uid) {
//             _activePickups.add(doc.id);
//           }
//         }
//       }
      
//       // Load dumping areas whenever waste reports are updated
//       _loadDumpingAreas();

//       setState(() {
//         _markers = markers;
//         _geofenceCircles = circles;
//       });
//     });
//   }

// // Modify the waste reports stream to handle assigned reports differently
// void _startWasteReportsStream() {
//   _reportsStream = _firestore
//       .collection('wasteReports')
//       .snapshots()
//       .listen((snapshot) {
//     List<Marker> markers = [];
//     List<CircleMarker> circles = [];
//     _activePickups = [];

//     for (var doc in snapshot.docs) {
//       final data = doc.data();
//       final status = data['status'];
//       final newStatus = data['assined'];
//       final type = data['type'] ?? 'waste point';
//       final location = data['location'];
//       final position = LatLng(
//         location['latitude'],
//         location['longitude'],
//       );

//       // Check if this report is assigned to current driver
//       final isAssignedToMe = status == 'assigned' && 
//                             data['assignedDriverId'] == widget.user?.uid;

//       if (status == 'pending' || newStatus == 'assigned' || 
//           (status == 'picked' && data['driverId'] == widget.user?.uid)) {
        
//         markers.add(
//           Marker(
//             width: 60,
//             height: 60,
//             point: position,
//             child: GestureDetector(
//               onTap: () => _showReportDetails(doc.id, data),
//               child: Stack(
//                 children: [
//                   Icon(
//                     status == 'picked' ? Icons.local_shipping 
//                     : isAssignedToMe ? Icons.assignment_turned_in 
//                     : Icons.delete_outline,
//                     color: status == 'picked' ? Colors.orange 
//                            : isAssignedToMe ? Colors.blue 
//                            : Colors.green,
//                     size: 30,
//                   ),
//                   if (status == 'pending' && type == 'waste report')
//                     const Positioned(
//                       right: 0,
//                       top: 0,
//                       child: Icon(
//                         Icons.push_pin,
//                         color: Colors.red,
//                         size: 15,
//                       ),
//                     ),
//                   if (isAssignedToMe)
//                     Positioned(
//                       right: -5,
//                       top: -5,
//                       child: Transform.rotate(
//                         angle: -0.4, // Slightly tilted
//                         child: const Icon(
//                           Icons.push_pin,
//                           color: Colors.blue,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         );

//         circles.add(
//           CircleMarker(
//             point: position,
//             radius: 200,
//             color: isAssignedToMe ? Colors.blue.withOpacity(0.1) 
//                    : Colors.green.withOpacity(0.1),
//             borderColor: isAssignedToMe ? Colors.blue : Colors.green,
//             borderStrokeWidth: 2,
//             useRadiusInMeter: true,
//           ),
//         );
        
//         if (status == 'picked' && data['driverId'] == widget.user?.uid) {
//           _activePickups.add(doc.id);
//         }
//       }
//     }
    
//     setState(() {
//       _markers = markers;
//       _geofenceCircles = circles;
//     });
//   });
// }

// First, modify the waste reports stream to handle assigned reports differently
void _startWasteReportsStream() {
  _reportsStream = _firestore
      .collection('wasteReports')
      .snapshots()
      .listen((snapshot) {
    List<Marker> markers = [];
    List<CircleMarker> circles = [];
    _activePickups = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];
      final type = data['type'] ?? 'waste point';
      final location = data['location'];
      final position = LatLng(
        location['latitude'] as double,
        location['longitude'] as double,
      );

      // Check if this report is assigned to current driver
      final isAssignedToMe = data['assignedDriverId'] == widget.user?.uid && 
                            status == 'assigned';

      // Show marker if: it's pending, assigned to me, or picked by me
      if (status == 'pending' || isAssignedToMe || 
          (status == 'picked' && data['driverId'] == widget.user?.uid)) {
        
        markers.add(
          Marker(
            width: 60,
            height: 60,
            point: position,
            child: GestureDetector(
              onTap: () => _showReportDetails(doc.id, data),
              child: Stack(
                children: [
                  // Base Icon
                  Icon(
                    status == 'picked' ? Icons.local_shipping 
                    : Icons.delete_outline,
                    color: status == 'picked' ? Colors.orange 
                           : isAssignedToMe ? Colors.blue 
                           : Colors.green,
                    size: 30,
                  ),
                  // Show flag for waste reports
                  if (type == 'waste report')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Image.asset(
                        'assets/images/red_flag.png',
                        width: 15,
                        height: 15,
                      ),
                    ),
                  // Show assignment pin
                  if (isAssignedToMe)
                    Positioned(
                      left: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.push_pin,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        // Add geofence circle with appropriate color
        circles.add(
          CircleMarker(
            point: position,
            radius: 200,
            color: isAssignedToMe ? 
                   Colors.blue.withOpacity(0.1) : 
                   Colors.green.withOpacity(0.1),
            borderColor: isAssignedToMe ? Colors.blue : Colors.green,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        );
        
        if (status == 'picked' && data['driverId'] == widget.user?.uid) {
          _activePickups.add(doc.id);
        }
      }
    }

    setState(() {
      _markers = markers;
      _geofenceCircles = circles;
    });
  });
}






Future<void> _loadDumpingAreas() async {
    try {
      // Only load dump points if there are active pickups
      if (_activePickups.isEmpty) {
        setState(() {
          _dumpMarkers = [];
          _dumpGeofenceCircles = [];
        });
        return;
      }

      final snapshot = await _firestore
          .collection('dumpingAreaCollection')
          .get();

      List<Marker> dumpMarkers = [];
      List<CircleMarker> dumpCircles = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'];
        final position = LatLng(
          location['latitude'],
          location['longitude'],
        );

        dumpMarkers.add(
          Marker(
            width: 60,
            height: 60,
            point: position,
            child: GestureDetector(
              onTap: () => _showDumpPointDetails(doc.id, data),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 30,
              ),
            ),
          ),
        );

        dumpCircles.add(
          CircleMarker(
            point: position,
            radius: 150, // 100 meters radius for dumping
            color: Colors.red.withOpacity(0.1),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
            useRadiusInMeter: true,
          ),
        );
      }

      setState(() {
        _dumpMarkers = dumpMarkers;
        _dumpGeofenceCircles = dumpCircles;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading dumping areas: $e');
    }
  }

// Modify _showReportDetails to check working status
void _showReportDetails(String id, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF115937),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.report_problem, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Waste Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Status: ${data['status']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.description,
                  'Description',
                  data['description'] ?? 'No description provided',
                ),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.access_time,
                  'Reported',
                  data['timestamp']?.toDate()?.toString() ?? 'Unknown',
                ),
                if (!_canCollectWaste && data['status'] == 'pending')
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Start your work day to collect waste',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                if (data['status'] == 'pending')
                  ElevatedButton.icon(
                    onPressed: _canCollectWaste 
                      ? () {
                          Navigator.pop(context);
                          _handlePickup(id, data);
                        }
                      : () {
                          Navigator.pop(context);
                          _showWorkStartDialog();
                        },
                    icon: Icon(_canCollectWaste ? Icons.check : Icons.play_arrow),
                    label: Text(_canCollectWaste ? 'Pickup' : 'Start Working'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF115937),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}





// Modify _handlePickup to check working status
Future<void> _handlePickup(String reportId, Map<String, dynamic> data) async {
  if (!_canCollectWaste) {
    _showErrorSnackBar('You must start your work day before collecting waste');
    _showWorkStartDialog();
    return;
  }

  if (!_isWorking) {
    _showErrorSnackBar('Your work session has ended. Please start a new session.');
    return;
  }

  try {
    // Update waste report status
    await _firestore.collection('wasteReports').doc(reportId).update({
      'status': 'picked',
      'driverId': widget.user?.uid,
      'pickupTimestamp': FieldValue.serverTimestamp(),
      'sessionId': _currentSessionId, // Add session ID to track pickups per session
    });

    // Create pickup log
    await _firestore.collection('pickupLogs').add({
      'wasteId': reportId,
      'driverId': widget.user?.uid,
      'sessionId': _currentSessionId,
      'timestamp': FieldValue.serverTimestamp(),
      'location': {
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      },
      'status': 'picked',
      'wasteLocation': data['location'],
      'description': data['description'],
    });

    setState(() {
      _activePickups.add(reportId);
      _showDumpSites = true;
      if (_dumpMarkers.isEmpty) {
        _loadDumpingAreas();
      }
    });

    _showSuccessSnackBar('Waste picked up successfully');
  } catch (e) {
    _showErrorSnackBar('Error recording pickup: $e');
  }
}



Future<void> _handleDump(String dumpAreaId) async {
  if (_activePickups.isEmpty) {
    _showErrorSnackBar('No active pickups to dump');
    return;
  }

  try {
    // Update all active waste reports
    await Future.wait(_activePickups.map((pickupId) async {
      await _firestore.collection('wasteReports').doc(pickupId).update({
        'status': 'dumped',
        'dumpAreaId': dumpAreaId,
        'dumpTimestamp': FieldValue.serverTimestamp(),
      });

      // Reset notification for this point
      _resetNotificationForPoint(pickupId);


        // Find and update corresponding pickup log
        final pickupLogs = await _firestore
            .collection('pickupLogs')
            .where('wasteId', isEqualTo: pickupId)
            .where('status', isEqualTo: 'picked')
            .get();

        if (pickupLogs.docs.isNotEmpty) {
          await pickupLogs.docs.first.reference.update({
            'status': 'dumped',
            'dumpAreaId': dumpAreaId,
            'dumpTimestamp': FieldValue.serverTimestamp(),
            'dumpLocation': {
              'latitude': _currentPosition?.latitude,
              'longitude': _currentPosition?.longitude,
            },
          });
        }
}));

    setState(() {
      _activePickups.clear();
      _showDumpSites = false; // Hide dump sites when no active pickups
    });

    _showSuccessSnackBar('Waste dumped successfully');
  } catch (e) {
    _showErrorSnackBar('Error updating dump status: $e');
  }
}






void _showDumpPointDetails(String id, Map<String, dynamic> data) {
  List<String> selectedPickups = List.from(_activePickups);
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 600;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.7,
          height: isSmallScreen ? screenSize.height * 0.9 : screenSize.height * 0.8,
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: isSmallScreen ? double.infinity : 800,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header remains the same...
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Dumping Area',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Dumping Point',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Details
                      _detailRow(
                        Icons.location_city,
                        'Location',
                        data['address'] ?? 'N/A',
                      ),
                      const SizedBox(height: 16),

                      // Active Pickups Counter remains the same...
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Active Pickups',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _activePickups.isEmpty 
                                        ? 'No Active Pickups'
                                        : '${selectedPickups.length} of ${_activePickups.length} selected',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _activePickups.isEmpty ? Colors.grey : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modified Pickup Selection Section for better responsiveness
                      if (_activePickups.isNotEmpty) ...[
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              'Select Pickups to Dump',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  if (selectedPickups.length == _activePickups.length) {
                                    selectedPickups.clear();
                                  } else {
                                    selectedPickups = List.from(_activePickups);
                                  }
                                });
                              },
                              icon: Icon(
                                selectedPickups.length == _activePickups.length
                                    ? Icons.deselect
                                    : Icons.select_all,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              label: Text(
                                selectedPickups.length == _activePickups.length
                                    ? 'Deselect All'
                                    : 'Select All',
                                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12,
                                  vertical: isSmallScreen ? 4 : 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Pickup List
                        FutureBuilder<List<DocumentSnapshot>>(
                          future: Future.wait(_activePickups.map(
                            (id) => _firestore.collection('pickupLogs')
                                .where('wasteId', isEqualTo: id)
                                .where('status', isEqualTo: 'picked')
                                .get()
                                .then((snap) => snap.docs.first)
                          )),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No pickup data available'),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final doc = snapshot.data![index];
                                final data = doc.data() as Map<String, dynamic>;
                                final wasteId = data['wasteId'] as String;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: selectedPickups.contains(wasteId)
                                          ? Colors.red.shade200
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: selectedPickups.contains(wasteId),
                                    onChanged: (bool? value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          selectedPickups.add(wasteId);
                                        } else {
                                          selectedPickups.remove(wasteId);
                                        }
                                      });
                                    },
                                    title: Text(
                                      'Pickup #${doc.id.substring(0, 6)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['description'] ?? 'No description'),
                                        Text(
                                          'Picked: ${_formatTimestamp(data['timestamp'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    secondary: Icon(
                                      Icons.delete_outline,
                                      color: selectedPickups.contains(wasteId)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    activeColor: Colors.red,
                                    checkboxShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Modified Action Buttons for better responsiveness
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 16,
                          vertical: isSmallScreen ? 4 : 8,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_activePickups.isNotEmpty)
                      ElevatedButton(
                        onPressed: selectedPickups.isEmpty ? null : () {
                          Navigator.pop(context);
                          _handleSelectedDumps(id, selectedPickups);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 16,
                            vertical: isSmallScreen ? 4 : 8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: isSmallScreen ? 16 : 20),
                            SizedBox(width: isSmallScreen ? 4 : 8),
                            Text(
                              selectedPickups.length == 1
                                  ? 'Dump Selected'
                                  : 'Dump ${selectedPickups.length}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}










String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  Future<void> _handleSelectedDumps(String dumpAreaId, List<String> selectedPickups) async {
    if (selectedPickups.isEmpty) {
      _showErrorSnackBar('No pickups selected for dumping');
      return;
    }

    try {
      // Update selected waste reports and pickup logs
      await Future.wait(selectedPickups.map((pickupId) async {
        // Update waste report
        await _firestore.collection('wasteReports').doc(pickupId).update({
          'status': 'dumped',
          'dumpAreaId': dumpAreaId,
          'dumpTimestamp': FieldValue.serverTimestamp(),
        });

        // Find and update corresponding pickup log
        final pickupLogs = await _firestore
            .collection('pickupLogs')
            .where('wasteId', isEqualTo: pickupId)
            .where('status', isEqualTo: 'picked')
            .get();

        if (pickupLogs.docs.isNotEmpty) {
          await pickupLogs.docs.first.reference.update({
            'status': 'dumped',
            'dumpAreaId': dumpAreaId,
            'dumpTimestamp': FieldValue.serverTimestamp(),
            'dumpLocation': {
              'latitude': _currentPosition?.latitude,
              'longitude': _currentPosition?.longitude,
            },
          });
        }
      }));

      setState(() {
        // Remove dumped pickups from active pickups
        _activePickups.removeWhere((pickup) => selectedPickups.contains(pickup));
      });

      _showSuccessSnackBar(
        selectedPickups.length == 1 
            ? 'Waste dumped successfully' 
            : '${selectedPickups.length} wastes dumped successfully'
      );
    } catch (e) {
      _showErrorSnackBar('Error updating dump status: $e');
    }
  }






   void _checkNearbyPoints(Position position) {
    // Only show and check dump points if there are active pickups
    setState(() {
      _showDumpSites = _activePickups.isNotEmpty;
    });

    // Check pickup points only if we don't have active pickups
    if (_activePickups.isEmpty) {
      for (var marker in _markers) {
        final String pointId;
        if (marker.key != null) {
          pointId = marker.key.toString();
        } else {
          pointId = '${marker.point.latitude}-${marker.point.longitude}';
        }

        // Calculate distance using Haversine formula
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          marker.point.latitude,
          marker.point.longitude
        );

        bool shouldNotify = distance <= PICKUP_RADIUS && 
            (!_notifiedPoints.containsKey(pointId) || !_notifiedPoints[pointId]!);

        // Check cooldown period
        if (shouldNotify && _lastNotificationTime.containsKey(pointId)) {
          final lastNotified = _lastNotificationTime[pointId]!;
          if (DateTime.now().difference(lastNotified) < NOTIFICATION_COOLDOWN) {
            shouldNotify = false;
          }
        }

        if (shouldNotify) {
          _showProximityAlert(
            'Pickup Point Nearby',
            'You are within ${distance.toStringAsFixed(0)} meters of a waste collection point.',
            false,
          );
          
          _notifiedPoints[pointId] = true;
          _lastNotificationTime[pointId] = DateTime.now();
          HapticFeedback.heavyImpact();
        }

        // Update nearby points for UI purposes
        if (distance <= PICKUP_RADIUS) {
          if (!_nearbyPoints.any((point) => point['id'] == pointId)) {
            setState(() {
              _nearbyPoints.add({
                'id': pointId,
                'distance': distance,
              });
            });
          }
        } else {
          setState(() {
            _nearbyPoints.removeWhere((point) => point['id'] == pointId);
          });
        }
      }
    }

    // Check dump points only if we have active pickups
    if (_activePickups.isNotEmpty) {
      for (var marker in _dumpMarkers) {
        final String pointId;
        if (marker.key != null) {
          pointId = marker.key.toString();
        } else {
          pointId = '${marker.point.latitude}-${marker.point.longitude}';
        }

        // Calculate distance using Haversine formula
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          marker.point.latitude,
          marker.point.longitude
        );

        bool shouldNotify = distance <= DUMP_RADIUS && 
            (!_notifiedPoints.containsKey(pointId) || !_notifiedPoints[pointId]!);

        // Check cooldown period
        if (shouldNotify && _lastNotificationTime.containsKey(pointId)) {
          final lastNotified = _lastNotificationTime[pointId]!;
          if (DateTime.now().difference(lastNotified) < NOTIFICATION_COOLDOWN) {
            shouldNotify = false;
          }
        }

        if (shouldNotify) {
          _showProximityAlert(
            'Dumping Point Nearby',
            'You are within ${distance.toStringAsFixed(0)} meters of a dumping point.',
            true,
          );
          
          _notifiedPoints[pointId] = true;
          _lastNotificationTime[pointId] = DateTime.now();
          HapticFeedback.heavyImpact();
        }

        // Update nearby dump points for UI purposes
        if (distance <= DUMP_RADIUS) {
          if (!_nearbyDumpPoints.any((point) => point['id'] == pointId)) {
            setState(() {
              _nearbyDumpPoints.add({
                'id': pointId,
                'distance': distance,
              });
            });
          }
        } else {
          setState(() {
            _nearbyDumpPoints.removeWhere((point) => point['id'] == pointId);
          });
        }
      }
    }
  }

  // Update the reset notification method
  void _resetNotificationForPoint(String pointId) {
    setState(() {
      _notifiedPoints[pointId] = false;
      _lastNotificationTime.remove(pointId);
    });
  }


Widget _detailRow(IconData icon, String label, String value, {bool isStatus = false, Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            if (isStatus)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    defaultPadding = screenWidth * 0.04;
    smallPadding = screenWidth * 0.02;

    return Scaffold(
      key: _scaffoldKey,  // Add this line
      backgroundColor: const Color(0xFF1E3C2F),
    drawer: CustomDrawer(
      // firstName: _firstName,
      // isAdmin: _isAdmin,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
        user: _userRole == 'driver' ? widget.user : null, // Only pass user if they're a driver

      
    ),
        
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _currentPosition == null
              ? _buildLocationWaiting()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: _buildMap(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLocationWaiting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_disabled,
            size: screenWidth * 0.15,
            color: Colors.white,
          ),
          SizedBox(height: defaultPadding),
          Text(
            'Waiting for location...',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.04,
            ),
          ),
          SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: _initializeLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: defaultPadding * 2,
                vertical: defaultPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: const Color(0xFF1E3C2F),
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

//  Widget _buildHeader() {
//     return SafeArea(
//       child: Padding(
//         padding: EdgeInsets.all(defaultPadding),
//         child: Row(
//           children: [
//             Icon(
//               Icons.local_shipping,
//               color: Colors.white,
//               size: screenWidth * 0.08,
//             ),
//             SizedBox(width: smallPadding),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Driver Dashboard',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: screenWidth * 0.06,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (_initialStartTime != null) ...[
//                     Row(
//                       children: [
//                         Container(
//                           width: 8,
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: _isWorking ? Colors.green : Colors.orange,
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           _isWorking 
//                               ? 'Working - Started at ${_formatTime(_initialStartTime!)}'
//                               : 'Paused - Started at ${_formatTime(_initialStartTime!)}',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: screenWidth * 0.035,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             if (_isWorking)
//               IconButton(
//                 icon: const Icon(Icons.pause_circle, color: Colors.white),
//                 onPressed: () => _endWorkSession(),
//                 tooltip: 'Pause Work Session',
//               )
//             else if (_hasStartedToday)
//               IconButton(
//                 icon: const Icon(Icons.play_circle, color: Colors.white),
//                 onPressed: () => _showContinueWorkDialog(),
//                 tooltip: 'Continue Working',
//               ),
//           ],
//         ),
//       ),
//     );
//   }
Widget _buildHeader() {
  return SafeArea(
    child: Padding(
      padding: EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();  // Modified this line
            },
          ),
          Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: screenWidth * 0.08,
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_initialStartTime != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isWorking ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isWorking 
                            ? 'Working - Started at ${_formatTime(_initialStartTime!)}'
                            : 'Paused - Started at ${_formatTime(_initialStartTime!)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_isWorking)
            IconButton(
              icon: const Icon(Icons.pause_circle, color: Colors.white),
              onPressed: () => _endWorkSession(),
              tooltip: 'Pause Work Session',
            )
          else if (_hasStartedToday)
            IconButton(
              icon: const Icon(Icons.play_circle, color: Colors.white),
              onPressed: () => _showContinueWorkDialog(),
              tooltip: 'Continue Working',
            ),
        ],
      ),
    ),
  );
}





Widget _buildMap() {
  return Stack(
    children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          initialZoom: 9,
          minZoom: 4,
          maxZoom: 18,
          // onMapReady: () {
          //   setState(() {
          //     // Map is ready
          //   });
          // },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          CircleLayer<Object>(  // Explicitly specify Object as the type parameter
            circles: [
              ..._geofenceCircles,
              ...(_showDumpSites ? _dumpGeofenceCircles : []),
            ],
          ),
          MarkerLayer(
            markers: [
              ..._markers,
              ...(_showDumpSites ? _dumpMarkers : []),
              Marker(
                width: 60,
                height: 60,
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                child: Transform.rotate(
                  angle: (_currentHeading ?? 0) * (math.pi / 180),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Map Controls
      Positioned(
        right: 20,
        bottom: 20,
        child: Column(
          children: [
            FloatingActionButton.small(
              heroTag: "zoomIn",
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom + 1,
                );
              },
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: "zoomOut",
              onPressed: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                  _mapController.camera.center,
                  currentZoom - 1,
                );
              },
              child: const Icon(Icons.remove),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: "myLocation",
              onPressed: () {
                if (_currentPosition != null) {
                  _mapController.move(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    _mapController.camera.zoom,
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
      // Attribution
      const Positioned(
        left: 10,
        bottom: 10,
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ),
    ],
  );
}

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  @override
  void dispose() {
    _positionStream?.cancel();
    _reportsStream?.cancel();
    _compassStream?.cancel();
  _assignedReportsStream?.cancel(); // Add this line
  _notifiedPoints.clear();
  _lastNotificationTime.clear();
  _workEndCheckTimer?.cancel();
  _pendingNotifications.clear();
    super.dispose();
  }




  

void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
  Navigator.of(context).pop();
  
 Widget page;
    switch (index) {
      case 0:
        page = MapPage(user: widget.user); // Pass the user along
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
      case 6:
        page = WasteReportPage(user: widget.user);
        break;
      case 7: // Driver dashboard
        if (_userRole == 'driver' && widget.user != null) {
          page = DriverDashboardPage(user: widget.user);
        } else {
          page = MapPage(user: widget.user);
        }
        break;
      default:
        page = MapPage(user: widget.user);
    }
    
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}
}