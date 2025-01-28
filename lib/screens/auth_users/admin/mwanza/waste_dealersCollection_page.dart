import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;


class WasteDealerForm extends StatefulWidget {
  final User? user;
  const WasteDealerForm({Key? key, required this.user}) : super(key: key);

  @override
  _WasteDealerFormState createState() => _WasteDealerFormState();
}

// Add these data models at the top of the file
class ItemType {
  final String name;
  final IconData icon;
  final Color color;

  const ItemType({
    required this.name,
    required this.icon,
    required this.color,
  });
}


class _WasteDealerFormState extends State<WasteDealerForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
 String _firstName = '';
  bool _isAdmin = false;
  // Screen size utilities
  late double screenWidth;
  late double screenHeight;
  static const primaryColor = Color(0xFF115937);

  // Responsive dimensions
  late double defaultPadding;
  late double smallPadding;
  late double cardPadding;
  late double headingSize;
  late double bodyTextSize;
  late double smallTextSize;

  // Add controllers for editable coordinates
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  // Form controllers
  final _dataCollectorController = TextEditingController();
  final _practitionerNameController = TextEditingController();
  final _practitionerAddressController = TextEditingController();
  final _practitionerMobileController = TextEditingController();
  final _practitionerEmailController = TextEditingController();
  final _otherCategoryController = TextEditingController();
  final _otherOwnershipController = TextEditingController();
  final _officialNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessMobileController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _otherWasteTypeController = TextEditingController();
  final _mainBuyerController = TextEditingController();
  final _otherSourcesController = TextEditingController();
  final _otherChallengesController = TextEditingController();
  final _otherSuccessController = TextEditingController();
  final _otherSafetyController = TextEditingController();
  final _otherSupportController = TextEditingController();
  final _streetController = TextEditingController();

  // Form data
  DateTime _selectedDate = DateTime.now();
  String? _dataCollectorName;
  String? _region;
  String? _district;
  String? _division;
  String? _ward;
  String? _street;
  String _practitionerCategory = 'Waste Picker';
  String _operationalStatus = 'Formal';
  String? _legalDocumentPhoto;
  String _ownershipStatus = 'Individual';
  double? _latitude;
  double? _longitude;
  List<String> _wasteTypes = [];
  List<String> _wasteSources = [];
  int _weeklyCapacity = 1;
  String _quantificationMethod = 'Scale house';
  String _coreBusiness = 'Collecting';
  String? _mainBuyer;
  List<String> _sourceKnowledge = [];
  bool _hasSupport = false;
  List<String> _supportTypes = [];
  List<String> _neededSupport = [];
  bool _hasSafetyMeasures = false;
  List<String> _safetyMeasures = [];
  List<String> _successStories = [];
  List<String> _challenges = [];

  Position? _currentPosition;



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
    _showSnackBar('Error uploading image: $e');
    return null;
  }
}








// Data lists
final wasteTypesList = [
  const ItemType(name: 'Plastics', icon: Icons.recycling, color: Colors.blue),
  const ItemType(name: 'Glass', icon: Icons.wine_bar, color: Colors.green),
  const ItemType(name: 'Papers', icon: Icons.description, color: Colors.orange),
  const ItemType(name: 'Metal', icon: Icons.construction, color: Colors.grey),
  const ItemType(name: 'Wood', icon: Icons.park, color: Colors.brown),
  const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.purple),
];

final supportTypesList = [
  const ItemType(name: 'Technology', icon: Icons.computer, color: Colors.blue),
  const ItemType(name: 'Capacity Building', icon: Icons.school, color: Colors.green),
  const ItemType(name: 'Financial', icon: Icons.attach_money, color: Colors.orange),
  const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.purple),
];

final neededSupportList = [
  const ItemType(name: 'Training', icon: Icons.school, color: Colors.blue),
  const ItemType(name: 'Capital', icon: Icons.money, color: Colors.green),
  const ItemType(name: 'Tools', icon: Icons.build, color: Colors.orange),
  const ItemType(name: 'Marketing', icon: Icons.trending_up, color: Colors.purple),
  // const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
];

final safetyMeasuresList = [
  const ItemType(name: 'PPE Usage', icon: Icons.security, color: Colors.blue),
  const ItemType(name: 'Operating Procedures', icon: Icons.assignment, color: Colors.green),
  const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
];









  // Geography Data (Replace with actual data)
  // final List<String> regions = ['Mwanza'];
  // final Map<String, List<String>> districts = {
  //   'Mwanza': [],
  // };
// Geography Data for Mwanza Region
final List<String> regions = ['Mwanza'];

final Map<String, List<String>> districts = {
  'Mwanza': ['Mwanza City/Nyamagana'],
};

// For districts and their wards (as strings only)
final Map<String, List<String>> districtsWards = {
  // 'Ilemela': [
  //   'Bugogwa', 'Buswelu', 'Buzuruga', 'Ibungilo', 'Ilemela', 
  //   'Kahama', 'Kawekamo', 'Kayenze', 'Kirumba', 'Kiseke', 
  //   'Kitangiri', 'Mecco', 'Nyakato', 'Nyamanoro', 'Nyamhongolo', 
  //   'Nyasaka', 'Pasiansi', 'Sangabuye', 'Shibula'
  // ],
  'Mwanza City/Nyamagana': [
    'Buhongwa', 'Butimba', 'Igogo', 'Igoma', 'Isamilo', 
    'Kishili', 'Luchelele', 'Lwanhima', 'Mabatini', 'Mahina', 
    'Mbugani', 'Mhandu', 'Mikuyuni', 'Mirongo', 'Mkolani', 
    'Nyamagana', 'Nyegezi', 'Pamba'
  ],
};




















  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
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
      });
    } catch (e) {
      _showSnackBar('Error getting location');
    }
  }



Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }






