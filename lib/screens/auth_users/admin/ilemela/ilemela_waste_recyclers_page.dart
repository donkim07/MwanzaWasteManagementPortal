import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer.dart';

import '../../login_page.dart';
import 'admin_management.dart';
import 'ilemela_agent.dart';
import 'ilemela_WHO_waste_reportMap.dart';
import 'ilemela_map_page.dart';
// import 'stakeholders_page.dart';
// import 'waste_aggregators_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_points_page.dart';
import 'ilemela_waste_reportMap.dart';
import 'ilemela_waste_reportingCollection.dart';
import 'ilemela_waste_recyclersCollection_page.dart';
import 'ilemela_stakeholder_page.dart';

class WasteRecyclersListPage extends StatefulWidget {
  final User? user;

  const WasteRecyclersListPage({Key? key, required this.user}) : super(key: key);

  @override
  _WasteRecyclersListPageState createState() => _WasteRecyclersListPageState();
}




class _WasteRecyclersListPageState extends State<WasteRecyclersListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  String _firstName = '';
  int _selectedIndex = 4; // For waste recyclers tab
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAgent = false;
  bool _isWardOfficer= false;
  // Screen size utilities
  late double screenWidth;
  late double screenHeight;
  
  // Responsive dimensions
  late double defaultPadding;
  late double smallPadding;
  late double cardPadding;
  late double headingSize;
  late double subheadingSize;
  late double bodyTextSize;
  late double smallTextSize;
  static const primaryColor = Color(0xFF115937);


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
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search recycling centers...',
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
              'Recycling Centers',
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
                        builder: (context) => WasteRecyclingCenterForm(user: widget.user),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        body: Container(
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('recyclingCentersCollection')
                      .snapshots(),
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
                        final centerName = data['ownership']?['centerName']?.toString().toLowerCase() ?? '';
                        final contactPerson = data['ownership']?['contactPerson']?.toString().toLowerCase() ?? '';
                        final district = data['basicInfo']?['district']?.toString().toLowerCase() ?? '';
                        
                        return centerName.contains(_searchQuery.toLowerCase()) ||
                               contactPerson.contains(_searchQuery.toLowerCase()) ||
                               district.contains(_searchQuery.toLowerCase());
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
                              'No recycling centers found',
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
                        return _buildRecyclingCenterCard(data, index)
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














  Widget _buildRecyclingCenterCard(Map<String, dynamic> data, int index) {
     final size = MediaQuery.of(context).size;
  // final labelSize = size.width * 0.035;
  // final valueSize = size.width * 0.04;
  
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showDetailsDialog(data),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['ownership']?['centerName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['ownership']?['contactPerson'] ?? 'N/A'} - ${data['location']?['district'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    color: const Color(0xFF115937),
                    onPressed: () => _showDetailsDialog(data),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  // _buildStatusBadge(data['status']?['centerStatus'] ?? 'N/A'),
                  // SizedBox(width: size.width * 0.015),
                  // _buildTypeBadge(data['operations']?['recyclingType'] ?? 'N/A'),
                                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


// Helper method to get responsive text size
double getResponsiveTextSize(BuildContext context, {
  required double small,
  required double medium,
  required double large,
}) {
  final width = MediaQuery.of(context).size.width;
  if (width < 360) return small;
  if (width < 600) return medium;
  return large;
}
  Widget _buildTypeBadge(String type) {
     final size = MediaQuery.of(context).size;
  // final labelSize = size.width * 0.035;
  final valueSize = size.width * 0.04;
  
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size.height * 0.015, vertical: size.height * 0.015),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: Colors.blue[900],
          fontWeight: FontWeight.w500,
          fontSize: valueSize,
        ),
      ),
    );
  }







