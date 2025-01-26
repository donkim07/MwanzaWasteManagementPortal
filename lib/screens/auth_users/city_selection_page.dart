import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import '/screens/mwanza/map/mwanza_page.dart';
// import '/screens/auth_users/login_page.dart';
import 'admin/ilemela/ilemela_map_page.dart';
import 'admin/mwanza/map_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CitySelectionPageUsers extends StatefulWidget {
  final User? user;
  CitySelectionPageUsers({Key? key, required this.user}) : super(key: key);

  @override
  _CitySelectionPageUsersState createState() => _CitySelectionPageUsersState();
}

class _CitySelectionPageUsersState extends State<CitySelectionPageUsers> {
  String? _firstName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (widget.user != null) {
      // Fetch the user's first name from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _firstName = userDoc['firstName'];
        });
      }
    }
  }

  void _navigateToMap(BuildContext context, String city) {
    if (city == 'Mwanza') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapPage(user: widget.user!),
        ),
      );
    } else {
      // Handle Ilemela navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ilemelaMapPage(user: widget.user!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double horizontalPadding = screenSize.width * 0.08;
    final double verticalPadding = screenSize.height * 0.04;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: horizontalPadding / 2),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              // child: IconButton(
              //   icon: const Icon(Icons.login, color: Colors.white),
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => LoginPage()),
              //     );
              //   },
              // ),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mwanza_bg.png', // Add appropriate image
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    const Color(0xFF115937).withOpacity(0.5),
                    const Color(0xFF115937).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            SizedBox(height: screenSize.height * 0.1),
                            if (_firstName != null)
                            Text(
                              'Welcome $_firstName! to',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.06,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: -0.2, end: 0),
                            
                            SizedBox(height: screenSize.height * 0.01),
                            
                            Text(
                              'Waste Management Portal',
                              textAlign: TextAlign.center, // Center the text within its container
                              style: TextStyle(
                                fontSize: screenSize.width * 0.08,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: -0.2, end: 0),
                            
                            SizedBox(height: screenSize.height * 0.05),
                            
                            Text(
                              'Select your city',
                              style: TextStyle(
                                fontSize: screenSize.width * 0.045,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ).animate()
                              .fadeIn(duration: 600.ms, delay: 400.ms),
                            
                            SizedBox(height: screenSize.height * 0.04),
                            
                            _buildCityButton(context, 'Ilemela', screenSize)
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 800.ms),
                            
                            SizedBox(height: screenSize.height * 0.04),
                            
                            _buildCityButton(context, 'Mwanza', screenSize)
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 600.ms),
                              
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityButton(BuildContext context, String city, Size screenSize) {
    return Container(
      width: double.infinity,
      height: screenSize.height * 0.075,
      margin: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.02,
      ),
      child: Material(
        color: const Color.fromARGB(51, 104, 104, 104),
        child: InkWell(
          onTap: () => _navigateToMap(context, city),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF115937).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                city,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenSize.width * 0.045,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