//  Update the _loadUserData method to include new user details
 Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      if (widget.user != null) {
        final userDoc = await _firestore.collection('users').doc(widget.user!.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _dataCollectorName = '${userDoc['firstName']} ${userDoc['lastName']}';
            _firstName = userDoc.data()?['firstName'] ?? '';
            _isAdmin = userDoc.data()?['role'] == 'admin';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error fetching user data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  

  void _showSnackBar(String message, [Color? red]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              preferredSize: Size.fromHeight(screenHeight * 0.08),
              child: Container(
                height: screenHeight * 0.08,
                padding: EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                  vertical: smallPadding,
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
                    Icon(
                      Icons.business,
                      color: const Color(0xFF115937),
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: smallPadding),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New Waste Dealer',
                          style: TextStyle(
                            fontSize: headingSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF115937),
                          ),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: smallTextSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _buildFormContent(),
      ),
    );
  }

// Add this inside _WasteDealerFormState class

Widget _buildFormContent() {
  return Container(
    color: Colors.white,
    child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  _buildBasicInfoCard(),
                  SizedBox(height: defaultPadding),
                  _buildLocationCard(),
                  SizedBox(height: defaultPadding),
                // Geographic Location Card
                _buildGeographicLocationCard(),
                const SizedBox(height: 24),
                  _buildPractitionerInfoCard(),
                  SizedBox(height: defaultPadding),
                  _buildOperationalStatusCard(),
                  SizedBox(height: defaultPadding),
                  // _buildBusinessInfoCard(),
                  // SizedBox(height: defaultPadding),
                  _buildWasteTypesCard(),
                  SizedBox(height: defaultPadding),
                  // _buildSourcesCard(),
                  // SizedBox(height: defaultPadding),
                  // _buildCapacityCard(),
                  // SizedBox(height: defaultPadding),
                  // _buildSupportCard(),
                  // SizedBox(height: defaultPadding),
                  // _buildSafetyCard(),
                  // SizedBox(height: defaultPadding),
                  // _buildSuccessAndChallengesCard(),
                  // SizedBox(height: defaultPadding * 2),
                  _buildSubmitButton(),
                ].animate(interval: const Duration(milliseconds: 50))
                 .fadeIn(duration: const Duration(milliseconds: 300))
                 .slideY(begin: 0.2, end: 0),
              ),
            ),
          ),
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
          ),
          SizedBox(height: defaultPadding),

//           // Data Collector Name
//           _buildResponsiveTextField(
//             label: 'Data Collector Name',
//             controller: _dataCollectorController,
//             prefixIcon: Icons.person_outline,
//             enabled: false,
//           ),

