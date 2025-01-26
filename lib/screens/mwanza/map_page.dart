import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


import '../../../../widgets/custom_drawer_non.dart';
// import '../../login_page.dart';
// import 'admin_management.dart';
import 'driver.dart';
import 'stakeholders_page.dart';
// import 'waste_aggregators_page.dart';
import 'waste_dealers_page.dart';
import 'waste_points_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_reportingCollection.dart';
class MapPage extends StatefulWidget {
  final User? user;
  const MapPage({this.user});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final mapController = MapController();
    String? _userRole; // Add this to track user role

  List<Marker> _markers = [];
  bool showLegalPoints = true;
  bool showIllegalPoints = true;
  int _selectedIndex = 0;
  bool _isAdmin = false;
  String _firstName = '';
  bool _isLoading = true;
  String? _selectedMarkerId;

  // Center of Tanzania approximately
  final LatLng _centerPoint = const LatLng(-2.51667, 32.9);


 bool showWasteDealers = true;
  bool showRecyclers = true;
bool showStakeholders = true;

  @override
  void initState() {
    super.initState();
    // _loadUserData();
        _checkUserRole(); // Add this

    _loadAllPoints(); // New combined loading method
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
  // Future<void> _loadUserData() async {
  //   try {
  //     if (widget.user != null) {
  //       final userDoc = await _firestore
  //           .collection('users')
  //           .doc(widget.user!.uid)
  //           .get();
  //       if (userDoc.exists && mounted) {
  //         setState(() {
  //           _firstName = userDoc.data()?['firstName'] ?? '';
  //           _isAdmin = userDoc.data()?['role'] == 'admin';
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



Widget _buildFilterOptions() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Wrap(
      spacing: 4,  // Space between widgets horizontally
      runSpacing: 4,  // Space between rows
      children: [
        _buildFilterOption(
          value: showLegalPoints,
          onChanged: (value) {
            setState(() {
              showLegalPoints = value ?? false;
              _selectedMarkerId = null;
            });
            _loadAllPoints();
          },
          iconPath: 'assets/images/legal_points.png',
          label: 'Legal',
        ),
        _buildFilterOption(
          value: showIllegalPoints,
          onChanged: (value) {
            setState(() {
              showIllegalPoints = value ?? false;
              _selectedMarkerId = null;
            });
            _loadAllPoints();
          },
          iconPath: 'assets/images/illegal_points.png',
          label: 'Illegal',
        ),
        _buildFilterOption(
          value: showWasteDealers,
          onChanged: (value) {
            setState(() {
              showWasteDealers = value ?? false;
              _selectedMarkerId = null;
            });
            _loadAllPoints();
          },
          iconPath: 'assets/images/wasteDealers_points.png',
          label: 'Dealers',
        ),
        _buildFilterOption(
          value: showRecyclers,
          onChanged: (value) {
            setState(() {
              showRecyclers = value ?? false;
              _selectedMarkerId = null;
            });
            _loadAllPoints();
          },
          iconPath: 'assets/images/recyclers_points.png',
          label: 'Recyclers',
        ),
        _buildFilterOption(
          value: showStakeholders,
          onChanged: (value) {
            setState(() {
              showStakeholders = value ?? false;
              _selectedMarkerId = null;
            });
            _loadAllPoints();
          },
          iconPath: 'assets/images/stakeholders_points.png',
          label: 'Stakeholders',
        ),
      ],
    ),
  );
}

