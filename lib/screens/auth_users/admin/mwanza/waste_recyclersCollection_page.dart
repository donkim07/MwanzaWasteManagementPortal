import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'WHO_waste_reportMap.dart';
import 'admin_management.dart';
import 'agent.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
import 'waste_aggregators_page.dart';
import 'waste_dealers_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_points_page.dart';
import 'waste_reportMap.dart';
import 'waste_reportingCollection.dart';


class WasteRecyclingCenterForm extends StatefulWidget {
  final User? user;
  const WasteRecyclingCenterForm({Key? key, required this.user}) : super(key: key);

  @override
  _WasteRecyclingCenterFormState createState() => _WasteRecyclingCenterFormState();
}

class _WasteRecyclingCenterFormState extends State<WasteRecyclingCenterForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  String _firstName = '';
  bool _isAdmin = false;
  int _selectedIndex = 4; // For waste dealers page


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

  // Form controllers
  final TextEditingController _centerNameController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _titleNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _endProductsController = TextEditingController();
  final TextEditingController _productMarketController = TextEditingController();
  final TextEditingController _otherOwnershipController = TextEditingController();
  final TextEditingController _organizationNameController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  String _supportType = 'Government';
  // Colors
  static const primaryColor = Color(0xFF115937);
  // static const secondaryColor = Color(0xFF90EE90);
bool _hasGovernmentSupport = false;
bool _hasOrganizationSupport = false;

  // Loading state
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Your existing state variables here...

  // Basic Information
  DateTime _selectedDate = DateTime.now();
  String? _dataCollectorName;
  String? _region;
  String? _district;
  String? _division;
  String? _ward;
  String? _street;

  // Status and License
  String _centerStatus = 'Formal';
  String? _businessLicensePhoto;

  // Ownership Information
  String _ownershipType = 'Private';
  String? _otherOwnershipType;
  String? _centerName;
  String? _contactPerson;
  String? _mobileNumber;
  String? _email;

  // Location Information
  String? _locationWard;
  String? _locationStreet;
  Position? _currentPosition;
  double? _latitude;
  double? _longitude;

  // Waste Types and Sources
  List<String> _wasteTypes = [];
  String? _otherWasteType;
  List<String> _wasteSources = [];
  String? _productPhoto;

  // Capacity and Operations
  int _weeklyCapacity = 1;
  String _quantificationMethod = 'Weighing';
  String _coreBusiness = 'Sell to other waste users (recyclers)';
  String _recyclingType = 'Production of end use products';
  String? _otherRecyclingType;
  String? _endProducts;
  String? _productMarket;

  // Support and Safety
  bool _hasSupport = false;
  List<String> _supportTypes = [];
  String? _otherSupportType;
  bool _hasSafetyMeasures = false;
  List<String> _safetyMeasures = [];
  String? _otherSafetyMeasure;

  // Authorization
  bool _needsAuthorization = false;
  List<String> _requiredPermits = [];
  String? _otherPermit;

  // Geography Data (Replace with actual data)
  // final List<String> regions = ['Dar es Salaam', 'Arusha', 'Dodoma', 'Mwanza'];
  // final Map<String, List<String>> districts = {
  //   'Dar es Salaam': ['Ilala', 'Kinondoni', 'Temeke'],
  // };
final List<String> regions = ['Mwanza'];

final Map<String, List<String>> districts = {
  'Mwanza': ['Mwanza City/Nyamagana'],
};

// For districts and their wards (as strings only)
final Map<String, List<String>> districtsWards = {
  'Ilemela': [
    'Bugogwa', 'Buswelu', 'Buzuruga', 'Ibungilo', 'Ilemela', 
    'Kahama', 'Kawekamo', 'Kayenze', 'Kirumba', 'Kiseke', 
    'Kitangiri', 'Mecco', 'Nyakato', 'Nyamanoro', 'Nyamhongolo', 
    'Nyasaka', 'Pasiansi', 'Sangabuye', 'Shibula'
  ],
  // 'Mwanza City/Nyamagana': [
  //   'Buhongwa', 'Butimba', 'Igogo', 'Igoma', 'Isamilo', 
  //   'Kishili', 'Luchelele', 'Lwanhima', 'Mabatini', 'Mahina', 
  //   'Mbugani', 'Mhandu', 'Mikuyuni', 'Mirongo', 'Mkolani', 
  //   'Nyamagana', 'Nyegezi', 'Pamba'
  // ],
};

// Add this near the top of the class with other instance variables
final FirebaseStorage _storage = FirebaseStorage.instance;

