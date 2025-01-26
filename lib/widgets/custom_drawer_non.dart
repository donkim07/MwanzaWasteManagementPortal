import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/auth_users/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CustomDrawer extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final User? user;  // Add this to pass the user

  const CustomDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.user,  // Make it optional since normal users won't have it
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

// class _CustomDrawerState extends State<CustomDrawer> {
//   bool get isDriver => widget.user != null;  // Simple check if user exists
class _CustomDrawerState extends State<CustomDrawer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userRole; // Add state variable for role

  @override
  void initState() {
    super.initState();
    _loadUserRole(); // Load role when drawer is created
  }

  // Method to load user role
  Future<void> _loadUserRole() async {
    if (widget.user != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(widget.user!.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc.data()?['role'];
          });
        }
      } catch (e) {
        print('Error loading user role: $e');
      }
    }
  }

  // Update the getters to use _userRole
  bool get isDriver => widget.user != null && _userRole == 'driver';
  bool get isAgent => widget.user != null && _userRole == 'agent';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C2F), // Dark forest green
              Color(0xFF115937), // Primary green
              Color(0xFF0D7A4F), // Rich emerald
            ],
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hi!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isDriver ? 'Driver' : 'User',  // Show role based on user status
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white.withOpacity(0.05),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
      _buildDrawerItem(
        icon: Icons.map,
        text: 'Map Page',
        index: 0,
      ),
      _buildDrawerItem(
        icon: Icons.location_on,
        text: 'Waste Points',
        index: 1,
      ),
      _buildDrawerItem(
        icon: Icons.business,
        text: 'Waste Dealers',
        index: 2,
      ),
      _buildDrawerItem(
        icon: Icons.recycling,
        text: 'Waste Recyclers',
        index: 4,
      ),
      _buildDrawerItem(
        icon: Icons.people,
        text: 'Stakeholders',
        index: 5,
      ),
      _buildDrawerItem(
        icon: Icons.people,
        text: 'Reports',
        index: 6,
      ),
      // Show driver dashboard only for drivers
      if (isDriver)
        _buildDrawerItem(
          icon: Icons.local_shipping,
          text: 'Driver Dashboard',
          index: 7,
        ),
      // Show agent dashboard only for agents
      if (isAgent)
        _buildDrawerItem(
          icon: Icons.person_outline,  // Changed icon to distinguish from driver
          text: 'Agent Dashboard',
          index: 8,
        ),
    ],
                ),
              ),
            ),
            // Only show logout if user is a driver
            // if (isDriver)
            //   Container(
            //     padding: const EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withOpacity(0.05),
            //       border: Border(
            //         top: BorderSide(
            //           color: Colors.white.withOpacity(0.2),
            //           width: 1,
            //         ),
            //       ),
            //     ),
            //     child: TextButton.icon(
            //       onPressed: () async {
            //         await FirebaseAuth.instance.signOut();
            //         Navigator.pushReplacement(context, 
            //           MaterialPageRoute(builder: (context) => const LoginPage()));
            //       },
            //       icon: const Icon(Icons.logout, color: Colors.white70),
            //       label: const Text(
            //         'Logout',
            //         style: TextStyle(
            //           color: Colors.white70,
            //           fontSize: 16,
            //         ),
            //       ),
            //       style: TextButton.styleFrom(
            //         padding: const EdgeInsets.all(16),
            //         backgroundColor: Colors.red.withOpacity(0.8),
            //         shape: RoundedRectangleBorder(
            //           borderRadius: BorderRadius.circular(12),
            //         ),
            //       ),
            //     ),
            //   ),
             // Update logout to show for both drivers and agents
    if (isDriver || isAgent)  // Changed condition to include agents
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: TextButton.icon(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(context, 
              MaterialPageRoute(builder: (context) => const LoginPage()));
          },
          icon: const Icon(Icons.logout, color: Colors.white70),
          label: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.red.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => widget.onItemTapped(index),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

