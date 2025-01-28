import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer_non.dart';
// import '../../widgets/custom_drawer.dart';
// import 'ilemela_map_page.dart';
// import '../admin_management.dart';
import 'agent.dart';
import 'driver.dart';
import 'ilemela_map_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_points_page.dart';
import 'ilemela_waste_recyclers_page.dart';
import 'waste_reportingCollection.dart';

class StakeholdersListPage extends StatefulWidget {
  final User? user;
  const StakeholdersListPage({this.user});

  @override
  _StakeholdersListPageState createState() => _StakeholdersListPageState();
}

class _StakeholdersListPageState extends State<StakeholdersListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  String _firstName = '';
      String? _userRole; // Add this to track user role

  int _selectedIndex = 5; // For stakeholders tab
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  static const secondaryColor = Color(0xFF90EE90);
  static const gradientColors = [
    Color(0xFF1E3C2F),
    Color(0xFF115937)
  ];

  @override
  void initState() {
    super.initState();
    // _loadUserData();
            _checkUserRole(); // Add this

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize responsive dimensions
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    defaultPadding = screenWidth * 0.04;
    smallPadding = screenWidth * 0.02;
    cardPadding = screenWidth * 0.035;
    headingSize = screenWidth * 0.045;
    bodyTextSize = screenWidth * 0.032;
    smallTextSize = screenWidth * 0.028;
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

  @override
  Widget build(BuildContext context) {
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
                    colors: gradientColors,
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(screenHeight * 0.08),
              child: Container(
                height: screenHeight * 0.08,
                padding: EdgeInsets.symmetric(
                  horizontal: defaultPadding, 
                  vertical: smallPadding
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
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(smallPadding),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        color: primaryColor,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Stakeholders',
                            style: TextStyle(
                              fontSize: headingSize,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                           // Text(
                          //   'Key partners and organizations',
                          //   style: TextStyle(
                          //     fontSize: smallTextSize,
                          //     color: Colors.grey[600],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search stakeholders...',
                          prefixIcon: const Icon(Icons.search, color: primaryColor),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Container(
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildStakeholdersList(),
        ),
      ),
    );
  }

  Widget _buildStakeholdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('stakeholdersCollection').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var documents = snapshot.data!.docs;
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          documents = documents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final searchLower = _searchQuery.toLowerCase();
            return data['respondent_name']?.toString().toLowerCase().contains(searchLower) == true ||
                   data['organization']?.toString().toLowerCase().contains(searchLower) == true ||
                   data['district']?.toString().toLowerCase().contains(searchLower) == true;
          }).toList();
        }

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: screenWidth * 0.15,
                  color: Colors.grey[400],
                ),
                SizedBox(height: defaultPadding),
                Text(
                  'No stakeholders found',
                  style: TextStyle(
                    fontSize: headingSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ).animate()
           .fadeIn(duration: const Duration(milliseconds: 500));
        }

        return GridView.builder(
          padding: EdgeInsets.all(defaultPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1),
            childAspectRatio: screenWidth > 600 ? 1.5 : 1.2,
            crossAxisSpacing: defaultPadding,
            mainAxisSpacing: defaultPadding,
          ),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;
            return _buildStakeholderCard(data, index);
          },
        );
      },
    );
  }

  Widget _buildStakeholderCard(Map<String, dynamic> data, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Organization and Department
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth * 0.08,
                  height: screenWidth * 0.08,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      data['organization']?.toString().substring(0, 1).toUpperCase() ?? 'S',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['organization'] ?? 'Unknown Organization',
                        style: TextStyle(
                          fontSize: bodyTextSize * 1.2,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (data['department'] != null) ...[
                        SizedBox(height: smallPadding / 2),
                        Text(
                          data['department'],
                          style: TextStyle(
                            fontSize: bodyTextSize,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            Divider(height: defaultPadding * 2),

            // Contact Information
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Respondent',
                      data['respondent_name'] ?? 'N/A',
                      Icons.person_outline,
                    ),
                    _buildInfoRow(
                      'Title',
                      data['title'] ?? 'N/A',
                      Icons.work_outline,
                    ),
                    _buildInfoRow(
                      'District',
                      data['district'] ?? 'N/A',
                      Icons.location_city,
                    ),
                    _buildInfoRow(
                      'Phone',
                      data['contact_phone'] ?? 'N/A',
                      Icons.phone_outlined,
                    ),
                    _buildInfoRow(
                      'Email',
                      data['email_address'] ?? 'N/A',
                      Icons.email_outlined,
                    ),
                    if (data['latitude'] != null && data['longitude'] != null)
                      _buildLocationRow(
                        data['latitude'],
                        data['longitude'],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
     .fadeIn(duration: const Duration(milliseconds: 300))
     .slideY(
       begin: 0.2,
       end: 0,
       delay: Duration(milliseconds: index * 100),
     );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.04,
            color: Colors.grey[600],
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: smallTextSize,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.grey[800],
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

  Widget _buildLocationRow(dynamic lat, dynamic lon) {
    return Container(
      margin: EdgeInsets.only(top: smallPadding),
      padding: EdgeInsets.all(smallPadding),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: screenWidth * 0.04,
            color: Colors.blue[700],
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: smallTextSize,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Lat: ${lat.toString()}\nLong: ${lon.toString()}',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // IconButton(
          //   icon: Icon(
          //     Icons.map_outlined,
          //     size: screenWidth * 0.05,
          //     color: Colors.blue[700],
          //   ),
          //   onPressed: () {
          //     // Optional: Add map view functionality
          //     _showLocationOnMap(lat, lon);
          //   },
          // ),
        ],
      ),
    );
  }

  // void _showLocationOnMap(dynamic lat, dynamic lon) {
  //   // Optional method to show location on map
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         backgroundColor: Colors.transparent,
  //         child: Container(
  //           width: screenWidth * 0.8,
  //           height: screenHeight * 0.6,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(24),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.2),
  //                 blurRadius: 20,
  //                 offset: const Offset(0, 10),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               // Header
  //               Container(
  //                 padding: EdgeInsets.all(defaultPadding),
  //                 decoration: const BoxDecoration(
  //                   color: primaryColor,
  //                   borderRadius: BorderRadius.only(
  //                     topLeft: Radius.circular(24),
  //                     topRight: Radius.circular(24),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.location_on,
  //                       color: Colors.white,
  //                       size: screenWidth * 0.05,
  //                     ),
  //                     SizedBox(width: smallPadding),
  //                     Expanded(
  //                       child: Text(
  //                         'Stakeholder Location',
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: headingSize,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                     IconButton(
  //                       icon: const Icon(Icons.close, color: Colors.white),
  //                       onPressed: () => Navigator.of(context).pop(),
  //                     ),
  //                   ],
  //                 ),
  //               ),
                
  //               // Map placeholder - You can integrate actual map here
  //               Expanded(
  //                 child: Center(
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Icon(
  //                         Icons.map,
  //                         size: screenWidth * 0.15,
  //                         color: Colors.grey[400],
  //                       ),
  //                       SizedBox(height: defaultPadding),
  //                       Text(
  //                         'Location Details',
  //                         style: TextStyle(
  //                           fontSize: headingSize,
  //                           color: primaryColor,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       SizedBox(height: smallPadding),
  //                       Text(
  //                         'Latitude: $lat\nLongitude: $lon',
  //                         textAlign: TextAlign.center,
  //                         style: TextStyle(
  //                           fontSize: bodyTextSize,
  //                           color: Colors.grey[600],
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ).animate()
  //        .fadeIn(duration: const Duration(milliseconds: 300))
  //        .scale(begin: Offset(dx, dy));
  //     },
  //   );
  // }

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  //   Navigator.of(context).pop();
    
  //   // Handle navigation based on the selected index
  //   // You'll need to implement your navigation logic here
  // }



void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
  Navigator.of(context).pop();
  
  
 Widget page;
    switch (index) {
      case 0:
        page = IlemelaMapPage(user: widget.user); // Pass the user along
        break;
      case 1:
        page =  WastePointsListPage(user: widget.user);
        break;
      case 2:
        page =  WasteDealersListPage(user: widget.user);
        break;
      case 4:
        page =  WasteRecyclersListPage(user: widget.user);
        break;
      case 5:
        page =  StakeholdersListPage(user: widget.user);
        break;
      case 6:
        page =  WasteReportPage(user: widget.user);
        break;
      case 7: // Driver dashboard
        if (_userRole == 'driver' && widget.user != null) {
          page = DriverDashboardPage(user: widget.user);
        } else {
          page = IlemelaMapPage(user: widget.user);
        }
        break;
        
      default:
        page = IlemelaMapPage(user: widget.user);
    }

  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}