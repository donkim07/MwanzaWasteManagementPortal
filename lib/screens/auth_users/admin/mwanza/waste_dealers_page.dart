import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer.dart';
import 'WHO_waste_reportMap.dart';
import 'admin_management.dart';
import 'agent.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
import 'waste_dealersCollection_page.dart';
import 'waste_points_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_reportMap.dart';
import 'waste_reportingCollection.dart';

class WasteDealersListPage extends StatefulWidget {
  final User? user;
  const WasteDealersListPage({Key? key, required this.user}) : super(key: key);

  @override
  _WasteDealersListPageState createState() => _WasteDealersListPageState();
}

class _WasteDealersListPageState extends State<WasteDealersListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  String _firstName = '';
  int _selectedIndex = 2; // For waste dealers tab
  bool _isLoading = true;
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
  bool _isAgent = false;
  bool _isWardOfficer= false;
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
    _loadUserData();
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
          // SliverAppBar(
          //   expandedHeight: 120,
          //   floating: true,
          //   pinned: true,
          //   backgroundColor: const Color(0xFF1E3C2F),
          //   elevation: 0,
          //   flexibleSpace: FlexibleSpaceBar(
          //     background: Container(
          //       decoration: const BoxDecoration(
          //         gradient: LinearGradient(
          //           begin: Alignment.topCenter,
          //           end: Alignment.bottomCenter,
          //           colors: gradientColors,
          //         ),
          //       ),
          //     ),
          //   ),
          //   bottom: PreferredSize(
          //     preferredSize: const Size.fromHeight(60),
          //     child: Container(
          //       height: 60,
          //       padding: EdgeInsets.symmetric(
          //         horizontal: defaultPadding,
          //         vertical: smallPadding,
          //       ),
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         borderRadius: const BorderRadius.only(
          //           topLeft: Radius.circular(30),
          //           topRight: Radius.circular(30),
          //         ),
          //         boxShadow: [
          //           BoxShadow(
          //             color: Colors.black.withOpacity(0.1),
          //             blurRadius: 10,
          //             offset: const Offset(0, -5),
          //           ),
          //         ],
          //       ),
          //       child: Row(
          //         children: [
          //           Icon(
          //             Icons.business,
          //             color: primaryColor,
          //             size: screenWidth * 0.06,
          //           ),
          //           SizedBox(width: smallPadding),
          //           Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Text(
          //                 'Waste Dealers',
          //                 style: TextStyle(
          //                   fontSize: headingSize,
          //                   fontWeight: FontWeight.bold,
          //                   color: primaryColor,
          //                 ),
          //               ),
          //               // Text(
          //               //   'Manage waste dealer records',
          //               //   style: TextStyle(
          //               //     fontSize: smallTextSize,
          //               //     color: Colors.grey[600],
          //               //   ),
          //               // ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Waste dealers...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF115937)),
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
            ),
            title: const Text(
              'Waste Dealers',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WasteDealerForm(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        body: _buildMainContent(),
      ),
    );
  }





// Add this to the _WasteDealersListPageState class

Widget _buildMainContent() {
  return Container(
    color: Colors.white,
    child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // _buildSearchAndActions(),
              Expanded(
                child: _buildDealersList(),
              ),
            ],
          ),
  );
}

// Widget _buildSearchAndActions() {
//   return Container(
//     padding: EdgeInsets.all(defaultPadding),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.05),
//           blurRadius: 10,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: smallPadding),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   style: TextStyle(fontSize: bodyTextSize),
//                   decoration: InputDecoration(
//                     hintText: 'Search dealers...',
//                     hintStyle: TextStyle(
//                       color: Colors.grey[500],
//                       fontSize: bodyTextSize,
//                     ),
//                     prefixIcon: Icon(
//                       Icons.search,
//                       color: primaryColor,
//                       size: screenWidth * 0.055,
//                     ),
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: smallPadding,
//                       vertical: smallPadding,
//                     ),
//                   ),
//                   onChanged: (value) {
//                     setState(() => _searchQuery = value.toLowerCase());
//                   },
//                 ),
//               ),
//             ),
//             SizedBox(width: defaultPadding),
//             // ElevatedButton.icon(
//             //   onPressed: () {
//             //     Navigator.push(
//             //       context,
//             //       MaterialPageRoute(
//             //         builder: (context) => WasteDealerForm(user: widget.user),
//             //       ),
//             //     );
//             //   },
//             //   icon: Icon(Icons.add, size: screenWidth * 0.045),
//             //   label: Text(
//             //     'Add Dealer',
//             //     style: TextStyle(fontSize: bodyTextSize),
//             //   ),
//             //   style: ElevatedButton.styleFrom(
//             //     backgroundColor: primaryColor,
//             //     foregroundColor: Colors.white,
//             //     padding: EdgeInsets.symmetric(
//             //       horizontal: defaultPadding,
//             //       vertical: smallPadding,
//             //     ),
//             //     shape: RoundedRectangleBorder(
//             //       borderRadius: BorderRadius.circular(12),
//             //     ),
//             //   ),
//             // ),
//           ],
//         ),
//       ],
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: -0.2, end: 0);
// }

