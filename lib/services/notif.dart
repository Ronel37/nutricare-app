import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _adminChangesSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _userUpdatesSubscriptions = {};
  
  final Set<int> _sentNotificationIds = {};

  Future<void> initialize() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    );
  }

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'DISMISS') {
      await AwesomeNotifications().cancel(receivedAction.id!);
    }
  }

  Future<bool> _wasNotificationSent(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final sentNotifications = prefs.getStringList('sent_notifications') ?? [];
    return sentNotifications.contains(notificationId.toString());
  }

  Future<void> _markNotificationAsSent(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final sentNotifications = prefs.getStringList('sent_notifications') ?? [];
    
    if (!sentNotifications.contains(notificationId.toString())) {
      sentNotifications.add(notificationId.toString());
      await prefs.setStringList('sent_notifications', sentNotifications);
    }
    
    _sentNotificationIds.add(notificationId);
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  void startListeningForAdminChanges(String userId) {
    print('Starting to listen for admin changes for user: $userId');
    _adminChangesSubscription?.cancel();

    _adminChangesSubscription = _firestore
        .collection('admin_changes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) async {
        print('Received admin changes update');
        
        final notificationsEnabled = await getNotificationsEnabled();
        if (!notificationsEnabled) {
          print('Notifications are disabled by user');
          return;
        }
        
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            print('New admin change detected');
            final data = change.doc.data() as Map<String, dynamic>;
            
            List<dynamic> readByUsers = data['readByUsers'] ?? [];
            if (readByUsers.contains(userId)) {
              print('Notification already read by user: $userId');
              continue;
            }
            
            final notificationId = change.doc.id.hashCode;
            if (await _wasNotificationSent(notificationId)) {
              print('Notification already sent before: $notificationId');
              continue;
            }
            
            try {
              await _sendAdminNotification(data, change.doc.id);
              print('Notification sent successfully for change: ${data['changeType']}');
              
              await _markNotificationAsSent(notificationId);
              
              await _markNotificationAsRead(change.doc.id, userId);
              print('Notification marked as read for user: $userId');
            } catch (e) {
              print('Error sending notification: $e');
            }
          }
        }
      },
      onError: (error) {
        print('Error in admin changes listener: $error');
      },
    );
  }

  void startListeningForUserUpdates() {
    print('Starting to listen for user updates');

    _userUpdatesSubscriptions.forEach((_, subscription) => subscription.cancel());
    _userUpdatesSubscriptions.clear();

    _firestore.collection('users').snapshots().listen((usersSnapshot) async {
   
      final notificationsEnabled = await getNotificationsEnabled();
      if (!notificationsEnabled) {
        print('Notifications are disabled for admin');
        return;
      }
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        if (_userUpdatesSubscriptions.containsKey(userId)) continue;

        final subscription = _firestore
            .collection('users')
            .doc(userId)
            .collection('persons')
            .snapshots()
            .listen(
          (snapshot) async {
            print('Received update for user: $userId');
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added || 
                  change.type == DocumentChangeType.modified) {
                print('New user update detected');
                final data = change.doc.data() as Map<String, dynamic>;
                
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                final notificationId = '${change.doc.id}_$timestamp'.hashCode;
                
                if (await _wasNotificationSent(notificationId)) {
                  print('Notification already sent before: $notificationId');
                  continue;
                }
                
                try {
                  await _notifyAdminAboutUserUpdate(data, change.doc.id, userId, notificationId);
                  print('Admin notification sent for user update');
                  
                  await _markNotificationAsSent(notificationId);
                } catch (e) {
                  print('Error sending admin notification: $e');
                }
              }
            }
          },
          onError: (error) {
            print('Error in user updates listener for user $userId: $error');
          },
        );

        _userUpdatesSubscriptions[userId] = subscription;
      }
    });
  }

  Future<void> _notifyAdminAboutUserUpdate(
      Map<String, dynamic> data, String docId, String userId, int notificationId) async {
    try {
      final adminEmail = 'rpgvince44@gmail.com';
      
      final adminQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        final adminId = adminQuery.docs.first.id;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userName = userDoc.data()?['name'] ?? 'Unknown User';
        
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'admin_updates',
            title: 'User Record Update',
            body: '$userName has updated their records (BMI: ${data['bmi']?.toStringAsFixed(1) ?? "N/A"})',
            notificationLayout: NotificationLayout.Default,
            payload: {
              'changeId': docId,
              'type': 'user_update',
              'userId': userId,
            },
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'DISMISS',
              label: 'Dismiss',
              actionType: ActionType.Default,
            ),
          ],
        );

        await _firestore.collection('admin_changes').add({
          'changeType': 'User Record Update',
          'description': '$userName has updated their records (BMI: ${data['bmi']?.toStringAsFixed(1) ?? "N/A"})',
          'timestamp': FieldValue.serverTimestamp(),
          'readByUsers': [adminId], 
          'userId': userId,
          'recordId': docId,
          'userName': userName,
          'bmi': data['bmi'],
          'weight': data['weight'],
          'height': data['height'],
          'notificationId': notificationId,
        });
      }
    } catch (e) {
      print('Error creating admin notification: $e');
      rethrow;
    }
  }

  Future<void> _sendAdminNotification(
      Map<String, dynamic> data, String docId) async {
    try {
      final notificationId = docId.hashCode;
      
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'admin_updates',
          title: 'Admin Update: ${data['changeType']}',
          body: data['description'],
          notificationLayout: NotificationLayout.Default,
          payload: {
            'changeId': docId,
            'type': data['changeType'],
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.Default,
          ),
        ],
      );
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> _markNotificationAsRead(String docId, String userId) async {
    try {
      await _firestore.collection('admin_changes').doc(docId).update({
        'readByUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> scheduleWeeklyReminder() async {
    final notificationsEnabled = await getNotificationsEnabled();
    if (!notificationsEnabled) {
      print('Cannot schedule reminder - notifications disabled');
      return;
    }
    
    final notificationId = 'weekly_reminder_${DateTime.now().millisecondsSinceEpoch}'.hashCode;
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'scheduled_channel',
        title: 'Weekly NutriCare Reminder',
        body: 'It\'s time to check your nutritional status and update your information.',
        notificationLayout: NotificationLayout.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'OPEN',
          label: 'Open App',
          actionType: ActionType.Default,
        ),
      ],
      schedule: NotificationCalendar(
        weekday: DateTime.now().weekday,
        hour: 9,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
    
    await _markNotificationAsSent(notificationId);
  }

  void dispose() {
    print('Disposing notification service');
    _adminChangesSubscription?.cancel();
    _userUpdatesSubscriptions.forEach((_, subscription) => subscription.cancel());
    _userUpdatesSubscriptions.clear();
  }
}