Future<String?> _uploadImage(String imagePath, String folder) async {
  try {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${widget.user?.uid ?? 'unknown'}${path.extension(imagePath)}';
    final Reference storageRef = _storage.ref().child('$folder/$fileName');
    
    // Create the upload task
    final UploadTask uploadTask = storageRef.putFile(File(imagePath));
    
    // Show progress indicator if needed
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      // You can use this to show upload progress if desired
    });

    // Wait for upload to complete and get download URL
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    _showErrorSnackBar('Error uploading image: $e');
    return null;
  }
}



  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
  }

  @override
  void dispose() {
    _centerNameController.dispose();
    _contactPersonController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _endProductsController.dispose();
    _productMarketController.dispose();
    super.dispose();
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
    subheadingSize = screenWidth * 0.035;
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
            _firstName = userDoc['firstName'] ?? '';
            _isAdmin = userDoc['role'] == 'admin';
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: smallPadding),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(defaultPadding),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: smallPadding),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(defaultPadding),
      ),
    );
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
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
              colors: [
                Color(0xFF1E3C2F),
                primaryColor,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling,
                  size: screenWidth * 0.15,
                  color: Colors.white.withOpacity(0.8),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(),
                SizedBox(height: smallPadding),
                Text(
                  'New Recycling Center',
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
        // _buildStatusCard(),
        // SizedBox(height: defaultPadding),
        _buildOwnershipCard(),
        SizedBox(height: defaultPadding),
        _buildLocationCard(),
        SizedBox(height: defaultPadding),
        _buildWasteTypesCard(),
        SizedBox(height: defaultPadding),
        // _buildCapacityCard(),
        // SizedBox(height: defaultPadding),
        // _buildSupportAndSafetyCard(),
        // SizedBox(height: defaultPadding),
        // _buildAuthorizationCard(),
        // SizedBox(height: defaultPadding * 2),
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
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.grey.shade200),
                ),
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
            ).animate()
             .fadeIn(duration: const Duration(milliseconds: 300))
             .slideX(begin: -0.2, end: 0),

            SizedBox(height: defaultPadding),

            _buildResponsiveTextField(
              controller: TextEditingController(text: _dataCollectorName),
              label: 'Data Collector Name',
              enabled: false,
              prefixIcon: Icons.person_outline,
            ).animate()
             .fadeIn(delay: const Duration(milliseconds: 200))
             .slideX(begin: 0.2, end: 0),

            _buildResponsiveDropdown(
              label: 'Region',
              value: _region,
              items: regions,
              prefixIcon: Icons.location_city,
              onChanged: (value) {
                setState(() {
                  _region = value;
                  _district = null;
                  _division = null;
                  _ward = null;
                  _street = null;
                });
              },
            ).animate()
             .fadeIn(delay: const Duration(milliseconds: 300))
             .slideX(begin: -0.2, end: 0),

            if (_region != null)
              // _buildResponsiveDropdown(
              //   label: 'District',
              //   value: _district,
              //   items: districts[_region] ?? [],
              //   prefixIcon: Icons.business,
              //   onChanged: (value) => setState(() => _district = value),
              // )
               _buildResponsiveTextField(
                    controller: _districtController,
                    label: 'District',
                    prefixIcon: Icons.business,
                  )
              .animate()
               .fadeIn()
               .slideX(begin: 0.2, end: 0),
          ],
        ),
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
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: headingSize,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
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
  bool isMultiline = false,
  void Function(String)? onChanged, // Added onChanged parameter
}) {
  return Container(
    margin: EdgeInsets.only(bottom: smallPadding),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: isMultiline ? 3 : 1,
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: isMultiline ? defaultPadding : smallPadding,
        ),
      ),
      validator: validator,
      onChanged: onChanged, // Added onChanged functionality
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(fontSize: bodyTextSize),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.arrow_drop_down, 
                  color: primaryColor, 
                  size: screenWidth * 0.06),
        isExpanded: true,
      ),
    );
  }



  Widget _buildWasteTypesCard() {
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
            'Waste Types and Sources',
            Icons.delete_outline,
          ),
          SizedBox(height: defaultPadding),

          // Waste Types Selection
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _buildCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Types of Waste Handled',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: smallPadding),
                _buildWasteTypeChips(),
              ],
            ),
          ).animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          if (_wasteTypes.contains('Others'))
            Padding(
              padding: EdgeInsets.only(top: defaultPadding),
              child: _buildResponsiveTextField(
                controller: TextEditingController(text: _otherWasteType),
                label: 'Specify Other Waste Type',
                prefixIcon: Icons.add_circle_outline,
                onChanged: (value) => setState(() => _otherWasteType = value),
              ),
            ).animate()
             .fadeIn()
             .slideY(begin: 0.2, end: 0),

          SizedBox(height: defaultPadding),

          // Waste Sources
          // Container(
          //   padding: EdgeInsets.all(cardPadding),
          //   decoration: _buildCardDecoration(),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Sources of Recyclable Materials',
          //         style: TextStyle(
          //           fontSize: bodyTextSize,
          //           fontWeight: FontWeight.w500,
          //         ),
          //       ),
          //       SizedBox(height: smallPadding),
          //       _buildWasteSourceChips(),
          //     ],
          //   ),
          // ).animate()
          //  .fadeIn(duration: const Duration(milliseconds: 400))
          //  .slideX(begin: 0.2, end: 0),
        ],
      ),
    ),
  );
}

Widget _buildCapacityCard() {
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
            'Capacity and Operations',
            Icons.settings,
          ),
          SizedBox(height: defaultPadding),

          // Weekly Capacity
          _buildCapacitySlider().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          SizedBox(height: defaultPadding),

          // Quantification Method
          _buildMethodSelection().animate()
           .fadeIn(duration: const Duration(milliseconds: 400))
           .slideX(begin: 0.2, end: 0),

          SizedBox(height: defaultPadding),





























          //recycling details like core business and type of recycling
          _buildBusinessQuestionsSection().animate()
          .fadeIn(duration: const Duration(milliseconds: 500))
           .slideY(begin: 0.2, end: 0),

          SizedBox(height: defaultPadding),

          // End Products Section
          _buildEndProductsSection().animate()
           .fadeIn(duration: const Duration(milliseconds: 500))
           .slideY(begin: 0.2, end: 0),

           
        ],
      ),
    ),
  );
}

Widget _buildCapacitySlider() {
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
              'Weekly Capacity',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: smallPadding,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Text(
                '$_weeklyCapacity Tonnes',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: bodyTextSize,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor: primaryColor.withOpacity(0.1),
            thumbColor: primaryColor,
            overlayColor: primaryColor.withOpacity(0.2),
            trackHeight: screenWidth * 0.01,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: screenWidth * 0.02,
            ),
          ),
          child: Slider(
            value: _weeklyCapacity.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) => setState(() => _weeklyCapacity = value.round()),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMethodSelection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantification Method',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: smallPadding),
        ...['Weighing', 'Estimation', 'Best guess'].map((method) => 
          _buildMethodCard(method)).toList(),
      ],
    ),
  );
}

