import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../../widgets/custom_drawer.dart';
import 'ilemela_map_page.dart';
import 'ilemela_waste_dealers_page.dart';
import 'ilemela_waste_points_page.dart';
import 'ilemela_waste_recyclers_page.dart';
import 'ilemela_stakeholder_page.dart';
import 'ilemela_waste_reportMap.dart';
import 'ilemela_waste_reportingCollection.dart';
import 'json.dart';




class UsersManagementPage extends StatefulWidget {
  final User? user;
  const UsersManagementPage({Key? key, required this.user}) : super(key: key);

  @override
  _UsersManagementPageState createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
 final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;
  String _firstName = '';
  int _selectedIndex = 6; 
  bool _isLoading = true;



  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = '';
  String _selectedDistrict = '';

  bool _isAgent = false;
  bool _isWardOfficer= false;

  // Add responsive sizing utilities
  late double screenWidth;
  late double screenHeight;
  late double defaultPadding;
  late double smallPadding;
  late double cardPadding;
  late double headingSize;
  late double bodyTextSize;
  late double smallTextSize;
  
  StateSetter? setDialogState;




// Add these variables in the _UsersManagementPageState class
String _selectedWard = '';
final Map<String, List<String>> districtsWards = {
  'Ilemela': [
    'Bugogwa', 'Buswelu', 'Buzuruga', 'Ibungilo', 'Ilemela', 
    'Kahama', 'Kawekamo', 'Kayenze', 'Kirumba', 'Kiseke', 
    'Kitangiri', 'Mecco', 'Nyakato', 'Nyamanoro', 'Nyamhongolo', 
    'Nyasaka', 'Pasiansi', 'Sangabuye', 'Shibula'
  ],
  'Mwanza City/Nyamagana': [
    'Buhongwa', 'Butimba', 'Igogo', 'Igoma', 'Isamilo', 
    'Kishili', 'Luchelele', 'Lwanhima', 'Mabatini', 'Mahina', 
    'Mbugani', 'Mhandu', 'Mikuyuni', 'Mirongo', 'Mkolani', 
    'Nyamagana', 'Nyegezi', 'Pamba'
  ],
};




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
                padding: EdgeInsets.all(defaultPadding),
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
                
              ),
            ),
            title: const Text(
              'User Management',
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
                  onPressed: _showAddUserDialog,
                ),
              ),
            ],
          ),
        ],
        body: Container(
          color: Colors.white,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              // : _buildUsersContent(),
              : _buildUsersList(),
          
        ),
      ),
    );
  }

Widget _buildUsersList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text('Error: ${snapshot.error}'),
        );
      }

      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final documents = snapshot.data!.docs;

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
                'No users found',
                style: TextStyle(
                  fontSize: headingSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.symmetric(vertical: defaultPadding),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          final data = doc.data() as Map<String, dynamic>;
          return _buildUserCard(doc, data, index);
        },
      );
    },
  );
}

Widget _buildUserCard(DocumentSnapshot doc, Map<String, dynamic> data, int index) {
  return Card(
    margin: EdgeInsets.only(
      left: defaultPadding,
      right: defaultPadding,
      bottom: defaultPadding,
    ),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showEditUserDialog(doc),
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar & Number
            Container(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                color: const Color(0xFF115937).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: headingSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF115937),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: defaultPadding),
            
            // User Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['firstName']} ${data['lastName']}',
                    style: TextStyle(
                      fontSize: bodyTextSize * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: smallPadding / 2),
                  Text(
                    data['email'] ?? '',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: smallPadding),
                  _buildRoleBadge(data['role'] ?? 'employee'),
                ],
              ),
            ),
            
            // Action Buttons
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.blue[700],
                    size: screenWidth * 0.055,
                  ),
                  onPressed: () => _showEditUserDialog(doc),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red[700],
                    size: screenWidth * 0.055,
                  ),
                  onPressed: () => _showDeleteConfirmation(doc.id),
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










  Widget _buildRoleBadge(String role) {
    final isAdmin = role.toLowerCase() == 'admin';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: smallPadding,
        vertical: smallPadding / 2,
      ),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isAdmin ? Colors.blue[700] : Colors.green[700],
          fontWeight: FontWeight.w500,
          fontSize: smallTextSize,
        ),
      ),
    );
  }


