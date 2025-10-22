import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutricare_app/services/notif.dart';
import 'package:nutricare_app/utils/responsive_util.dart';
import 'package:nutricare_app/pages/user/profile_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    final remindersEnabled = prefs.getBool('reminders_enabled') ?? true;

    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _remindersEnabled = remindersEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    await NotificationService().setNotificationsEnabled(value);

    setState(() {
      _notificationsEnabled = value;
      _isLoading = false; // Hide loading indicator
      
      // If notifications are disabled, reminders should also be disabled
      if (!value) {
        _remindersEnabled = false;
        prefs.setBool('reminders_enabled', false);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Notifications enabled' 
          : 'Notifications disabled'),
        backgroundColor: const Color(0xFF0A3D00),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', value);

    if (value) {
      // If enabling reminders, ensure notifications are also enabled
      if (!_notificationsEnabled) {
        await _toggleNotifications(true);
      } else {
        // Schedule a new reminder
        await NotificationService().scheduleWeeklyReminder();
        await prefs.setInt('last_reminder_scheduled', DateTime.now().millisecondsSinceEpoch);
      }
    }

    setState(() {
      _remindersEnabled = value;
      _isLoading = false; // Hide loading indicator
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Weekly reminders enabled' 
          : 'Weekly reminders disabled'),
        backgroundColor: const Color(0xFF0A3D00),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    
    await NotificationService().cancelAllNotifications();
    
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications cleared'),
        backgroundColor: const Color(0xFF0A3D00),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0A3D00),
                ),
              )
            : ListView(
                padding: EdgeInsets.all(
                  ResponsiveUtil.getHorizontalPadding(context),
                ),
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Notification Settings'),
                  _buildSettingCard(
                    title: 'Enable Notifications',
                    subtitle: 'Receive updates and important alerts',
                    icon: Icons.notifications,
                    toggle: Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeColor: Colors.green,
                    ),
                  ),
                  _buildSettingCard(
                    title: 'Weekly Reminders',
                    subtitle: 'Get reminded to check your nutritional status',
                    icon: Icons.calendar_today,
                    toggle: Switch(
                      value: _remindersEnabled,
                      onChanged: _notificationsEnabled 
                        ? _toggleReminders 
                        : null,
                      activeColor: Colors.green,
                    ),
                    enabled: _notificationsEnabled,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Profile Settings'),
                  _buildActionCard(
                    title: 'Profile Settings',
                    subtitle: 'Update your profile and phone number for SMS notifications',
                    icon: Icons.person_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileSettings()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Actions'),
                  _buildActionCard(
                    title: 'Clear All Notifications',
                    subtitle: 'Remove all current notifications',
                    icon: Icons.notifications_off,
                    onTap: _clearAllNotifications,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('About'),
                  _buildInfoCard(
                    title: 'Notification Information',
                    content: 'Notifications help you stay updated with important information and reminders. '
                        'You can enable or disable them at any time.\n\n'
                        'Weekly reminders can help you maintain consistent tracking of your nutritional status.',
                    icon: Icons.info_outline,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget toggle,
    bool enabled = true,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: enabled 
                    ? const Color(0xFF0A3D00).withOpacity(0.3) 
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: enabled ? Colors.white : Colors.grey,
                size: ResponsiveUtil.getResponsiveIconSize(context, 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey,
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: enabled ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
            toggle,
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: ResponsiveUtil.getResponsiveIconSize(context, 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade600,
                size: ResponsiveUtil.getResponsiveIconSize(context, 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue,
                  size: ResponsiveUtil.getResponsiveIconSize(context, 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 