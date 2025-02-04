// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:data_table_2/data_table_2.dart';

// import '../../login_page.dart';
import 'admin_management.dart';
import 'ilemela_agent.dart';
import 'ilemela_WHO_waste_reportMap.dart';
import 'ilemela_map_page.dart';
// import 'stakeholders_page.dart';
// import 'waste_aggregators_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_reportMap.dart';
import 'ilemela_waste_reportingCollection.dart';
import 'ilemela_waste_recyclersCollection_page.dart';
import 'ilemela_waste_recyclers_page.dart';
import 'ilemela_waste_points_page.dart';

// class WastePointsListPage extends StatefulWidget {
//   final User? user;

//   const WastePointsListPage({Key? key, required this.user}) : super(key: key);

//   @override
//   _WastePointsListPageState createState() => _WastePointsListPageState();
// }

// class _WastePointsListPageState extends State<WastePointsListPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isAdmin = false;
//   String _firstName = '';
//   int _selectedIndex = 1;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     try {
//       if (widget.user != null) {
//         final userDoc = await _firestore
//             .collection('users')
//             .doc(widget.user!.uid)
//             .get();
//         if (userDoc.exists && mounted) {
//           setState(() {
//             _firstName = userDoc.data()?['firstName'] ?? '';
//             _isAdmin = userDoc.data()?['role'] == 'admin';
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading user data: $e')),
//         );
//       }
//     }
//   }


