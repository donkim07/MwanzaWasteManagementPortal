import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:waste_manager/screens/auth_users/admin/mwanza/waste_reportMap.dart';
import '../../../../widgets/custom_drawer.dart';
import '../../login_page.dart';
import 'WHO_waste_reportMap.dart';
import 'admin_management.dart';
import 'agent.dart';
import 'map_page.dart';
import 'stakeholders_page.dart';
import 'waste_aggregators_page.dart';
import 'waste_dealers_page.dart';
import 'waste_points_page.dart';
import 'waste_recyclersCollection_page.dart';
import 'waste_recyclers_page.dart';


class WasteReportPage extends StatefulWidget {
  final User? user;
  const WasteReportPage({Key? key, required this.user}) : super(key: key);

  @override
  _WasteReportPageState createState() => _WasteReportPageState();
}

class _WasteReportPageState extends State<WasteReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();
    int _selectedIndex = 7; // For waste dealers tab
  bool _isAdmin = false;
  String _firstName = '';
  bool _isAgent = false;
  bool _isWardOfficer= false;
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  
  // State variables
  String? _selectedDistrict;
  String? _selectedWard;
  XFile? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _status = 'pending';

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
  static const gradientColors = [Color(0xFF1E3C2F), Color(0xFF115937)];

  // District and Ward data
  final Map<String, List<String>> districtsWards = {
    'Mwanza City/Nyamagana': [
      'Buhongwa', 'Butimba', 'Igogo', 'Igoma', 'Isamilo', 
      'Kishili', 'Luchelele', 'Lwanhima', 'Mabatini', 'Mahina', 
      'Mbugani', 'Mhandu', 'Mikuyuni', 'Mirongo', 'Mkolani', 
      'Nyamagana', 'Nyegezi', 'Pamba'
    ],
    'Ilemela': [
      'Buswelu', 'Bugogwa', 'Ilemela', 'Nyamanoro', 'Kirumba',
      'Kitangiri', 'Pasiansi', 'Kiseke', 'Sangabuye', 'Kawekamo',
      'Mecco', 'Buzuruga'
    ],
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _imageFile = image);
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
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
      ),
    );
  }


  Future<File> _compressImage(File file) async {
  // Get original file size
  final originalSize = await file.length();
  
  // If file is smaller than 1.5MB, return original
  if (originalSize < 1.5 * 1024 * 1024) {
    return file;
  }

  // Create temp file for compressed image
  final dir = await Directory.systemTemp.createTemp();
  final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

  // Calculate quality based on original size
  int quality = 85;
  if (originalSize > 5 * 1024 * 1024) {
    quality = 60;
  } else if (originalSize > 2.5 * 1024 * 1024) {
    quality = 70;
  }

  // Compress file
  final result = await FlutterImageCompress.compressAndGetFile(
    file.path,
    targetPath,
    quality: quality,
    format: CompressFormat.jpeg,
  );

  return File(result?.path ?? file.path);
}