//           // Location Information
//           _buildLocationDropdowns(),
//         ],
//       ),
//     ),
//   );
// }
Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, 
                     size: screenWidth * 0.05,
                     color: Colors.grey[600]),
                SizedBox(width: smallPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Collector',
                        style: TextStyle(
                          fontSize: smallTextSize,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: smallPadding / 2),
                      Text(
                        _dataCollectorName ?? 'N/A',
                        style: TextStyle(
                          fontSize: bodyTextSize,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
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
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}



// Widget _buildLocationDropdowns() {
//   return LayoutBuilder(
//     builder: (context, constraints) {
//       return Wrap(
//         spacing: smallPadding,
//         runSpacing: smallPadding,
//         children: [
//           _buildResponsiveDropdown(
//             label: 'Region',
//             value: _region,
//             items: regions,
//             icon: Icons.map,
//             onChanged: (value) {
//               setState(() {
//                 _region = value;
//                 _district = null;
//                 _division = null;
//                 _ward = null;
//                 _street = null;
//               });
//             },
//           ),
//           if (_region != null)
//             _buildResponsiveDropdown(
//               label: 'District',
//               value: _district,
//               items: districts[_region] ?? [],
//               icon: Icons.location_city,
//               onChanged: (value) => setState(() {
//                 _district = value;
//                 _division = null;
//                 _ward = null;
//                 _street = null;
//               }),
//             ),
//           // Add similar dropdowns for division, ward, street
//         ],
//       );
//     },
//   );
// }

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
            'Location Information',
            Icons.location_on_outlined,
          ),
          SizedBox(height: defaultPadding),
          
          // Location Dropdowns wrapped in responsive container
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              return Wrap(
                spacing: defaultPadding,
                runSpacing: defaultPadding,
                children: [
                  SizedBox(
                    width: isNarrow ? constraints.maxWidth 
                                  : (constraints.maxWidth - defaultPadding) / 2,
                    child: _buildResponsiveDropdown(
                      label: 'Region',
                      value: _region,
                      items: regions,
                      icon: Icons.map, // Added icon
                      onChanged: (value) {
                        setState(() {
                          _region = value;
                          _district = null;
                          _division = null;
                          _ward = null;
                          _street = null;
                        });
                      },
                    ),
                  ),
                  if (_region != null)
                    SizedBox(
                      width: isNarrow ? constraints.maxWidth 
                                    : (constraints.maxWidth - defaultPadding) / 2,
                      child: _buildResponsiveDropdown(
                        label: 'District',
                        value: _district,
                        items: districts[_region] ?? [],
                        icon: Icons.location_city, // Added icon
                        onChanged: (value) {
                          setState(() {
                            _district = value;
                            _division = null;
                            _ward = null;
                            _street = null;
                          });
                        },
                      ),
                    ),
                  if (_district != null)
                  //   SizedBox(
                  //     width: isNarrow ? constraints.maxWidth 
                  //                   : (constraints.maxWidth - defaultPadding) / 2,
                  //     child: _buildResponsiveDropdown(
                  //       label: 'Division',
                  //       value: _division,
                  //       items: ['Division 1', 'Division 2'],
                  //       icon: Icons.grid_view, // Added icon
                  //       onChanged: (value) {
                  //         setState(() {
                  //           _division = value;
                  //           _ward = null;
                  //           _street = null;
                  //         });
                  //       },
                  //     ),
                  //   ),
                  // if (_division != null)
                    SizedBox(
                      width: isNarrow ? constraints.maxWidth 
                                    : (constraints.maxWidth - defaultPadding) / 2,
                      child: _buildResponsiveDropdown(
                        label: 'Ward',
                        value: _ward,
                        items: districtsWards[_district] ?? [],
                        icon: Icons.apartment, // Added icon
                        onChanged: (value) => setState(() => _ward = value),
                      ),
                    ),
                    if (_ward != null)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: _buildResponsiveTextField(
                        label: 'Street',
                        controller: _streetController,
                        prefixIcon: Icons.add_road,
                      ),
                    ),
                  // if (_ward != null)
                  //   SizedBox(
                  //     width: isNarrow ? constraints.maxWidth 
                  //                   : (constraints.maxWidth - defaultPadding) / 2,
                  //     child: _buildResponsiveDropdown(
                  //       label: 'Street',
                  //       value: _street,
                  //       items: ['Street 1', 'Street 2'],
                  //       icon: Icons.add_road, // Added icon
                  //       onChanged: (value) => setState(() => _street = value),
                  //     ),
                  //   ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}
Widget _buildPractitionerInfoCard() {
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
            'Practitioner Information',
            Icons.person_outline,
          ),
          SizedBox(height: defaultPadding),

          // Category Selection
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category of Waste Practitioner',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF115937),
                  ),
                ),
                SizedBox(height: defaultPadding),
                Wrap(
                  spacing: smallPadding,
                  runSpacing: smallPadding,
                  children: [
                    _buildCategoryChip('Waste Picker', Icons.recycling),
                    _buildCategoryChip('Waste Dealer', Icons.store),
                    _buildCategoryChip('Waste Aggregator', Icons.business),
                    _buildCategoryChip('Others', Icons.more_horiz),
                  ],
                ),
              ],
            ),
          ),

          // Contact Details
          if (_practitionerCategory == 'Others')
            Padding(
              padding: EdgeInsets.only(top: defaultPadding),
              child: _buildResponsiveTextField(
                label: 'Specify Other Category',
                controller: _otherCategoryController,
                prefixIcon: Icons.edit_note,
              ),
            ),

          SizedBox(height: defaultPadding),

          // Basic Information Fields
          _buildResponsiveTextField(
            label: 'Name of Waste Practitioner',
            controller: _practitionerNameController,
            prefixIcon: Icons.person,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          _buildResponsiveTextField(
            label: 'Address',
            controller: _practitionerAddressController,
            prefixIcon: Icons.location_on_outlined,
          ),
          _buildResponsiveTextField(
            label: 'Mobile Number',
            controller: _practitionerMobileController,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          _buildResponsiveTextField(
            label: 'Email Address',
            controller: _practitionerEmailController,
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    ),
  );
}

// Continue with helper widgets and other form sections...
Widget _buildSectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: const Color(0xFF115937).withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF115937),
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
            color: const Color(0xFF115937),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

















Widget _buildOperationalStatusCard() {
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
            'Operational Status',
            Icons.verified_outlined,
          ),
          SizedBox(height: defaultPadding),
          
          // Status Selection
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operational Status',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF115937),
                  ),
                ),
                SizedBox(height: smallPadding),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusOption(
                        'Formal',
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: smallPadding),
                    Expanded(
                      child: _buildStatusOption(
                        'Informal',
                        Icons.cancel_outlined,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // if (_operationalStatus == 'Formal')
          //   Padding(
          //     padding: EdgeInsets.only(top: defaultPadding),
          //     child: _buildDocumentUploadSection(),
          //   ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildDocumentUploadSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.blue[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, 
                 color: Colors.blue[700], 
                 size: screenWidth * 0.06),
            SizedBox(width: smallPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Documentation',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Upload business license or permit',
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        Center(
          child: _legalDocumentPhoto != null
              ? _buildDocumentPreview()
              : _buildUploadButton(),
        ),
      ],
    ),
  );
}

Widget _buildBusinessInfoCard() {
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
            'Business Information',
            Icons.business,
          ),
          SizedBox(height: defaultPadding),

          // Ownership Type Selection
          _buildOwnershipTypeSection(),

          if (_ownershipStatus != 'Individual') ...[
            SizedBox(height: defaultPadding),
            _buildBusinessDetailsSection(),
          ],
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideX(begin: 0.2, end: 0);
}

