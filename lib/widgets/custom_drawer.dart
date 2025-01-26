// lib/widgets/custom_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth_users/login_page.dart';

// class CustomDrawer extends StatefulWidget {
//   final String firstName;
//   final bool isAdmin;
//   final int selectedIndex;
//   final Function(int) onItemTapped;
//   final User? user;

//   const CustomDrawer({
//     Key? key,
//     required this.firstName,
//     required this.isAdmin,
//     required this.selectedIndex,
//     required this.onItemTapped,
//     required this.user,
//   }) : super(key: key);

//   @override
//   State<CustomDrawer> createState() => _CustomDrawerState();
// }

// class _CustomDrawerState extends State<CustomDrawer> {
//   @override
//   Widget build(BuildContext context) {
//     // const Color primaryGreen = Color(0xFF115937);
    
//     return Drawer(
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF1E3C2F), // Dark forest green
//               Color(0xFF115937), // Primary green
//               Color(0xFF0D7A4F), // Rich emerald
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.1),
//                 border: Border(
//                   bottom: BorderSide(
//                     color: Colors.white.withOpacity(0.2),
//                     width: 1,
//                   ),
//                 ),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.eco,
//                     size: 48,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Hi, ${widget.firstName}!',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     widget.isAdmin ? 'Admin' : 'Employee',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.7),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 color: Colors.white.withOpacity(0.05),
//                 child: ListView(
//                   padding: EdgeInsets.zero,
//                   children: [
//                     _buildDrawerItem(
//                       icon: Icons.map,
//                       text: 'Map Page',
//                       index: 0,
//                     ),
//                     _buildDrawerItem(
//                       icon: Icons.location_on,
//                       text: 'Waste Points',
//                       index: 1,
//                     ),
//                     _buildDrawerItem(
//                       icon: Icons.business,
//                       text: 'Waste Dealers',
//                       index: 2,
//                     ),
                   
//                     _buildDrawerItem(
//                       icon: Icons.recycling,
//                       text: 'Waste Recyclers',
//                       index: 4,
//                     ),
//                     _buildDrawerItem(
//                       icon: Icons.people,
//                       text: 'Stakeholders',
//                       index: 5,
//                     ),
//                     if (widget.isAdmin)
//                       _buildDrawerItem(
//                         icon: Icons.manage_accounts,
//                         text: 'Users',
//                         index: 6,
//                       ),
//                     _buildDrawerItem(
//                       icon: Icons.people,
//                       text: 'Waste Reporting',
//                       index: 7,
//                     ),
//                     if (widget.isAdmin)
//                     _buildDrawerItem(
//                       icon: Icons.people,
//                       text: 'Waste Reports',
//                       index: 8,
//                     ),
//                     // _buildDrawerItem(
//                     //   icon: Icons.people,
//                     //   text: 'import',
//                     //   index: 10,
//                     // ),
                   
                    
//                   ],
//                 ),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.05),
//                 border: Border(
//                   top: BorderSide(
//                     color: Colors.white.withOpacity(0.2),
//                     width: 1,
//                   ),
//                 ),
//               ),
//               child: TextButton.icon(
//                 onPressed: () async {
//                   await FirebaseAuth.instance.signOut();
//                   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
//                 },




//                 icon: const Icon(Icons.logout, color: Colors.white70),
//                 label: const Text(
//                   'Logout',
//                   style: TextStyle(
//                     color: Colors.white70,
//                     fontSize: 16,
//                   ),
//                 ),
//                 style: TextButton.styleFrom(
//                   padding: const EdgeInsets.all(16),
//                   backgroundColor: Colors.red.withOpacity(0.8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
class CustomDrawer extends StatefulWidget {
  final String firstName;
  final bool isAdmin;
  final bool isWardOfficer;  // Add this
  final bool isAgent;        // Add this
  final int selectedIndex;
  final Function(int) onItemTapped;
  final User? user;

  const CustomDrawer({
    Key? key,
    required this.firstName,
    required this.isAdmin,
    required this.isWardOfficer,  // Add this
    required this.isAgent,        // Add this
    required this.selectedIndex,
    required this.onItemTapped,
    required this.user,
  }) : super(key: key);

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C2F),
              Color(0xFF115937),
              Color(0xFF0D7A4F),
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
                  Text(
                    'Hi, ${widget.firstName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isAdmin ? 'Admin' : 
                    widget.isWardOfficer ? 'Ward Health Officer' :
                    widget.isAgent ? 'Agent' : 'Employee',
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
                      text: 'Waste Reporting',
                      index: 7,
                    ),
                   if (!widget.isAgent && !widget.isWardOfficer)
                    _buildDrawerItem(
                      icon: Icons.report,
                      text: 'Waste Reports',
                      index: 8,
                    ),
                    // Add Ward Health Officer Dashboard
                    if (widget.isWardOfficer)
                    _buildDrawerItem(
                      icon: Icons.health_and_safety,
                      text: 'Ward Officer Dashboard',
                      index: 9,
                    ),
                    // Add Agent Dashboard
                    if (widget.isAgent)
                    _buildDrawerItem(
                      icon: Icons.person_outline,
                      text: 'Agent Dashboard',
                      index: 10,
                    ),
                    if (widget.isAdmin)
                      _buildDrawerItem(
                        icon: Icons.manage_accounts,
                        text: 'Users',
                        index: 6,
                      ),
                  ],
                ),
              ),
            ),
            // Show logout for all authenticated users
            if (widget.user != null)
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