Widget _buildMethodCard(String method) {
  final bool isSelected = _quantificationMethod == method;
  return Container(
    margin: EdgeInsets.only(bottom: smallPadding),
    decoration: BoxDecoration(
      color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(
        color: isSelected ? primaryColor : Colors.grey[300]!,
      ),
    ),
    child: RadioListTile<String>(
      title: Text(
        method,
        style: TextStyle(
          fontSize: bodyTextSize,
          color: isSelected ? primaryColor : Colors.grey[700],
        ),
      ),
      value: method,
      groupValue: _quantificationMethod,
      onChanged: (value) => setState(() => _quantificationMethod = value!),
      activeColor: primaryColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: smallPadding,
      ),
    ),
  ).animate()
   .fadeIn()
   .scale(delay: Duration(milliseconds: 200 * ['Weighing', 'Estimation', 'Best guess'].indexOf(method)));
}

BoxDecoration _buildCardDecoration() {
  return BoxDecoration(
    color: Colors.grey[50],
    borderRadius: BorderRadius.circular(screenWidth * 0.02),
    border: Border.all(color: Colors.grey[200]!),
  );
}















Widget _buildWasteTypeChips() {
  final List<String> wasteTypes = [
    'Plastics',
    'Glasses',
    'Papers',
    'Metal',
    'Wood',
    'Others',
  ];

  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: wasteTypes.asMap().entries.map((entry) {
      final int index = entry.key;
      final String type = entry.value;
      final bool isSelected = _wasteTypes.contains(type);
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getWasteTypeIcon(type),
                size: screenWidth * 0.04,
                color: isSelected ? Colors.white : primaryColor,
              ),
              SizedBox(width: smallPadding / 2),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontSize: smallTextSize,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _wasteTypes.add(type);
              } else {
                _wasteTypes.remove(type);
              }
            });
          },
          selectedColor: primaryColor,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * index))
       .scale(begin: const Offset(0.8, 0.8));
    }).toList(),
  );
}

IconData _getWasteTypeIcon(String type) {
  switch (type) {
    case 'Plastics':
      return Icons.recycling;
    case 'Glasses':
      return Icons.wine_bar;
    case 'Papers':
      return Icons.description;
    case 'Metal':
      return Icons.architecture;
    case 'Wood':
      return Icons.nature;
    case 'Others':
      return Icons.add_circle_outline;
    default:
      return Icons.category;
  }
}

Widget _buildSafetyAndSupportCard() {
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
            'Safety & Support Measures',
            Icons.health_and_safety,
          ),
          SizedBox(height: defaultPadding),

          // Government Support Section
          _buildSupportSection().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          SizedBox(height: defaultPadding),

          // Safety Measures Section
          _buildSafetyMeasuresSection().animate()
           .fadeIn(duration: const Duration(milliseconds: 400))
           .slideX(begin: 0.2, end: 0),
        ],
      ),
    ),
  );
}

Widget _buildSupportSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSupportTypeSelection(),
        if (_hasSupport) ...[
          SizedBox(height: defaultPadding),
          if (_supportType == 'Other Organization') ...[
            _buildResponsiveTextField(
              controller: _organizationNameController,
              label: 'Organization Name',
              prefixIcon: Icons.business,
              validator: _validateRequired,
            ),
            SizedBox(height: defaultPadding),
          ],
          Text(
            'Support Types',
            style: TextStyle(
              fontSize: bodyTextSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: smallPadding),
          _buildSupportTypeChips(),
        ],
      ],
    ),
  );
}

Widget _buildSafetyMeasuresSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildExpandableToggle(
          title: 'Safety Measures',
          value: _hasSafetyMeasures,
          onChanged: (value) => setState(() => _hasSafetyMeasures = value),
          activeColor: Colors.orange[700]!,
        ),

        if (_hasSafetyMeasures) ...[
          SizedBox(height: defaultPadding),
          _buildSafetyMeasuresList(),
        ],
      ],
    ),
  );
}

Widget _buildSupportTypeSelection() {
  return Row(
    children: [
      Expanded(
        child: _buildSupportOption(
          'Government',
          Icons.account_balance,
        ),
      ),
      SizedBox(width: smallPadding),
      Expanded(
        child: _buildSupportOption(
          'Other Organization',
          Icons.business,
        ),
      ),
    ],
  );
}

Widget _buildSupportOption(String type, IconData icon) {
  final isSelected = _supportType == type && _hasSupport;
  return InkWell(
    onTap: () => setState(() {
      _hasSupport = true;
      _supportType = type;
    }),
    child: Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[700] : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: screenWidth * 0.06,
          ),
          SizedBox(height: smallPadding),
          Text(
            type,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[800],
              fontWeight: FontWeight.bold,
              fontSize: smallTextSize,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}


Widget _buildExpandableToggle({
  required String title,
  required bool value,
  required Function(bool) onChanged,
  required Color activeColor,
}) {
  return Row(
    children: [
      Expanded(
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? activeColor : Colors.grey[400],
              size: screenWidth * 0.06,
            ),
            SizedBox(width: smallPadding),
            Text(
              title,
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w500,
                color: value ? activeColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        activeTrackColor: activeColor.withOpacity(0.2),
      ),
    ],
  );
}

Widget _buildSafetyMeasuresList() {
  final measures = [
    'Training on OSHA safety precautions',
    'Use of PPE',
    'Standard operating procedures',
    'Regular safety audits',
    'Emergency response plan',
  ];

  return Column(
    children: measures.asMap().entries.map((entry) {
      final index = entry.key;
      final measure = entry.value;
      final isSelected = _safetyMeasures.contains(measure);

      return Container(
        margin: EdgeInsets.only(bottom: smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? Colors.orange[300]! : Colors.grey[300]!,
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            measure,
            style: TextStyle(
              fontSize: bodyTextSize,
              color: isSelected ? Colors.orange[700] : Colors.grey[700],
            ),
          ),
          value: isSelected,
          onChanged: (bool? checked) {
            setState(() {
              if (checked == true) {
                _safetyMeasures.add(measure);
              } else {
                _safetyMeasures.remove(measure);
              }
            });
          },
          activeColor: Colors.orange[700],
          checkColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * index))
       .slideX(begin: 0.2, end: 0);
    }).toList(),
  );
}

