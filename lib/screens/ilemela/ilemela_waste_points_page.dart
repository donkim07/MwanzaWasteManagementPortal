
import 'package:firebase_auth/firebase_auth.dart';

import 'agent.dart';
import 'driver.dart';
import 'ilemela_map_page.dart';
// import 'stakeholders_page.dart';
// import 'waste_aggregators_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_recyclers_page.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer_non.dart';
import 'stakeholders_page.dart';
import 'waste_reportingCollection.dart';
// import 'waste_pointsCollection_page.dart';

class WastePointsListPage extends StatefulWidget {
  final User? user;

  const WastePointsListPage({this.user});

  @override
  _WastePointsListPageState createState() => _WastePointsListPageState();
}

class _WastePointsListPageState extends State<WastePointsListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // bool _isAdmin = false;
  // String _firstName = '';
      String? _userRole; // Add this to track user role


  int _selectedIndex = 1;
  final bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                    hintText: 'Search waste points...',
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
              'Waste Collection Points',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            // actions: [
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 8),
            //     child: IconButton(
            //       icon: Container(
            //         padding: const EdgeInsets.all(8),
            //         decoration: BoxDecoration(
            //           color: Colors.white.withOpacity(0.2),
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //         child: const Icon(Icons.add, color: Colors.white),
            //       ),
            //       onPressed: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => WasteCollectionPage(user: widget.user),
            //           ),
            //         );
            //       },
            //     ),
            //   ),
            // ],
          ),
        ],
        body: Container(
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('ilemelaWasteCollectionPoints').snapshots(),
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
                        final collectorName = data['dataCollector']?['name']?.toString().toLowerCase() ?? '';
                        final district = data['location']?['district']?.toString().toLowerCase() ?? '';
                        final ward = data['location']?['ward']?.toString().toLowerCase() ?? '';
                        
                        return collectorName.contains(_searchQuery.toLowerCase()) ||
                              district.contains(_searchQuery.toLowerCase()) ||
                              ward.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    if (documents.isEmpty) {
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
                              'No waste collection points found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final data = documents[index].data() as Map<String, dynamic>;
                        return _buildWastePointCard(data, index)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 50))
                            .slideX(begin: 0.2, end: 0);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildWastePointCard(Map<String, dynamic> data, int index) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: () => _showDetailsDialog(data),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Index container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF115937).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF115937),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Data collector and location info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['dataCollector']?['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['location']?['district'] ?? 'N/A'} - ${data['location']?['ward'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // View details button
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  color: const Color(0xFF115937),
                  onPressed: () => _showDetailsDialog(data),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: data['status'] == 'Legal'
                    ? const Color(0xFF115937).withOpacity(0.1)
                    : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['status'] ?? 'N/A',
                style: TextStyle(
                  color: data['status'] == 'Legal'
                      ? const Color(0xFF115937)
                      : Colors.red[900],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showDetailsDialog(Map<String, dynamic> data) {
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF115937),
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
                        Icons.location_on_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Collection Point Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['location']?['district'] ?? 'N/A'} - ${data['location']?['ward'] ?? 'N/A'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
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
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        title: 'Basic Information',
                        icon: Icons.info_outline,
                        children: [
                          _buildDetailRow(
                            'Collection Status',
                            data['status']?.toString() ?? 'N/A',
                            isStatus: true,
                          ),
                          _buildDetailRow(
                            'Data Collector',
                            data['dataCollector']?['name']?.toString() ?? 'N/A',
                          ),
                          _buildDetailRow(
                            'Date Added',
                            _formatDate(data['date']),
                          ),
                        ],
                      ),

                      _buildInfoSection(
                        title: 'Location Details',
                        icon: Icons.location_on_outlined,
                        children: [
                          _buildDetailRow('Region', data['location']?['region']?.toString() ?? 'N/A'),
                          _buildDetailRow('District', data['location']?['district']?.toString() ?? 'N/A'),
                          _buildDetailRow('Ward', data['location']?['ward']?.toString() ?? 'N/A'),
                          _buildDetailRow('Street', data['location']?['street']?.toString() ?? 'N/A'),
                          _buildCoordinatesRow(
                            data['location']?['coordinates']?['latitude'] as double?,
                            data['location']?['coordinates']?['longitude'] as double?,
                          ),
                        ],
                      ),

                      if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                        _buildInfoSection(
                          title: 'Collection Image',
                          icon: Icons.image_outlined,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['imageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[100],
                                      child: const Center(
                                        child: Text('Image not available'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                      if (data['catchmentAreas'] != null)
                        _buildInfoSection(
                          title: 'Catchment Info',
                          icon: Icons.people_outline,
                          children: [
                            _buildDetailRow(
                              'Catchment Ward',
                              data['catchmentAreas']?['catchmentWard']?.toString() ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Ward Population',
                              '${data['catchmentAreas']?['wardPopulation']?.toString() ?? 'N/A'} people',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildInfoSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF115937).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF115937),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115937),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: value == 'Legal'
                  ? const Color(0xFF115937).withOpacity(0.1)
                  : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Legal'
                    ? const Color(0xFF115937)
                    : Colors.red[900],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
      ],
    ),
  );
}

Widget _buildCoordinatesRow(double? latitude, double? longitude) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[100]!),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Lat: ${latitude?.toStringAsFixed(6) ?? 'N/A'}\nLong: ${longitude?.toStringAsFixed(6) ?? 'N/A'}',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeatureRow(String label, bool value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF115937).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: value ? const Color(0xFF115937) : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                value ? 'Yes' : 'No',
                style: TextStyle(
                  color: value ? const Color(0xFF115937) : Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget _buildCoordinatesRow(double? latitude, double? longitude) {
//   return Container(
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       color: Colors.blue[50],
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.blue[100]!),
//     ),
//     child: Row(
//       children: [
//         const Icon(Icons.location_on, color: Colors.blue, size: 20),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             'Lat: ${latitude?.toStringAsFixed(6) ?? 'N/A'}\nLong: ${longitude?.toStringAsFixed(6) ?? 'N/A'}',
//             style: const TextStyle(
//               color: Colors.blue,
//               fontSize: 14,
//               height: 1.5,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

Widget _buildWasteTypesChart(Map<String, dynamic> wasteTypes) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: wasteTypes.entries.map((entry) {
      final percentage = entry.value as num;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Separate row for the label and percentage
            Row(
              children: [
                Expanded( // Allow type name to wrap if needed
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  HSLColor.fromAHSL(
                    1.0,
                    120 * (percentage / 100),
                    0.6,
                    0.5,
                  ).toColor(),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

String _formatDate(dynamic date) {
  if (date is Timestamp) {
    return DateFormat('MMM dd, yyyy').format(date.toDate());
  }
  return 'N/A';
}

String _formatList(List<dynamic> list) {
  if (list.isEmpty) return 'None';
  return list.join(', ');
}




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



}









