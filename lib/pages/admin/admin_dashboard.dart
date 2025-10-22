import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_app/pages/admin/add_another_admin.dart';
import 'package:nutricare_app/pages/admin/add_recipe.dart';
import 'package:nutricare_app/pages/admin/admin_feedb.dart';
import 'package:nutricare_app/pages/admin/analysis.dart';
import 'package:nutricare_app/pages/admin/help.dart';
import 'package:nutricare_app/pages/admin/trail.dart';
import 'package:nutricare_app/pages/admin/view_persons2.dart';
import 'package:nutricare_app/pages/admin/user_updates_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  static final List<Widget> _pages = [
    DashboardContent(),
    AdminActivityPage(),
    AdminNotificationsPage(),
    AdminHelpPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login-admin');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'NutriCare Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF0A3D00),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.black,
              selectedLabelTextStyle: const TextStyle(color: Colors.white),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white),
              selectedIconTheme: const IconThemeData(color: Color(0xFF0A3D00)),
              unselectedIconTheme: const IconThemeData(color: Colors.white),
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('User Activity'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.notifications_active),
                  label: Text('Updates'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.help),
                  label: Text('Help'),
                ),
              ],
            ),
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: Colors.grey,
            ),
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  Future<void> _notifyUsers(BuildContext context, String changeType, String description) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('admin_changes').add({
      'changeType': changeType,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'readByUsers': [],
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 32),
          Text(
            'Management Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardCard(
                context: context,
                title: 'View Records',
                description: 'Access and manage all user records',
                icon: Icons.person_search,
                iconColor: Colors.blue,
                onTap: () async {
                  await _notifyUsers(
                    context,
                    'User Records Update',
                    'Admin has updated user records. Check it out!'
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewPersons2()),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                title: 'Analytics',
                description: 'Monitor user nutritional growth',
                icon: Icons.insights,
                iconColor: Colors.green,
                onTap: () async {
                  await _notifyUsers(
                    context,
                    'Tracking BMI',
                    'Using Charts to show the Growth of Nutritional records'
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MonthlyBmiProgressPage()),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                title: 'Manage Recipes',
                description: 'Add and update nutritional recipes',
                icon: Icons.book,
                iconColor: Colors.orange,
                onTap: () async {
                  await _notifyUsers(
                    context,
                    'New Recipes',
                    'Admin has added new recipes. Check it out!'
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRecipePage()),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                title: 'View Feedbacks',
                description: 'Review user responses',
                icon: Icons.feedback,
                iconColor: Colors.red,
                onTap: () async {
                  await _notifyUsers(
                    context,
                    'Feedback Review',
                    'Admin has reviewed user feedback. Check it out!'
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminFeedbackPage()),
                  );
                },
              ),
              _buildDashboardCard(
                context: context,
                title: 'Add Admin',
                description: 'Add another admin account',
                icon: Icons.person_add,
                iconColor: Colors.teal,
                onTap: () async {
                  await _notifyUsers(
                    context,
                    'Admin Access',
                    'Admin has updated admin access. Check it out!'
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddAnotherAdmin()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.admin_panel_settings,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NutriCare Administration Panel',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have full access to all administrative functions',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 40,
                color: iconColor,
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: TextStyle(
                      fontSize: 19,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(description,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0A3D00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Access',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