Widget _buildAuthorizationCard() {
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
            'Authorization Requirements',
            Icons.verified_user,
          ),
          SizedBox(height: defaultPadding),

          _buildAuthorizationToggle().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          if (_needsAuthorization) ...[
            SizedBox(height: defaultPadding),
            _buildRequiredPermitsList().animate()
             .fadeIn(duration: const Duration(milliseconds: 400))
             .slideY(begin: 0.2, end: 0),
          ],
        ],
      ),
    ),
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
              Expanded(
                child: Column(
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
          SizedBox(height: defaultPadding),
          _buildValidationSummary(),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildValidationSummary() {
  final List<String> validationIssues = _getValidationIssues();
  
  if (validationIssues.isEmpty) {
    return Container(
      padding: EdgeInsets.all(smallPadding),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: screenWidth * 0.05),
          SizedBox(width: smallPadding),
          Expanded(
            child: Text(
              'All required information has been provided',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: smallTextSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Required Information',
        style: TextStyle(
          fontSize: smallTextSize,
          fontWeight: FontWeight.bold,
          color: Colors.red[700],
        ),
      ),
      SizedBox(height: smallPadding),
      ...validationIssues.map((issue) => Padding(
        padding: EdgeInsets.only(bottom: smallPadding / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
              size: screenWidth * 0.04,
            ),
            SizedBox(width: smallPadding),
            Expanded(
              child: Text(
                issue,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: smallTextSize,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    ],
  );
}

Widget _buildSubmitButton() {
  final bool isValid = _getValidationIssues().isEmpty;
  
  return Container(
    width: double.infinity,
    height: screenHeight * 0.06,
    child: ElevatedButton(
      onPressed: isValid && !_isSubmitting ? _submitForm : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isValid ? primaryColor : Colors.grey[300],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        elevation: isValid ? 2 : 0,
      ),
      child: _isSubmitting
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: screenWidth * 0.05),
                SizedBox(width: smallPadding),
                Text(
                  'Submit Recycling Center',
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

Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    final formData = await _prepareFormData();
    await _uploadFormData(formData);

    _showSuccessDialog();
    _resetForm();
  } catch (error) {
    _showErrorDialog(error.toString());
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

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
          const Text('Success!'),
        ],
      ),
      content: const Text('Recycling center information has been successfully submitted.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // Return to list page
          },
          child: const Text('OK'),
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
          const Text('Error'),
        ],
      ),
      content: Text('Failed to submit recycling center information: $error'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Color _getCompletionColor(double percentage) {
  if (percentage >= 0.8) return Colors.green[700]!;
  if (percentage >= 0.5) return Colors.orange[700]!;
  return Colors.red[700]!;
}

IconData _getCompletionIcon(double percentage) {
  if (percentage >= 0.8) return Icons.check_circle;
  if (percentage >= 0.5) return Icons.warning;
  return Icons.error;
}

// Update the _calculateFormCompletion method with proper null checks and error handling
double _calculateFormCompletion() {
  int totalFields = 0;
  int completedFields = 0;

  // Basic Info
  totalFields += 4; // Region, district, ward, street
  if (_region != null) completedFields++;
  if (_district != null) completedFields++;
  if (_ward != null) completedFields++;
  if (_street != null) completedFields++;

  // Location
  totalFields += 2; // Latitude, longitude
  if (_latitude != null) completedFields++;
  if (_longitude != null) completedFields++;

  // Center Info
  totalFields += 4; // Name, contact, mobile, email
  if (_centerNameController.text.isNotEmpty) completedFields++;
  if (_contactPersonController.text.isNotEmpty) completedFields++;
  if (_mobileNumberController.text.isNotEmpty) completedFields++;
  if (_emailController.text.isNotEmpty) completedFields++;

  // Waste Types and Operations
  totalFields += 3; // Waste types, capacity, method
  if (_wasteTypes.isNotEmpty) completedFields++;
  if (_weeklyCapacity > 0) completedFields++;
  if (_quantificationMethod.isNotEmpty) completedFields++;

  // Prevent division by zero
  if (totalFields == 0) return 0.0;
  
  // Ensure the result is between 0 and 1
  double completion = completedFields / totalFields;
  return completion.clamp(0.0, 1.0);
}

// Add a safe conversion helper method
int _safeToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) {
    if (value.isFinite) return value.toInt();
    return 0;
  }
  return 0;
}

List<String> _getValidationIssues() {
  final issues = <String>[];
  
  // // Add validation checks for required fields
  // if (_centerName == null || _centerName!.isEmpty) {
  //   issues.add('Center name is required');
  // }
  
  // Add more validation rules...
  
  return issues;
}









Widget _buildStatusCard() {
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
            'Center Status',
            Icons.verified_outlined,
          ),
          SizedBox(height: defaultPadding),

          _buildStatusToggle().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          // if (_centerStatus == 'Formal') 
          //   _buildLicenseUpload().animate()
          //    .fadeIn(duration: const Duration(milliseconds: 400))
          //    .slideY(begin: 0.2, end: 0),
        ],
      ),
    ),
  );
}