Widget _buildOwnershipTypeSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ownership Type',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF115937),
          ),
        ),
        SizedBox(height: defaultPadding),
        Wrap(
          spacing: smallPadding,
          runSpacing: smallPadding,
          children: [
            _buildOwnershipChip('Individual', Icons.person),
            _buildOwnershipChip('Company', Icons.business),
            _buildOwnershipChip('CBO', Icons.groups),
            _buildOwnershipChip('Others', Icons.more_horiz),
          ],
        ),
      ],
    ),
  );
}

Widget _buildBusinessDetailsSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          'Business Details',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF115937),
          ),
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          label: 'Official Business Name',
          controller: _officialNameController,
          prefixIcon: Icons.business_outlined,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
        _buildResponsiveTextField(
          label: 'Contact Person',
          controller: _contactPersonController,
          prefixIcon: Icons.person_outline,
        ),
        _buildResponsiveTextField(
          label: 'Business Address',
          controller: _businessAddressController,
          prefixIcon: Icons.location_on_outlined,
        ),
        _buildResponsiveTextField(
          label: 'Business Mobile',
          controller: _businessMobileController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        _buildResponsiveTextField(
          label: 'Business Email',
          controller: _businessEmailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    ),
  );
}

// Widget _buildLocationCard() {
//   return Card(
//     elevation: 2,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(screenWidth * 0.03),
//     ),
//     child: Padding(
//       padding: EdgeInsets.all(cardPadding),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionHeader(
//             'Physical Location',
//             Icons.location_on,
//           ),
//           SizedBox(height: defaultPadding),

//           // Location Dropdowns
//           _buildLocationSelectionSection(),

//           SizedBox(height: defaultPadding),

//           // Coordinates
//           _buildCoordinatesSection(),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideX(begin: -0.2, end: 0);
// }

// Helper methods for document handling
Future<void> _pickDocument() async {
  try {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _legalDocumentPhoto = image.path);
    }
  } catch (e) {
    _showSnackBar('Error picking image: $e');
  }
}

// Helper widgets for the form
Widget _buildStatusOption(String status, IconData icon, Color color) {
  final isSelected = _operationalStatus == status;
  return InkWell(
    onTap: () => setState(() => _operationalStatus = status),
    child: Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? color : Colors.grey[500],
            size: screenWidth * 0.08,
          ),
          SizedBox(height: smallPadding),
          Text(
            status,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: smallTextSize,
            ),
          ),
        ],
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
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
            'Waste Types',
            Icons.delete_outline,
          ),
          SizedBox(height: defaultPadding),

          // Waste Types Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 600 ? 3 : 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: smallPadding,
              mainAxisSpacing: smallPadding,
            ),
            itemCount: wasteTypesList.length,
            itemBuilder: (context, index) => _buildWasteTypeChip(
              wasteTypesList[index].name,
              wasteTypesList[index].icon,
            ),
          ),

          if (_wasteTypes.contains('Others'))
            Padding(
              padding: EdgeInsets.only(top: defaultPadding),
              child: _buildResponsiveTextField(
                label: 'Specify Other Waste Types',
                controller: _otherWasteTypeController,
                prefixIcon: Icons.edit_note,
              ),
            ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildSourcesCard() {
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
            'Sources & Collection',
            Icons.source_outlined,
          ),
          SizedBox(height: defaultPadding),

          Container(
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
                  'Main Sources of Waste',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF115937),
                  ),
                ),
                SizedBox(height: defaultPadding),
                _buildSourceOptions(),
              ],
            ),
          ),

          if (_wasteSources.contains('Others'))
            Padding(
              padding: EdgeInsets.only(top: defaultPadding),
              child: _buildResponsiveTextField(
                label: 'Specify Other Sources',
                controller: _otherSourcesController,
                prefixIcon: Icons.edit_note,
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _buildSupportCard() {
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
            'Support & Assistance',
            Icons.support_outlined,
          ),
          SizedBox(height: defaultPadding),

          // Government Support Toggle
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: _hasSupport ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(
                color: _hasSupport ? Colors.green[200]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Government Support',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.w500,
                      color: _hasSupport ? Colors.green[700] : Colors.grey[800],
                    ),
                  ),
                  subtitle: Text(
                    'Support from government or organizations',
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: _hasSupport ? Colors.green[600] : Colors.grey[600],
                    ),
                  ),
                  value: _hasSupport,
                  onChanged: (value) => setState(() => _hasSupport = value),
                  activeColor: Colors.green[700],
                ),
                if (_hasSupport) ...[
                  SizedBox(height: defaultPadding),
                  _buildSupportTypeGrid(),
                ],
              ],
            ),
          ),
          if (_supportTypes.contains('Others')) ...[
            SizedBox(height: defaultPadding),
            _buildOtherSupportInput(),
          ],
          SizedBox(height: defaultPadding),

          // Needed Support Section
          _buildNeededSupportSection(),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideX(begin: -0.2, end: 0);
}

