// signup_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waste_manager/screens/auth_users/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../city_selection_page.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;


Future _signUp() async {
  // Check if required fields are filled
  if (_firstNameController.text.trim().isEmpty) {
    _showSnackBar('Please enter your first name.');
    return;
  }

  if (_emailController.text.trim().isEmpty) {
    _showSnackBar('Please enter your email address.');
    return;
  }

  if (_passwordController.text.trim().isEmpty) {
    _showSnackBar('Please enter your password.');
    return;
  }

  // Process the inputs: capitalize names and lowercase email
  String firstName = _firstNameController.text.trim();
  String lastName = _lastNameController.text.trim();
  String email = _emailController.text.trim().toLowerCase(); // Convert email to lowercase

  // Capitalize the first letter of first and last names
  if (firstName.isNotEmpty) {
    firstName = firstName[0].toUpperCase() + firstName.substring(1);
  }
  if (lastName.isNotEmpty) {
    lastName = lastName[0].toUpperCase() + lastName.substring(1);
  }

  setState(() => _isLoading = true);
  try {
    // Attempt to create the user in Firebase Authentication
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: _passwordController.text.trim(),
    );

    // Get the user ID
    String uid = userCredential.user!.uid;

    // Save additional user information to Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'createdAt': Timestamp.now(),
    });

    // Navigate to the next page
    if (mounted) {
      final user = _auth.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CitySelectionPageUsers(user: user)),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;

    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'This email is already registered. Please use a different email.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address entered is not valid. Please check and try again.';
        break;
      case 'weak-password':
        errorMessage = 'Your password is too weak. Please use at least 6 characters.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'This sign-up method is not enabled. Please contact support.';
        break;
      case 'network-request-failed':
        errorMessage = 'It looks like you’re offline. Please check your internet connection.';
        break;
      default:
        errorMessage = 'An unexpected error occurred. Please try again.';
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF90EE90).withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Icon(
                    Icons.eco,
                    size: 80,
                    color: const Color(0xFF90EE90),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // First Name Field
                  _buildTextField(
                    controller: _firstNameController,
                    labelText: 'First Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),

                  // Last Name Field
                  _buildTextField(
                    controller: _lastNameController,
                    labelText: 'Last Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),


                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Signup Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF90EE90),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                //Login link
                  Row(  
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF90EE90),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF90EE90)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