Widget _buildFilterOption({
  required bool value,
  required Function(bool?) onChanged,
  required String iconPath,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            iconPath,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}



@override

Widget build(BuildContext context) {
  // Screen size utilities
  final screenWidth = MediaQuery.of(context).size.width;
  final defaultPadding = screenWidth * 0.04;
  final smallPadding = screenWidth * 0.02;

  return Scaffold(
    backgroundColor: const Color(0xFF1E3C2F),
    drawer: CustomDrawer(
      // firstName: _firstName,
      // isAdmin: _isAdmin,
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
        user: _userRole == 'driver' ? widget.user : null, // Only pass user if they're a driver

      
    ),
    body: NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
SliverAppBar(
          expandedHeight: 130,
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
            preferredSize: const Size.fromHeight(70),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
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
              child: _buildFilterOptions(),
            ),
          ),
          title: const Text(
              'Mwanza Map',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ),
      ],     
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _centerPoint,
              initialZoom: 9,
              minZoom: 4,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedMarkerId = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: _markers,
                rotate: true,
              ),
            ],
          ),
          
          // Map Controls Container
          Positioned(
            right: defaultPadding,
            bottom: defaultPadding,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ... Your existing map control buttons ...
              ],
            ),
          ),

          // Detail Card
          if (_selectedMarkerId != null)
            Builder(
              builder: (context) {
                final selectedData = getSelectedMarkerData();
                if (selectedData != null) {
                  return _buildDetailCard(selectedData);
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    ),
  );
}











// In your MapPage class, update _loadAllPoints:
Future<void> _loadAllPoints() async {
  try {
    List<Marker> allMarkers = [];
    
    // Load all collections in parallel
    final futures = <Future>[];
    
    // Waste Collection Points
    if (showLegalPoints || showIllegalPoints) {
      futures.add(_firestore.collection('wasteCollectionPoints').get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            if ((showLegalPoints && data['status'] == 'Legal') ||
                (showIllegalPoints && data['status'] == 'Illegal')) {
              final markerData = MarkerData.fromDocument(
                id: doc.id,
                data: data,
                type: 'waste_point',
              );
              final marker = _createMarker(markerData); // Now returns Marker directly
              allMarkers.add(marker);
            }
          } catch (e) {
            print('Error creating waste point marker: $e');
          }
        }
      }));
    }

    // Waste Dealers
    if (showWasteDealers) {
      futures.add(_firestore.collection('wasteDealersCollection').get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          try {
            final markerData = MarkerData.fromDocument(
              id: doc.id,
              data: doc.data(),
              type: 'dealer',
            );
            final marker = _createMarker(markerData);
            allMarkers.add(marker);
          } catch (e) {
            print('Error creating dealer marker: $e');
          }
        }
      }));
    }

    // Recyclers
    if (showRecyclers) {
      futures.add(_firestore.collection('recyclingCentersCollection').get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          try {
            final markerData = MarkerData.fromDocument(
              id: doc.id,
              data: doc.data(),
              type: 'recycler',
            );
            final marker = _createMarker(markerData);
            allMarkers.add(marker);
          } catch (e) {
            print('Error creating recycler marker: $e');
          }
        }
      }));
    }

    // Stakeholders
    if (showStakeholders) {
      futures.add(_firestore.collection('stakeholdersCollection').get().then((snapshot) async {
        for (var doc in snapshot.docs) {
          try {
            final markerData = MarkerData.fromDocument(
              id: doc.id,
              data: doc.data(),
              type: 'stakeholder',
            );
            final marker = _createMarker(markerData);
            allMarkers.add(marker);
          } catch (e) {
            print('Error creating stakeholder marker: $e');
          }
        }
      }));
    }

    // Wait for all futures to complete
    await Future.wait(futures);

    if (mounted) {
      setState(() => _markers = allMarkers);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading points: $e')),
      );
    }
  }
}

Marker _createMarker(MarkerData data) {
  // Store the marker data in the marker's key for later access
  return Marker(
    key: ValueKey('marker_${data.id}'), // Add this line
    width: 200,
    height: _selectedMarkerId == data.id ? 150 : 50,
    point: data.position,
    child: MarkerWidget(
      data: data,
      isSelected: _selectedMarkerId == data.id,
      onTap: () {
        setState(() {
          _selectedMarkerId = _selectedMarkerId == data.id ? null : data.id;
        });
        mapController.move(data.position, mapController.camera.zoom);
      },
    ),
  );
}


Widget _buildStatusBadge(String status) {
  final isPositive = status.toLowerCase() == 'formal' || 
                     status.toLowerCase() == 'legal';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      status,
      style: TextStyle(
        color: isPositive ? Colors.green : Colors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );
}





