Widget _buildDealersList() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore.collection('wasteDealersCollection').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _buildErrorState('Error loading dealers: ${snapshot.error}');
      }

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      var documents = snapshot.data!.docs;
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        documents = documents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>;
          final basicInfo = data['basicInfo'] as Map<String, dynamic>;
          
          return practitionerInfo['name'].toString().toLowerCase().contains(_searchQuery) ||
                 practitionerInfo['category'].toString().toLowerCase().contains(_searchQuery) ||
                 basicInfo['district'].toString().toLowerCase().contains(_searchQuery);
        }).toList();
      }

      if (documents.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        color: primaryColor,
        child: ListView.builder(
          padding: EdgeInsets.all(defaultPadding),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;
            return _buildDealerCard(documents[index], data, index);
          },
        ),
      );
    },
  );
}

Widget _buildDealerCard(DocumentSnapshot doc, Map<String, dynamic> data, int index) {
  final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>;
  final basicInfo = data['basicInfo'] as Map<String, dynamic>;
  final operationalStatus = data['operationalStatus'] as Map<String, dynamic>;

  return Card(
    margin: EdgeInsets.only(bottom: defaultPadding),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      onTap: () => _showDetailsDialog(doc),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar/Number container
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: defaultPadding),
                
                // Details section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practitionerInfo['name'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: bodyTextSize * 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: smallPadding / 2),
                      Text(
                        '${practitionerInfo['category'] ?? 'N/A'} • ${basicInfo['district'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: bodyTextSize,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: smallPadding),
                      Row(
                        children: [
                          _buildStatusBadge(
                            operationalStatus['status'] ?? 'N/A',
                          ),
                          if (data['wasteTypes'] != null) ...[
                            SizedBox(width: smallPadding),
                            _buildWasteTypesBadge(
                              (data['wasteTypes'] as List<dynamic>).length,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.visibility_outlined,
                        color: primaryColor,
                        size: screenWidth * 0.055,
                      ),
                      onPressed: () => _showDetailsDialog(doc),
                      tooltip: 'View Details',
                    ),
                    // if (_isAdmin) ...[
                    //   IconButton(
                    //     icon: Icon(
                    //       Icons.edit_outlined,
                    //       color: Colors.blue[700],
                    //       size: screenWidth * 0.055,
                    //     ),
                    //     onPressed: () => _navigateToEdit(doc),
                    //     tooltip: 'Edit',
                    //   ),
                    //   IconButton(
                    //     icon: Icon(
                    //       Icons.delete_outline,
                    //       color: Colors.red[700],
                    //       size: screenWidth * 0.055,
                    //     ),
                    //     onPressed: () => _showDeleteConfirmation(doc.id),
                    //     tooltip: 'Delete',
                    //   ),
                    // ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideX(begin: 0.2, end: 0, delay: Duration(milliseconds: index * 100));
}

Widget _buildStatusBadge(String status) {
  final isActive = status.toLowerCase() == 'formal';
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: defaultPadding / 2,
      vertical: smallPadding / 2,
    ),
    decoration: BoxDecoration(
      color: isActive ? Colors.green[50] : Colors.orange[50],
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isActive ? Colors.green[200]! : Colors.orange[200]!,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.warning,
          size: screenWidth * 0.035,
          color: isActive ? Colors.green[700] : Colors.orange[700],
        ),
        SizedBox(width: smallPadding / 2),
        Text(
          status,
          style: TextStyle(
            fontSize: smallTextSize,
            color: isActive ? Colors.green[700] : Colors.orange[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildWasteTypesBadge(int count) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: defaultPadding / 2,
      vertical: smallPadding / 2,
    ),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.delete_outline,
          size: screenWidth * 0.035,
          color: Colors.blue[700],
        ),
        SizedBox(width: smallPadding / 2),
        Text(
          '$count types',
          style: TextStyle(
            fontSize: smallTextSize,
            color: Colors.blue[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.business_outlined,
          size: screenWidth * 0.15,
          color: Colors.grey[400],
        ),
        SizedBox(height: defaultPadding),
        Text(
          'No waste dealers found',
          style: TextStyle(
            fontSize: headingSize,
            color: Colors.grey[600],
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          SizedBox(height: smallPadding),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: bodyTextSize,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .scale(begin: const Offset(0.8, 0));
}

Widget _buildErrorState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: screenWidth * 0.15,
          color: Colors.red[400],
        ),
        SizedBox(height: defaultPadding),
        Text(
          'Something went wrong',
          style: TextStyle(
            fontSize: headingSize,
            color: Colors.red[700],
          ),
        ),
        SizedBox(height: smallPadding),
        Text(
          message,
          style: TextStyle(
            fontSize: bodyTextSize,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300));
}



















// Add this to the _WasteDealersListPageState class

void _showDetailsDialog(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildDialogHeader(data),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(data),
                        // _buildBusinessInfoSection(data),
                        // _buildOperationsSection(data),
                        // _buildWasteSection(data),
                        // _buildSupportAndSafetySection(data),
                        // _buildFeedbackSection(data),
                        _buildMetadataSection(data),
                      ].animate(interval: const Duration(milliseconds: 100))
                       .fadeIn(duration: const Duration(milliseconds: 300))
                       .slideY(begin: 0.2, end: 0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate()
       .fadeIn(duration: const Duration(milliseconds: 300))
   .scale(begin: const Offset(0.9, 0));
    },
  );
}

Widget _buildDialogHeader(Map<String, dynamic> data) {
  final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>;
  final basicInfo = data['basicInfo'] as Map<String, dynamic>;

  return Container(
    padding: EdgeInsets.all(defaultPadding),
    decoration: const BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        SizedBox(width: defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                practitionerInfo['name'] ?? 'N/A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${basicInfo['district'] ?? 'N/A'} - ${basicInfo['ward'] ?? 'N/A'}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: smallTextSize,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

// Widget _buildBasicInfoSection(Map<String, dynamic> data) {
//   final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>;
//   final basicInfo = data['basicInfo'] as Map<String, dynamic>;
//   final operationalStatus = data['operationalStatus'] as Map<String, dynamic>;


//   // Safely access coordinates
//   final coordinates = basicInfo['coordinates'] as Map<String, dynamic>?;
//   final latitude = coordinates?['latitude'];
//   final longitude = coordinates?['longitude'];

//   return _buildInfoSection(
//     title: 'Basic Information',
//     icon: Icons.info_outline,
//     children: [
//       _buildDetailRow('Category', practitionerInfo['category'] ?? 'N/A'),
//       _buildDetailRow('Mobile', practitionerInfo['mobile'] ?? 'N/A'),
//       _buildDetailRow('Email', practitionerInfo['email'] ?? 'N/A'),
//       _buildDetailRow(
//         'Status', 
//         operationalStatus['status'] ?? 'N/A',
//         isStatus: true,
//       ),


//             // if (operationalStatus['status']?['documentPhoto'] != null)
//         // _buildImageRow('Business License', data['operationalStatus']?['documentPhoto']),


//       _buildDetailRow('Region', basicInfo['region'] ?? 'N/A'),
//       _buildDetailRow('District', basicInfo['district'] ?? 'N/A'),
//       _buildDetailRow('Division', basicInfo['division'] ?? 'N/A'),
//       _buildDetailRow('Ward', basicInfo['ward'] ?? 'N/A'),
//       _buildDetailRow('Street', basicInfo['street'] ?? 'N/A'),
//       // if ('coordinates' != null)
//       // _buildCoordinatesRow(
//       //     data['basicInfo']?['coordinates']?['latitude'],
//       //     data['basicInfo']?['coordinates']?['longitude'],
//       //   ),
//             if (coordinates != null) ...[
//         _buildDetailRow('Latitude', latitude?.toString() ?? 'N/A'),
//         _buildDetailRow('Longitude', longitude?.toString() ?? 'N/A'),
//       ],
//     ],
//   );
// }
Widget _buildBasicInfoSection(Map<String, dynamic> data) {
  final practitionerInfo = data['practitionerInfo'] as Map<String, dynamic>;
  final basicInfo = data['basicInfo'] as Map<String, dynamic>;
  final operationalStatus = data['operationalStatus'] as Map<String, dynamic>;
  
  // Safely access coordinates
  final coordinates = basicInfo['coordinates'] as Map<String, dynamic>?;
  final latitude = coordinates?['latitude'];
  final longitude = coordinates?['longitude'];

  return _buildInfoSection(
    title: 'Basic Information',
    icon: Icons.info_outline,
    children: [
      _buildDetailRow('Category', practitionerInfo['category'] ?? 'N/A'),
      _buildDetailRow('Mobile', practitionerInfo['mobile'] ?? 'N/A'),
      _buildDetailRow('Email', practitionerInfo['email'] ?? 'N/A'),
      _buildDetailRow(
        'Status', 
        operationalStatus['status'] ?? 'N/A',
        isStatus: true,
      ),
      _buildDetailRow('Region', basicInfo['region'] ?? 'N/A'),
      _buildDetailRow('District', basicInfo['district'] ?? 'N/A'),
      _buildDetailRow('Division', basicInfo['division'] ?? 'N/A'),
      _buildDetailRow('Ward', basicInfo['ward'] ?? 'N/A'),
      _buildDetailRow('Street', basicInfo['street'] ?? 'N/A'),
      if (coordinates != null) ...[
        _buildDetailRow('Latitude', latitude?.toString() ?? 'N/A'),
        _buildDetailRow('Longitude', longitude?.toString() ?? 'N/A'),
      ],
    ],
  );
}

Widget _buildImageRow(String label, String imageUrl) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF115937)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}

Widget _buildBusinessInfoSection(Map<String, dynamic> data) {
  final businessInfo = data['businessInfo'] as Map<String, dynamic>;

  return _buildInfoSection(
    title: 'Business Information',
    icon: Icons.business_center_outlined,
    children: [
      _buildDetailRow('Ownership Type', businessInfo['ownershipType'] ?? 'N/A'),
      if (businessInfo['ownershipType'] != 'Individual') ...[
        _buildDetailRow('Official Name', businessInfo['officialName'] ?? 'N/A'),
        _buildDetailRow('Contact Person', businessInfo['contactPerson'] ?? 'N/A'),
        _buildDetailRow('Business Address', businessInfo['address'] ?? 'N/A'),
        _buildDetailRow('Business Mobile', businessInfo['mobile'] ?? 'N/A'),
        _buildDetailRow('Business Email', businessInfo['email'] ?? 'N/A'),
      ],
    ],
  );
}

Widget _buildOperationsSection(Map<String, dynamic> data) {
  final capacity = data['capacity'] as Map<String, dynamic>;

  return _buildInfoSection(
    title: 'Operations',
    icon: Icons.settings_outlined,
    children: [


      _buildCapacityIndicator(capacity['weeklyCapacity'] ?? 0),
      SizedBox(height: defaultPadding),
      if (capacity['mainBuyer'] != null)
        _buildDetailRow('Main Buyer', capacity['mainBuyer']),
    ],
  );
}

Widget _buildWasteSection(Map<String, dynamic> data) {
  return _buildInfoSection(
    title: 'Waste Information',
    icon: Icons.delete_outline,
    children: [
      _buildWasteTypesList(data['wasteTypes'] ?? []),
      SizedBox(height: defaultPadding),
      _buildWasteSourcesList(data['wasteSources'] ?? []),
    ],
  );
}

Widget _buildSupportAndSafetySection(Map<String, dynamic> data) {
  final support = data['support'] as Map<String, dynamic>;
  final safety = data['safety'] as Map<String, dynamic>;

  return _buildInfoSection(
    title: 'Support & Safety',
    icon: Icons.health_and_safety_outlined,
    children: [
      _buildSupportStatus(support),
      SizedBox(height: defaultPadding),
      _buildSafetyMeasures(safety),
    ],
  );
}

Widget _buildFeedbackSection(Map<String, dynamic> data) {
  final feedback = data['feedback'] as Map<String, dynamic>;

  return _buildInfoSection(
    title: 'Feedback',
    icon: Icons.feedback_outlined,
    children: [
      _buildSuccessStories(feedback['successStories'] ?? []),
      SizedBox(height: defaultPadding),
      _buildChallenges(feedback['challenges'] ?? []),
    ],
  );
}

Widget _buildMetadataSection(Map<String, dynamic> data) {
  final metadata = data['metadata'] as Map<String, dynamic>;
  final collector = data['dataCollector'] as Map<String, dynamic>;

  return _buildInfoSection(
    title: 'Additional Information',
    icon: Icons.more_horiz,
    children: [
      _buildDetailRow(
        'Created At',
        _formatTimestamp(metadata['createdAt']),
      ),
      _buildDetailRow(
        'Last Updated',
        _formatTimestamp(metadata['updatedAt']),
      ),
      _buildDetailRow(
        'Data Collector',
        collector['name'] ?? 'N/A',
      ),
    ],
  );
}

// Helper widgets for the sections
Widget _buildInfoSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: defaultPadding),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(smallPadding),
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
              SizedBox(width: smallPadding),
              Text(
                title,
                style: TextStyle(
                  fontSize: bodyTextSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Column(children: children),
        ),
      ],
    ),
  );
}














Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
  return Padding(
    padding: EdgeInsets.only(bottom: smallPadding),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: screenWidth * 0.2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: smallTextSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: defaultPadding),
        Expanded(
          child: isStatus
              ? _buildStatusBadge(value)
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.grey[800],
                  ),
                ),
        ),
      ],
    ),
  );
}