Widget _buildStatusToggle() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operating Status',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: smallPadding),
        Row(
          children: ['Formal', 'Informal'].map((status) {
            final isSelected = _centerStatus == status;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _centerStatus = status),
                child: Container(
                  margin: EdgeInsets.all(smallPadding),
                  padding: EdgeInsets.symmetric(
                    vertical: defaultPadding,
                    horizontal: smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey[300]!,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        status == 'Formal' ? Icons.verified : Icons.warning,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(height: smallPadding),
                      Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: bodyTextSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

Widget _buildLicenseUpload() {
  return Container(
    margin: EdgeInsets.only(top: defaultPadding),
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business License',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: defaultPadding),
        _businessLicensePhoto != null
            ? _buildUploadedLicense()
            : _buildLicenseUploadButton(),
      ],
    ),
  );
}

Widget _buildOwnershipCard() {
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
            'Ownership Information',
            Icons.business,
          ),
          SizedBox(height: defaultPadding),

          // _buildOwnershipTypeSelection().animate()
          //  .fadeIn(duration: const Duration(milliseconds: 300))
          //  .slideX(begin: -0.2, end: 0),

          // SizedBox(height: defaultPadding),

          _buildOwnershipDetails().animate()
           .fadeIn(duration: const Duration(milliseconds: 400))
           .slideY(begin: 0.2, end: 0),
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
            Icons.location_on,
          ),
          SizedBox(height: defaultPadding),

          _buildLocationCoordinates().animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          SizedBox(height: defaultPadding),

          // _buildLocationAddress().animate()
          //  .fadeIn(duration: const Duration(milliseconds: 400))
          //  .slideY(begin: 0.2, end: 0),
        ],
      ),
    ),
  );
}
Widget _buildSelectableChip({
  required String label,
  required bool isSelected,
  required Function(bool) onSelected,
  required IconData icon,
}) {
  return FilterChip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: screenWidth * 0.04,
          color: isSelected ? Colors.white : primaryColor,
        ),
        SizedBox(width: smallPadding / 2),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontSize: smallTextSize,
          ),
        ),
      ],
    ),
    selected: isSelected,
    onSelected: onSelected,
    selectedColor: primaryColor,
    backgroundColor: Colors.grey[100],
    checkmarkColor: Colors.white,
    elevation: isSelected ? 2 : 0,
    padding: EdgeInsets.symmetric(
      horizontal: defaultPadding,
      vertical: smallPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey[300]!,
      ),
    ),
  );
}

Widget _buildWasteSourceChips() {
  final sources = [
    {'label': 'Direct from collection points', 'icon': Icons.location_on},
    {'label': 'Waste pickers', 'icon': Icons.person},
    {'label': 'Waste dealers', 'icon': Icons.business},
    {'label': 'Waste aggregators', 'icon': Icons.group},
  ];

  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: sources.asMap().entries.map((entry) {
      final index = entry.key;
      final source = entry.value['label'] as String;
      final icon = entry.value['icon'] as IconData;
      final isSelected = _wasteSources.contains(source);

      return _buildSelectableChip(
        label: source,
        isSelected: isSelected,
        icon: icon,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _wasteSources.add(source);
            } else {
              _wasteSources.remove(source);
            }
          });
        },
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * index))
       .scale(begin: const Offset(0.8, 0.8));
    }).toList(),
  );
}








Widget _buildEndProductsSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End Products',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          controller: _endProductsController,
          label: 'Products Produced',
          prefixIcon: Icons.inventory_2,
          isMultiline: true,
        ),
        SizedBox(height: defaultPadding),
        _buildProductPhotoUpload(),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          controller: _productMarketController,
          label: 'Target Market',
          prefixIcon: Icons.storefront,
        ),
      ],
    ),
  );
}

Widget _buildProductPhotoUpload() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Photos',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: smallPadding),
        if (_productPhoto != null)
          _buildUploadedPhoto()
        else
          _buildPhotoUploadButton(),
      ],
    ),
  );
}

Widget _buildUploadedPhoto() {
  return Stack(
    children: [
      Container(
        width: double.infinity,
        height: screenHeight * 0.2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          image: DecorationImage(
            image: FileImage(File(_productPhoto!)),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Positioned(
        top: smallPadding,
        right: smallPadding,
        child: IconButton(
          onPressed: () => setState(() => _productPhoto = null),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.red,
          ),
        ),
      ),
    ],
  ).animate()
   .fadeIn()
   .scale(begin: const Offset(0.8, 0.8));
}

Widget _buildPhotoUploadButton() {
  return InkWell(
    onTap: () => _pickImage(ImageSource.camera, 'product'),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo,
            size: screenWidth * 0.08,
            color: primaryColor,
          ),
          SizedBox(height: smallPadding),
          Text(
            'Take Product Photo',
            style: TextStyle(
              fontSize: bodyTextSize,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSupportTypeChips() {
  final supportTypes = [
    'Technology',
    'Capacity building',
    'Financial',
    'Infrastructure',
    'Training',
  ];

  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: supportTypes.asMap().entries.map((entry) {
      final index = entry.key;
      final type = entry.value;
      final isSelected = _supportTypes.contains(type);

      return FilterChip(
        label: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontSize: smallTextSize,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _supportTypes.add(type);
            } else {
              _supportTypes.remove(type);
            }
          });
        },
        selectedColor: Colors.green[700],
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          side: BorderSide(
            color: isSelected ? Colors.green[700]! : Colors.grey[300]!,
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * index))
       .scale(begin: const Offset(0.8, 0.8));
    }).toList(),
  );
}