Widget _buildMapControlButton({
  required IconData icon,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: const Color(0xFF115937),
            size: 24,
          ),
        ),
      ),
    ),
  );
}










Widget _buildDetailCard(MarkerData data) {
  return Positioned(
    bottom: 16,
    left: 16,
    right: 16,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedMarkerId = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Content based on marker type
            _buildMarkerDetails(data),
            
            // Action buttons
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     TextButton(
            //       onPressed: () => _navigateToDetails(data),
            //       child: const Text('View Details'),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildMarkerDetails(MarkerData data) {
  switch (data.type) {
    case 'waste_point':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location: ${data.subtitle}'),
          const SizedBox(height: 4),
          _buildStatusBadge(data.status),
          const SizedBox(height: 8),
          Text('Status: ${data.status}'),
        ],
      );
      
    case 'dealer':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.subtitle),
          const SizedBox(height: 4),
          _buildStatusBadge(data.status),
          const SizedBox(height: 8),
          Text('Operational Status: ${data.status}'),
        ],
      );
      
    case 'recycler':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${data.subtitle}'),
          const SizedBox(height: 4),
          _buildStatusBadge(data.status),
          const SizedBox(height: 8),
          Text('Center Status: ${data.status}'),
        ],
      );
      
    case 'stakeholder':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Title: ${data.subtitle}'),
          const SizedBox(height: 4),
          Text('Organization: ${data.status}'),
        ],
      );
      
    default:
      return const SizedBox.shrink();
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



  // Add a method to find selected marker data
MarkerData? getSelectedMarkerData() {
  if (_selectedMarkerId == null) return null;
  
  try {
    final selectedMarker = _markers.firstWhere(
      (marker) => marker.key is ValueKey && 
                  (marker.key as ValueKey).value == 'marker_$_selectedMarkerId'
    );
    
    if (selectedMarker.child is MarkerWidget) {
      return (selectedMarker.child as MarkerWidget).data;
    }
  } catch (e) {
    print('Error finding selected marker: $e');
  }
  return null;
}
}












class MarkerData {
  final Map<String, dynamic> details;

  final String id;
  final String title;
  final String subtitle;
  final String status;
  final LatLng position;
  final String iconPath;
  final String type;

  MarkerData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.position,
    required this.iconPath,
    required this.type,
      this.details = const {},
  });