bool _validateForm({bool isEdit = false}) {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        (!isEdit && _passwordController.text.trim().isEmpty)) {
      _showSnackBar('Please fill in all fields', Colors.red);
      return false;
    }
    return true;
  }


// Update the _handleAddUser method to include district:
// Future<void> _handleAddUser() async {
//   if (!_validateForm()) return;
  
//   setState(() => _isLoading = true);
//   try {
//     final userCredential = await FirebaseAuth.instance
//         .createUserWithEmailAndPassword(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );

//     // Add user details to Firestore
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(userCredential.user!.uid)
//         .set({
//       'firstName': _firstNameController.text.trim(),
//       'lastName': _lastNameController.text.trim(),
//       'email': _emailController.text.trim().toLowerCase(),
//       'role': _selectedRole,
//       'district': _selectedRole.toLowerCase() == 'employee' ? _selectedDistrict : '', // Only save district for employees
//       'createdAt': Timestamp.now(),
//     });

//     if (mounted) {
//       Navigator.of(context).pop();
//       _showSnackBar('User added successfully', Colors.green);
//       _resetForm();
//     }
//   } catch (e) {
//     if (mounted) {
//       _showSnackBar('Error adding user: $e', Colors.red);
//     }
//   } finally {
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
// }
Future<void> _handleAddUser() async {
  if (!_validateForm()) return;
  
  setState(() => _isLoading = true);
  try {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Prepare the user data
    final userData = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim().toLowerCase(),
      'role': _selectedRole,
      'createdAt': Timestamp.now(),
    };

    // Add district and ward based on role
    if (_selectedRole.toLowerCase() == 'employee' || _selectedRole.toLowerCase() == 'agent') {
      userData['district'] = _selectedDistrict;
    } else if (_selectedRole.toLowerCase() == 'ward health officer') {
      userData['district'] = _selectedDistrict;
      userData['ward'] = _selectedWard;
    }

    // Add user details to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set(userData);

    if (mounted) {
      Navigator.of(context).pop();
      _showSnackBar('User added successfully', Colors.green);
      _resetForm();
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('Error adding user: $e', Colors.red);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



void _showAddUserDialog() {
  if (!_isAdmin) return;
  _resetForm();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenWidth * 0.8,
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: screenHeight * 0.8,
              ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(defaultPadding),
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
                            Icons.person_add,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: defaultPadding),
                        Expanded(
                          child: Text(
                            'Add New User',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headingSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(defaultPadding),
                      child: _buildUserForm(
                        setDialogState:setDialogState  // Pass the StateSetter

                      ),
                    ),
                  ),
                  
                  // Actions
                  Container(
                    padding: EdgeInsets.all(defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: bodyTextSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(width: smallPadding),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleAddUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF115937),
                            padding: EdgeInsets.symmetric(
                              horizontal: defaultPadding,
                              vertical: smallPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: screenWidth * 0.05,
                                  height: screenWidth * 0.05,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Add User',
                                  style: TextStyle(
                                    fontSize: bodyTextSize,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
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
    },
  );
}

Widget _buildUserForm({bool isEdit = false, required StateSetter setDialogState}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Personal Information Section
      _buildFormSection(
        title: 'Personal Information',
        icon: Icons.person,
        children: [
          _buildFormField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
          ),
          SizedBox(height: smallPadding),
          _buildFormField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
          ),
        ],
      ),
      
      SizedBox(height: defaultPadding),
      
      // Account Information Section
      _buildFormSection(
        title: 'Account Information',
        icon: Icons.account_circle,
        children: [
          _buildFormField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          if (!isEdit) ...[
            SizedBox(height: smallPadding),
            _buildFormField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outlined,
              isPassword: true,
            ),
          ],
        ],
      ),
      
      SizedBox(height: defaultPadding),
      
      // Role Selection Section
      _buildFormSection(
        title: 'Role Assignment',
        icon: Icons.work_outline,
        children: [
          _buildRoleSelector(setDialogState),
        ],
      ),
    ],
  );
}

