import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/custom_drawer.dart';

// import '../../login_page.dart';
import 'WHO_waste_reportMap.dart';
import 'admin_management.dart';
import 'agent.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
// import 'waste_aggregators_page.dart';
import 'waste_dealers_page.dart';
import 'waste_recyclers_page.dart';
import 'waste_points_page.dart';
import 'waste_reportMap.dart';
import 'waste_reportingCollection.dart';

class SourceOption {
  final String name;
  final IconData icon;
  SourceOption(this.name, this.icon);
}

class InstitutionType {
  final String name;
  final IconData icon;
  InstitutionType(this.name, this.icon);
}

class WasteCollectionPage extends StatefulWidget {
  final User? user;
  const WasteCollectionPage({Key? key, required this.user}) : super(key: key);

  @override
  _WasteCollectionPageState createState() => _WasteCollectionPageState();
}


class _WasteCollectionPageState extends State<WasteCollectionPage> {
  // Keep your existing variable declarations...
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  int _selectedIndex = 1; // Since this is the Waste Points page
  String _firstName = '';
  bool _isAdmin = false;
  final Map<String, TextEditingController> _wasteTypeControllers = {};

  // Add controllers for editable coordinates
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
final _otherWasteSourceController = TextEditingController();
final _otherInstitutionController = TextEditingController();
// final _wardPopulationController = TextEditingController();
final TextEditingController _wardPopulationController = TextEditingController();

  final _catchmentStreetController = TextEditingController();
  final _catchmentWardPopController = TextEditingController();
  final _catchmentStreetpopController = TextEditingController();
  final _streetPopulationController = TextEditingController();
  final _streetController = TextEditingController();
 final _otherObstacleController = TextEditingController();
  final _disposalStreetController = TextEditingController();

// Screen size utilities
double get screenWidth => MediaQuery.of(context).size.width;
double get screenHeight => MediaQuery.of(context).size.height;

// Responsive text sizes
double get headingSize => screenWidth * 0.045;
double get subheadingSize => screenWidth * 0.035;
double get bodyTextSize => screenWidth * 0.032;
double get smallTextSize => screenWidth * 0.028;

// Responsive spacing
double get defaultPadding => screenWidth * 0.04;
double get smallPadding => screenWidth * 0.02;
double get cardPadding => screenWidth * 0.035;

  // Form data
  DateTime _selectedDate = DateTime.now();
  String? _dataCollectorName;
  // ignore: unused_field
  Position? _currentPosition;
  
  // Form fields
  String? _region;
  String? _district;
  String? _division;
  String? _ward;
  String? _street;
  String _collectionPointStatus = 'Legal';
  String? _selectedWard;
  // String? _selectedStreet;
  double? _latitude;
  double? _longitude;
  // String _locationType = 'Residential';
  // bool _isAccessible = true;
  // List<String> _accessObstacles = [];
  // String? _otherObstacle;
  // int _capacity = 1;
  // Map<String, int> _catchmentAreas = {};
    static const primaryColor = Color(0xFF115937);
  final TextEditingController _imageUrlController = TextEditingController();

  // Map<String, double> _wasteTypes = {
  //   'Decomposable material': 0,
  //   'Paper': 0,
  //   'Plastics': 0,
  //   'Textiles': 0,
  //   'Leather': 0,
  //   'Wood': 0,
  //   'Glass': 0,
  //   'Metals': 0,
  //   'Others': 0,
  // };
  // String? _otherWasteType;
  
  // bool _hasSegregationFacilities = false;
  // List<String> _segregatedWasteTypes = [];
  // String? _otherSegregatedType;
  // List<String> _segregationFacilities = [];
  // String? _otherFacilityType;
  // bool _hasDemarcation = false;
  // bool _hasSortingPractice = false;
  // bool _hasAttendant = false;
  // bool _isAttendantTrained = false;
  // bool _hasppe = false;
  // List<String> _ppeTypes = [];
  // String? _otherPPE;
  // int _disposalDistance = 1;
  
  // String? _disposalDistrict;
  // String? _disposalWard;
  // String? _disposalStreet;

  // String? _catchmentWard;
  // String? _catchmentWardPop;
  // String? _catchmentStreet;
  // String? _catchmentStreetpop;


  // bool _hasTransport = false;
  // String _transportFrequency = 'Every day';
  // String _transportResponsible = 'Council';
  // String _transportType = 'Toyo';
  // bool _transportMeetsNeeds = false;
  
  // List<String> _neighborOpinions = [];
  // String? _otherNeighborOpinion;
  // List<String> _wasteSources = [];
  // String? _institutionType;
  // String? _otherInstitution;
  // String? _otherWasteSource;





  // Tanzania Geography Data (You would need to populate this with actual data)
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
  

// If you need population data, keep it in a separate map
final Map<String, int> wardPopulations = {
  // Ilemela wards
  // 'Bugogwa': 35633,
  // 'Buswelu': 42614,
  // 'Buzuruga': 25338,
  // 'Ibungilo': 24295,
  // 'Ilemela': 26091,
  // 'Kahama': 21816,
  // 'Kawekamo': 26670,
  // 'Kayenze': 17201,
  // 'Kirumba': 32364,
  // 'Kiseke': 30664,
  // 'Kitangiri': 23642,
  // 'Mecco': 23294,
  // 'Nyakato': 29560,
  // 'Nyamanoro': 24624,
  // 'Nyamhongolo': 29277,
  // 'Nyasaka': 41897,
  // 'Pasiansi': 16274,
  // 'Sangabuye': 13004,
  // 'Shibula': 25429,
  
  // Mwanza City/Nyamagana wards
  'Buhongwa': 67254,
  'Butimba': 36069,
  'Igogo': 25515,
  'Igoma': 57263,
  'Isamilo': 27881,
  'Kishili': 63054,
  'Luchelele': 18889,
  'Lwanhima': 28109,
  'Mabatini': 24458,
  'Mahina': 57260,
  'Mbugani': 18395,
  'Mhandu': 43440,
  'Mikuyuni': 20492,
  'Mirongo': 2141,
  'Mkolani': 48102,
  'Nyamagana': 5033,
  'Nyegezi': 28454,
  'Pamba': 23025,
};









  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUserData();
      // Initialize controllers for each waste type
  // _wasteTypes.forEach((key, value) {
  //   _wasteTypeControllers[key] = TextEditingController(text: value.toString());
  // });
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













// Basic Info Card
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
          
          // Date Selector
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
                       size: screenWidth * 0.05,
                       color: Colors.grey[600]),
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
                       size: screenWidth * 0.04,
                       color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          SizedBox(height: defaultPadding),
          
          // Data Collector Info
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
                
                    SizedBox(
                      width: isNarrow ? constraints.maxWidth 
                                    : (constraints.maxWidth - defaultPadding) / 2,
                      child: _buildResponsiveDropdown(
                        label: 'Ward',
                        value: _ward,
                        items: districtsWards[_district] ?? [],
                        icon: Icons.apartment, // Added icon
                        // onChanged: (value) => setState(() => _ward = value),
                        onChanged: (value) {
                      setState(() {
                        _ward = value;
                        // Auto-fill the population when ward is selected
                        if (value != null) {
                          _wardPopulationController.text = wardPopulations[value]?.toString() ?? '';
                        } else {
                          _wardPopulationController.text = '';
                        }
                      });
                    },
                      ),
                    ),
                      SizedBox(
                      width: constraints.maxWidth,
                      child: _buildResponsiveTextField(
                        label: 'Street',
                        controller: _streetController,
                        prefixIcon: Icons.add_road,
                      ),
                    ),
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

// Shared Section Header
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

// Responsive Dropdown

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


// Add form validation helper
bool _validateForm() {
  if (_region == null || _district == null || _ward == null) {
    _showSnackBar('Please fill in all location fields');
    return false;
  }

  // Validate coordinates
  if (_latitude == null || _longitude == null) {
    _showSnackBar('Please get or enter location coordinates');
    return false;
  }

  // Validate waste types total
  // final totalPercentage = _wasteTypes.values.fold(0.0, (sum, value) => sum + value);
  // if ((totalPercentage - 100).abs() > 0.01) {
  //   _showSnackBar('Waste type percentages must total 100%');
  //   return false;
  // }

  // Add other validation as needed
  return true;
}