//  Widget _buildDataTable(List<DocumentSnapshot> documents) {
//     return Container(
//       width: MediaQuery.of(context).size.width,
//       child: Theme(
//         data: Theme.of(context).copyWith(
//           dataTableTheme: const DataTableThemeData(
//             headingTextStyle: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         child: PaginatedDataTable2(
//           columns: const [
//             DataColumn2(
//               label: Text('SN.'),
//               size: ColumnSize.S,
//             ),
//             DataColumn2(
//               label: Text('Data Collector'),
//               size: ColumnSize.L,
//             ),
//             DataColumn2(
//               label: Text('District'),
//               size: ColumnSize.M,
//             ),
//             DataColumn2(
//               label: Text('Ward'),
//               size: ColumnSize.M,
//             ),
//             DataColumn2(
//               label: Text('Street'),
//               size: ColumnSize.M,
//             ),
//             DataColumn2(
//               label: Text('Status'),
//               size: ColumnSize.M,
//             ),
//             DataColumn2(
//               label: Text('Actions'),
//               size: ColumnSize.S,
//             ),
//           ],
//           source: _WasteDataSource(context, documents),
//           rowsPerPage: 10,
//           minWidth: 800,
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawer() {
//     return Drawer(
//       child: Column(
//         children: [
//           UserAccountsDrawerHeader(
//             accountName: Text('Hi, $_firstName!'),
//             accountEmail: Text(_isAdmin ? 'Admin' : 'Employee'),
//             decoration: const BoxDecoration(
//               color: Color(0xFF90EE90),
//             ),
//           ),
//           Expanded(
//             child: ListView(
//               children: [
//                 _buildDrawerItem(
//                   icon: Icons.map,
//                   text: 'Map Page',
//                   index: 0,
//                 ),
//                 _buildDrawerItem(
//                   icon: Icons.location_on,
//                   text: 'Waste Points',
//                   index: 1,
//                 ),
//                 _buildDrawerItem(
//                   icon: Icons.business,
//                   text: 'Waste Dealers',
//                   index: 2,
//                 ),
//                 _buildDrawerItem(
//                   icon: Icons.store,
//                   text: 'Waste Aggregators',
//                   index: 3,
//                 ),
//                 _buildDrawerItem(
//                   icon: Icons.recycling,
//                   text: 'Waste Recyclers',
//                   index: 4,
//                 ),
//                 _buildDrawerItem(
//                   icon: Icons.people,
//                   text: 'Stakeholders',
//                   index: 5,
//                 ),
//                 if (_isAdmin)
//                   _buildDrawerItem(
//                     icon: Icons.manage_accounts,
//                     text: 'Users',
//                     index: 6,
//                   ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: ElevatedButton.icon(
//               onPressed: () async {
//                 await _auth.signOut();
//                 Navigator.pushReplacement(
//                   context,
//                   MaterialPageRoute(builder: (context) => const LoginPage()),
//                 );
//               },
//               icon: const Icon(Icons.logout),
//               label: const Text("Logout"),
//               style: ElevatedButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.redAccent,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDrawerItem({
//     required IconData icon,
//     required String text,
//     required int index,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: _selectedIndex == index
//             ? const Color(0xFF90EE90)
//             : Colors.grey[600],
//       ),
//       title: Text(
//         text,
//         style: TextStyle(
//           color: _selectedIndex == index
//               ? const Color(0xFF90EE90)
//               : Colors.grey[600],
//           fontWeight:
//               _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//       selected: _selectedIndex == index,
//       onTap: () => _onItemTapped(index),
//     );
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     Navigator.of(context).pop();
    
//     Widget page;
//     switch (index) {
//       case 0:
//         page = MapPage(user: widget.user);
//         break;
//       case 1:
//         page = WastePointsListPage(user: widget.user);
//         break;
//       case 2:
//         page = WasteDealersListPage(user: widget.user);
//         break;
//       case 3:
//         page = WasteAggregatorsPage();
//         break;
//       case 4:
//         page = WasteRecyclersListPage(user: widget.user);
//         break;
//       case 5:
//         page = StakeholdersPage();
//         break;
//       case 6:
//         page = UsersManagementPage(user: widget.user);
//         break;
//       default:
//         page = MapPage(user: widget.user);
//     }
    
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => page),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Waste Collection Points'),
//         backgroundColor: const Color(0xFF90EE90),
//       ),
//       drawer: _buildDrawer(),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Container(
//               width: double.infinity,
//               height: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     const Color(0xFF90EE90).withOpacity(0.2),
//                     Colors.white,
//                   ],
//                 ),
//               ), 
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => WasteCollectionPage(user: widget.user
                                
//                               ),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.add),
//                         label: const Text('Add New'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF90EE90),
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 16,
//                           ),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                     child: StreamBuilder<QuerySnapshot>(
//                       stream: _firestore
//                           .collection('ilemelaWasteCollectionPoints')
//                           .snapshots(),
//                       builder: (context, snapshot) {
//                         if (snapshot.hasError) {
//                           return Center(
//                             child: Text('Error: ${snapshot.error}'),
//                           );
//                         }

//                         if (!snapshot.hasData) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }

//                         final documents = snapshot.data!.docs;
//                         if (documents.isEmpty) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(
//                                   Icons.warning_amber_rounded,
//                                   size: 64,
//                                   color: Colors.grey,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   'No waste collection points found',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }
//                         return Card(
//                           margin: const EdgeInsets.all(16),
//                           elevation: 4,
//                           child: _buildDataTable(documents),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }










// class _WasteDataSource extends DataTableSource {
//   final BuildContext context;
//   final List<DocumentSnapshot> _documents;

//   _WasteDataSource(this.context, this._documents);

//   void _showDetailsDialog(Map<String, dynamic> data) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.8,
//             height: MediaQuery.of(context).size.height * 0.8,
//             padding: EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: double.infinity,
//                   child: Row(
                  
//                   children: [
//                   Expanded(

//                   child: Text(
//                       'Waste Collection Point Details',
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                           overflow: TextOverflow.ellipsis, // Handle potential overflow
//                         ),
//                       ),
//                     IconButton(
//                         icon: Icon(Icons.close),
//                         onPressed: () => Navigator.of(context).pop(),
//                         padding: EdgeInsets.zero,
//                         constraints: BoxConstraints(),
//                         splashRadius: 24,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Divider(height: 20),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildSection(
//                           'Basic Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Date', _formatDate(data['date'])),
//                               _buildDetailRow('Data Collector', data['dataCollector']?['name'] ?? 'N/A'),
//                               _buildDetailRow('Status', data['status'] ?? 'N/A', isStatus: true),
//                             ],
//                           ),
//                         ),
                        
//                         _buildSection(
//                           'Location Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Region', data['location']?['region'] ?? 'N/A'),
//                               _buildDetailRow('District', data['location']?['district'] ?? 'N/A'),
//                               _buildDetailRow('Division', data['location']?['division'] ?? 'N/A'),
//                               _buildDetailRow('Ward', data['location']?['ward'] ?? 'N/A'),
//                               _buildDetailRow('Street', data['location']?['street'] ?? 'N/A'),
//                               _buildDetailRow('Coordinates', 
//                                 'Lat: ${data['location']?['coordinates']?['latitude'] ?? 'N/A'}, '
//                                 'Long: ${data['location']?['coordinates']?['longitude'] ?? 'N/A'}'
//                               ),
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Collection Point Characteristics',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Location Type', data['locationType'] ?? 'N/A'),
//                               _buildDetailRow('Accessible', 
//                                 data['accessibility']?['isAccessible'] == true ? 'Yes' : 'No'
//                               ),
//                               if (data['accessibility']?['isAccessible'] == false)
//                                 _buildDetailRow('Obstacles', 
//                                   _formatList(data['accessibility']?['obstacles'] ?? [])
//                                 ),
//                               _buildDetailRow('Capacity (Tonnages)', 
//                                 '${data['capacity']?.toString() ?? 'N/A'}'
//                               ),
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Waste Types',
//                           _buildWasteTypesTable(data['wasteTypes'] ?? {}),
//                         ),