Widget _buildFormSection({
  required String title,
  required IconData icon,
  required List<Widget> children,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
    ),
    padding: EdgeInsets.all(defaultPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF115937),
              size: screenWidth * 0.05,
            ),
            SizedBox(width: smallPadding),
            Text(
              title,
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115937),
              ),
            ),
          ],
        ),
        SizedBox(height: smallPadding),
        ...children,
      ],
    ),
  );
}

Widget _buildFormField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool isPassword = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextFormField(
    controller: controller,
    obscureText: isPassword,
    keyboardType: keyboardType,
    style: TextStyle(fontSize: bodyTextSize),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.grey[600],
        fontSize: bodyTextSize,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF115937),
        size: screenWidth * 0.05,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF115937), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

// Update the _buildRoleSelector method to include the district selector:
// Widget _buildRoleSelector([StateSetter? setDialogState]) {
//   return Container(
//     padding: EdgeInsets.all(smallPadding),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.grey[300]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Role',
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: smallTextSize,
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         // Wrap roles in a responsive layout
//         Wrap(
//           spacing: smallPadding,
//           runSpacing: smallPadding,
//           children: [
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 4) / 2,
//               child: _buildRoleOption('Admin', Icons.admin_panel_settings, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 4) / 2,
//               child: _buildRoleOption('Employee', Icons.person_outline, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 4) / 2,
//               child: _buildRoleOption('Driver', Icons.drive_eta_outlined, setDialogState),
//             ),
//           ],
//         ),
        
//         // Show district selector only when Employee role is selected
//         if (_selectedRole.toLowerCase() == 'employee') ...[
//           SizedBox(height: defaultPadding),
//           Text(
//             'Select District',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: smallTextSize,
//             ),
//           ),
//           SizedBox(height: smallPadding),
//           Wrap(
//             spacing: smallPadding,
//             runSpacing: smallPadding,
//             children: [
//               SizedBox(
//                 width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 4) / 2,
//                 child: _buildDistrictOption('Mwanza City', Icons.location_city, setDialogState),
//               ),
//               SizedBox(
//                 width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 4) / 2,
//                 child: _buildDistrictOption('Ilemela Municipal', Icons.business, setDialogState),
//               ),
//             ],
//           ),
//         ],
//       ],
//     ),
//   );
// }
// Widget _buildRoleSelector([StateSetter? setDialogState]) {
//   return Container(
//     padding: EdgeInsets.all(smallPadding),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.grey[300]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Role',
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: smallTextSize,
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         // Wrap roles in a responsive layout
//         Wrap(
//           spacing: smallPadding,
//           runSpacing: smallPadding,
//           children: [
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//               child: _buildRoleOption('Admin', Icons.admin_panel_settings, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//               child: _buildRoleOption('Employee', Icons.person_outline, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//               child: _buildRoleOption('Driver', Icons.drive_eta_outlined, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//               child: _buildRoleOption('Ward Health Officer', Icons.local_hospital, setDialogState),
//             ),
//             SizedBox(
//               width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//               child: _buildRoleOption('Agent', Icons.support_agent, setDialogState),
//             ),
//           ],
//         ),
        