Widget _buildSafetyCard() {
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
            'Safety Measures',
            Icons.health_and_safety_outlined,
          ),
          SizedBox(height: defaultPadding),

          // Safety Toggle and Measures
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: _hasSafetyMeasures ? Colors.orange[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(
                color: _hasSafetyMeasures ? Colors.orange[200]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Safety Measures Implemented',
                    style: TextStyle(
                      fontSize: bodyTextSize,
                      fontWeight: FontWeight.w500,
                      color: _hasSafetyMeasures ? Colors.orange[700] : Colors.grey[800],
                    ),
                  ),
                  subtitle: Text(
                    'Occupational health and safety measures',
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: _hasSafetyMeasures ? Colors.orange[600] : Colors.grey[600],
                    ),
                  ),
                  value: _hasSafetyMeasures,
                  onChanged: (value) => setState(() => _hasSafetyMeasures = value),
                  activeColor: Colors.orange[700],
                ),
                if (_hasSafetyMeasures) ...[
                  SizedBox(height: defaultPadding),
                  _buildSafetyMeasuresGrid(),
                ],
              ],
            ),
          ),
                    if (_safetyMeasures.contains('Others')) ...[
            SizedBox(height: defaultPadding),
            _buildOtherSafetyInput(),
          ],
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

Widget _buildSuccessAndChallengesCard() {
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
            'Success Stories & Challenges',
            Icons.auto_graph,
          ),
          SizedBox(height: defaultPadding),

          // Success Stories Section
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success Stories',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: defaultPadding),
                _buildSuccessStoriesGrid(),
              ],
            ),
          ),
          if (_successStories.contains('Others')) ...[
            SizedBox(height: defaultPadding),
            _buildOtherSuccessInput(),
          ],
          SizedBox(height: defaultPadding),

          // Challenges Section
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenges',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: defaultPadding),
                _buildChallengesGrid(),
              ],
            ),
          ),
          
          if (_challenges.contains('Others')) ...[
            SizedBox(height: defaultPadding),
            _buildOtherChallengeInput(),
          ],
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

// Helper methods for grids and options
Widget _buildSupportTypeGrid() {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: screenWidth > 600 ? 3 : 2,
      childAspectRatio: 3,
      crossAxisSpacing: smallPadding,
      mainAxisSpacing: smallPadding,
    ),
    itemCount: supportTypesList.length,
    itemBuilder: (context, index) {
      final type = supportTypesList[index];
      return _buildSupportChip(type.name, type.icon, type.color);
    },
  );
}




















Widget _buildOtherChallengeInput() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: const Color.fromARGB(205, 247, 103, 103),
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.orange[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: const Color.fromARGB(255, 247, 111, 87),
                size: screenWidth * 0.05),
            SizedBox(width: smallPadding),
            Text(
              'Other Challenges',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 250, 116, 114),
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          label: 'Specify Other Challenges',
          controller: _otherChallengesController,
          prefixIcon: Icons.edit_outlined,
        ),
      ],
    ),
  );
}

Widget _buildOtherSuccessInput() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: const Color.fromARGB(225, 59, 122, 65),
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.orange[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: const Color.fromARGB(255, 6, 97, 14),
                size: screenWidth * 0.05),
            SizedBox(width: smallPadding),
            Text(
              'Other Success',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 7, 101, 41),
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          label: 'Specify Other Success',
          controller: _otherSuccessController,
          prefixIcon: Icons.edit_outlined,
        ),
      ],
    ),
  );
}

Widget _buildOtherSafetyInput() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.orange[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: Colors.orange[700],
                size: screenWidth * 0.05),
            SizedBox(width: smallPadding),
            Text(
              'Other Safety',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          label: 'Specify Other Safety',
          controller: _otherSafetyController,
          prefixIcon: Icons.edit_outlined,
        ),
      ],
    ),
  );
}

Widget _buildOtherSupportInput() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.orange[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: Colors.orange[700],
                size: screenWidth * 0.05),
            SizedBox(width: smallPadding),
            Text(
              'Other Support',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        _buildResponsiveTextField(
          label: 'Specify Other Support',
          controller: _otherSupportController,
          prefixIcon: Icons.edit_outlined,
        ),
      ],
    ),
  );
}










// Helper widgets for grids and chips
Widget _buildWasteTypeChip(String type, IconData icon) {
  final isSelected = _wasteTypes.contains(type);
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _wasteTypes.remove(type);
          } else {
            _wasteTypes.add(type);
          }
        });
      },
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                type,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                  fontSize: smallTextSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}

Widget _buildSuccessStoriesGrid() {
  final successStories = [
    const ItemType(name: 'Making Livelihood', icon: Icons.home_work, color: Colors.green),
    const ItemType(name: 'Build House', icon: Icons.home, color: Colors.blue),
    const ItemType(name: 'Pay School Fees', icon: Icons.school, color: Colors.orange),
    const ItemType(name: 'Create Employment', icon: Icons.groups, color: Colors.purple),
    const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: screenWidth > 600 ? 3 : 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: smallPadding,
      mainAxisSpacing: smallPadding,
    ),
    itemCount: successStories.length,
    itemBuilder: (context, index) {
      final story = successStories[index];
      return _buildSelectionChip(
        story.name,
        story.icon,
        story.color,
        _successStories.contains(story.name),
        (selected) {
          setState(() {
            if (selected) {
              _successStories.add(story.name);
            } else {
              _successStories.remove(story.name);
            }
          });
        },
      );
    },
  );
}