Future<void> _submitForm() async {
  // 1. Check if form is valid
  if (!_formKey.currentState!.validate()) {
    _showSnackBar('Please fill in all required fields');
    return;
  }

  // 2. Validate essential fields
  if (!_validateEssentialFields()) {
    return;
  }

  // 3. Show loading state
  setState(() => _isLoading = true);

  try {
    // 4. Get current user
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    // 5. Create form data with null checks
    final formData = await _createFormData(user);

    // 6. Submit to Firestore
    // await _firestore.collection('wasteCollectionPoints').add(formData);
    // 6. Submit to wasteCollectionPoints collection and get the DocumentReference
    final DocumentReference<Map<String, dynamic>> wastePointRef = await _firestore
        .collection('wasteCollectionPoints')
        .add(formData);



    // 7. Create and submit waste report data
    final reportData = {
      'district': _district ?? '',
      'ward': _ward ?? '',
      'street': _streetController.text.trim(),
      'location': {
        'latitude': _latitude ?? 0.0,
        'longitude': _longitude ?? 0.0,
      },
      'status': 'pending',
      'type': 'waste point',
      'relatedDocumentId': wastePointRef.id, // Reference to the original document
      'metadata': {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
      }
    };

    // 8. Submit to wasteReports collection
    await _firestore.collection('wasteReports').add(reportData);

    // 9. Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // 10. Reset form
    _resetForm();

  } catch (e) {
    if (mounted) {
      _showSnackBar('Error submitting data: ${e.toString()}');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

bool _validateEssentialFields() {
  // Validate location fields
  if (_region == null || _district == null || _ward == null) {
    _showSnackBar('Please complete all location fields');
    return false;
  }

  // Validate coordinates
  if (_latitude == null || _longitude == null) {
    _showSnackBar('Please provide location coordinates');
    return false;
  }

  // Validate waste types
  // final totalPercentage = _wasteTypes.values.fold(0.0, (sum, value) => sum + value);
  // if ((totalPercentage - 100).abs() > 0.01) {
  //   _showSnackBar('Waste type percentages must total 100%');
  //   return false;
  // }

  return true;
}

Future<Map<String, dynamic>> _createFormData(User user) async {
  // Get user document for additional info
  final userDoc = await _firestore.collection('users').doc(user.uid).get();
  final userName = userDoc.exists ? 
    '${userDoc.data()?['firstName'] ?? ''} ${userDoc.data()?['lastName'] ?? ''}' : 
    'Unknown User';

  return {
    'date': Timestamp.fromDate(_selectedDate),
    'dataCollector': {
      'uid': user.uid,
      'name': userName,
    },
    'location': {
      'region': _region ?? '',
      'district': _district ?? '',
      'ward': _ward ?? '',
      'street': _streetController.text.trim(),
      'coordinates': {
        'latitude': _latitude ?? 0.0,
        'longitude': _longitude ?? 0.0,
      },
    },
    'status': _collectionPointStatus,
    // 'locationType': _locationType,
    // 'accessibility': {
    //   'isAccessible': _isAccessible,
    //   'obstacles': _accessObstacles,
    //   'otherObstacle': _otherObstacleController.text.trim(),
    // },
    // 'capacity': _capacity,
    'imageUrl': _imageUrlController.text.trim(),
    'catchmentAreas': {
      'catchmentWard': _ward ?? '',
      'wardPopulation': int.tryParse(_wardPopulationController.text.trim()) ?? 0,
      // 'street': _streetController.text.trim(),
      // 'streetPopulation': int.tryParse(_streetPopulationController.text.trim()) ?? 0,
    },
    // 'wasteTypes': Map.fromEntries(
    //   _wasteTypeControllers.entries.map(
    //     (e) => MapEntry(e.key, double.tryParse(e.value.text.trim()) ?? 0.0)
    //   ),
    // ),
    // 'otherWasteType': _otherWasteType ?? '',
    // 'segregation': {
    //   'hasSegregationFacilities': _hasSegregationFacilities,
    //   'segregatedTypes': _segregatedWasteTypes,
    //   'otherSegregatedType': _otherSegregatedType ?? '',
    //   'facilities': _segregationFacilities,
    // },
    // 'infrastructure': {
    //   'hasDemarcation': _hasDemarcation,
    //   'hasSortingPractice': _hasSortingPractice,
    // },
    // 'attendant': {
    //   'hasAttendant': _hasAttendant,
    //   'isTrained': _isAttendantTrained,
    //   'hasPPE': _hasppe,
    //   'ppeTypes': _ppeTypes,
    //   'otherPPE': _otherPPE ?? '',
    // },
    // 'disposal': {
    //   'distance': _disposalDistance,
    //   'location': {
    //     'district': _disposalDistrict ?? '',
    //     'ward': _disposalWard ?? '',
    //     'street': _disposalStreetController.text.trim(),
    //   },
    //   'transport': {
    //     'available': _hasTransport,
    //     'frequency': _transportFrequency,
    //     'responsible': _transportResponsible,
    //     'type': _transportType,
    //     'meetsNeeds': _transportMeetsNeeds,
    //   },
    // },
    // 'feedback': {
    //   'neighborOpinions': _neighborOpinions,
    //   'otherOpinion': _otherNeighborOpinion ?? '',
    // },
    // 'wasteSources': {
    //   'sources': _wasteSources,
    //   'institutionType': _institutionType ?? '',
    //   'otherInstitution': _otherInstitutionController.text.trim(),
    //   'otherSource': _otherWasteSourceController.text.trim(),
    // },
    'metadata': {
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
      'status': 'active',
    },
  };
}

void _resetForm() {
  if (_formKey.currentState != null) {
    _formKey.currentState!.reset();
  }
  
  setState(() {
    // Reset basic fields
    _selectedDate = DateTime.now();
    _region = null;
    _district = null;
    _ward = null;
    
    // Reset controllers
    _streetController.clear();
    _wardPopulationController.clear();
    _streetPopulationController.clear();
    _otherObstacleController.clear();
    _otherWasteSourceController.clear();
    _otherInstitutionController.clear();
    _disposalStreetController.clear();
    
    // Reset waste type controllers
    _wasteTypeControllers.forEach((_, controller) => controller.text = '0');
    // _wasteTypes.forEach((key, _) => _wasteTypes[key] = 0);
    
    // Reset selection fields
    _collectionPointStatus = 'Legal';
    // _locationType = 'Residential';
    // _isAccessible = true;
    // _accessObstacles = [];
    // _hasSegregationFacilities = false;
    // _segregatedWasteTypes = [];
    // _segregationFacilities = [];
    // _hasDemarcation = false;
    // _hasSortingPractice = false;
    // _hasAttendant = false;
    // _isAttendantTrained = false;
    // _hasppe = false;
    // _ppeTypes = [];
    // _hasTransport = false;
    // _transportFrequency = 'Every day';
    // _transportResponsible = 'Council';
    // _transportType = 'Toyo';
    // _transportMeetsNeeds = false;
    // _neighborOpinions = [];
    // _wasteSources = [];
    
    // Reset coordinates
    _latitude = null;
    _longitude = null;
    _latitudeController.clear();
    _longitudeController.clear();



    _imageUrlController.clear();

  });
}




























  // Add this new card for image URL input
  Widget _buildImageUrlCard() {
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
            _buildSectionHeader('Collection Point Image', Icons.image_outlined),
            SizedBox(height: defaultPadding),
            
            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildResponsiveTextField(
                    label: 'Image URL',
                    controller: _imageUrlController,
                    prefixIcon: Icons.link,
                    keyboardType: TextInputType.url,
                  ),
                  if (_imageUrlController.text.isNotEmpty) ...[
                    SizedBox(height: defaultPadding),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Image.network(
                          _imageUrlController.text,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: screenWidth * 0.1,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
            'Collection Point Status',
            Icons.info_outline,
          ),
          SizedBox(height: defaultPadding),
          
          _buildResponsiveRadioGroup(
            title: 'Status of the waste collection point',
            groupValue: _collectionPointStatus,
            options: {
              'Legal': 'Legal',
              'Illegal': 'Illegal',
            },
            onChanged: (value) => setState(() => _collectionPointStatus = value),
          ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}




  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }


Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }







 Widget _buildRadioGroup({
    required String title,
    required String groupValue,
    required Map<String, String> options,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600])),
        ...options.entries.map(
          (entry) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: groupValue == entry.key 
                    ? const Color(0xFF90EE90) 
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: groupValue,
              onChanged: (value) => onChanged(value!),
              activeColor: const Color(0xFF90EE90),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxGroup({
    required String title,
    required List<String> selectedValues,
    required List<String> options,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600])),
        ...options.map(
          (option) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedValues.contains(option)
                    ? const Color(0xFF90EE90)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: CheckboxListTile(
              title: Text(option),
              value: selectedValues.contains(option),
              onChanged: (bool? value) {
                List<String> newValues = List.from(selectedValues);
                if (value!) {
                  newValues.add(option);
                } else {
                  newValues.remove(option);
                }
                onChanged(newValues);
              },
              activeColor: const Color(0xFF90EE90),
            ),
          ),
        ),
      ],
    );
  }