void _showDetailsDialog(Map<String, dynamic> data) {
  final size = MediaQuery.of(context).size;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.03,
        ),
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.9,
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
                padding: EdgeInsets.all(size.width * 0.05),
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
                        Icons.recycling,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['ownership']?['centerName'] ?? 'Recycling Center',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data['location']?['region'] ?? 'N/A'} - ${data['location']?['district'] ?? 'N/A'}',
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
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(size.width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(
                          title: 'Basic Information',
                          icon: Icons.info_outline,
                          children: [
                            // _buildStatusBadge(data['status']?['centerStatus'] ?? 'N/A'),
                            // const SizedBox(height: 16),
                            _buildDetailRow('Company Name', data['ownership']?['centerName'] ?? 'N/A'),
                            _buildDetailRow('Contact Person', data['ownership']?['contactPerson'] ?? 'N/A'),
                            _buildDetailRow('Title', data['ownership']?['title'] ?? 'N/A'),
                            _buildDetailRow('Mobile', data['ownership']?['mobileNumber'] ?? 'N/A'),
                            _buildDetailRow('Email', data['ownership']?['email'] ?? 'N/A'),
                            // _buildDetailRow('Ownership Type', data['ownership']?['type'] ?? 'N/A'),
                            // if (data['status']?['businessLicensePhoto'] != null)
                            //   _buildImageRow('Business License', data['status']?['businessLicensePhoto']),
                          ],
                        ).animate()
                         .fadeIn(duration: const Duration(milliseconds: 300))
                         .slideX(begin: -0.2, end: 0),

                        _buildInfoSection(
                          title: 'Location',
                          icon: Icons.location_on_outlined,
                          children: [
                            // _buildDetailRow('Ward', data['location']?['ward'] ?? 'N/A'),
                            // _buildDetailRow('Street', data['location']?['street'] ?? 'N/A'),
                            _buildCoordinatesRow(
                              data['location']?['coordinates']?['latitude'],
                              data['location']?['coordinates']?['longitude'],
                            ),
                          ],
                        ).animate()
                         .fadeIn(duration: const Duration(milliseconds: 400)),

                        // _buildInfoSection(
                        //   title: 'Operations',
                        //   icon: Icons.settings,
                        //   children: [
                            // _buildCapacityIndicator(data['operations']?['weeklyCapacity'] ?? 0),
                            // const SizedBox(height: 16),
                            // _buildDetailRow('Quantification Method', data['operations']?['quantificationMethod'] ?? 'N/A'),
                            // _buildDetailRow('Core Business', data['operations']?['coreBusiness'] ?? 'N/A'),
                            // _buildDetailRow('Recycling Type', data['operations']?['recyclingType'] ?? 'N/A'),
                            // _buildDetailRow('End Products', data['operations']?['endProducts'] ?? 'N/A'),
                            // _buildDetailRow('Product Market', data['operations']?['productMarket'] ?? 'N/A'),
                            // if (data['operations']?['productPhoto'] != null)
                            //   _buildImageRow('Product Photo', data['operations']?['productPhoto']),
                        //   ],
                        // ).animate()
                        //  .fadeIn(duration: const Duration(milliseconds: 500)),

                        _buildInfoSection(
                          title: 'Waste Types',
                          icon: Icons.delete_outline,
                          children: [
                            _buildWasteTypesList('Waste Types', data['wasteTypes']?['types'] ?? []),
                            const SizedBox(height: 16),
                            // _buildWasteTypesList('Waste Sources', data['wasteTypes']?['sources'] ?? []),
                          ],
                        ).animate()
                         .fadeIn(duration: const Duration(milliseconds: 600)),

                        // _buildInfoSection(
                        //   title: 'Support Information',
                        //   icon: Icons.support_agent,
                        //   children: [
                        //     _buildSupportStatus(data['support'] ?? {}),
                        //   ],
                        // ).animate()
                        //  .fadeIn(duration: const Duration(milliseconds: 700)),

                        // _buildInfoSection(
                        //   title: 'Safety Measures',
                        //   icon: Icons.health_and_safety_outlined,
                        //   children: [
                        //     _buildSafetyMeasures(data['safety'] ?? {}),
                        //   ],
                        // ).animate()
                        //  .fadeIn(duration: const Duration(milliseconds: 800)),

                        // _buildInfoSection(
                        //   title: 'Authorization',
                        //   icon: Icons.verified_outlined,
                        //   children: [
                        //     _buildAuthorizationDetails(data['authorization'] ?? {}),
                        //   ],
                        // ).animate()
                        //  .fadeIn(duration: const Duration(milliseconds: 900)),




































                          _buildInfoSection(
                            title: 'Raw Material Image',
                            icon: Icons.image_outlined,
                            children: [
                              if (data['recyclingData']?['rawMaterialImageUrl'] != null && data['rawMaterialImageUrl'].toString().isNotEmpty)
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
                                      data['recyclingData']?['rawMaterialImageUrl'],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: const Color(0xFF115937),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[100],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
_buildInfoSection(
                            title: 'End Product Image',
                            icon: Icons.image_outlined,
                            children: [
                              if (data['recyclingData']?['endProductImageUrl'] != null && data['endProductImageUrl'].toString().isNotEmpty)
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
                                      data['recyclingData']?['endProductImageUrl'],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: const Color(0xFF115937),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[100],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.broken_image_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),









































                        

                        _buildInfoSection(
                          title: 'Additional Information',
                          icon: Icons.more_horiz,
                          children: [
                            _buildDetailRow('Created At', _formatTimestamp(data['metadata']?['createdAt'])),
                            _buildDetailRow('Updated At', _formatTimestamp(data['metadata']?['updatedAt'])),
                            _buildDetailRow('Data Collector', data['dataCollector']?['name'] ?? 'N/A'),
                          ],
                        ).animate()
                         .fadeIn(duration: const Duration(milliseconds: 1000)),
                      ],
                    ),
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
  final size = MediaQuery.of(context).size;
  // Calculate responsive font sizes
  final titleSize = size.width * 0.04; // Responsive title size
  final iconSize = size.width * 0.05; // Responsive icon size
  
  return Container(
    margin: EdgeInsets.only(bottom: size.height * 0.03),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(size.width * 0.04),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.02),
                decoration: BoxDecoration(
                  color: const Color(0xFF115937).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.width * 0.02),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF115937),
                  size: iconSize,
                ),
              ),
              SizedBox(width: size.width * 0.03),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF115937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(children: children),
        ),
      ],
    ),
  );
}