Widget _buildChallengesGrid() {
  final challenges = [
    const ItemType(name: 'Lack of Tools', icon: Icons.build, color: Colors.red),
    const ItemType(name: 'Poor Transportation', icon: Icons.local_shipping, color: Colors.orange),
    const ItemType(name: 'Lack of PPE', icon: Icons.security, color: Colors.yellow),
    const ItemType(name: 'Lack of Training', icon: Icons.school, color: Colors.blue),
    const ItemType(name: 'Financial Support', icon: Icons.money, color: Colors.green),
    const ItemType(name: 'Others', icon: Icons.more_horiz, color: Colors.grey),
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: screenWidth > 600 ? 3 : 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: smallPadding,
      mainAxisSpacing: smallPadding,
    ),
    itemCount: challenges.length,
    itemBuilder: (context, index) {
      final challenge = challenges[index];
      return _buildSelectionChip(
        challenge.name,
        challenge.icon,
        challenge.color,
        _challenges.contains(challenge.name),
        (selected) {
          setState(() {
            if (selected) {
              _challenges.add(challenge.name);
            } else {
              _challenges.remove(challenge.name);
            }
          });
        },
      );
    },
  );
}

Widget _buildSelectionChip(
  String label,
  IconData icon,
  Color color,
  bool isSelected,
  Function(bool) onSelected,
) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontSize: smallTextSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}


// Inside _WasteDealerFormState class

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
            'Capacity & Operations',
            Icons.assessment_outlined,
          ),
          SizedBox(height: defaultPadding),

          // Weekly Capacity Slider
          Container(
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
                  'Weekly Capacity (Tons)',
                  style: TextStyle(
                    fontSize: bodyTextSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF115937),
                  ),
                ),
                Slider(
                  value: _weeklyCapacity.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '${_weeklyCapacity.round()} tons',
                  onChanged: (value) => setState(() => _weeklyCapacity = value.round()),
                  activeColor: const Color(0xFF115937),
                ),
              ],
            ),
          ),

          SizedBox(height: defaultPadding),

          // Main Buyer Information
          _buildResponsiveTextField(
            label: 'Main Buyer/Market',
            controller: _mainBuyerController,
            prefixIcon: Icons.store,
          ),
        ],
      ),
    ),
  );
}

Widget _buildSubmitButton() {
  return Container(
    width: double.infinity,
    height: screenHeight * 0.06,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF115937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        elevation: 2,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              'Submit Form',
              style: TextStyle(
                fontSize: bodyTextSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}

Widget _buildResponsiveDropdown({
  required String label,
  required String? value,
  required List<String> items,
  required Function(String?) onChanged,
  IconData? icon,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: smallPadding),
    child: DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: TextStyle(fontSize: bodyTextSize),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: smallTextSize,
          color: Colors.grey[600],
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey[600], size: screenWidth * 0.05)
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
          borderSide: const BorderSide(color: Color(0xFF115937), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: defaultPadding,
          vertical: smallPadding,
        ),
      ),
    ),
  );
}

Widget _buildCategoryChip(String category, IconData icon) {
  final isSelected = _practitionerCategory == category;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => setState(() => _practitionerCategory = category),
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                fontSize: smallTextSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}

Widget _buildDocumentPreview() {
  return Container(
    width: double.infinity,
    height: screenHeight * 0.2,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.blue[200]!),
      image: DecorationImage(
        image: FileImage(File(_legalDocumentPhoto!)),
        fit: BoxFit.cover,
      ),
    ),
    child: Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => setState(() => _legalDocumentPhoto = null),
        ),
      ],
    ),
  );
}

Widget _buildUploadButton() {
  return ElevatedButton.icon(
    onPressed: _pickDocument,
    icon: Icon(
      Icons.camera_alt,
      size: screenWidth * 0.05,
    ),
    label: Text(
      'Take Photo',
      style: TextStyle(fontSize: bodyTextSize),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue[700],
      padding: EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: smallPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
    ),
  );
}

Widget _buildOwnershipChip(String type, IconData icon) {
  final isSelected = _ownershipStatus == type;
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => setState(() => _ownershipStatus = type),
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF115937).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? const Color(0xFF115937) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? const Color(0xFF115937) : Colors.grey[600],
                fontSize: smallTextSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}

