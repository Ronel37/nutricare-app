import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/user/collection.dart';
import 'package:nutricare_app/pages/user/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database.dart';
import 'homepage.dart';
import 'help_page.dart';
import 'settings_page.dart';
import 'dart:async';
import 'dart:ui';
import 'package:nutricare_app/utils/responsive_util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _hideSystemUiTimer;
  bool _isAppBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  List<Widget> get _pages => [
        HomePage(),
        CollectionPage(),
        ProfilePage(onLogout: _logout),
      ];

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _hideSystemUiTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _scheduleHideSystemUI() {
    _hideSystemUiTimer?.cancel();
    _hideSystemUiTimer = Timer(const Duration(seconds: 1), () {
      _hideSystemUI();
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 5 && _isAppBarVisible) {
      setState(() {
        _isAppBarVisible = false;
      });
    } else if (_scrollController.offset <= 5 && !_isAppBarVisible) {
      setState(() {
        _isAppBarVisible = true;
      });
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _scheduleHideSystemUI();
  }

  Future<void> _logout() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await AuthServices()
            .logUserActivity(user.email ?? 'Unknown', 'Logged Out');
      }
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double appBarFontSize = ResponsiveUtil.getResponsiveFontSize(context, 20);

    return GestureDetector(
      onTap: _scheduleHideSystemUI,
      onPanDown: (_) => _scheduleHideSystemUI(),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: AnimatedOpacity(
              opacity: _isAppBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logo.jpg',
                      width: ResponsiveUtil.isTablet(context) ? 42 : 36,
                      height: ResponsiveUtil.isTablet(context) ? 42 : 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'NutriCare',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: appBarFontSize,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              )),
        ),
        body: _pages[_currentIndex],
        bottomNavigationBar: buildBottomNavigationBar(),
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    double paddingHorizontal = ResponsiveUtil.isTablet(context) ? 80 : 50;
    double navBarHeight = ResponsiveUtil.isTablet(context) ? 70 : 60;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: navBarHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: Color(0xFF0A3D00),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.menu_book_rounded, 'Collection'),
                _buildNavItem(2, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    double iconSize = ResponsiveUtil.getResponsiveIconSize(context, 22);
    double fontSize = ResponsiveUtil.getResponsiveFontSize(context, 10);

    return InkWell(
      onTap: () => _onTap(index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: iconSize, color: isSelected ? Colors.green : Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.green : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Function() onLogout;

  const ProfilePage({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double verticalPadding = ResponsiveUtil.getVerticalPadding(context);
    double horizontalPadding = ResponsiveUtil.getHorizontalPadding(context);
    
    return Container(
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
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(context),
            SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: verticalPadding, 
                  horizontal: horizontalPadding
                ),
                children: [
                  _buildProfileMenuItem(
                    context: context,
                    icon: Icons.psychology_outlined,
                    title: 'AI Recommendations',
                    onTap: () {
                      Navigator.pushNamed(context, '/ai-recommendations');
                    },
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.015),
                  _buildProfileMenuItem(
                    context: context,
                    icon: Icons.feedback_outlined,
                    title: 'Feedback',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FeedbackPage()),
                      );
                    },
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.015),
                  _buildProfileMenuItem(
                    context: context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpPage()),
                      );
                    },
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.015),
                  _buildProfileMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                  ),
                  Divider(
                    color: Colors.white24,
                    thickness: 1,
                    height: ResponsiveUtil.screenHeight(context) * 0.04,
                  ),
                  _buildProfileMenuItem(
                    context: context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    onTap: onLogout,
                    iconColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    double containerSize = ResponsiveUtil.isTablet(context) ? 85 : 70;
    double iconSize = ResponsiveUtil.isTablet(context) ? 50 : 40;
    double titleFontSize = ResponsiveUtil.getResponsiveFontSize(context, 20);
    double emailFontSize = ResponsiveUtil.getResponsiveFontSize(context, 14);
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtil.getVerticalPadding(context), 
        horizontal: ResponsiveUtil.getHorizontalPadding(context)
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: Icon(Icons.person, size: iconSize, color: Colors.white),
          ),
          SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? 'No email',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: emailFontSize,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
  }) {
    double containerSize = ResponsiveUtil.isTablet(context) ? 45 : 40;
    double iconSize = ResponsiveUtil.getResponsiveIconSize(context, 20);
    double fontSize = ResponsiveUtil.getResponsiveFontSize(context, 16);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.screenWidth(context) * 0.025, 
          vertical: ResponsiveUtil.screenHeight(context) * 0.015
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.04),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
