// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:intl/intl.dart';

// class StakeholderForm extends StatefulWidget {
//   final User? user;
//   const StakeholderForm({Key? key, required this.user}) : super(key: key);

//   @override
//   _StakeholderFormState createState() => _StakeholderFormState();
// }

// class _StakeholderFormState extends State<StakeholderForm> {
//   final _formKey = GlobalKey<FormState>();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool _isLoading = false;

//   // Form controllers
//   final _organizationController = TextEditingController();
//   final _departmentController = TextEditingController();
//   final _respondentNameController = TextEditingController();
//   final _titleController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _districtController = TextEditingController();
//   final _latitudeController = TextEditingController();
//   final _longitudeController = TextEditingController();

//   // Screen size utilities
//   late double screenWidth;
//   late double screenHeight;
//   late double defaultPadding;
//   late double smallPadding;
//   late double cardPadding;
//   late double headingSize;
//   late double bodyTextSize;
//   late double smallTextSize;

//   // Theme colors
//   static const primaryColor = Color(0xFF115937);
//   static const gradientColors = [Color(0xFF1E3C2F), Color(0xFF115937)];

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     screenWidth = MediaQuery.of(context).size.width;
//     screenHeight = MediaQuery.of(context).size.height;
//     defaultPadding = screenWidth * 0.04;
//     smallPadding = screenWidth * 0.02;
//     cardPadding = screenWidth * 0.035;
//     headingSize = screenWidth * 0.045;
//     bodyTextSize = screenWidth * 0.032;
//     smallTextSize = screenWidth * 0.028;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1E3C2F),
//       body: NestedScrollView(
//         headerSliverBuilder: (context, innerBoxIsScrolled) => [
//           SliverAppBar(
//             expandedHeight: 120,
//             floating: true,
//             pinned: true,
//             backgroundColor: const Color(0xFF1E3C2F),
//             elevation: 0,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: gradientColors,
//                   ),
//                 ),
//               ),
//             ),
//             bottom: PreferredSize(
//               preferredSize: Size.fromHeight(screenHeight * 0.08),
//               child: Container(
//                 height: screenHeight * 0.08,
//                 padding: EdgeInsets.all(defaultPadding),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(30),
//                     topRight: Radius.circular(30),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 10,
//                       offset: const Offset(0, -5),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.person_add_outlined,
//                       color: primaryColor,
//                       size: screenWidth * 0.06,
//                     ),
//                     SizedBox(width: smallPadding),
//                     Text(
//                       'Add New Stakeholder',
//                       style: TextStyle(
//                         fontSize: headingSize,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//         body: Container(
//           color: Colors.white,
//           child: _buildForm(),
//         ),
//       ),
//     );
//   }

//   Widget _buildForm() {
//     return Form(
//       key: _formKey,
//       child: SingleChildScrollView(
//         padding: EdgeInsets.all(defaultPadding),
//         child: Column(
//           children: [
//             _buildOrganizationCard(),
//             SizedBox(height: defaultPadding),
//             _buildContactCard(),
//             SizedBox(height: defaultPadding),
//             _buildLocationCard(),
//             SizedBox(height: defaultPadding * 2),
//             _buildSubmitButton(),
//           ].animate(interval: const Duration(milliseconds: 50))
//            .fadeIn(duration: const Duration(milliseconds: 300))
//            .slideY(begin: 0.2, end: 0),
//         ),
//       ),
//     );
//   }