Widget _buildAuthorizationToggle() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authorization Requirements',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: smallPadding),
        _buildExpandableToggle(
          title: 'Requires Authorization',
          value: _needsAuthorization,
          onChanged: (value) => setState(() => _needsAuthorization = value),
          activeColor: Colors.blue[700]!,
        ),
      ],
    ),
  );
}

Widget _buildRequiredPermitsList() {
  final permits = [
    'Environmental Impact Assessment (EIA)',
    'Waste Handling Permit',
    'Trade License',
    'Health and Safety Certificate',
    'Fire Safety Permit',
  ];

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: permits.length,
    itemBuilder: (context, index) {
      final permit = permits[index];
      final isRequired = _requiredPermits.contains(permit);

      return Container(
        margin: EdgeInsets.only(bottom: smallPadding),
        decoration: BoxDecoration(
          color: isRequired ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isRequired ? Colors.blue[300]! : Colors.grey[300]!,
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            permit,
            style: TextStyle(
              fontSize: bodyTextSize,
              color: isRequired ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
          value: isRequired,
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                _requiredPermits.add(permit);
              } else {
                _requiredPermits.remove(permit);
              }
            });
          },
          activeColor: Colors.blue[700],
          checkColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: smallPadding,
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * index))
       .slideX(begin: 0.2, end: 0);
    },
  );
}

// Missing methods that were called
Future<void> _pickImage(ImageSource source, String type) async {
  try {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    
    if (image != null) {
      setState(() {
        if (type == 'license') {
          _businessLicensePhoto = image.path;
        } else if (type == 'product') {
          _productPhoto = image.path;
        }
      });
    }
  } catch (e) {
    _showErrorSnackBar('Error picking image: $e');
  }
}

Future<Map<String, dynamic>> _prepareFormData() async {
  // Upload images if they exist
  // String? licensePhotoUrl;
  // String? productPhotoUrl;

  // if (_businessLicensePhoto != null) {
  //   licensePhotoUrl = await _uploadImage(_businessLicensePhoto!, 'licenses');
  // }

  // if (_productPhoto != null) {
  //   productPhotoUrl = await _uploadImage(_productPhoto!, 'products');
  // }

  return {
    'date': Timestamp.fromDate(_selectedDate),
    'dataCollector': {
      'uid': widget.user?.uid,
      'name': _dataCollectorName,
    },
    // 'status': {
    //   'centerStatus': _centerStatus,
    //   'businessLicensePhoto': licensePhotoUrl,
    // },
    'ownership': {
      // 'type': _ownershipType,
      'centerName': _centerNameController.text,
      'contactPerson': _contactPersonController.text,
      'title': _titleNameController.text,
      'mobileNumber': _mobileNumberController.text,
      'email': _emailController.text,
    },
    
      'location': {
        'region': _region,
        'district': _districtController.text,
        // 'ward': _locationWard,
        // 'street': _locationStreet,
        'coordinates': {
          'latitude': _latitude,
          'longitude': _longitude,
        },
      },
      'wasteTypes': {
        'types': _wasteTypes,
        'otherType': _otherWasteType,
        // 'sources': _wasteSources,
      },
      // 'operations': {
      //   'weeklyCapacity': _weeklyCapacity,
      //   'quantificationMethod': _quantificationMethod,
      //   'coreBusiness': _coreBusiness,
      //   'recyclingType': _recyclingType,
      //   'otherRecyclingType': _otherRecyclingType,
      //   'endProducts': _endProductsController.text,
      //   'productPhoto': productPhotoUrl,
      //   'productMarket': _productMarketController.text,
      // },
  //     'support': {
  //   'hasGovernmentSupport': _hasGovernmentSupport,
  //   'hasOrganizationSupport': _hasOrganizationSupport,
  //   'organizationName': _organizationNameController.text,
  //   'supportTypes': _supportTypes,
  // },
      // 'safety': {
      //   'hasSafetyMeasures': _hasSafetyMeasures,
      //   'measures': _safetyMeasures,
      //   'otherMeasure': _otherSafetyMeasure,
      // },
      // 'authorization': {
      //   'required': _needsAuthorization,
      //   'permits': _requiredPermits,
      //   'otherPermit': _otherPermit,
      // },
    'metadata': {
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
    },
  };
}

Future<void> _uploadFormData(Map<String, dynamic> formData) async {
  try {
    await _firestore.collection('recyclingCentersCollection').add(formData);
  } catch (e) {
    throw Exception('Failed to upload form data: $e');
  }
}

void _resetForm() {
  setState(() {
_selectedDate = DateTime.now();
    _centerStatus = 'Formal';
    _ownershipType = 'Private';
    _weeklyCapacity = 1;
    _quantificationMethod = 'Weighing';
    _coreBusiness = 'Sell to other waste users (recyclers)';
    _recyclingType = 'Production of end use products';
    
    // Clear controllers
    _centerNameController.clear();
    _contactPersonController.clear();
    _mobileNumberController.clear();
    _emailController.clear();
    _endProductsController.clear();
    _productMarketController.clear();
    
    // Clear lists
    _wasteTypes = [];
    _wasteSources = [];
    _supportTypes = [];
    _safetyMeasures = [];
    _requiredPermits = [];
    
    // Reset booleans
    _hasSupport = false;
    _hasSafetyMeasures = false;
    _needsAuthorization = false;
    
    // Clear optional values
    _otherOwnershipType = null;
    _otherWasteType = null;
    _otherRecyclingType = null;
    _otherSupportType = null;
    _otherSafetyMeasure = null;
    _otherPermit = null;
    
    // Clear images
    _businessLicensePhoto = null;
    _productPhoto = null;
  });
  _formKey.currentState?.reset();
}