Widget _buildCoordinatesRow(double? latitude, double? longitude) {
  return Container(
    margin: EdgeInsets.only(top: smallPadding),
    padding: EdgeInsets.all(defaultPadding),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[100]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.blue[700],
              size: screenWidth * 0.05,
            ),
            SizedBox(width: smallPadding),
            Text(
              'Location Coordinates',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: smallPadding),
        Row(
          children: [
            _buildCoordinateItem('Latitude', latitude),
            SizedBox(width: defaultPadding),
            _buildCoordinateItem('Longitude', longitude),
          ],
        ),
      ],
    ),
  );
}

Widget _buildCoordinateItem(String label, double? value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: smallTextSize,
            color: Colors.blue[700],
          ),
        ),
        Text(
          value?.toStringAsFixed(6) ?? 'N/A',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
            color: Colors.blue[900],
          ),
        ),
      ],
    ),
  );
}

Widget _buildCapacityIndicator(num weeklyCapacity) {
  final percentage = (weeklyCapacity / 50) * 100; // Assuming 50 tonnes is max
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Weekly Capacity',
            style: TextStyle(
              fontSize: smallTextSize,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '${weeklyCapacity.toString()} tonnes/week',
            style: TextStyle(
              fontSize: bodyTextSize,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
      SizedBox(height: smallPadding),
      Stack(
        children: [
          Container(
            height: screenHeight * 0.025,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          FractionallySizedBox(
            widthFactor: percentage / 100,
            child: Container(
              height: screenHeight * 0.025,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    secondaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildWasteTypesList(List<dynamic> types) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Waste Types Handled',
        style: TextStyle(
          fontSize: smallTextSize,
          color: Colors.grey[600],
        ),
      ),
      SizedBox(height: smallPadding),
      Wrap(
        spacing: smallPadding,
        runSpacing: smallPadding,
        children: types.map((type) => Container(
          padding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: screenWidth * 0.04,
                color: primaryColor,
              ),
              SizedBox(width: smallPadding / 2),
              Text(
                type.toString(),
                style: TextStyle(
                  fontSize: smallTextSize,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    ],
  );
}

Widget _buildWasteSourcesList(List<dynamic> sources) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Waste Sources',
        style: TextStyle(
          fontSize: smallTextSize,
          color: Colors.grey[600],
        ),
      ),
      SizedBox(height: smallPadding),
      Column(
        children: sources.map((source) => Container(
          margin: EdgeInsets.only(bottom: smallPadding),
          padding: EdgeInsets.all(smallPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(smallPadding),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.source_outlined,
                  size: screenWidth * 0.04,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(width: smallPadding),
              Expanded(
                child: Text(
                  source.toString(),
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    ],
  );
}


Widget _buildSupportStatus(Map<String, dynamic> support) {
  final hasSupport = support['hasSupport'] ?? false;
  final types = support['types'] as List<dynamic>? ?? [];
  final needed = support['needed'] as List<dynamic>? ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Current Support Status
      Container(
        padding: EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: hasSupport ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasSupport ? Colors.green[200]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSupport ? Icons.check_circle : Icons.cancel_outlined,
              color: hasSupport ? Colors.green[700] : Colors.grey[600],
              size: screenWidth * 0.06,
            ),
            SizedBox(width: defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSupport ? 'Has Government Support' : 'No Government Support',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.bold,
                      color: hasSupport ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                  if (hasSupport && types.isNotEmpty) ...[
                    SizedBox(height: smallPadding),
                    Wrap(
                      spacing: smallPadding,
                      runSpacing: smallPadding,
                      children: types.map((type) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: smallPadding,
                          vertical: smallPadding / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          type.toString(),
                          style: TextStyle(
                            fontSize: smallTextSize,
                            color: Colors.green[700],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Support Needed
      if (needed.isNotEmpty) ...[
        SizedBox(height: defaultPadding),
        Text(
          'Support Needed',
          style: TextStyle(
            fontSize: smallTextSize,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: smallPadding),
        ...needed.map((item) => Container(
          margin: EdgeInsets.only(bottom: smallPadding),
          padding: EdgeInsets.all(smallPadding),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange[700],
                size: screenWidth * 0.045,
              ),
              SizedBox(width: smallPadding),
              Expanded(
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ],
  );
}

Widget _buildSafetyMeasures(Map<String, dynamic> safety) {
  final hasMeasures = safety['hasMeasures'] ?? false;
  final measures = safety['measures'] as List<dynamic>? ?? [];

  return Container(
    padding: EdgeInsets.all(defaultPadding),
    decoration: BoxDecoration(
      color: hasMeasures ? Colors.blue[50] : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasMeasures ? Colors.blue[200]! : Colors.grey[300]!,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasMeasures ? Icons.verified_outlined : Icons.warning_outlined,
              color: hasMeasures ? Colors.blue[700] : Colors.grey[600],
              size: screenWidth * 0.06,
            ),
            SizedBox(width: defaultPadding),
            Expanded(
              child: Text(
                hasMeasures ? 'Safety Measures in Place' : 'No Safety Measures',
                style: TextStyle(
                  fontSize: bodyTextSize,
                  fontWeight: FontWeight.bold,
                  color: hasMeasures ? Colors.blue[700] : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        if (hasMeasures && measures.isNotEmpty) ...[
          SizedBox(height: defaultPadding),
          ...measures.map((measure) => Padding(
            padding: EdgeInsets.only(bottom: smallPadding),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue[700],
                  size: screenWidth * 0.045,
                ),
                SizedBox(width: smallPadding),
                Expanded(
                  child: Text(
                    measure.toString(),
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    ),
  );
}

Widget _buildSuccessStories(List<dynamic> stories) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Success Stories',
        style: TextStyle(
          fontSize: smallTextSize,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: smallPadding),
      ...stories.map((story) => Container(
        margin: EdgeInsets.only(bottom: smallPadding),
        padding: EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.stars_outlined,
              color: Colors.green[700],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Expanded(
              child: Text(
                story.toString(),
                style: TextStyle(
                  fontSize: bodyTextSize,
                  color: Colors.green[900],
                ),
              ),
            ),
          ],
        ),
      )),
    ],
  );
}

Widget _buildChallenges(List<dynamic> challenges) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Challenges',
        style: TextStyle(
          fontSize: smallTextSize,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: smallPadding),
      ...challenges.map((challenge) => Container(
        margin: EdgeInsets.only(bottom: smallPadding),
        padding: EdgeInsets.all(defaultPadding),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.red[700],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Expanded(
              child: Text(
                challenge.toString(),
                style: TextStyle(
                  fontSize: bodyTextSize,
                  color: Colors.red[900],
                ),
              ),
            ),
          ],
        ),
      )),
    ],
  );
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

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate());
  }
  return 'N/A';
}
}