//   Widget _buildOrganizationCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader(
//               'Organization Details',
//               Icons.business_outlined,
//             ),
//             SizedBox(height: defaultPadding),
//             _buildTextField(
//               controller: _organizationController,
//               label: 'Organization Name',
//               icon: Icons.business,
//               validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//             ),
//             _buildTextField(
//               controller: _departmentController,
//               label: 'Department',
//               icon: Icons.account_tree_outlined,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContactCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader(
//               'Contact Information',
//               Icons.contact_mail_outlined,
//             ),
//             SizedBox(height: defaultPadding),
//             _buildTextField(
//               controller: _respondentNameController,
//               label: 'Respondent Name',
//               icon: Icons.person_outline,
//               validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//             ),
//             _buildTextField(
//               controller: _titleController,
//               label: 'Title/Position',
//               icon: Icons.work_outline,
//             ),
//             _buildTextField(
//               controller: _phoneController,
//               label: 'Phone Number',
//               icon: Icons.phone_outlined,
//               keyboardType: TextInputType.phone,
//             ),
//             _buildTextField(
//               controller: _emailController,
//               label: 'Email Address',
//               icon: Icons.email_outlined,
//               keyboardType: TextInputType.emailAddress,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLocationCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(cardPadding),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionHeader(
//               'Location Details',
//               Icons.location_on_outlined,
//             ),
//             SizedBox(height: defaultPadding),
//             _buildTextField(
//               controller: _districtController,
//               label: 'District',
//               icon: Icons.location_city_outlined,
//               validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
//             ),
//             _buildTextField(
//               controller: _addressController,
//               label: 'Address',
//               icon: Icons.home_outlined,
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildTextField(
//                     controller: _latitudeController,
//                     label: 'Latitude',
//                     icon: Icons.north_outlined,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   ),
//                 ),
//                 SizedBox(width: smallPadding),
//                 Expanded(
//                   child: _buildTextField(
//                     controller: _longitudeController,
//                     label: 'Longitude',
//                     icon: Icons.east_outlined,
//                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(screenWidth * 0.02),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           ),
//           child: Icon(
//             icon,
//             color: primaryColor,
//             size: screenWidth * 0.05,
//           ),
//         ),
//         SizedBox(width: smallPadding),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: headingSize,
//             fontWeight: FontWeight.bold,
//             color: primaryColor,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     String? Function(String?)? validator,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: smallPadding),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         validator: validator,
//         style: TextStyle(fontSize: bodyTextSize),
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(icon),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey[300]!),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: primaryColor, width: 2),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: screenHeight * 0.06,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _submitForm,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 2,
//         ),
//         child: _isLoading
//             ? const CircularProgressIndicator(color: Colors.white)
//             : Text(
//                 'Submit',
//                 style: TextStyle(
//                   fontSize: bodyTextSize,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//     );
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       await _firestore.collection('ilemelaStakeholdersCollection').add({
//         'organization': _organizationController.text,
//         'department': _departmentController.text,
//         'respondent_name': _respondentNameController.text,
//         'title': _titleController.text,
//         'contact_phone': _phoneController.text,
//         'email_address': _emailController.text,
//         'address': _addressController.text,
//         'district': _districtController.text,
//         'latitude': double.tryParse(_latitudeController.text),
//         'longitude': double.tryParse(_longitudeController.text),
//         'created_at': FieldValue.serverTimestamp(),
//         'updated_at': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Stakeholder added successfully')),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error adding stakeholder: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _organizationController.dispose();
//     _departmentController.dispose();
//     _respondentNameController.dispose();
//     _titleController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     _addressController.dispose();
//     _districtController.dispose();
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class StakeholderForm extends StatefulWidget {
  final User? user;
  const StakeholderForm({Key? key, required this.user}) : super(key: key);

  @override
  _StakeholderFormState createState() => _StakeholderFormState();
}

class _StakeholderFormState extends State<StakeholderForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Form controllers
  final _dataCollectorController = TextEditingController();
  final _organizationController = TextEditingController();
  final _departmentController = TextEditingController();
  final _respondentNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
    final _websiteController = TextEditingController();


  // State variables
  String? _dataCollectorName;
  DateTime _selectedDate = DateTime.now();
  
  // Geography Data
  final List<String> districts = ['Ilemela'];
  final Map<String, List<String>> districtsWards = {
    // 'Mwanza City/Nyamagana': [
    //   'Buhongwa', 'Butimba', 'Igogo', 'Igoma', 'Isamilo', 
    //   'Kishili', 'Luchelele', 'Lwanhima', 'Mabatini', 'Mahina', 
    //   'Mbugani', 'Mhandu', 'Mikuyuni', 'Mirongo', 'Mkolani', 
    //   'Nyamagana', 'Nyegezi', 'Pamba'
    // ],
    'Ilemela': [
      'Buswelu', 'Bugogwa', 'Ilemela', 'Nyamanoro', 'Kirumba',
      'Kitangiri', 'Pasiansi', 'Kiseke', 'Sangabuye', 'Kawekamo',
      'Mecco', 'Buzuruga'
    ],
  };

  // Screen size utilities
  late double screenWidth;
  late double screenHeight;
  late double defaultPadding;
  late double smallPadding;
  late double cardPadding;
  late double headingSize;
  late double bodyTextSize;
  late double smallTextSize;
  Position? _currentPosition;
  double? _latitude;
  double? _longitude;

  // Theme colors
  static const primaryColor = Color(0xFF115937);
  static const gradientColors = [Color(0xFF1E3C2F), Color(0xFF115937)];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeResponsiveDimensions();
  }

  void _initializeResponsiveDimensions() {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    defaultPadding = screenWidth * 0.04;
    smallPadding = screenWidth * 0.02;
    cardPadding = screenWidth * 0.035;
    headingSize = screenWidth * 0.045;
    bodyTextSize = screenWidth * 0.032;
    smallTextSize = screenWidth * 0.028;
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.user != null) {
        final userDoc = await _firestore.collection('users').doc(widget.user!.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _dataCollectorName = '${userDoc['firstName']} ${userDoc['lastName']}';
            _dataCollectorController.text = _dataCollectorName ?? '';
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


Future<void> _getCurrentLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Location services are disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permissions are denied');
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Update the text field controllers
      _latitudeController.text = _latitude.toString();
      _longitudeController.text = _longitude.toString();
    });
  } catch (e) {
    _showSnackBar('Error getting location');
  }
}

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: smallPadding),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(defaultPadding),
                    child: _buildFormContent(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: screenHeight * 0.2,
      floating: true,
      pinned: true,
      backgroundColor: primaryColor,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: screenWidth * 0.15,
                  color: Colors.white.withOpacity(0.8),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(),
                SizedBox(height: smallPadding),
                Text(
                  'New Stakeholder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: headingSize,
                    fontWeight: FontWeight.bold,
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
                Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: bodyTextSize,
                  ),
                )
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        _buildBasicInfoCard(),
        SizedBox(height: defaultPadding),
        _buildOrganizationCard(),
        SizedBox(height: defaultPadding),
        _buildContactCard(),
        SizedBox(height: defaultPadding),
        _buildLocationCard(),
        SizedBox(height: defaultPadding * 2),
        _buildFormSummaryCard(),
        SizedBox(height: defaultPadding),
        _buildSubmitButton(),
      ].animate(interval: const Duration(milliseconds: 50))
       .fadeIn(duration: const Duration(milliseconds: 300))
       .slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Basic Information',
              Icons.info_outline,
            ),
            SizedBox(height: defaultPadding),

            // Date Selection
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: _buildCardDecoration(),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, 
                         color: Colors.grey[600], 
                         size: screenWidth * 0.05),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: smallTextSize,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: smallPadding / 2),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: TextStyle(
                              fontSize: bodyTextSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, 
                         color: Colors.grey[400], 
                         size: screenWidth * 0.04),
                  ],
                ),
              ),
            ),

            SizedBox(height: defaultPadding),

            _buildResponsiveTextField(
              controller: _dataCollectorController,
              label: 'Data Collector',
              prefixIcon: Icons.person_outline,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Organization Details',
              Icons.business_outlined,
            ),
            SizedBox(height: defaultPadding),

            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: _buildCardDecoration(),
              child: Column(
                children: [
                  _buildResponsiveTextField(
                    controller: _organizationController,
                    label: 'Organization Name',
                    prefixIcon: Icons.business,
                    validator: _validateRequired,
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    controller: _departmentController,
                    label: 'Department',
                    prefixIcon: Icons.account_tree_outlined,
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    controller: _websiteController,
                    label: 'Website',
                    prefixIcon: Icons.account_tree_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Contact Information',
              Icons.contact_mail_outlined,
            ),
            SizedBox(height: defaultPadding),

            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: _buildCardDecoration(),
              child: Column(
                children: [
                  _buildResponsiveTextField(
                    controller: _respondentNameController,
                    label: 'Respondent Name',
                    prefixIcon: Icons.person_outline,
                    validator: _validateRequired,
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    controller: _titleController,
                    label: 'Title/Position',
                    prefixIcon: Icons.work_outline,
                    validator: _validateRequired,
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Location Details',
              Icons.location_on_outlined,
            ),
            SizedBox(height: defaultPadding),

            // District and Ward Selection
            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: _buildCardDecoration(),
              child: Column(
                children: [
                  _buildResponsiveDropdown(
                    label: 'District',
                    value: _districtController.text.isEmpty ? null : _districtController.text,
                    items: districts,
                    prefixIcon: Icons.location_city_outlined,
                    onChanged: (value) {
                      setState(() => _districtController.text = value ?? '');
                    },
                  ),
                  // SizedBox(height: smallPadding),
                  // if (_districtController.text.isNotEmpty)
                  //   _buildResponsiveDropdown(
                  //     label: 'Ward',
                  //     value: null,
                  //     items: districtsWards[_districtController.text] ?? [],
                  //     prefixIcon: Icons.map_outlined,
                  //     onChanged: (value) {
                  //       // Handle ward selection
                  //     },
                  //   ),
                ],
              ),
            ),

            SizedBox(height: defaultPadding),

            // Address and Coordinates
            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: _buildCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // _buildResponsiveTextField(
                  //   controller: _addressController,
                  //   label: 'Address',
                  //   prefixIcon: Icons.home_outlined,
                  //   validator: _validateRequired,
                  // ),
                  // SizedBox(height: smallPadding),
                  

          // _buildSectionHeader(
          //   'Location Details',
          //   Icons.location_on,
          // ),
          // SizedBox(height: defaultPadding),

          _buildLocationCoordinates().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          SizedBox(height: defaultPadding),

        ],
                  ),
                
              ),
            
          ],
        ),
      ),
    );
  }