Widget _buildTextField({
    required String label,
    required String? value,
    required Function(String) onChanged,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        enabled: enabled,
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }




// Widget _buildCapacityCard() {
//   return Card(
//     elevation: 2,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionTitle('Capacity'),
          
//           _buildDropdown(
//             label: 'Capacity (Tonnages)',
//             value: _capacity.toString(),
//             items: List.generate(20, (index) => (index + 1).toString()),
//             onChanged: (value) => setState(() => _capacity = int.parse(value!)),
//           ),
//         ],
//       ),
//     ),
//   );
// }













// Widget _buildLocationCharacteristicsCard() {
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
//             'Location Characteristics',
//             Icons.location_city_outlined,
//           ),
//           SizedBox(height: defaultPadding),

//           Container(
//             padding: EdgeInsets.all(cardPadding),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//               border: Border.all(color: Colors.grey[200]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Characterize the location',
//                   style: TextStyle(
//                     fontSize: bodyTextSize,
//                     fontWeight: FontWeight.w500,
//                     color: primaryColor,
//                   ),
//                 ),
//                 SizedBox(height: defaultPadding),
//                 ...['Residential', 'Industrial', 'Commercial', 'Institutional']
//                     .map((type) => _buildLocationTypeOption(type))
//                     .toList(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildLocationTypeOption(String type) {
//   final isSelected = _locationType == type;
//   return Padding(
//     padding: EdgeInsets.only(bottom: smallPadding),
//     child: InkWell(
//       onTap: () => setState(() => _locationType = type),
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       child: Container(
//         padding: EdgeInsets.all(cardPadding),
//         decoration: BoxDecoration(
//           color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(
//             color: isSelected ? primaryColor : Colors.grey[300]!,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               _getLocationTypeIcon(type),
//               color: isSelected ? primaryColor : Colors.grey[600],
//               size: screenWidth * 0.05,
//             ),
//             SizedBox(width: smallPadding),
//             Text(
//               type,
//               style: TextStyle(
//                 fontSize: bodyTextSize,
//                 color: isSelected ? primaryColor : Colors.grey[800],
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//             const Spacer(),
//             if (isSelected)
//               Icon(
//                 Icons.check_circle_outline,
//                 color: primaryColor,
//                 size: screenWidth * 0.05,
//               ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// Widget _buildAccessibilityCard() {
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
//             'Accessibility',
//             Icons.accessible_outlined,
//           ),
//           SizedBox(height: defaultPadding),

//           Container(
//             padding: EdgeInsets.all(cardPadding),
//             decoration: BoxDecoration(
//               color: _isAccessible ? Colors.green[50] : Colors.orange[50],
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//               border: Border.all(
//                 color: _isAccessible ? Colors.green[200]! : Colors.orange[200]!,
//               ),
//             ),
//             child: Column(
//               children: [
//                 SwitchListTile(
//                   title: Text(
//                     'Easy Accessibility',
//                     style: TextStyle(
//                       fontSize: bodyTextSize,
//                       fontWeight: FontWeight.w500,
//                       color: _isAccessible ? Colors.green[700] : Colors.orange[700],
//                     ),
//                   ),
//                   subtitle: Text(
//                     'Is the waste collection point easily accessible?',
//                     style: TextStyle(
//                       fontSize: smallTextSize,
//                       color: _isAccessible ? Colors.green[600] : Colors.orange[600],
//                     ),
//                   ),
//                   value: _isAccessible,
//                   onChanged: (value) => setState(() => _isAccessible = value),
//                   activeColor: Colors.green[700],
//                 ),

//                 if (!_isAccessible) ...[
//                   SizedBox(height: defaultPadding),
//                   _buildObstaclesGrid(),
//                 ],
//               ],
//             ),
//           ),

//           if (!_isAccessible && _accessObstacles.contains('Others'))
//             Padding(
//               padding: EdgeInsets.only(top: defaultPadding),
//               child: _buildResponsiveTextField(
//                 label: 'Specify other obstacle',
//                 controller: _otherObstacleController,
//                 prefixIcon: Icons.add_circle_outline,
//               ),
//             ),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

Widget _buildCatchmentAreasCard() {
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
            'Catchment Areas',
            Icons.people_outlined,
          ),
          SizedBox(height: defaultPadding),

          // Ward Selection and Population
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
                // _buildResponsiveDropdown(
                //   label: 'Ward',
                //   value: _selectedWard,
                //   items: districtsWards[_district] ?? [],
                //   icon: Icons.location_city,
                //   onChanged: (value) => setState(() => _selectedWard = value),
                // ),
                // SizedBox(height: smallPadding),
                // _buildResponsiveTextField(
                //   label: 'Ward Population',
                //   controller: _wardPopulationController,
                //   prefixIcon: Icons.groups,
                //   keyboardType: TextInputType.number,
                // ),
                _buildResponsiveDropdown(
                    label: 'Ward',
                    value: _ward,
                    items: districtsWards[_district] ?? [],
                    icon: Icons.location_city,
                    onChanged: (value) {
                      setState(() {
                        _ward = value;
                        // Auto-fill the population when ward is selected
                        if (value != null) {
                          _wardPopulationController.text = wardPopulations[value]?.toString() ?? '';
                        } else {
                          _wardPopulationController.text = '';
                        }
                      });
                    },
                  ),
                  SizedBox(height: smallPadding),
                  _buildResponsiveTextField(
                    label: 'Ward Population',
                    controller: _wardPopulationController,
                    prefixIcon: Icons.groups,
                    keyboardType: TextInputType.number,
                    // readOnly: true, // Make it read-only since it's auto-filled
                  ),
              ],
            ),
          ),

          SizedBox(height: defaultPadding),

          // Street Input
          // Container(
          //   padding: EdgeInsets.all(cardPadding),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[50],
          //     borderRadius: BorderRadius.circular(screenWidth * 0.02),
          //     border: Border.all(color: Colors.grey[200]!),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       _buildResponsiveTextField(
          //         label: 'Street Name',
          //         controller: _catchmentStreetController,
          //         prefixIcon: Icons.add_road,
          //       ),
          //       SizedBox(height: smallPadding),
          //       _buildResponsiveTextField(
          //         label: 'Street Population',
          //         controller: _catchmentStreetpopController,
          //         prefixIcon: Icons.groups,
          //         keyboardType: TextInputType.number,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

// IconData _getLocationTypeIcon(String type) {
//   switch (type) {
//     case 'Residential':
//       return Icons.home_outlined;
//     case 'Industrial':
//       return Icons.factory_outlined;
//     case 'Commercial':
//       return Icons.store_outlined;
//     case 'Institutional':
//       return Icons.account_balance_outlined;
//     default:
//       return Icons.location_city_outlined;
//   }
// }



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




Widget _buildResponsiveRadioGroup({
  required String title,
  required String groupValue,
  required Map<String, String> options,
  required Function(String) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: bodyTextSize,
          color: Colors.grey[600],
        ),
      ),
      SizedBox(height: smallPadding),
      ...options.entries.map(
        (entry) => Container(
          margin: EdgeInsets.symmetric(vertical: smallPadding / 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: groupValue == entry.key
                  ? const Color(0xFF90EE90)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: RadioListTile<String>(
            title: Text(
              entry.value,
              style: TextStyle(fontSize: bodyTextSize),
            ),
            value: entry.key,
            groupValue: groupValue,
            onChanged: (value) => onChanged(value!),
            activeColor: const Color(0xFF90EE90),
            contentPadding: EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: smallPadding,
            ),
          ),
        ),
      ),
    ],
  );
}



















// Widget _buildWasteSourcesCard() {
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
//             'Waste Sources',
//             Icons.source_outlined,
//           ),
//           SizedBox(height: defaultPadding),

