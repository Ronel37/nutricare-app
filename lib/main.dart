import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:nutricare_app/pages/initial pages/login_screen.dart';
import 'package:nutricare_app/pages/initial pages/splash_screen.dart';
import 'package:nutricare_app/pages/initial pages/welcome_screen.dart';
import 'package:nutricare_app/pages/initial pages/login_admin.dart';
import 'package:nutricare_app/pages/initial pages/email_verification_screen.dart';
import 'package:nutricare_app/pages/admin/admin_dashboard.dart';
import 'package:nutricare_app/pages/user/home_screen.dart';
import 'package:nutricare_app/pages/user/ai_recommendation_screen.dart';
import 'package:nutricare_app/services/notif.dart';

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'DISMISS') {
    await AwesomeNotifications().cancel(receivedAction.id!);
  }
}

Future<void> initializeNotifications() async {
  await AwesomeNotifications().initialize(
   null, 
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic alerts',
        defaultColor: Colors.green,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'scheduled_channel',
        channelName: 'Scheduled Reminders',
        channelDescription: 'Channel for weekly NutriCare reminders',
        defaultColor: Colors.teal,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        locked: true,
        enableVibration: true,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'admin_updates',
        channelName: 'Admin Updates',
        channelDescription: 'Notifications for admin changes in the app',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        playSound: true,
        enableVibration: true,
        criticalAlerts: true,
      )
    ],
    debug: true,
  );

  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  
  final prefs = await SharedPreferences.getInstance();
  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
  
  if (notificationsEnabled && !isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
  
  if (!notificationsEnabled && isAllowed) {
    await AwesomeNotifications().cancelAll();
  }
  
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationService.onActionReceivedMethod,
  );
  await NotificationService().initialize();
}

Future<void> checkAndScheduleReminders() async {
  final prefs = await SharedPreferences.getInstance();
  final bool remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
  
  if (remindersEnabled) {
    final lastScheduled = prefs.getInt('last_reminder_scheduled') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (now - lastScheduled > Duration(days: 7).inMilliseconds) {
      await NotificationService().scheduleWeeklyReminder();
      await prefs.setInt('last_reminder_scheduled', now);
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDcqlfbuL7F-9K1al3E8CE3Txw8W3u0S2s",
        appId: "1:580108383684:web:7c51fefee9dc26340fa091",
        messagingSenderId: "580108383684",
        projectId: "nutricare-database-c7d0c",
        authDomain: "nutricare-database-c7d0c.firebaseapp.com",
        storageBucket: "nutricare-database-c7d0c.firebasestorage.app",
        measurementId: "G-49MBEH1X72",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  await initializeNotifications();

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  
  await checkAndScheduleReminders();

  runApp(NutriCare(isFirstLaunch: isFirstLaunch));
}

class NutriCare extends StatelessWidget {
  final bool isFirstLaunch;
  const NutriCare({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: kIsWeb ? '/' : (isFirstLaunch ? '/welcome' : '/splash-screen'),
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/login-screen': (context) => const LoginScreen(),
        '/login-admin': (context) => CreateAdmin(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/admin-dashboard': (context) => const AdminDashboard(),
        '/home-screen': (context) => const HomeScreen(),
        '/splash-screen': (context) => SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/ai-recommendations': (context) => const AIRecommendationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasData) {
            return const AdminDashboard();
          } else {
            return CreateAdmin();
          }
        },
      );
    } else {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user != null) {
              NotificationService().startListeningForAdminChanges(user.uid);
              if (user.email == 'rpgvince44@gmail.com') {
                NotificationService().startListeningForUserUpdates();
              }
            }
            return user?.email == 'rpgvince44@gmail.com'
                ? const AdminDashboard()
                : const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      );
    }
  }
}