Widget _buildCoordinatesSection() {
  return Container(
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
          'GPS Coordinates',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF115937),
          ),
        ),
        SizedBox(height: smallPadding),
        Row(
          children: [
            Expanded(
              child: Text(
                _currentPosition != null
                    ? 'Lat: ${_latitude?.toStringAsFixed(6)}\nLong: ${_longitude?.toStringAsFixed(6)}'
                    : 'Location not captured',
                style: TextStyle(
                  fontSize: smallTextSize,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(
                Icons.my_location,
                size: screenWidth * 0.045,
              ),
              label: Text(
                'Capture',
                style: TextStyle(fontSize: smallTextSize),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF115937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


Widget _buildGeographicLocationCard() {
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
            'Geographic Location',
            Icons.location_on,
          ),
          SizedBox(height: defaultPadding),
          
          // Coordinates Section
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location, 
                         color: Colors.grey[600], 
                         size: screenWidth * 0.05),
                    SizedBox(width: smallPadding),
                    Text(
                      'Coordinates',
                      style: TextStyle(
                        fontSize: bodyTextSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: defaultPadding),
                
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Wrap(
                      spacing: defaultPadding,
                      runSpacing: defaultPadding,
                      children: [
                        SizedBox(
                          width: isNarrow ? constraints.maxWidth 
                                        : (constraints.maxWidth - defaultPadding) / 2,
                          child: _buildCoordinateField(
                            label: 'Latitude',
                            controller: _latitudeController,
                            icon: Icons.north,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final lat = double.tryParse(value);
                              if (lat == null || lat < -90 || lat > 90) {
                                return 'Invalid latitude';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: isNarrow ? constraints.maxWidth 
                                        : (constraints.maxWidth - defaultPadding) / 2,
                          child: _buildCoordinateField(
                            label: 'Longitude',
                            controller: _longitudeController,
                            icon: Icons.east,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              final lng = double.tryParse(value);
                              if (lng == null || lng < -180 || lng > 180) {
                                return 'Invalid longitude';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                SizedBox(height: defaultPadding),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _getCurrentLocation();
                      if (_latitude != null && _longitude != null) {
                        _latitudeController.text = _latitude!.toStringAsFixed(6);
                        _longitudeController.text = _longitude!.toStringAsFixed(6);
                      }
                    },
                    icon: Icon(Icons.my_location, size: screenWidth * 0.05),
                    label: Text(
                      'Get Current Location',
                      style: TextStyle(fontSize: bodyTextSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF115937),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: defaultPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
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
   .slideY(begin: 0.2, end: 0);
}


Widget _buildCoordinateField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  required String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: TextStyle(fontSize: bodyTextSize),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: smallTextSize,
        color: Colors.grey[600],
      ),
      prefixIcon: Icon(icon, color: Colors.grey[600], size: screenWidth * 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.all(defaultPadding),
    ),
    validator: validator,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\-?\d*\.?\d*')),
    ],
    onChanged: (value) {
      if (value.isNotEmpty) {
        setState(() {
          if (label == 'Latitude') {
            _latitude = double.tryParse(value);
          } else {
            _longitude = double.tryParse(value);
          }
        });
      }
    },
  );
}




Widget _buildLocationSelectionSection() {
  return Column(
    children: [
      _buildResponsiveDropdown(
        label: 'Ward',
        value: _ward,
        items: const ['Ward 1', 'Ward 2', 'Ward 3'], // Replace with actual data
        onChanged: (value) => setState(() => _ward = value),
        icon: Icons.location_city,
      ),
      _buildResponsiveDropdown(
        label: 'Street',
        value: _street,
        items: const ['Street 1', 'Street 2', 'Street 3'], // Replace with actual data
        onChanged: (value) => setState(() => _street = value),
        icon: Icons.add_road,
      ),
    ],
  );
}

Widget _buildSourceOptions() {
  final sources = ['Households', 'Markets', 'Industries', 'Institutions', 'Others'];
  return Wrap(
    spacing: smallPadding,
    runSpacing: smallPadding,
    children: sources.map((source) {
      return FilterChip(
        label: Text(source),
        selected: _wasteSources.contains(source),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _wasteSources.add(source);
            } else {
              _wasteSources.remove(source);
            }
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF115937).withOpacity(0.1),
        checkmarkColor: const Color(0xFF115937),
        labelStyle: TextStyle(
          color: _wasteSources.contains(source)
              ? const Color(0xFF115937)
              : Colors.grey[700],
          fontSize: smallTextSize,
        ),
      );
    }).toList(),
  );
}

Widget _buildNeededSupportSection() {
  return Container(
    padding: EdgeInsets.all(cardPadding),
    decoration: BoxDecoration(
      color: Colors.purple[50],
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      border: Border.all(color: Colors.purple[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Needed',
          style: TextStyle(
            fontSize: bodyTextSize,
            fontWeight: FontWeight.w500,
            color: Colors.purple[700],
          ),
        ),
        SizedBox(height: defaultPadding),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth > 600 ? 3 : 2,
            childAspectRatio: 3,
            crossAxisSpacing: smallPadding,
            mainAxisSpacing: smallPadding,
          ),
          itemCount: neededSupportList.length,
          itemBuilder: (context, index) {
            final support = neededSupportList[index];
            return _buildSelectionChip(
              support.name,
              support.icon,
              support.color,
              _neededSupport.contains(support.name),
              (selected) {
                setState(() {
                  if (selected) {
                    _neededSupport.add(support.name);
                  } else {
                    _neededSupport.remove(support.name);
                  }
                });
              },
            );
          },
        ),
      ],
    ),
  );
}

Widget _buildSafetyMeasuresGrid() {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: screenWidth > 600 ? 3 : 2,
      childAspectRatio: 2.5,
      crossAxisSpacing: smallPadding,
      mainAxisSpacing: smallPadding,
    ),
    itemCount: safetyMeasuresList.length,
    itemBuilder: (context, index) {
      final measure = safetyMeasuresList[index];
      return _buildSelectionChip(
        measure.name,
        measure.icon,
        measure.color,
        _safetyMeasures.contains(measure.name),
        (selected) {
          setState(() {
            if (selected) {
              _safetyMeasures.add(measure.name);
            } else {
              _safetyMeasures.remove(measure.name);
            }
          });
        },
      );
    },
  );
}









Widget _buildSupportChip(String type, IconData icon, Color color) {
  final isSelected = _supportTypes.contains(type);
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _supportTypes.remove(type);
          } else {
            _supportTypes.add(type);
          }
        });
      },
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: Container(
        padding: EdgeInsets.all(smallPadding),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: screenWidth * 0.045,
            ),
            SizedBox(width: smallPadding),
            Flexible(
              child: Text(
                type,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontSize: smallTextSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  ).animate()
   .scale(duration: const Duration(milliseconds: 200));
}