//                         _buildSection(
//                           'Segregation Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Has Segregation Facilities',
//                                 data['segregation']?['hasSegregationFacilities'] == true ? 'Yes' : 'No'
//                               ),
//                               if (data['segregation']?['hasSegregationFacilities'] == true) ...[
//                                 _buildDetailRow('Segregated Types',
//                                   _formatList(data['segregation']?['segregatedTypes'] ?? [])
//                                 ),
//                                 _buildDetailRow('Facilities',
//                                   _formatList(data['segregation']?['facilities'] ?? [])
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Infrastructure',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Has Demarcation',
//                                 data['infrastructure']?['hasDemarcation'] == true ? 'Yes' : 'No'
//                               ),
//                               _buildDetailRow('Has Sorting Practice',
//                                 data['infrastructure']?['hasSortingPractice'] == true ? 'Yes' : 'No'
//                               ),
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Attendant Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Has Attendant',
//                                 data['attendant']?['hasAttendant'] == true ? 'Yes' : 'No'
//                               ),
//                               if (data['attendant']?['hasAttendant'] == true) ...[
//                                 _buildDetailRow('Is Trained',
//                                   data['attendant']?['isTrained'] == true ? 'Yes' : 'No'
//                                 ),
//                                 _buildDetailRow('Has PPE',
//                                   data['attendant']?['hasPPE'] == true ? 'Yes' : 'No'
//                                 ),
//                                 if (data['attendant']?['hasPPE'] == true)
//                                   _buildDetailRow('PPE Types',
//                                     _formatList(data['attendant']?['ppeTypes'] ?? [])
//                                   ),
//                               ],
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Disposal Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Distance to Disposal (KM)',
//                                 '${data['disposal']?['distance']?.toString() ?? 'N/A'}'
//                               ),
//                               _buildDetailRow('Disposal Location',
//                                 'District: ${data['disposal']?['location']?['district'] ?? 'N/A'}\n'
//                                 'Ward: ${data['disposal']?['location']?['ward'] ?? 'N/A'}\n'
//                                 'Street: ${data['disposal']?['location']?['street'] ?? 'N/A'}'
//                               ),
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Transport Information',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Transport Available',
//                                 data['disposal']?['transport']?['available'] == true ? 'Yes' : 'No'
//                               ),
//                               if (data['disposal']?['transport']?['available'] == true) ...[
//                                 _buildDetailRow('Frequency', 
//                                   data['disposal']?['transport']?['frequency'] ?? 'N/A'
//                                 ),
//                                 _buildDetailRow('Responsible', 
//                                   data['disposal']?['transport']?['responsible'] ?? 'N/A'
//                                 ),
//                                 _buildDetailRow('Type', 
//                                   data['disposal']?['transport']?['type'] ?? 'N/A'
//                                 ),
//                                 _buildDetailRow('Meets Needs',
//                                   data['disposal']?['transport']?['meetsNeeds'] == true ? 'Yes' : 'No'
//                                 ),
//                               ],
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Neighbor Feedback',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Opinions',
//                                 _formatList(data['feedback']?['neighborOpinions'] ?? [])
//                               ),
//                             ],
//                           ),
//                         ),