//         // Show district selector for Employee, Agent, and Ward Health Officer roles
//         if (_selectedRole.toLowerCase() == 'employee' || 
//             _selectedRole.toLowerCase() == 'agent' ||
//             _selectedRole.toLowerCase() == 'ward health officer') ...[
//           SizedBox(height: defaultPadding),
//           Text(
//             'Select District',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: smallTextSize,
//             ),
//           ),
//           SizedBox(height: smallPadding),
//           Wrap(
//             spacing: smallPadding,
//             runSpacing: smallPadding,
//             children: [
//               SizedBox(
//                 width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//                 child: _buildDistrictOption('Mwanza City', Icons.location_city, setDialogState),
//               ),
//               SizedBox(
//                 width: screenWidth > 600 ? 180 : (screenWidth - defaultPadding * 2) / 2,
//                 child: _buildDistrictOption('Ilemela Municipal', Icons.business, setDialogState),
//               ),
//             ],
//           ),
//         ],

//         // Show ward selector only for Ward Health Officer role
//         if (_selectedRole.toLowerCase() == 'ward health officer' && _selectedDistrict.isNotEmpty) ...[
//           SizedBox(height: defaultPadding),
//           Text(
//             'Select Ward',
//             style: TextStyle(
//               color: Colors.grey[600],
//               fontSize: smallTextSize,
//             ),
//           ),
//           SizedBox(height: smallPadding),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: smallPadding),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: DropdownButtonHideUnderline(
//               child: DropdownButton<String>(
//                 value: _selectedWard.isEmpty ? null : _selectedWard,
//                 hint: Text('Select a ward'),
//                 isExpanded: true,
//                 items: districtsWards[_selectedDistrict.contains('Mwanza') ? 'Mwanza City/Nyamagana' : 'Ilemela']
//                     ?.map<DropdownMenuItem<String>>((String ward) {
//                   return DropdownMenuItem<String>(
//                     value: ward,
//                     child: Text(ward),
//                   );
//                 }).toList() ?? [],
//                 onChanged: (String? newValue) {
//                   if (newValue != null) {
//                     setState(() {
//                       _selectedWard = newValue;
//                     });
//                     setDialogState?.call(() {
//                       _selectedWard = newValue;
//                     });
//                   }
//                 },
//               ),
//             ),
//           ),
//         ],
//       ],
//     ),
//   );
// }
Widget _buildRoleSelector([StateSetter? setDialogState]) {
  return Container(
    padding: EdgeInsets.all(smallPadding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Role',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: smallTextSize,
          ),
        ),
        SizedBox(height: smallPadding),
        
        // Roles
        Wrap(
          spacing: screenWidth * 0.02,
          runSpacing: screenWidth * 0.02,
          children: [
            SizedBox(
              width: (screenWidth - defaultPadding * 4) / 2,
              child: _buildRoleOption('Admin', Icons.admin_panel_settings, setDialogState),
            ),
            SizedBox(
              width: (screenWidth - defaultPadding * 4) / 2,
              child: _buildRoleOption('Employee', Icons.person_outline, setDialogState),
            ),
            SizedBox(
              width: (screenWidth - defaultPadding * 4) / 2,
              child: _buildRoleOption('Driver', Icons.drive_eta_outlined, setDialogState),
            ),
            SizedBox(
              width: (screenWidth - defaultPadding * 4) / 2,
              child: _buildRoleOption('Ward Health Officer', Icons.local_hospital, setDialogState),
            ),
            SizedBox(
              width: (screenWidth - defaultPadding * 4) / 2,
              child: _buildRoleOption('Agent', Icons.support_agent, setDialogState),
            ),
          ],
        ),
        
        // District selector
        if (_selectedRole.toLowerCase() == 'employee' || 
            _selectedRole.toLowerCase() == 'agent' ||
            _selectedRole.toLowerCase() == 'ward health officer') ...[
          SizedBox(height: defaultPadding),
          Text(
            'Select District',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: smallTextSize,
            ),
          ),
          SizedBox(height: smallPadding),
          Wrap(
            spacing: screenWidth * 0.02,
            children: [
              SizedBox(
                width: (screenWidth - defaultPadding * 4) / 2,
                child: _buildDistrictOption('Mwanza City', Icons.location_city, setDialogState),
              ),
              SizedBox(
                width: (screenWidth - defaultPadding * 4) / 2,
                child: _buildDistrictOption('Ilemela Municipal', Icons.business, setDialogState),
              ),
            ],
          ),
        ],

        // Ward selector
        if (_selectedRole.toLowerCase() == 'ward health officer' && _selectedDistrict.isNotEmpty) ...[
          SizedBox(height: defaultPadding),
          Text(
            'Select Ward',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: smallTextSize,
            ),
          ),
          SizedBox(height: smallPadding),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: smallPadding,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWard.isEmpty ? null : _selectedWard,
                hint: const Text('Select a ward'),
                isExpanded: true,
                items: districtsWards[_selectedDistrict.contains('Mwanza') ? 'Mwanza City/Nyamagana' : 'Ilemela']
                    ?.map<DropdownMenuItem<String>>((String ward) {
                  return DropdownMenuItem<String>(
                    value: ward,
                    child: Text(ward),
                  );
                }).toList() ?? [],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedWard = newValue;
                    });
                    setDialogState?.call(() {
                      _selectedWard = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ],
    ),
  );
}