Widget _buildSupportAndSafetyCard() {
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
            'Support & Safety',
            Icons.health_and_safety,
          ),
          SizedBox(height: defaultPadding),

          // Support Types Section
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _buildCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Government Support Toggle
                Row(
                  children: [
                    Icon(
                      _hasGovernmentSupport ? Icons.check_circle : Icons.cancel,
                      color: _hasGovernmentSupport ? Colors.green[700] : Colors.grey[400],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Text(
                        'Government Support',
                        style: TextStyle(
                          fontSize: bodyTextSize,
                          fontWeight: FontWeight.w500,
                          color: _hasGovernmentSupport ? Colors.green[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: _hasGovernmentSupport,
                      onChanged: (value) => setState(() => _hasGovernmentSupport = value),
                      activeColor: Colors.green[700],
                      activeTrackColor: Colors.green[100],
                    ),
                  ],
                ),

                // Organization Support Toggle
                SizedBox(height: defaultPadding),
                Row(
                  children: [
                    Icon(
                      _hasOrganizationSupport ? Icons.check_circle : Icons.cancel,
                      color: _hasOrganizationSupport ? Colors.blue[700] : Colors.grey[400],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Text(
                        'Organization Support',
                        style: TextStyle(
                          fontSize: bodyTextSize,
                          fontWeight: FontWeight.w500,
                          color: _hasOrganizationSupport ? Colors.blue[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: _hasOrganizationSupport,
                      onChanged: (value) => setState(() => _hasOrganizationSupport = value),
                      activeColor: Colors.blue[700],
                      activeTrackColor: Colors.blue[100],
                    ),
                  ],
                ),

                // Organization Name Field
                if (_hasOrganizationSupport) ...[
                  SizedBox(height: defaultPadding),
                  _buildResponsiveTextField(
                    controller: _organizationNameController,
                    label: 'Organization Name',
                    prefixIcon: Icons.business,
                    validator: _validateRequired,
                  ),
                ],

                // Support Types for either Government or Organization
                if (_hasGovernmentSupport || _hasOrganizationSupport) ...[
                  SizedBox(height: defaultPadding),
                  Text(
                    'Support Types',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: smallPadding),
                  _buildSupportTypeChips(),
                ],
              ],
            ),
          ).animate()
           .fadeIn(duration: const Duration(milliseconds: 300))
           .slideX(begin: -0.2, end: 0),

          SizedBox(height: defaultPadding),

          // Safety Measures Section
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: _buildCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasSafetyMeasures ? Icons.security : Icons.warning,
                      color: _hasSafetyMeasures ? Colors.orange[700] : Colors.grey[400],
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: Text(
                        'Safety Measures',
                        style: TextStyle(
                          fontSize: bodyTextSize,
                          fontWeight: FontWeight.w500,
                          color: _hasSafetyMeasures ? Colors.orange[700] : Colors.grey[700],
                        ),
                      ),
                    ),
                    Switch(
                      value: _hasSafetyMeasures,
                      onChanged: (value) => setState(() => _hasSafetyMeasures = value),
                      activeColor: Colors.orange[700],
                      activeTrackColor: Colors.orange[100],
                    ),
                  ],
                ),
                if (_hasSafetyMeasures) ...[
                  SizedBox(height: defaultPadding),
                  _buildSafetyMeasuresList(),
                ],
              ],
            ),
          ).animate()
           .fadeIn(duration: const Duration(milliseconds: 400))
           .slideX(begin: 0.2, end: 0),
        ],
      ),
    ),
  );
}

Widget _buildUploadedLicense() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Stack(
      children: [
        Container(
          width: double.infinity,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            image: DecorationImage(
              image: FileImage(File(_businessLicensePhoto!)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: smallPadding,
          right: smallPadding,
          child: Row(
            children: [
              IconButton(
                onPressed: () => _pickImage(ImageSource.camera, 'license'),
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                ),
              ),
              SizedBox(width: smallPadding),
              IconButton(
                onPressed: () => setState(() => _businessLicensePhoto = null),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ).animate()
   .fadeIn()
   .scale(begin: const Offset(0.8, 0.8));
}

Widget _buildLicenseUploadButton() {
  return InkWell(
    onTap: () => _pickImage(ImageSource.camera, 'license'),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo,
            size: screenWidth * 0.08,
            color: primaryColor,
          ),
          SizedBox(height: smallPadding),
          Text(
            'Take License Photo',
            style: TextStyle(
              fontSize: bodyTextSize,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}








Widget _buildBusinessQuestionsSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Core Business Question
        Text(
          'What is the core business of the recycling center?',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: defaultPadding),
        _buildBusinessTypeSelection(),
        
        SizedBox(height: defaultPadding * 1.5),
        
        // Recycling Type Question
        Text(
          'What type of recycling takes place at the recycling center?',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: defaultPadding),
        _buildRecyclingTypeSelection(),
      ],
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildBusinessTypeSelection() {
  final businessTypes = [
    {
      'type': 'Sell to other waste users (recyclers)',
      'icon': Icons.store,
    },
    {
      'type': 'Own recycling',
      'icon': Icons.recycling,
    },
  ];

  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: businessTypes.asMap().entries.map((entry) {
      final type = entry.value['type'] as String;
      final icon = entry.value['icon'] as IconData;
      final isSelected = _coreBusiness == type;

      return InkWell(
        onTap: () => setState(() => _coreBusiness = type),
        child: Container(
          width: (screenWidth - (cardPadding * 4)) / 2,
          padding: EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: screenWidth * 0.06,
              ),
              SizedBox(height: smallPadding),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: smallTextSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * entry.key))
       .scale(begin: const Offset(0.8, 0.8));
    }).toList(),
  );
}

Widget _buildRecyclingTypeSelection() {
  return Column(
    children: [
      _buildRecyclingTypeOption(
        'Production of end use products',
        Icons.inventory_2,
      ),
      SizedBox(height: smallPadding),
      _buildRecyclingTypeOption(
        'Production of raw materials',
        Icons.category,
      ),
      SizedBox(height: smallPadding),
      _buildRecyclingTypeOption(
        'Others',
        Icons.more_horiz,
      ),
      if (_recyclingType == 'Others') ...[
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          controller: TextEditingController(text: _otherRecyclingType),
          label: 'Specify other recycling type',
          prefixIcon: Icons.edit,
          onChanged: (value) => setState(() => _otherRecyclingType = value),
        ),
      ],
    ],
  );
}

Widget _buildRecyclingTypeOption(String type, IconData icon) {
  final isSelected = _recyclingType == type;
  return InkWell(
    onTap: () => setState(() => _recyclingType = type),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: smallPadding,
      ),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: isSelected ? primaryColor : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
            size: screenWidth * 0.05,
          ),
          SizedBox(width: smallPadding),
          Expanded(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: bodyTextSize,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
        ],
      ),
    ),
  );
}