//           // Sources Grid
//           Container(
//             padding: EdgeInsets.all(cardPadding),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//               border: Border.all(color: Colors.grey[200]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Who brings waste to this collection point?',
//                   style: TextStyle(
//                     fontSize: bodyTextSize,
//                     fontWeight: FontWeight.w500,
//                     color: primaryColor,
//                   ),
//                 ),
//                 SizedBox(height: defaultPadding),
//                 _buildSourcesGrid(),
//               ],
//             ),
//           ),

//           if (_wasteSources.contains('Institutions')) ...[
//             SizedBox(height: defaultPadding),
//             _buildInstitutionTypeSection(),
//           ],

//           if (_wasteSources.contains('Others')) ...[
//             SizedBox(height: defaultPadding),
//             _buildOtherSourceInput(),
//           ],
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildSourcesGrid() {
//   final sources = [
//     SourceOption('Households', Icons.home_outlined),
//     SourceOption('Institutions', Icons.account_balance_outlined),
//     SourceOption('Collection vendors', Icons.local_shipping_outlined),
//     SourceOption('Registered groups', Icons.groups_outlined),
//     SourceOption('Others', Icons.add_circle_outline),
//   ];

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
//       return GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: crossAxisCount,
//           childAspectRatio: 3,
//           crossAxisSpacing: smallPadding,
//           mainAxisSpacing: smallPadding,
//         ),
//         itemCount: sources.length,
//         itemBuilder: (context, index) {
//           final source = sources[index];
//           return _buildSourceChip(source.name, source.icon);
//         },
//       );
//     },
//   );
// }

// Widget _buildSourceChip(String source, IconData icon) {
//   final isSelected = _wasteSources.contains(source);
//   return Material(
//     color: Colors.transparent,
//     child: InkWell(
//       onTap: () {
//         setState(() {
//           if (isSelected) {
//             _wasteSources.remove(source);
//             if (source == 'Institutions') {
//               _institutionType = null;
//               _otherInstitution = null;
//             }
//           } else {
//             _wasteSources.add(source);
//           }
//         });
//       },
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: EdgeInsets.all(smallPadding),
//         decoration: BoxDecoration(
//           color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(
//             color: isSelected ? primaryColor : Colors.grey[300]!,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? primaryColor : Colors.grey[600],
//               size: screenWidth * 0.045,
//             ),
//             SizedBox(width: smallPadding),
//             Flexible(
//               child: Text(
//                 source,
//                 style: TextStyle(
//                   color: isSelected ? primaryColor : Colors.grey[600],
//                   fontSize: smallTextSize,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   ).animate()
//    .scale(duration: const Duration(milliseconds: 200));
// }

// Widget _buildInstitutionTypeSection() {
//   final institutionTypes = [
//     InstitutionType('Hospital', Icons.local_hospital_outlined),
//     InstitutionType('School', Icons.school_outlined),
//     InstitutionType('Factory', Icons.factory_outlined),
//     InstitutionType('Others', Icons.more_horiz),
//   ];

//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.blue[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.blue[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.account_balance_outlined, 
//                 color: Colors.blue[700], 
//                 size: screenWidth * 0.05),
//             SizedBox(width: smallPadding),
//             Text(
//               'Institution Type',
//               style: TextStyle(
//                 fontSize: bodyTextSize,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue[700],
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: defaultPadding),
//         Wrap(
//           spacing: smallPadding,
//           runSpacing: smallPadding,
//           children: institutionTypes.map((type) => _buildInstitutionTypeChip(
//             type.name,
//             type.icon,
//           )).toList(),
//         ),
//         if (_institutionType == 'Others') ...[
//           SizedBox(height: defaultPadding),
//           _buildResponsiveTextField(
//             label: 'Specify Institution Type',
//             controller: _otherInstitutionController,
//             prefixIcon: Icons.edit_outlined,
//           ),
//         ],
//       ],
//     ),
//   );
// }

// Widget _buildInstitutionTypeChip(String type, IconData icon) {
//   final isSelected = _institutionType == type;
//   return FilterChip(
//     label: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           icon,
//           size: screenWidth * 0.04,
//           color: isSelected ? Colors.white : Colors.blue[700],
//         ),
//         SizedBox(width: smallPadding / 2),
//         Text(type),
//       ],
//     ),
//     selected: isSelected,
//     onSelected: (selected) {
//       setState(() {
//         _institutionType = selected ? type : null;
//         if (type != 'Others') {
//           _otherInstitution = null;
//         }
//       });
//     },
//     selectedColor: Colors.blue[700],
//     checkmarkColor: Colors.white,
//     labelStyle: TextStyle(
//       color: isSelected ? Colors.white : Colors.blue[700],
//       fontSize: smallTextSize,
//     ),
//   );
// }

// Widget _buildOtherSourceInput() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.orange[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.orange[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.add_circle_outline,
//                 color: Colors.orange[700],
//                 size: screenWidth * 0.05),
//             SizedBox(width: smallPadding),
//             Text(
//               'Other Waste Source',
//               style: TextStyle(
//                 fontSize: bodyTextSize,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.orange[700],
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: defaultPadding),
//         _buildResponsiveTextField(
//           label: 'Specify Other Source',
//           controller: _otherWasteSourceController,
//           prefixIcon: Icons.edit_outlined,
//         ),
//       ],
//     ),
//   );
// }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C2F),
      // drawer: CustomDrawer(
      //   firstName: _firstName,
      //   isAdmin: _isAdmin,
      //   selectedIndex: _selectedIndex,
      //   onItemTapped: _onItemTapped,
      //   user: widget.user,
      // ),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF115937).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_location_alt,
                        color: Color(0xFF115937),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New Collection Point',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: Colors.white,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        _buildLocationCard(),
                         const SizedBox(height: 24),

//                 // Status Card
                _buildStatusCard(),
                const SizedBox(height: 24),

                // Geographic Location Card
                _buildGeographicLocationCard(),
                const SizedBox(height: 24),

                // // Location Characteristics Card
                // _buildLocationCharacteristicsCard(),
                // const SizedBox(height: 24),

                // // Accessibility Card
                // _buildAccessibilityCard(),
                // const SizedBox(height: 24),

                // // Capacity Card
                // _buildCapacityCard(),
                // const SizedBox(height: 24),

                // Catchment Areas Card
                _buildCatchmentAreasCard(),
                const SizedBox(height: 24),

                // // Waste Types Card
                // _buildWasteTypesCard(),
                // const SizedBox(height: 24),

                // // Segregation Facilities Card
                // _buildSegregationCard(),
                // const SizedBox(height: 24),

                // // Infrastructure Card
                // _buildInfrastructureCard(),
                // const SizedBox(height: 24),

                // // Attendant Information Card
                // _buildAttendantCard(),
                // const SizedBox(height: 24),

                // // Disposal Information Card
                // _buildDisposalCard(),
                // const SizedBox(height: 24),

                // // Transport Information Card
                // _buildTransportCard(),
                // const SizedBox(height: 24),

                // // Neighbor Opinions Card
                // _buildNeighborOpinionsCard(),
                // const SizedBox(height: 24),

                // Waste Sources Card
                // _buildWasteSourcesCard(),
                // const SizedBox(height: 24),
                    _buildImageUrlCard(),
                const SizedBox(height: 24),
                // Form Completion Status Card
                _buildFormCompletionCard(),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),
                     ].animate(interval: const Duration(milliseconds: 50))
                       .fadeIn(duration: const Duration(milliseconds: 300))
                       .slideX(begin: 0.2, end: 0),
                    ),
                  ),
                ),
              ),
      ),
    );
  }








// Widget _buildWasteTypesCard() {
//   // Calculate total percentage
//   final totalPercentage = _wasteTypes.values.fold(0.0, (sum, value) => sum + value);
//   final isValidTotal = (totalPercentage - 100).abs() < 0.01;

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
//             'Waste Composition',
//             Icons.pie_chart_outline,
//           ),
//           SizedBox(height: defaultPadding),

//           // Total Percentage Indicator
//           Container(
//             padding: EdgeInsets.all(cardPadding),
//             decoration: BoxDecoration(
//               color: isValidTotal ? Colors.green[50] : Colors.orange[50],
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//               border: Border.all(
//                 color: isValidTotal ? Colors.green[200]! : Colors.orange[200]!,
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   isValidTotal ? Icons.check_circle : Icons.warning,
//                   color: isValidTotal ? Colors.green : Colors.orange,
//                   size: screenWidth * 0.06,
//                 ),
//                 SizedBox(width: smallPadding),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Total: ${totalPercentage.toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           fontSize: bodyTextSize,
//                           fontWeight: FontWeight.bold,
//                           color: isValidTotal ? Colors.green[700] : Colors.orange[700],
//                         ),
//                       ),
//                       if (!isValidTotal)
//                         Text(
//                           'Total should equal 100%',
//                           style: TextStyle(
//                             fontSize: smallTextSize,
//                             color: Colors.orange[700],
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: defaultPadding),