bool _validateForm() {
  if (!_formKey.currentState!.validate()) {
    _showSnackBar('Please fill in all required fields');
    return false;
  }

  // Basic validations
  if (_region == null || _district == null) {
    _showSnackBar('Please select region and district');
    return false;
  }

  // Practitioner information validation
  if (_practitionerCategory == 'Others' && _otherCategoryController.text.isEmpty) {
    _showSnackBar('Please specify other practitioner category');
    return false;
  }

  // Business information validation for non-individual ownership
  if (_ownershipStatus != 'Individual') {
    if (_officialNameController.text.isEmpty) {
      _showSnackBar('Please enter official business name');
      return false;
    }
  }

  // Waste types validation
  if (_wasteTypes.isEmpty) {
    _showSnackBar('Please select at least one waste type');
    return false;
  }

  if (_wasteTypes.contains('Others') && _otherWasteTypeController.text.isEmpty) {
    _showSnackBar('Please specify other waste types');
    return false;
  }

  // // Sources validation
  // if (_wasteSources.isEmpty) {
  //   _showSnackBar('Please select at least one waste source');
  //   return false;
  // }

  // if (_wasteSources.contains('Others') && _otherSourcesController.text.isEmpty) {
  //   _showSnackBar('Please specify other sources');
  //   return false;
  // }

  // Location validation
  if (_latitude == null || _longitude == null) {
    _showSnackBar('Please capture GPS coordinates');
    return false;
  }

  // // Support types validation
  // if (_hasSupport && _supportTypes.isEmpty) {
  //   _showSnackBar('Please select at least one support type');
  //   return false;
  // }

  // // Safety measures validation
  // if (_hasSafetyMeasures && _safetyMeasures.isEmpty) {
  //   _showSnackBar('Please select at least one safety measure');
  //   return false;
  // }

  return true;
}

// Clean up resources when disposing
@override
void dispose() {
  // Dispose all controllers
  _dataCollectorController.dispose();
  _practitionerNameController.dispose();
  _practitionerAddressController.dispose();
  _practitionerMobileController.dispose();
  _practitionerEmailController.dispose();
  _otherCategoryController.dispose();
  _otherOwnershipController.dispose();
  _officialNameController.dispose();
  _contactPersonController.dispose();
  _businessAddressController.dispose();
  _businessMobileController.dispose();
  _businessEmailController.dispose();
  _otherWasteTypeController.dispose();
  _mainBuyerController.dispose();
  _otherSourcesController.dispose();
  super.dispose();
}










// Form submission and validation logic
Future<void> _submitForm() async {
  if (!_validateForm()) return;
  // String? legalDocumentPhotoUrl;

  //   if (_legalDocumentPhoto != null) {
  //   legalDocumentPhotoUrl = await _uploadImage(_legalDocumentPhoto!, 'dealersDocs');
  // }


  setState(() => _isLoading = true);
  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    Map<String, dynamic> formData = {
      'date': Timestamp.fromDate(_selectedDate),
      'dataCollector': {
        'uid': user.uid,
        'name': _dataCollectorName,
      },
      'basicInfo': {
        'region': _region,
        'district': _district,
        'division': _division,
        'ward': _ward,
        'street': _streetController.text.trim(),
        'coordinates': {
          'latitude': _latitude,
          'longitude': _longitude,
        },
      },
      'practitionerInfo': {
        'category': _practitionerCategory,
        'name': _practitionerNameController.text,
        'address': _practitionerAddressController.text,
        'mobile': _practitionerMobileController.text,
        'email': _practitionerEmailController.text,
      },
      'operationalStatus': {
        'status': _operationalStatus,
        'wasteTypes': _wasteTypes,
        // 'documentPhoto': legalDocumentPhotoUrl,
      },
      // 'businessInfo': {
      //   'ownershipType': _ownershipStatus,
      //   'officialName': _officialNameController.text,
      //   'contactPerson': _contactPersonController.text,
      //   'address': _businessAddressController.text,
      //   'mobile': _businessMobileController.text,
      //   'email': _businessEmailController.text,
      // },
      // 'location': {
      //   // 'ward': _ward,
      //   // 'street': _street,
      //   'coordinates': {
      //     'latitude': _latitude,
      //     'longitude': _longitude,
      //   },
      // },
      // 'wasteTypes': _wasteTypes,
      // 'wasteSources': _wasteSources,
      // 'capacity': {
      //   'weeklyCapacity': _weeklyCapacity,
      //   'mainBuyer': _mainBuyerController.text,
      // },
      // 'support': {
      //   'hasSupport': _hasSupport,
      //   'types': _supportTypes,
      //   'needed': _neededSupport,
      // },
      // 'safety': {
      //   'hasMeasures': _hasSafetyMeasures,
      //   'measures': _safetyMeasures,
      // },
      // 'feedback': {
      //   'successStories': _successStories,
      //   'challenges': _challenges,
      // },
      'metadata': {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
    };

    await _firestore.collection('wasteDealersCollection').add(formData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    _showSnackBar('Error submitting data: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}



}