Widget _buildLocationCoordinates() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Location',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.my_location),
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withOpacity(0.1),
                foregroundColor: primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: smallPadding),
        Row(
          children: [
            Expanded(
              child: _buildResponsiveTextField(
                controller: _latitudeController,
                label: 'Latitude',
                prefixIcon: Icons.location_searching,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateLatitude,
              ),
            ),
            SizedBox(width: smallPadding),
            Expanded(
              child: _buildResponsiveTextField(
                controller: _longitudeController,
                label: 'Longitude',
                prefixIcon: Icons.location_searching,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateLongitude,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


    Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(screenWidth * 0.02),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
            fontSize: headingSize,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: smallPadding),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: bodyTextSize),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: smallTextSize,
            color: Colors.grey[600],
          ),
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Colors.grey[600], size: screenWidth * 0.05)
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildResponsiveDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: smallPadding),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(fontSize: bodyTextSize),
            ),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: smallTextSize,
            color: Colors.grey[600],
          ),
          prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Colors.grey[600], size: screenWidth * 0.05)
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: onChanged,
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.grey[200]!),
    );
  }

  Widget _buildFormSummaryCard() {
    final completionPercentage = _calculateFormCompletion();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: _getCompletionColor(completionPercentage).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    _getCompletionIcon(completionPercentage),
                    color: _getCompletionColor(completionPercentage),
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: smallPadding),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Completion',
                      style: TextStyle(
                        fontSize: bodyTextSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(completionPercentage * 100).round()}% Complete',
                      style: TextStyle(
                        fontSize: smallTextSize,
                        color: _getCompletionColor(completionPercentage),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: defaultPadding),
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
              child: LinearProgressIndicator(
                value: completionPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCompletionColor(completionPercentage),
                ),
                minHeight: screenWidth * 0.02,
              ),
            ),
          ],
        ),
      ),
    ).animate()
     .fadeIn(duration: const Duration(milliseconds: 300))
     .slideY(begin: 0.2, end: 0);
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: screenWidth * 0.05),
                  SizedBox(width: smallPadding),
                  Text(
                    'Submit Stakeholder',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    ).animate()
     .fadeIn(duration: const Duration(milliseconds: 300))
     .slideY(begin: 0.2, end: 0);
  }

  // Validation Methods
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final lat = double.tryParse(value);
    if (lat == null || lat < -90 || lat > 90) {
      return 'Invalid latitude';
    }
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.isEmpty) return null; // Optional
    final lng = double.tryParse(value);
    if (lng == null || lng < -180 || lng > 180) {
      return 'Invalid longitude';
    }
    return null;
  }

  // Helper Methods for Form State
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  double _calculateFormCompletion() {
    int totalFields = 0;
    int completedFields = 0;

    void checkField(String? value) {
      totalFields++;
      if (value != null && value.isNotEmpty) {
        completedFields++;
      }
    }

    checkField(_organizationController.text);
    checkField(_respondentNameController.text);
    checkField(_titleController.text);
    checkField(_phoneController.text);
    checkField(_emailController.text);
    // checkField(_addressController.text);
    checkField(_districtController.text);

    return totalFields > 0 ? completedFields / totalFields : 0;
  }

  Color _getCompletionColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  IconData _getCompletionIcon(double percentage) {
    if (percentage >= 0.8) return Icons.check_circle;
    if (percentage >= 0.5) return Icons.warning;
    return Icons.error;
  }

  // Form Submission
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestore.collection('ilemelaStakeholdersCollection').add({
        'date': Timestamp.fromDate(_selectedDate),
        'data_collector': _dataCollectorController.text,
        'organization': _organizationController.text,
        'department': _departmentController.text,
        'respondent_name': _respondentNameController.text,
        'title': _titleController.text,
        'contact_phone': _phoneController.text,
        'email_address': _emailController.text,
        'website': _websiteController.text,
        'district': _districtController.text,
        'location': {
          'coordinates': {
             'latitude': double.tryParse(_latitudeController.text),
            'longitude': double.tryParse(_longitudeController.text),
          }
        },

        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Success/Error Dialogs
  Future<void> _showSuccessDialog() {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(Icons.check_circle, color: Colors.green[700]),
            ),
            SizedBox(width: smallPadding),
            Text('Success!'),
          ],
        ),
        content: Text('Stakeholder information has been successfully submitted.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to list
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(Icons.error_outline, color: Colors.red[700]),
            ),
            SizedBox(width: smallPadding),
            Text('Error'),
          ],
        ),
        content: Text('Failed to submit stakeholder information: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}