//           // Waste Type Inputs
//           LayoutBuilder(
//             builder: (context, constraints) {
//               return Column(
//                 children: _wasteTypes.entries.map((entry) {
//                   return Padding(
//                     padding: EdgeInsets.only(bottom: smallPadding),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               flex: 2,
//                               child: Text(
//                                 entry.key,
//                                 style: TextStyle(
//                                   fontSize: bodyTextSize,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                             SizedBox(width: smallPadding),
//                             SizedBox(
//                               width: constraints.maxWidth * 0.25,
//                               child: TextFormField(
//                                 controller: _wasteTypeControllers[entry.key],
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(fontSize: bodyTextSize),
//                                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                                 decoration: InputDecoration(
//                                   suffixText: '%',
//                                   contentPadding: EdgeInsets.symmetric(
//                                     horizontal: smallPadding,
//                                     vertical: smallPadding / 2,
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                                   ),
//                                 ),
//                                 inputFormatters: [
//                                   FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
//                                 ],
//                                 onChanged: (value) {
//                                   final number = double.tryParse(value);
//                                   if (number != null && number >= 0 && number <= 100) {
//                                     setState(() {
//                                       _wasteTypes[entry.key] = number;
//                                     });
//                                   }
//                                 },
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: smallPadding / 2),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(screenWidth * 0.01),
//                           child: LinearProgressIndicator(
//                             value: entry.value / 100,
//                             backgroundColor: Colors.grey[200],
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               HSLColor.fromAHSL(
//                                 1.0,
//                                 120 * (entry.value / 100),
//                                 0.6,
//                                 0.5,
//                               ).toColor(),
//                             ),
//                             minHeight: screenWidth * 0.015,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               );
//             },
//           ),

//           if (_wasteTypes['Others']! > 0)
//             _buildOtherWasteTypeInput(),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildOtherWasteTypeInput() {
//   return Container(
//     margin: EdgeInsets.only(top: defaultPadding),
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Specify Other Waste Types',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         TextFormField(
//           initialValue: _otherWasteType,
//           style: TextStyle(fontSize: bodyTextSize),
//           decoration: InputDecoration(
//             hintText: 'Enter other waste types',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.all(defaultPadding),
//           ),
//           onChanged: (value) => setState(() => _otherWasteType = value),
//           maxLines: 2,
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildSegregationCard() {
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
//             'Waste Segregation',
//             Icons.category,
//           ),
//           SizedBox(height: defaultPadding),

//           // Segregation Toggle
//           _buildSegregationToggle(),

//           if (_hasSegregationFacilities) ...[
//             SizedBox(height: defaultPadding),
            
//             // Segregated Types
//             _buildSegregatedTypesSection(),

//             if (_segregatedWasteTypes.contains('Other'))
//               _buildOtherSegregatedTypeInput(),

//             SizedBox(height: defaultPadding),
            
//             // Facilities
//             _buildFacilitiesSection(),
//           ],
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildSegregationToggle() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: _hasSegregationFacilities ? Colors.green[50] : Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(
//         color: _hasSegregationFacilities ? Colors.green[200]! : Colors.grey[200]!,
//       ),
//     ),
//     child: Row(
//       children: [
//         Icon(
//           _hasSegregationFacilities ? Icons.check_circle : Icons.cancel_outlined,
//           color: _hasSegregationFacilities ? Colors.green : Colors.grey,
//           size: screenWidth * 0.06,
//         ),
//         SizedBox(width: smallPadding),
//         Expanded(
//           child: Text(
//             'Segregation Facilities Available',
//             style: TextStyle(
//               fontSize: bodyTextSize,
//               fontWeight: FontWeight.w500,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         Switch.adaptive(
//           value: _hasSegregationFacilities,
//           onChanged: (value) => setState(() => _hasSegregationFacilities = value),
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildSegregatedTypesSection() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Types of Waste Segregated',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         LayoutBuilder(
//           builder: (context, constraints) {
//             return Wrap(
//               spacing: smallPadding,
//               runSpacing: smallPadding,
//               children: [
//                 'Domestic garbage',
//                 'Plastics',
//                 'Papers',
//                 'Glass',
//                 'Other',
//               ].map((type) => Container(
//                 constraints: BoxConstraints(
//                   maxWidth: constraints.maxWidth > 600 
//                     ? constraints.maxWidth / 3 - smallPadding * 2
//                     : constraints.maxWidth / 2 - smallPadding,
//                 ),
//                 child: ChoiceChip(
//                   label: Text(
//                     type,
//                     style: TextStyle(
//                       fontSize: smallTextSize,
//                       color: _segregatedWasteTypes.contains(type) 
//                         ? Colors.white 
//                         : Colors.grey[700],
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   selected: _segregatedWasteTypes.contains(type),
//                   onSelected: (selected) {
//                     setState(() {
//                       if (selected) {
//                         _segregatedWasteTypes.add(type);
//                       } else {
//                         _segregatedWasteTypes.remove(type);
//                       }
//                     });
//                   },
//                   selectedColor: const Color(0xFF115937),
//                   backgroundColor: Colors.grey[100],
//                 ),
//               )).toList(),
//             );
//           },
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildOtherSegregatedTypeInput() {
//   return Padding(
//     padding: EdgeInsets.only(top: defaultPadding),
//     child: TextFormField(
//       initialValue: _otherSegregatedType,
//       style: TextStyle(fontSize: bodyTextSize),
//       decoration: InputDecoration(
//         labelText: 'Specify Other Type',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//         ),
//         contentPadding: EdgeInsets.all(defaultPadding),
//       ),
//       onChanged: (value) => setState(() => _otherSegregatedType = value),
//     ),
//   );
// }

// Widget _buildFacilitiesSection() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Available Facilities',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         LayoutBuilder(
//           builder: (context, constraints) {
//             return Wrap(
//               spacing: smallPadding,
//               runSpacing: smallPadding,
//               children: [
//                 'Metal bins',
//                 'Plastic bins',
//                 'Concrete chambers',
//                 'Others',
//               ].map((facility) => Container(
//                 constraints: BoxConstraints(
//                   maxWidth: constraints.maxWidth > 600 
//                     ? constraints.maxWidth / 3 - smallPadding * 2
//                     : constraints.maxWidth / 2 - smallPadding,
//                 ),
//                 child: FilterChip(
//                   label: Text(
//                     facility,
//                     style: TextStyle(fontSize: smallTextSize),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   selected: _segregationFacilities.contains(facility),
//                   onSelected: (selected) {
//                     setState(() {
//                       if (selected) {
//                         _segregationFacilities.add(facility);
//                       } else {
//                         _segregationFacilities.remove(facility);
//                       }
//                     });
//                   },
//                   selectedColor: const Color(0xFF115937).withOpacity(0.2),
//                   checkmarkColor: const Color(0xFF115937),
//                 ),
//               )).toList(),
//             );
//           },
//         ),
//       ],
//     ),
//   );
// }


// Widget _buildInfrastructureCard() {
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
//             'Infrastructure',
//             Icons.business,
//           ),
//           SizedBox(height: defaultPadding),

//           // Infrastructure Grid
//           LayoutBuilder(
//             builder: (context, constraints) {
//               final isNarrow = constraints.maxWidth < 600;
//               return Wrap(
//                 spacing: defaultPadding,
//                 runSpacing: defaultPadding,
//                 children: [
//                   SizedBox(
//                     width: isNarrow ? constraints.maxWidth 
//                                   : (constraints.maxWidth - defaultPadding) / 2,
//                     child: _buildInfrastructureItem(
//                       title: 'Demarcation (Fence)',
//                       value: _hasDemarcation,
//                       icon: Icons.fence,
//                       onChanged: (value) => setState(() => _hasDemarcation = value),
//                     ),
//                   ),
//                   SizedBox(
//                     width: isNarrow ? constraints.maxWidth 
//                                   : (constraints.maxWidth - defaultPadding) / 2,
//                     child: _buildInfrastructureItem(
//                       title: 'Sorting Practice',
//                       value: _hasSortingPractice,
//                       icon: Icons.sort,
//                       onChanged: (value) => setState(() => _hasSortingPractice = value),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildInfrastructureItem({
//   required String title,
//   required bool value,
//   required IconData icon,
//   required Function(bool) onChanged,
// }) {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: value ? Colors.green[50] : Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(
//         color: value ? Colors.green[200]! : Colors.grey[200]!,
//       ),
//     ),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           icon,
//           color: value ? Colors.green : Colors.grey,
//           size: screenWidth * 0.06,
//         ),
//         SizedBox(height: smallPadding),
//         Text(
//           title,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//             color: value ? Colors.green[700] : Colors.grey[700],
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         Switch.adaptive(
//           value: value,
//           onChanged: onChanged,
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildAttendantCard() {
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
//             'Attendant Information',
//             Icons.person,
//           ),
//           SizedBox(height: defaultPadding),

//           // Attendant Toggle
//           _buildAttendantToggle(),

//           if (_hasAttendant) ...[
//             SizedBox(height: defaultPadding),

//             // Attendant Status Grid
//             LayoutBuilder(
//               builder: (context, constraints) {
//                 final isNarrow = constraints.maxWidth < 600;
//                 return Wrap(
//                   spacing: defaultPadding,
//                   runSpacing: defaultPadding,
//                   children: [
//                     SizedBox(
//                       width: isNarrow ? constraints.maxWidth 
//                                     : (constraints.maxWidth - defaultPadding) / 2,
//                       child: _buildAttendantStatusItem(
//                         title: 'Training Status',
//                         value: _isAttendantTrained,
//                         icon: Icons.school,
//                         onChanged: (value) => setState(() => _isAttendantTrained = value),
//                         activeText: 'Trained',
//                         inactiveText: 'Untrained',
//                       ),
//                     ),
//                     SizedBox(
//                       width: isNarrow ? constraints.maxWidth 
//                                     : (constraints.maxWidth - defaultPadding) / 2,
//                       child: _buildAttendantStatusItem(
//                         title: 'PPE Available',
//                         value: _hasppe,
//                         icon: Icons.security,
//                         onChanged: (value) => setState(() => _hasppe = value),
//                         activeText: 'Has PPE',
//                         inactiveText: 'No PPE',
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),

//             if (_hasppe)
//               _buildPPESection(),
//           ],
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildAttendantToggle() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: _hasAttendant ? Colors.green[50] : Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(
//         color: _hasAttendant ? Colors.green[200]! : Colors.grey[200]!,
//       ),
//     ),
//     child: Row(
//       children: [
//         Icon(
//           _hasAttendant ? Icons.person_outline : Icons.person_off_outlined,
//           color: _hasAttendant ? Colors.green : Colors.grey,
//           size: screenWidth * 0.06,
//         ),
//         SizedBox(width: smallPadding),
//         Expanded(
//           child: Text(
//             'Attendant Available',
//             style: TextStyle(
//               fontSize: bodyTextSize,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//         Switch.adaptive(
//           value: _hasAttendant,
//           onChanged: (value) => setState(() => _hasAttendant = value),
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   );
// }




// Widget _buildAttendantStatusItem({
//   required String title,
//   required bool value,
//   required IconData icon,
//   required Function(bool) onChanged,
//   required String activeText,
//   required String inactiveText,
// }) {
//   return Container(
//     padding: const EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: value ? Colors.green[50] : Colors.grey[50],
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(
//         color: value ? Colors.green[200]! : Colors.grey[200]!,
//       ),
//     ),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(
//           icon,
//           color: value ? Colors.green : Colors.grey,
//           size: 24,
//         ),
//         const SizedBox(height: 8),
//         Text(
//           title,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: value ? Colors.green[700] : Colors.grey[700],
//           ),
//         ),
//         Text(
//           value ? activeText : inactiveText,
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             fontSize: 10,
//             color: value ? Colors.green[700] : Colors.grey[700],
//           ),
//         ),
//         const SizedBox(height: 8),
//         Switch(
//           value: value,
//           onChanged: onChanged,
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 200))
//   //  .scale(begin: 0.95);
//   .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0));
// }





// Widget _buildPPESection() {
//   return Container(
//     margin: EdgeInsets.only(top: defaultPadding),
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Available PPE Types',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: defaultPadding),
//         LayoutBuilder(
//           builder: (context, constraints) {
//             return Wrap(
//               spacing: smallPadding,
//               runSpacing: smallPadding,
//               children: [
//                 _buildPPEChip('Gumboot', Icons.hiking, constraints),
//                 _buildPPEChip('Gloves', Icons.back_hand, constraints),
//                 _buildPPEChip('Mask', Icons.masks, constraints),
//                 _buildPPEChip('Helmet', Icons.engineering, constraints),
//                 _buildPPEChip('Face shield', Icons.face, constraints),
//                 _buildPPEChip('Coverall', Icons.person_outline, constraints),
//                 _buildPPEChip('Others', Icons.add, constraints),
//               ],
//             );
//           },
//         ),

//         if (_ppeTypes.contains('Others'))
//           Padding(
//             padding: EdgeInsets.only(top: defaultPadding),
//             child: TextFormField(
//               initialValue: _otherPPE,
//               style: TextStyle(fontSize: bodyTextSize),
//               decoration: InputDecoration(
//                 labelText: 'Specify Other PPE',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                 ),
//                 contentPadding: EdgeInsets.all(defaultPadding),
//               ),
//               onChanged: (value) => setState(() => _otherPPE = value),
//             ),
//           ),
//       ],
//     ),
//   );
// }

// Widget _buildPPEChip(String label, IconData icon, BoxConstraints constraints) {
//   final isSelected = _ppeTypes.contains(label);
//   return Container(
//     constraints: BoxConstraints(
//       maxWidth: constraints.maxWidth > 600 
//         ? constraints.maxWidth / 3 - smallPadding * 2
//         : constraints.maxWidth / 2 - smallPadding,
//     ),
//     child: FilterChip(
//       label: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: screenWidth * 0.04,
//             color: isSelected ? Colors.white : Colors.grey[600],
//           ),
//           SizedBox(width: smallPadding / 2),
//           Flexible(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: smallTextSize,
//                 color: isSelected ? Colors.white : Colors.grey[600],
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           if (selected) {
//             _ppeTypes.add(label);
//           } else {
//             _ppeTypes.remove(label);
//           }
//         });
//       },
//       selectedColor: const Color(0xFF115937),
//       backgroundColor: Colors.grey[100],
//       padding: EdgeInsets.symmetric(
//         horizontal: smallPadding,
//         vertical: smallPadding / 2,
//       ),
//     ),
//   );
// }

// Widget _buildTransportCard() {
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
//             'Transport Information',
//             Icons.local_shipping,
//           ),
//           SizedBox(height: defaultPadding),

//           // Transport Toggle
//           _buildTransportToggle(),

//           if (_hasTransport) ...[
//             SizedBox(height: defaultPadding),
            
//             // Transport Details
//             Container(
//               padding: EdgeInsets.all(cardPadding),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildTransportFrequencySection(),
//                   SizedBox(height: defaultPadding),
//                   _buildTransportTypeSection(),
//                   SizedBox(height: defaultPadding),
//                   _buildTransportResponsibleSection(),
//                   SizedBox(height: defaultPadding),
//                   _buildTransportNeedsSection(),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildTransportToggle() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: _hasTransport ? Colors.green[50] : Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(
//         color: _hasTransport ? Colors.green[200]! : Colors.grey[200]!,
//       ),
//     ),
//     child: Row(
//       children: [
//         Icon(
//           _hasTransport ? Icons.check_circle : Icons.cancel_outlined,
//           color: _hasTransport ? Colors.green : Colors.grey,
//           size: screenWidth * 0.06,
//         ),
//         SizedBox(width: smallPadding),
//         Expanded(
//           child: Text(
//             'Transport Available',
//             style: TextStyle(
//               fontSize: bodyTextSize,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//         Switch.adaptive(
//           value: _hasTransport,
//           onChanged: (value) => setState(() => _hasTransport = value),
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildTransportFrequencySection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         'Collection Frequency',
//         style: TextStyle(
//           fontSize: bodyTextSize,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       SizedBox(height: smallPadding),
//       LayoutBuilder(
//         builder: (context, constraints) {
//           return Wrap(
//             spacing: smallPadding,
//             runSpacing: smallPadding,
//             children: [
//               'Every day',
//               'After 2 - 3 days',
//               'After 4 - 5 days',
//               'Once a week',
//               'More than a week',
//             ].map((frequency) => Container(
//               constraints: BoxConstraints(
//                 maxWidth: constraints.maxWidth > 600 
//                   ? constraints.maxWidth / 3 - smallPadding * 2
//                   : constraints.maxWidth / 2 - smallPadding,
//               ),
//               child: ChoiceChip(
//                 label: Text(
//                   frequency,
//                   style: TextStyle(
//                     fontSize: smallTextSize,
//                     color: _transportFrequency == frequency 
//                       ? Colors.white 
//                       : Colors.grey[700],
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 selected: _transportFrequency == frequency,
//                 onSelected: (selected) {
//                   if (selected) {
//                     setState(() => _transportFrequency = frequency);
//                   }
//                 },
//                 selectedColor: const Color(0xFF115937),
//                 backgroundColor: Colors.grey[100],
//               ),
//             )).toList(),
//           );
//         },
//       ),
//     ],
//   );
// }


// Widget _buildTransportTypeSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         'Transport Type',
//         style: TextStyle(
//           fontSize: bodyTextSize,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       SizedBox(height: smallPadding),
//       Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: ListView.separated(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: ['Toyo', 'Tractor', 'Truck', 'Compacting truck'].length,
//           separatorBuilder: (context, index) => Divider(
//             height: 1,
//             color: Colors.grey[300],
//           ),
//           itemBuilder: (context, index) {
//             final type = ['Toyo', 'Tractor', 'Truck', 'Compacting truck'][index];
//             return RadioListTile<String>(
//               title: Text(
//                 type,
//                 style: TextStyle(fontSize: bodyTextSize),
//               ),
//               value: type,
//               groupValue: _transportType,
//               onChanged: (value) => setState(() => _transportType = value!),
//               activeColor: const Color(0xFF115937),
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: defaultPadding,
//                 vertical: smallPadding,
//               ),
//             );
//           },
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildTransportResponsibleSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         'Transport Responsible',
//         style: TextStyle(
//           fontSize: bodyTextSize,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       SizedBox(height: smallPadding),
//       Container(
//         padding: EdgeInsets.symmetric(horizontal: defaultPadding),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             value: _transportResponsible,
//             isExpanded: true,
//             icon: Icon(
//               Icons.arrow_drop_down,
//               size: screenWidth * 0.06,
//               color: const Color(0xFF115937),
//             ),
//             items: [
//               'Council',
//               'Contracted firm by the council',
//               'Private venture',
//             ].map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(
//                   value,
//                   style: TextStyle(fontSize: bodyTextSize),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               );
//             }).toList(),
//             onChanged: (value) => setState(() => _transportResponsible = value!),
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _buildTransportNeedsSection() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: _transportMeetsNeeds ? Colors.green[50] : Colors.orange[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(
//         color: _transportMeetsNeeds ? Colors.green[200]! : Colors.orange[200]!,
//       ),
//     ),
//     child: Row(
//       children: [
//         Icon(
//           _transportMeetsNeeds ? Icons.check_circle : Icons.warning,
//           color: _transportMeetsNeeds ? Colors.green : Colors.orange,
//           size: screenWidth * 0.06,
//         ),
//         SizedBox(width: smallPadding),
//         Expanded(
//           child: Text(
//             'Transport Meets Needs',
//             style: TextStyle(
//               fontSize: bodyTextSize,
//               fontWeight: FontWeight.w500,
//               color: _transportMeetsNeeds ? Colors.green[700] : Colors.orange[700],
//             ),
//           ),
//         ),
//         Switch.adaptive(
//           value: _transportMeetsNeeds,
//           onChanged: (value) => setState(() => _transportMeetsNeeds = value),
//           activeColor: const Color(0xFF115937),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildDisposalCard() {
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
//             'Disposal Information',
//             Icons.delete_outline,
//           ),
//           SizedBox(height: defaultPadding),

//           // Distance Slider
//           _buildDisposalDistanceSection(),

//           SizedBox(height: defaultPadding),

//           // Disposal Location
//           _buildDisposalLocationSection(),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildDisposalDistanceSection() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(Icons.directions, size: screenWidth * 0.05),
//             SizedBox(width: smallPadding),
//             Expanded(
//               child: Text(
//                 'Distance to Disposal Area',
//                 style: TextStyle(
//                   fontSize: bodyTextSize,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: defaultPadding,
//                 vertical: smallPadding,
//               ),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF115937).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(screenWidth * 0.02),
//               ),
//               child: Text(
//                 '$_disposalDistance KM',
//                 style: TextStyle(
//                   fontSize: bodyTextSize,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF115937),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: defaultPadding),
//         SliderTheme(
//           data: SliderThemeData(
//             activeTrackColor: const Color(0xFF115937),
//             inactiveTrackColor: const Color(0xFF115937).withOpacity(0.1),
//             thumbColor: const Color(0xFF115937),
//             overlayColor: const Color(0xFF115937).withOpacity(0.2),
//             trackHeight: screenWidth * 0.01,
//             thumbShape: RoundSliderThumbShape(
//               enabledThumbRadius: screenWidth * 0.02,
//             ),
//             overlayShape: RoundSliderOverlayShape(
//               overlayRadius: screenWidth * 0.03,
//             ),
//           ),
//           child: Slider(
//             value: _disposalDistance.toDouble(),
//             min: 1,
//             max: 50,
//             divisions: 49,
//             onChanged: (value) => setState(() => _disposalDistance = value.round()),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildDisposalLocationSection() {
//   return LayoutBuilder(
//     builder: (context, constraints) {
//       final isNarrow = constraints.maxWidth < 600;
//       return Container(
//         padding: EdgeInsets.all(cardPadding),
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(color: Colors.grey[200]!),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.location_on_outlined, size: screenWidth * 0.05),
//                 SizedBox(width: smallPadding),
//                 Text(
//                   'Final Disposal Location',
//                   style: TextStyle(
//                     fontSize: bodyTextSize,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: defaultPadding),
//             Wrap(
//               spacing: defaultPadding,
//               runSpacing: defaultPadding,
//               children: [
//                 SizedBox(
//                   width: isNarrow ? constraints.maxWidth 
//                                 : (constraints.maxWidth - defaultPadding) / 2,
//                   child: _buildResponsiveDropdown(
//                     label: 'District',
//                     value: _disposalDistrict,
//                     items: districts[_region] ?? [],
//                     onChanged: (value) => setState(() => _disposalDistrict = value),
//                     icon: Icons.location_city,
//                   ),
//                 ),
//                 SizedBox(
//                   width: isNarrow ? constraints.maxWidth 
//                                 : (constraints.maxWidth - defaultPadding) / 2,
//                   child: _buildResponsiveDropdown(
//                     label: 'Ward',
//                     value: _disposalWard,
//                     items: districtsWards[_district] ?? [],
//                     onChanged: (value) => setState(() => _disposalWard = value),
//                     icon: Icons.apartment,
//                   ),
//                 ),
//                 SizedBox(
//                   width: isNarrow ? constraints.maxWidth : double.infinity,
//                   child: _buildResponsiveTextField(
//                     label: 'Street',
//                     controller: _disposalStreetController,
//                     // items: ['Street 1', 'Street 2'],
//                     // onChanged: (value) => setState(() => _disposalStreet = value),
//                     prefixIcon: Icons.add_road,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }

// Widget _buildNeighborOpinionsCard() {
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
//             'Neighbor Opinions',
//             Icons.people_outline,
//           ),
//           SizedBox(height: defaultPadding),

//           _buildOpinionsSection(),

//           if (_neighborOpinions.contains('Other'))
//             _buildOtherOpinionInput(),
//         ],
//       ),
//     ),
//   ).animate()
//    .fadeIn(duration: const Duration(milliseconds: 300))
//    .slideY(begin: 0.2, end: 0);
// }

// Widget _buildOpinionsSection() {
//   return Container(
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Opinions of Immediate Neighbors',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         SizedBox(height: defaultPadding),
//         LayoutBuilder(
//           builder: (context, constraints) {
//             return Wrap(
//               spacing: smallPadding,
//               runSpacing: smallPadding,
//               children: [
//                 _buildOpinionChip(
//                   'Ok with the collection point',
//                   Icons.thumb_up_outlined,
//                   Colors.green,
//                   constraints,
//                 ),
//                 _buildOpinionChip(
//                   'Causes bad smell',
//                   Icons.sick_outlined,
//                   Colors.orange,
//                   constraints,
//                 ),
//                 _buildOpinionChip(
//                   'Collected wastes encroaches their environment',
//                   Icons.warning_outlined,
//                   Colors.red,
//                   constraints,
//                 ),
//                 _buildOpinionChip(
//                   'Noises of people and machines',
//                   Icons.volume_up_outlined,
//                   Colors.purple,
//                   constraints,
//                 ),
//                 _buildOpinionChip(
//                   'Other',
//                   Icons.add,
//                   Colors.blue,
//                   constraints,
//                 ),
//               ],
//             );
//           },
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildOpinionChip(String label, IconData icon, Color color, BoxConstraints constraints) {
//   final isSelected = _neighborOpinions.contains(label);
//   return Container(
//     constraints: BoxConstraints(
//       maxWidth: constraints.maxWidth > 600 
//         ? constraints.maxWidth / 2 - smallPadding
//         : constraints.maxWidth,
//     ),
//     child: FilterChip(
//       label: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: screenWidth * 0.04,
//             color: isSelected ? Colors.white : color.withOpacity(0.8),
//           ),
//           SizedBox(width: smallPadding / 2),
//           Flexible(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: smallTextSize,
//                 color: isSelected ? Colors.white : Colors.black87,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           if (selected) {
//             _neighborOpinions.add(label);
//           } else {
//             _neighborOpinions.remove(label);
//           }
//         });
//       },
//       selectedColor: color,
//       backgroundColor: color.withOpacity(0.1),
//       padding: EdgeInsets.symmetric(
//         horizontal: smallPadding,
//         vertical: smallPadding / 2,
//       ),
//     ),
//   );
// }

// Widget _buildOtherOpinionInput() {
//   return Container(
//     margin: EdgeInsets.only(top: defaultPadding),
//     padding: EdgeInsets.all(cardPadding),
//     decoration: BoxDecoration(
//       color: Colors.blue[50],
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       border: Border.all(color: Colors.blue[200]!),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Specify Other Opinion',
//           style: TextStyle(
//             fontSize: bodyTextSize,
//             fontWeight: FontWeight.w500,
//             color: Colors.blue[700],
//           ),
//         ),
//         SizedBox(height: smallPadding),
//         TextFormField(
//           initialValue: _otherNeighborOpinion,
//           style: TextStyle(fontSize: bodyTextSize),
//           decoration: InputDecoration(
//             hintText: 'Enter other neighbor opinions...',
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.02),
//             ),
//             filled: true,
//             fillColor: Colors.white,
//             contentPadding: EdgeInsets.all(defaultPadding),
//           ),
//           maxLines: 3,
//           onChanged: (value) => setState(() => _otherNeighborOpinion = value),
//         ),
//       ],
//     ),
//   );
// }





// Widget _buildObstaclesGrid() {
//   final obstacles = [
//     ObstacleOption(
//       'No road at all',
//       Icons.no_crash_outlined,
//       Colors.red,
//     ),
//     ObstacleOption(
//       'Poor road condition',
//       Icons.wrong_location_outlined,
//       Colors.orange,
//     ),
//     ObstacleOption(
//       'Located at the rock hills',
//       Icons.landscape_outlined,
//       Colors.brown,
//     ),
//     ObstacleOption(
//       'Located at flooded area',
//       Icons.water_outlined,
//       Colors.blue,
//     ),
//     ObstacleOption(
//       'Others',
//       Icons.add_circle_outline,
//       Colors.grey,
//     ),
//   ];

//   return LayoutBuilder(
//     builder: (context, constraints) {
//       final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
//       return GridView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: crossAxisCount,
//           childAspectRatio: 3,
//           crossAxisSpacing: smallPadding,
//           mainAxisSpacing: smallPadding,
//         ),
//         itemCount: obstacles.length,
//         itemBuilder: (context, index) {
//           final obstacle = obstacles[index];
//           return _buildObstacleChip(
//             obstacle.name,
//             obstacle.icon,
//             obstacle.color,
//           );
//         },
//       );
//     },
//   );
// }

// Widget _buildObstacleChip(String obstacle, IconData icon, Color color) {
//   final isSelected = _accessObstacles.contains(obstacle);
//   return Material(
//     color: Colors.transparent,
//     child: InkWell(
//       onTap: () {
//         setState(() {
//           if (isSelected) {
//             _accessObstacles.remove(obstacle);
//             if (obstacle == 'Others') {
//               _otherObstacle = null;
//               _otherObstacleController.clear();
//             }
//           } else {
//             _accessObstacles.add(obstacle);
//           }
//         });
//       },
//       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: EdgeInsets.all(smallPadding),
//         decoration: BoxDecoration(
//           color: isSelected ? color.withOpacity(0.1) : Colors.white,
//           borderRadius: BorderRadius.circular(screenWidth * 0.02),
//           border: Border.all(
//             color: isSelected ? color : Colors.grey[300]!,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: isSelected ? color : Colors.grey[600],
//               size: screenWidth * 0.045,
//             ),
//             SizedBox(width: smallPadding),
//             Flexible(
//               child: Text(
//                 obstacle,
//                 style: TextStyle(
//                   color: isSelected ? color : Colors.grey[600],
//                   fontSize: smallTextSize,
//                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             if (isSelected) ...[
//               SizedBox(width: smallPadding / 2),
//               Icon(
//                 Icons.check_circle_outline,
//                 color: color,
//                 size: screenWidth * 0.04,
//               ),
//             ],
//           ],
//         ),
//       ),
//     ),
//   ).animate()
//    .scale(
//      duration: const Duration(milliseconds: 200),
//      curve: Curves.easeOut,
//    );
// }








// Final Submit Button with loading state
Widget _buildSubmitButton() {
  return Container(
    margin: EdgeInsets.only(
      top: defaultPadding,
      bottom: defaultPadding * 2,
    ),
    child: ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF115937),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: defaultPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        elevation: 2,
        minimumSize: Size(double.infinity, screenHeight * 0.06),
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
              'Submit Form',
              style: TextStyle(
                fontSize: headingSize,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

// Form Completion Status Card
Widget _buildFormCompletionCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
    ),
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form Completion Status',
            style: TextStyle(
              fontSize: headingSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: smallPadding),
          Text(
            'Please review all required fields before submission.',
            style: TextStyle(
              fontSize: bodyTextSize,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: defaultPadding),
          LinearProgressIndicator(
            value: _calculateFormProgress(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _calculateFormProgress() == 1.0 ? Colors.green : Colors.orange,
            ),
            minHeight: screenWidth * 0.02,
            borderRadius: BorderRadius.circular(screenWidth * 0.01),
          ),
          SizedBox(height: smallPadding),
          Text(
            '${(_calculateFormProgress() * 100).toInt()}% Complete',
            style: TextStyle(
              fontSize: smallTextSize,
              color: _calculateFormProgress() == 1.0 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  ).animate()
   .fadeIn(duration: const Duration(milliseconds: 300))
   .slideY(begin: 0.2, end: 0);
}

// Helper method to calculate form progress
double _calculateFormProgress() {
  int totalFields = 0;
  int completedFields = 0;

  // Add your form validation logic here
  void checkField(dynamic value) {
    totalFields++;
    if (value != null && value.toString().isNotEmpty) {
      completedFields++;
    }
  }

  // Check all required fields
  checkField(_region);
  checkField(_district);
  checkField(_ward);
  // checkField(_street);
  checkField(_latitude);
  checkField(_longitude);
  // Add more fields as needed...

  return totalFields > 0 ? completedFields / totalFields : 0;
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

// And in dispose:
@override
void dispose() {
//   _latitudeController.dispose();
//   _longitudeController.dispose();
//   _wasteTypeControllers.values.forEach((controller) => controller.dispose());
//   _otherWasteSourceController.dispose();
//   _otherInstitutionController.dispose();
//   super.dispose();
// }
  // Dispose all controllers
  _streetController.dispose();
  _wardPopulationController.dispose();
  _streetPopulationController.dispose();
  _otherObstacleController.dispose();
  _otherWasteSourceController.dispose();
  _otherInstitutionController.dispose();
  _disposalStreetController.dispose();
  _latitudeController.dispose();
  _longitudeController.dispose();
  _imageUrlController.dispose();

  
  // Dispose waste type controllers
  _wasteTypeControllers.values.forEach((controller) => controller.dispose());
  super.dispose();
}
}
// Helper class for type safety and organization
class ObstacleOption {
  final String name;
  final IconData icon;
  final Color color;

  ObstacleOption(this.name, this.icon, this.color);
}