Future<String> _uploadImage() async {
  if (_imageFile == null) throw Exception('No image selected');

  // Show upload progress dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UploadProgressDialog(),
  );

  try {
    // Compress image if needed
    final File compressedFile = await _compressImage(File(_imageFile!.path));

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('waste_reports')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Upload with progress tracking
    final uploadTask = storageRef.putFile(
      compressedFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Listen to upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      double progress = snapshot.bytesTransferred / snapshot.totalBytes;
      if (mounted) {
        // UploadProgressDialog.of(context)?.updateProgress(progress);
      }
    });

    // Wait for upload to complete
    await uploadTask;
    
    // Get download URL
    final url = await storageRef.getDownloadURL();
    
    // Close progress dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    return url;
  } catch (e) {
    // Close progress dialog on error
    if (mounted) {
      Navigator.of(context).pop();
    }
    throw e;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
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
                        Icons.report_problem_outlined,
                        size: screenWidth * 0.15,
                        color: Colors.white.withOpacity(0.8),
                      )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOut)
                      .fadeIn(),
                      SizedBox(height: smallPadding),
                      Text(
                        'Ripoti Eneo la Taka',
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
                        'Tusaidie kuweka mji wetu safi',
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
          ),
        ],
        body: Container(
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
              child: Column(
                children: [
                  _buildReporterCard(),
                  SizedBox(height: defaultPadding),
                  _buildLocationCard(),
                  SizedBox(height: defaultPadding),
                  _buildImageCard(),
                  SizedBox(height: defaultPadding * 2),
                  _buildSubmitButton(),
                ].animate(interval: const Duration(milliseconds: 50))
                 .fadeIn(duration: const Duration(milliseconds: 300))
                 .slideY(begin: 0.2, end: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReporterCard() {
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
              'Taarifa za Mripoti',
              Icons.person_outline,
            ),
            SizedBox(height: defaultPadding),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Jina Lako',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => 
                value?.isEmpty ?? true ? 'Tafadhali ingiza jina lako' : null,
            ),


            SizedBox(height: defaultPadding),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Namba Yako',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => 
                value?.isEmpty ?? true ? 'Tafadhali ingiza namba za sim' : null,
            ),


            SizedBox(height: defaultPadding),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Barua Pepe',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => 
                value?.isEmpty ?? true ? 'Tafadhali ingiza barua Pepe yako' : null,
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
              'Taarifa za Mahali',
              Icons.location_on_outlined,
            ),
            SizedBox(height: defaultPadding),
            
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: 'Wilaya',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: districtsWards.keys.map((String district) {
                return DropdownMenuItem<String>(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDistrict = newValue;
                  _selectedWard = null;
                });
              },
              validator: (value) => 
                value == null ? 'Tafadhali chagua wilaya' : null,
            ),
            
            SizedBox(height: defaultPadding),
            
            if (_selectedDistrict != null)
              DropdownButtonFormField<String>(
                value: _selectedWard,
                decoration: InputDecoration(
                  labelText: 'Kata',
                  prefixIcon: const Icon(Icons.map),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: districtsWards[_selectedDistrict]?.map((String ward) {
                  return DropdownMenuItem<String>(
                    value: ward,
                    child: Text(ward),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedWard = newValue);
                },
                validator: (value) => 
                  value == null ? 'Tafadhali chagua kata' : null,
              ),
            
            SizedBox(height: defaultPadding),
            
            TextFormField(
              controller: _streetController,
              decoration: InputDecoration(
                labelText: 'Jina la Mtaa',
                prefixIcon: const Icon(Icons.add_road),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => 
                value?.isEmpty ?? true ? 'Tafadhali ingiza jina la mtaa' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
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
              'Picha ya Eneo',
              Icons.camera_alt_outlined,
            ),
            SizedBox(height: defaultPadding),
            
            if (_imageFile != null)
              Container(
                width: double.infinity,
                height: screenHeight * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(_imageFile!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _imageFile = null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              InkWell(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: screenWidth * 0.1,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: smallPadding),
                      Text(
                        'Piga picha ya eneo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: bodyTextSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
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
                Icon(Icons.send_rounded, size: screenWidth * 0.05),
                SizedBox(width: smallPadding),
                Text(
                  'Tuma Ripoti',
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

  // In WasteReportPage
Future<void> _submitReport() async {
  if (!_formKey.currentState!.validate()) return;
  
  if (_imageFile == null) {
    _showErrorSnackBar('Samahani, piga picha ya eneo');
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    final String imageUrl = await _uploadImage();

    // Add report to Firestore and get the DocumentReference
    final DocumentReference docRef = await _firestore.collection('wasteReports').add({
      'reporterName': _nameController.text,
      'reporterPhone': _phoneController.text,
      'reporterEmail': _emailController.text,
      'district': _selectedDistrict,
      'ward': _selectedWard,
      'street': _streetController.text,
      'type': 'waste report',
      'location': {
        'latitude': _latitude,
        'longitude': _longitude,
      },
      'imageUrl': imageUrl,
      'status': 'pending',
      'reportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notifications with ward and district information
    await _sendNotifications(
      docRef.id, 
      imageUrl,
      _selectedWard!,
      _selectedDistrict!
    );

    _showSuccessDialog();
  } catch (e) {
    _showErrorDialog('Failed to submit report: $e');
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}


Future<void> _sendNotifications(String reportId, String imageUrl, String ward, String district) async {
  try {
    // Query for admins and employees
    final usersQuery = await _firestore
        .collection('users')
        .where('role', whereIn: ['admin', 'employee', 'ward health officer'])
        .get();

    for (var userDoc in usersQuery.docs) {
      final userData = userDoc.data();
      final userRole = userData['role'] as String;
      final fcmToken = userData['fcmToken'];
      
      // Skip if no FCM token
      if (fcmToken == null) continue;

      // For ward health officers, only send if report is in their ward
      if (userRole == 'ward health officer') {
        final userWard = userData['ward'] as String?;
        final userDistrict = userData['district'] as String?;
        
        // Skip if ward or district doesn't match
        if (userWard != ward || userDistrict != district) continue;
      }
      
      // For employees, only send if district matches
      if (userRole == 'employee') {
        final userDistrict = userData['district'] as String?;
        if (userDistrict != district) continue;
      }

      // Add notification to Firestore
      await _firestore.collection('notifications').add({
        'userId': userDoc.id,
        'title': 'New Waste Report',
        'body': 'A new dumping area report has been submitted',
        'imageUrl': imageUrl,
        'reportId': reportId,
        'type': 'waste_report',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'screen': 'WasteReportsMap',
          'reportId': reportId,
        }
      });

      // Send FCM notification
      await _firestore.collection('fcm_requests').add({
        'token': fcmToken,
        'notification': {
          'title': 'New Waste Report',
          'body': 'A new dumping area report has been submitted',
          'image': imageUrl,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'screen': 'WasteReportsMap',
          'reportId': reportId,
        }
      });
    }
  } catch (e) {
    print('Error sending notifications: $e');
  }
}



  // Future<String> _uploadImage() async {
  //   if (_imageFile == null) throw Exception('No image selected');

  //   final storageRef = FirebaseStorage.instance
  //       .ref()
  //       .child('waste_reports')
  //       .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

  //   final uploadTask = await storageRef.putFile(
  //     File(_imageFile!.path),
  //     SettableMetadata(contentType: 'image/jpeg'),
  //   );

  //   return await uploadTask.ref.getDownloadURL();
  // }






 // Update the success dialog to be responsive
Future<void> _showSuccessDialog() {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final screenSize = MediaQuery.of(context).size;
      final isSmallScreen = screenSize.width < 600;
      final dialogWidth = isSmallScreen ? screenSize.width * 0.9 : screenSize.width * 0.6;
      final padding = screenSize.width * 0.04;
      final iconSize = isSmallScreen ? 24.0 : 32.0;
      
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          width: dialogWidth,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(padding * 0.5),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: padding * 0.5),
                  Expanded(
                    child: Text(
                        'Ripoti Imetumwa!',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: padding),
              Text(
                  'Asante kwa kusaidia kuweka mji wetu safi.',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(height: padding * 0.5),
                Text(
                  'Ripoti yako imetumwa kwa mafanikio na itafanyiwa mapitio na timu yetu.',
                  style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: padding),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to previous screen
                  },
                  child: Text(
                    'Sawa',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
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
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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




  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    super.dispose();
  }
}






// Add this new widget class for the upload progress dialog
class UploadProgressDialog extends StatefulWidget {
  const UploadProgressDialog({Key? key}) : super(key: key);

  static _UploadProgressDialogState? of(BuildContext context) {
    return context.findAncestorStateOfType<_UploadProgressDialogState>();
  }

  @override
  _UploadProgressDialogState createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  double _progress = 0;

  void updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final padding = screenSize.width * 0.04;
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: padding),
            Text(
              'Inapakia Picha...',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding / 2),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: padding / 2),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }









}