// Add this new method for district selection:
Widget _buildDistrictOption(String district, IconData icon, [StateSetter? setDialogState]) {
  final isSelected = _selectedDistrict.toLowerCase() == district.toLowerCase();
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        // Update both the parent state and dialog state
        setState(() {
          _selectedDistrict = district;
        });
        setDialogState?.call(() {
          _selectedDistrict = district;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Flexible(
              child: Text(
                district,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: bodyTextSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildRoleOption(String role, IconData icon, [StateSetter? setDialogState]) {
  final isSelected = _selectedRole.toLowerCase() == role.toLowerCase();
  final isLongText = role.length > 10;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role.toLowerCase();
        });
        setDialogState?.call(() {
          _selectedRole = role.toLowerCase();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: smallPadding,
          vertical: smallPadding / 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
              size: screenWidth * 0.04,
            ),
            SizedBox(width: smallPadding / 2),
            Expanded(
              child: Text(
                role,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isLongText ? bodyTextSize * 0.85 : bodyTextSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
Widget _buildRoleOptionWithWrapping(String role, IconData icon, [StateSetter? setDialogState]) {
  final isSelected = _selectedRole.toLowerCase() == role.toLowerCase();
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role.toLowerCase();
        });
        setDialogState?.call(() {
          _selectedRole = role.toLowerCase();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Flexible(
              child: Text(
                role,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: bodyTextSize * 0.9, // Slightly smaller font for long text
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Widget _buildRoleOption(String role, IconData icon, [StateSetter? setDialogState]) {
//   final isSelected = _selectedRole.toLowerCase() == role.toLowerCase();
//   return Material(
//     color: Colors.transparent,
//     child: InkWell(
//       onTap: () {
//         // Update both the parent state and dialog state
//         setState(() {
//           _selectedRole = role.toLowerCase();
//         });
//         setDialogState?.call(() {
//           _selectedRole = role.toLowerCase();
//         });
//       },
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: EdgeInsets.all(smallPadding),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
//               size: screenWidth * 0.045,
//             ),
//             SizedBox(width: smallPadding),
//             Text(
//               role,
//               style: TextStyle(
//                 color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 fontSize: bodyTextSize,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }



// Update the _showEditUserDialog method to include district:
void _showEditUserDialog(DocumentSnapshot user) {
  _resetForm();
  final userData = user.data() as Map<String, dynamic>;
  _firstNameController.text = userData['firstName'] ?? '';
  _lastNameController.text = userData['lastName'] ?? '';
  _emailController.text = userData['email'] ?? '';
  _selectedRole = userData['role'] ?? 'employee';
  _selectedDistrict = userData['district'] ?? '';
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(  // Add StatefulBuilder here
        builder: (BuildContext context, StateSetter setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: screenWidth * 0.8,
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: screenHeight * 0.8,
              ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(defaultPadding),
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
                            Icons.edit,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: defaultPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit User',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: headingSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userData['email'] ?? '',
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
                  ),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(defaultPadding),
                      child: _buildUserForm(
                        isEdit: true,
                        setDialogState: setDialogState  // Pass setDialogState here
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: EdgeInsets.all(defaultPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: bodyTextSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        SizedBox(width: smallPadding),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleEditUser(user.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF115937),
                            padding: EdgeInsets.symmetric(
                              horizontal: defaultPadding,
                              vertical: smallPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: screenWidth * 0.05,
                                  height: screenWidth * 0.05,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: bodyTextSize,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
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
    },
  );
}



// Update the _handleEditUser method to include district:
// Future<void> _handleEditUser(String userId) async {
//   if (_validateForm(isEdit: true)) {
//     setState(() => _isLoading = true);

//     try {
//       await FirebaseFirestore.instance.collection('users').doc(userId).update({
//         'firstName': _firstNameController.text.trim(),
//         'lastName': _lastNameController.text.trim(),
//         'email': _emailController.text.trim().toLowerCase(),
//         'role': _selectedRole,
//         'district': _selectedRole.toLowerCase() == 'employee' ? _selectedDistrict : '', // Only update district for employees
//       });

//       Navigator.pop(context);
//       _showSnackBar('User updated successfully', Colors.green);
//     } catch (e) {
//       _showSnackBar('Error updating user: ${e.toString()}', Colors.red);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
// }

Future<void> _handleEditUser(String userId) async {
  if (_validateForm(isEdit: true)) {
    setState(() => _isLoading = true);

    try {
      // Prepare the update data
      final updateData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'role': _selectedRole,
      };

      // Add district and ward based on role
      if (_selectedRole.toLowerCase() == 'employee' || _selectedRole.toLowerCase() == 'agent') {
        updateData['district'] = _selectedDistrict;
        updateData['ward'] = ''; // Clear ward if exists
      } else if (_selectedRole.toLowerCase() == 'ward health officer') {
        updateData['district'] = _selectedDistrict;
        updateData['ward'] = _selectedWard;
      } else {
        updateData['district'] = ''; // Clear district if not needed
        updateData['ward'] = ''; // Clear ward if not needed
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updateData);

      Navigator.pop(context);
      _showSnackBar('User updated successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error updating user: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}


void _showDeleteConfirmation(String userId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: screenWidth * 0.8,
          constraints: const BoxConstraints(
            maxWidth: 400,
          ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red[700],
                  size: screenWidth * 0.15,
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    Text(
                      'Delete User',
                      style: TextStyle(
                        fontSize: headingSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: smallPadding),
                    Text(
                      'This action cannot be undone. Are you sure you want to delete this user?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: bodyTextSize,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(defaultPadding),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: smallPadding),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: bodyTextSize,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: defaultPadding),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleDeleteUser(userId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: smallPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_forever, size: screenWidth * 0.045),
                                  SizedBox(width: smallPadding),
                                  Text(
                                    'Delete',
                                    style: TextStyle(fontSize: bodyTextSize),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
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


Future<void> _handleDeleteUser(String userId) async {
  setState(() => _isLoading = true);

  try {
    // Delete just the Firestore document for the selected user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .delete();


    Navigator.pop(context);
    _showSnackBar('User deleted successfully', Colors.green);
  } catch (e) {
    _showSnackBar('Error deleting user: ${e.toString()}', Colors.red);
  } finally {
    setState(() => _isLoading = false);
  }
}



// Update the _resetForm method to include district:
// void _resetForm() {
//   _firstNameController.clear();
//   _lastNameController.clear();
//   _emailController.clear();
//   _passwordController.clear();
//   _selectedRole = 'employee';
//   _selectedDistrict = '';
// }
void _resetForm() {
  _firstNameController.clear();
  _lastNameController.clear();
  _emailController.clear();
  _passwordController.clear();
  _selectedRole = 'employee';
  _selectedDistrict = '';
  _selectedWard = '';
}
  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
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
      case 10:
      page = DataImportScreen(user: widget.user);
      break;
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