factory MarkerData.fromDocument({
  required String id,
  required Map<String, dynamic> data,
  required String type,
}) {
  // Debug print to check data structure
  print('Processing $type with data: $data');

  // Extract coordinates based on type
  late double latitude;
  late double longitude;
  
  try {
    if (type == 'dealer') {
      // For waste dealers, check both possible location structures
      final location = data['location'] ?? data['basicInfo']?['location'];
      if (location != null) {
        latitude = (location['coordinates']?['latitude'] ?? 0.0) as double;
        longitude = (location['coordinates']?['longitude'] ?? 0.0) as double;
      } else {
        print('No location data found for dealer: $id');
        throw Exception('Invalid coordinates for dealer');
      }
    } else {
      // For other types
      final location = data['location']?['coordinates'];
      latitude = (location?['latitude'] ?? 0.0) as double;
      longitude = (location?['longitude'] ?? 0.0) as double;
    }

    if (latitude == 0.0 || longitude == 0.0) {
      throw Exception('Invalid coordinates');
    }

    // Determine marker properties based on type
    late String title;
    late String subtitle;
    late String status;
    late String iconPath;

    switch (type) {
      case 'waste_point':
        title = '${data['location']?['district'] ?? ''}, ${data['location']?['ward'] ?? ''}';
        subtitle = 'Street: ${data['location']?['street'] ?? ''}';
        status = data['status'] ?? 'N/A';
        iconPath = status == 'Legal' ? 
          'assets/images/legal_points.png' : 
          'assets/images/illegal_points.png';
        break;
      case 'dealer':
        final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>? ?? {};
        final basicInfo = data['basicInfo'] as Map<String, dynamic>? ?? {};
        title = practitionerInfo['name']?.toString() ?? 'Unknown Dealer';
        subtitle = '${practitionerInfo['category'] ?? ''} • ${basicInfo['district'] ?? ''}';
        status = (data['operationalStatus'] as Map<String, dynamic>?)?['status']?.toString() ?? 'N/A';
        iconPath = 'assets/images/wasteDealers_points.png';
        break;
      case 'recycler':
        title = data['ownership']?['centerName'] ?? 'Unknown Recycler';
        subtitle = data['operations']?['recyclingType'] ?? '';
        status = data['status']?['centerStatus'] ?? 'N/A';
        iconPath = 'assets/images/recyclers_points.png';
        break;
      case 'stakeholder':
        title = data['respondent_name'] ?? 'Unknown Stakeholder';
        subtitle = data['title'] ?? '';
        status = data['organization'] ?? 'N/A';
        iconPath = 'assets/images/stakeholders_points.png';
        break;
      default:
        throw Exception('Invalid marker type');
    }

    return MarkerData(
      id: id,
      title: title,
      subtitle: subtitle,
      status: status,
      position: LatLng(latitude, longitude),
      iconPath: iconPath,
      type: type,
    );
  } catch (e) {
    print('Error creating marker for $type with id $id: $e');
    rethrow;
  }
}
  // factory MarkerData.fromDocument({
  //   required String id,
  //   required Map<String, dynamic> data,
  //   required String type,
  // }) {
    
  //   // Extract coordinates based on type
  //   final location = data['location']?['coordinates'];
  //   final latitude = location?['latitude'] as double?;
  //   final longitude = location?['longitude'] as double?;

  //   if (latitude == null || longitude == null) {
  //     throw Exception('Invalid coordinates');
  //   }

  //   // Determine marker properties based on type
  //   late String title;
  //   late String subtitle;
  //   late String status;
  //   late String iconPath;

  //   switch (type) {
  //     case 'waste_point':
  //       title = '${data['location']?['district'] ?? ''}, ${data['location']?['ward'] ?? ''}';
  //       subtitle = 'Street: ${data['location']?['street'] ?? ''}';
  //       status = data['status'] ?? 'N/A';
  //       iconPath = status == 'Legal' ? 
  //         'assets/images/legal_points.png' : 
  //         'assets/images/illegal_points.png';
  //       break;
  //     case 'dealer':
  //       title = data['practitionerInfo']?['name'] ?? 'Unknown Dealer';
  //       subtitle = data['practitionerInfo']?['category'] ?? '';
  //       status = data['operationalStatus'] ?? 'N/A';
  //       iconPath = 'assets/images/wasteDealers_points.png';
  //       break;
  //     case 'recycler':
  //       title = data['ownership']?['centerName'] ?? 'Unknown Recycler';
  //       subtitle = data['operations']?['recyclingType'] ?? '';
  //       status = data['status']?['centerStatus'] ?? 'N/A';
  //       iconPath = 'assets/images/recyclers_points.png';
  //       break;
  //     case 'stakeholder':
  //       title = data['respondent_name'] ?? 'Unknown Stakeholder';
  //       subtitle = data['title'] ?? '';
  //       status = data['organization'] ?? 'N/A';
  //       iconPath = 'assets/images/stakeholders_points.png';
  //       break;
  //     default:
  //       throw Exception('Invalid marker type');
  //   }

  //   return MarkerData(
  //     id: id,
  //     title: title,
  //     subtitle: subtitle,
  //     status: status,
  //     position: LatLng(latitude, longitude),
  //     iconPath: iconPath,
  //     type: type,
  //   );
  // }
}

class MarkerWidget extends StatelessWidget {
  final MarkerData data;
  final bool isSelected;
  final VoidCallback onTap;

  const MarkerWidget({
    Key? key,
    required this.data,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Image.asset(
            data.iconPath,
            width: 32,
            height: 32,
          ),
        ),
      ],
    );
  }
}