Widget _buildOwnershipTypeSelection() {
  final ownershipTypes = [
    {'type': 'Private', 'icon': Icons.person_outline},
    {'type': 'Government', 'icon': Icons.account_balance},
    {'type': 'Others', 'icon': Icons.more_horiz},
  ];

  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: ownershipTypes.asMap().entries.map((entry) {
      final type = entry.value['type'] as String;
      final icon = entry.value['icon'] as IconData;
      final isSelected = _ownershipType == type;

      return InkWell(
        onTap: () => setState(() => _ownershipType = type),
        child: Container(
          width: (screenWidth - (cardPadding * 2) - (smallPadding * 2)) / 3,
          padding: EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: screenWidth * 0.06,
              ),
              SizedBox(height: smallPadding),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: smallTextSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ).animate()
       .fadeIn(delay: Duration(milliseconds: 100 * entry.key))
       .scale(begin: const Offset(0.8, 0.8));
    }).toList(),
  );
}

Widget _buildOwnershipDetails() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // if (_ownershipType == 'Others')
      //   _buildResponsiveTextField(
      //     controller: _otherOwnershipController,
      //     label: 'Specify Other Ownership Type',
      //     prefixIcon: Icons.edit,
      //     validator: _validateRequired,
      //   ),
      //   SizedBox(height: defaultPadding),
      _buildResponsiveTextField(
        controller: _centerNameController,
        label: 'Center Name',
        prefixIcon: Icons.business,
        validator: _validateRequired,
      ),
      _buildResponsiveTextField(
        controller: _contactPersonController,
        label: 'Contact Person',
        prefixIcon: Icons.person,
        validator: _validateRequired,
      ),
      _buildResponsiveTextField(
        controller: _titleNameController,
        label: 'Title',
        prefixIcon: Icons.person,
        validator: _validateRequired,
      ),
      _buildResponsiveTextField(
        controller: _mobileNumberController,
        label: 'Mobile Number',
        prefixIcon: Icons.phone,
        keyboardType: TextInputType.phone,
        validator: _validatePhone,
      ),
      _buildResponsiveTextField(
        controller: _emailController,
        label: 'Email',
        prefixIcon: Icons.email,
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
      ),
    ].animate(interval: const Duration(milliseconds: 100))
     .fadeIn()
     .slideX(begin: 0.2, end: 0),
  );
}

// Required field validator
String? _validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }
  return null;
}

// Email validator
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Email is optional
  }
  // Simple email validation regex
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Please enter a valid email address';
  }
  return null;
}

// Phone number validator
String? _validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return null; // Phone is optional
  }
  // Remove any spaces or special characters
  final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
  // Check for valid length and format
  if (cleanPhone.length < 10 || cleanPhone.length > 15) {
    return 'Please enter a valid phone number';
  }
  return null;
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
              icon: const Icon(Icons.my_location),
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



Widget _buildLocationAddress() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: _buildCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Details',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveDropdown(
          label: 'Ward',
          value: _locationWard,
          items: districtsWards[_district] ?? [], // Replace with actual data
          prefixIcon: Icons.location_city,
          onChanged: (value) => setState(() => _locationWard = value),
        ),
        // _buildResponsiveDropdown(
        //   label: 'Street',
        //   value: _locationStreet,
        //   items: ['Street 1', 'Street 2'], // Replace with actual data
        //   prefixIcon: Icons.add_road,
        //   onChanged: (value) => setState(() => _locationStreet = value),
        // ),
      ],
    ),
  );
}

// Add validation methods
String? _validateLatitude(String? value) {
  if (value == null || value.isEmpty) return 'Required';
  final lat = double.tryParse(value);
  if (lat == null || lat < -90 || lat > 90) {
    return 'Invalid latitude';
  }
  return null;
}

String? _validateLongitude(String? value) {
  if (value == null || value.isEmpty) return 'Required';
  final lng = double.tryParse(value);
  if (lng == null || lng < -180 || lng > 180) {
    return 'Invalid longitude';
  }
  return null;
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
}