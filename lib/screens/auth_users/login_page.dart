
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:waste_manager/screens/auth_users/admin/signup_page.dart';
import '../mwanza/driver.dart';
import 'admin/ilemela/ilemela_map_page.dart';
import 'admin/mwanza/map_page.dart';
import 'city_selection_page.dart';
// import 'admin/mwanza/admin_management.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }
Future<void> _checkNotificationPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> _updateFCMToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('FCM Token updated: $token');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<void> _logLoginEvent() async {
    await _analytics.logEvent(
      name: 'login',
      parameters: {
        'method': 'email_password',
      },
    );
  }






// Update the _login method to include district-based routing:
// Future _login() async {
//   if (_emailController.text.trim().isEmpty) {
//     _showSnackBar('Please enter your email address.');
//     return;
//   }

//   if (_passwordController.text.trim().isEmpty) {
//     _showSnackBar('Please enter your password.');
//     return;
//   }

//   setState(() => _isLoading = true);
//   try {
//     // Sign in user
//     UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );

//     // Get user
//     final user = userCredential.user;
//     if (user != null && mounted) {
//       // Log login event
//       await _logLoginEvent();

//       // Update FCM token
//       await _updateFCMToken(user.uid);

//       // Fetch user data
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();

//       if (userDoc.exists) {
//         final role = userDoc.data()?['role'];
//         final district = userDoc.data()?['district'];

//         // Subscribe to topics based on role
//         if (role == 'admin') {
//           await _messaging.subscribeToTopic('admin_notifications');
//         } else if (role == 'driver') {
//           await _messaging.subscribeToTopic('driver_notifications');
//         }

//         // Navigate based on role and district
//         if (!mounted) return;
        
//         switch (role) {
//           case 'admin':
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => CitySelectionPageUsers(user: user),
//               ),
//             );
//             break;
//           case 'employee':
//             // Check district for employees
//             if (district == 'Mwanza City') {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => MapPage(user: user),
//                 ),
//               );
//             } else if (district == 'Ilemela Municipal') {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ilemelaMapPage(user: user),
//                 ),
//               );
//             } else {
//               _showSnackBar('Invalid district assignment. Please contact admin.');
//             }
//             break;
//           case 'driver':
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DriverDashboardPage(user: user),
//               ),
//             );
//             break;
//           default:
//             _showSnackBar('Unrecognized role. Please contact support.');
//             break;
//         } 
//       } else {
//         _showSnackBar('User data not found. Please try again.');
//       }
//     }
//   } on FirebaseAuthException catch (e) {
//     // Print the error code to the console for debugging
//     print('FirebaseAuthException code: ${e.code}');

//     String errorMessage;

//     switch (e.code) {

//       case 'invalid-credential':
//         errorMessage = 'Incorrect credentials. Please try again or Sign Up.';
//         break;
//       case 'invalid-email':
//         errorMessage = 'The email address is invalid. Please check and enter a valid email.';
//         break;
//       case 'user-disabled':
//         errorMessage = 'This account has been disabled. Please contact support.';
//         break;
//       case 'network-request-failed':
//         errorMessage = 'It looks like you’re offline. Please check your internet connection.';
//         break;
//       default:
//         errorMessage = 'An error occurred. Please try again.';
//     }

//     _showSnackBar(errorMessage);
//   } catch (e) {
//     _showSnackBar('Something went wrong. Please try again later.');
//   } finally {
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
// }



Future _login() async {
  if (_emailController.text.trim().isEmpty) {
    _showSnackBar('Please enter your email address.');
    return;
  }

  if (_passwordController.text.trim().isEmpty) {
    _showSnackBar('Please enter your password.');
    return;
  }

  setState(() => _isLoading = true);
  try {
    // Sign in user
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Get user
    final user = userCredential.user;
    if (user != null && mounted) {
      // Log login event
      await _logLoginEvent();

      // Update FCM token
      await _updateFCMToken(user.uid);

      // Fetch user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        final district = userDoc.data()?['district'];

        // Subscribe to topics based on role
        if (role == 'admin') {
          await _messaging.subscribeToTopic('admin_notifications');
        } else if (role == 'driver') {
          await _messaging.subscribeToTopic('driver_notifications');
        }

        // Navigate based on role and district
        if (!mounted) return;
        
        switch (role?.toLowerCase()) {
          case 'admin':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CitySelectionPageUsers(user: user),
              ),
            );
            break;

          case 'employee':
          case 'agent':
          case 'ward health officer':
            // Check district and route accordingly
            if (district == 'Mwanza City') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MapPage(user: user),
                ),
              );
            } else if (district == 'Ilemela Municipal') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ilemelaMapPage(user: user),
                ),
              );
            } else {
              _showSnackBar('Invalid district assignment. Please contact admin.');
            }
            break;

          case 'driver':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverDashboardPage(user: user),
              ),
            );
            break;

          default:
            _showSnackBar('Unrecognized role. Please contact support.');
            break;
        } 
      } else {
        _showSnackBar('User data not found. Please try again.');
      }
    }
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException code: ${e.code}');

    String errorMessage;
    switch (e.code) {
      case 'invalid-credential':
        errorMessage = 'Incorrect credentials. Please try again or Sign Up.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is invalid. Please check and enter a valid email.';
        break;
      case 'user-disabled':
        errorMessage = 'This account has been disabled. Please contact support.';
        break;
      case 'network-request-failed':
        errorMessage = 'It looks like you\'re offline. Please check your internet connection.';
        break;
      default:
        errorMessage = 'An error occurred. Please try again.';
    }

    _showSnackBar(errorMessage);
  } catch (e) {
    _showSnackBar('Something went wrong. Please try again later.');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}










// Helper method to show SnackBar
void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}


 @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryGreen = Color(0xFF115937);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: size.height,  // Make the container height equal to the screen height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C2F), // Dark forest green
              Color(0xFF115937), // Your primary green
              Color(0xFF0D7A4F), // Rich emerald
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08,
                vertical: size.height * 0.02,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.08),
                  
                  // Logo
                  Icon(
                    Icons.eco,
                    size: size.width * 0.2,
                    color: Colors.white,
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .scale(delay: 200.ms),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  // Welcome Text
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                  
                  SizedBox(height: size.height * 0.06),
                  
                  // Login Form
                  Container(
                    padding: EdgeInsets.all(size.width * 0.06),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                        ).animate()
                          .fadeIn(duration: 600.ms, delay: 300.ms)
                          .slideX(begin: -0.2, end: 0),
                        
                        SizedBox(height: size.height * 0.02),
                        
                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          isPassword: true,
                        ).animate()
                          .fadeIn(duration: 600.ms, delay: 400.ms)
                          .slideX(begin: -0.2, end: 0),
                        
                        SizedBox(height: size.height * 0.03),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: size.height * 0.065,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: size.width * 0.05,
                                    height: size.width * 0.05,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        )
                        
                        .animate()
                          .fadeIn(duration: 600.ms, delay: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.9),
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}