Widget _buildStatusBadge(String status) {
  final bool isFormal = status.toLowerCase() == 'formal';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: isFormal ? Colors.green[50] : Colors.red[50],
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isFormal ? Colors.green[200]! : Colors.red[200]!,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFormal ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isFormal ? Colors.green[700] : Colors.red[700],
        ),
        const SizedBox(width: 8),
        Text(
          status,
          style: TextStyle(
            color: isFormal ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

Widget _buildWasteTypesList(String title, List<dynamic> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF115937).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.toString(),
            style: const TextStyle(
              color: Color(0xFF115937),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        )).toList(),
      ),
    ],
  );
}

Widget _buildSupportStatus(Map<String, dynamic> support) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Government Support
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: support['hasGovernmentSupport'] == true ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: support['hasGovernmentSupport'] == true ? Colors.green[200]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance,
              color: support['hasGovernmentSupport'] == true ? Colors.green[700] : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                support['hasGovernmentSupport'] == true 
                    ? 'Has Government Support' 
                    : 'No Government Support',
                style: TextStyle(
                  color: support['hasGovernmentSupport'] == true ? Colors.green[700] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Organization Support
      if (support['hasOrganizationSupport'] == true) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.business, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supporting Organization',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (support['organizationName'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  support['organizationName'],
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Support Types
      if ((support['supportTypes'] as List?)?.isNotEmpty ?? false) ...[
        const Text(
          'Types of Support',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (support['supportTypes'] as List).map((type) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Text(
              type.toString(),
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    ],
  );
}

Widget _buildSafetyMeasures(Map<String, dynamic> safety) {
  final hasMeasures = safety['hasSafetyMeasures'] ?? false;
  final measures = safety['measures'] as List<dynamic>? ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasMeasures ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasMeasures ? Colors.green[200]! : Colors.orange[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasMeasures ? Icons.verified : Icons.warning,
              color: hasMeasures ? Colors.green[700] : Colors.orange[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasMeasures ? 'Safety Measures Implemented' : 'No Safety Measures',
                style: TextStyle(
                  color: hasMeasures ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      if (hasMeasures && measures.isNotEmpty) ...[
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: measures.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green[700],
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(measures[index].toString()),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ],
  );
}
Widget _buildAuthorizationDetails(Map<String, dynamic> authorization) {
  final required = authorization['required'] ?? false;
  final permits = authorization['permits'] as List<dynamic>? ?? [];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: required ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: required ? Colors.blue[200]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              required ? Icons.verified_user : Icons.not_interested,
              color: required ? Colors.blue[700] : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                required ? 'Authorization Required' : 'No Authorization Required',
                style: TextStyle(
                  color: required ? Colors.blue[700] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      if (required && permits.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text(
          'Required Permits',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: permits.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.file_present, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      permits[index].toString(),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
      if (authorization['otherPermit'] != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Other Permits',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authorization['otherPermit'],
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

Widget _buildCapacityIndicator(num weeklyCapacity) {
  final size = MediaQuery.of(context).size;
  // Calculate responsive sizes
  final labelSize = size.width * 0.035; // Label font size
  final valueSize = size.width * 0.04; // Value font size
  final barHeight = size.height * 0.015; // Height of the progress bar
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Weekly Capacity',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: labelSize,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.03,
              vertical: size.height * 0.008,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF115937).withOpacity(0.1),
              borderRadius: BorderRadius.circular(size.width * 0.04),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weeklyCapacity.toString(),
                  style: TextStyle(
                    color: const Color(0xFF115937),
                    fontWeight: FontWeight.w600,
                    fontSize: valueSize,
                  ),
                ),
                SizedBox(width: size.width * 0.01),
                Text(
                  'Tonnes',
                  style: TextStyle(
                    color: const Color(0xFF115937),
                    fontWeight: FontWeight.w500,
                    fontSize: labelSize * 0.8, // Slightly smaller than the number
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: size.height * 0.015),
      Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(barHeight / 2),
        ),
        child: FractionallySizedBox(
          widthFactor: weeklyCapacity / 100, // Assuming max capacity is 100
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF115937),
                  const Color(0xFF115937).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
          ),
        ),
      ),
      // Optional: Add capacity scale
      // SizedBox(height: size.height * 0.01),
      // Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Text(
      //       '0',
      //       style: TextStyle(
      //         color: Colors.grey[600],
      //         fontSize: labelSize * 0.7,
      //       ),
      //     ),
      //     Text(
      //       'Max: 100 Tonnes',
      //       style: TextStyle(
      //         color: Colors.grey[600],
      //         fontSize: labelSize * 0.7,
      //       ),
      //     ),
      //   ],
      // ),
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

Widget _buildCoordinatesRow(double? latitude, double? longitude) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue[100]!),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            const Text(
              'Coordinates',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCoordinateItem('Latitude', latitude),
            Container(
              height: 30,
              width: 1,
              color: Colors.blue[200],
            ),
            _buildCoordinateItem('Longitude', longitude),
          ],
        ),
      ],
    ),
  );
}

Widget _buildCoordinateItem(String label, double? value) {
   final size = MediaQuery.of(context).size;
  final valueSize = size.width * 0.04;
  
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: valueSize,
        ),
      ),
      SizedBox(height: size.height * 0.005),
      Text(
        value?.toStringAsFixed(6) ?? 'N/A',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: valueSize,
        ),
      ),
    ],
  );
}

Widget _buildDetailRow(String label, String value) {
  final size = MediaQuery.of(context).size;
  final labelSize = size.width * 0.035;
  final valueSize = size.width * 0.04;
  
  return Padding(
    padding: EdgeInsets.only(bottom: size.height * 0.015),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: labelSize,
          ),
        ),
        SizedBox(height: size.height * 0.005),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: valueSize,
          ),
        ),
      ],
    ),
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

}





String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toDate());
  }
  return 'N/A';
}

String _formatList(List<dynamic>? list) {
  if (list == null || list.isEmpty) return 'None';
  return list.join(', ');
}