//                         _buildSection(
//                           'Waste Sources',
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildDetailRow('Sources',
//                                 _formatList(data['wasteSources']?['sources'] ?? [])
//                               ),
//                               if (data['wasteSources']?['sources']?.contains('Institutions') == true)
//                                 _buildDetailRow('Institution Type',
//                                   data['wasteSources']?['institutionType'] ?? 'N/A'
//                                 ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildSection(String title, Widget content) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF90EE90),
//             ),
//           ),
//           SizedBox(height: 8),
//           content,
//           Divider(height: 24),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 3,
//             child: isStatus ? 
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: value == 'Legal' 
//                       ? Color(0xFF90EE90).withOpacity(0.2)
//                       : Color(0xFFFFCDD2).withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: value == 'Legal'
//                         ? Color(0xFF90EE90)
//                         : Colors.red.shade300,
//                     width: 1,
//                   ),
//                 ),
//                 child: Text(
//                   value,
//                   style: TextStyle(
//                     color: value == 'Legal'
//                         ? Color(0xFF2E7D32)
//                         : Colors.red.shade700,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 13,
//                   ),
//                 ),
//               )
//             : Text(
//                 value,
//                 style: TextStyle(
//                   color: Colors.black87,
//                 ),
//               ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildWasteTypesTable(Map<String, dynamic> wasteTypes) {
//     return Table(
//       columnWidths: {
//         0: FlexColumnWidth(2),
//         1: FlexColumnWidth(1),
//       },
//       children: wasteTypes.entries.map((entry) {
//         return TableRow(
//           children: [
//             Padding(
//               padding: EdgeInsets.symmetric(vertical: 4),
//               child: Text(entry.key),
//             ),
//             Padding(
//               padding: EdgeInsets.symmetric(vertical: 4),
//               child: Text('${entry.value}%'),
//             ),
//           ],
//         );
//       }).toList(),
//     );
//   }

//   String _formatDate(dynamic date) {
//     if (date is Timestamp) {
//       return DateFormat('yyyy-MM-dd').format(date.toDate());
//     }
//     return 'N/A';
//   }

//   String _formatList(List<dynamic> list) {
//     if (list.isEmpty) return 'None';
//     return list.join(', ');
//   }

//   @override
//   DataRow? getRow(int index) {
//     if (index >= _documents.length) return null;
    
//     final doc = _documents[index];
//     final data = doc.data() as Map<String, dynamic>;
//     final wasteTypes = data['wasteTypes'] as Map<String, dynamic>? ?? {};
    
//     final activeWasteTypes = wasteTypes.entries
//         .where((entry) => (entry.value as num) > 0)
//         .map((entry) => '${entry.key}: ${entry.value}%')
//         .join('\n');

//     return DataRow(
//       cells: [
//         DataCell(Text('${index + 1}')),
//         DataCell(Text(data['dataCollector']?['name'] ?? 'N/A')),
//         DataCell(Text(data['location']?['district'] ?? 'N/A')),
//         DataCell(Text(data['location']?['ward'] ?? 'N/A')),
//         DataCell(Text(data['location']?['street'] ?? 'N/A')),
// DataCell(
//   Container(
//     constraints: BoxConstraints(maxWidth: 100), // Add maximum width constraint
//     child: Container(
//       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
//       decoration: BoxDecoration(
//         color: data['status'] == 'Legal' 
//             ? Color(0xFF90EE90).withOpacity(0.2)
//             : Color(0xFFFFCDD2).withOpacity(0.2),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: data['status'] == 'Legal'
//               ? Color(0xFF90EE90)
//               : Colors.red.shade300,
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center, // Center the content
//         children: [
//           Flexible( // Added Flexible to handle text overflow
//             child: Text(
//               data['status'] ?? 'N/A',
//               style: TextStyle(
//                 color: data['status'] == 'Legal'
//                     ? Color(0xFF2E7D32)
//                     : Colors.red.shade700,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12, // Slightly smaller font
//               ),
//               overflow: TextOverflow.ellipsis, // Handle text overflow
//             ),
//           ),
//         ],
//       ),
//     ),
//   ),
// ),
//         DataCell(
//           IconButton(
//             icon: Icon(Icons.visibility, color: Color(0xFF90EE90)),
//             onPressed: () => _showDetailsDialog(data),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   bool get isRowCountApproximate => false;

//   @override
//   int get rowCount => _documents.length;

//   @override
//   int get selectedRowCount => 0;
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer.dart';
import 'ilemela_waste_pointsCollection_page.dart';
import 'ilemela_stakeholder_page.dart';

class WastePointsListPage extends StatefulWidget {
  final User? user;

  const WastePointsListPage({Key? key, required this.user}) : super(key: key);

  @override
  _WastePointsListPageState createState() => _WastePointsListPageState();
}

class _WastePointsListPageState extends State<WastePointsListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  String _firstName = '';
  int _selectedIndex = 1;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAgent = false;
  bool _isWardOfficer= false;
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
                        builder: (context) => WasteCollectionPage(user: widget.user),
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









