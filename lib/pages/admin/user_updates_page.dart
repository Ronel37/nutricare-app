import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Update Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
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
        child: _buildNotificationsList(),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('admin_notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A3D00)),
            ),
          );
        }

        if (snapshot.data?.docs.isEmpty ?? true) {
          return const Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final notifications = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final timestamp = data['timestamp'] as Timestamp?;
              final time = timestamp?.toDate();
              final userName = data['userName'] ?? 'User';
              final personName = data['personName'] ?? 'Person';
              final updateType = data['updateType'] ?? 'update';
              final updateData = data['data'] as Map<String, dynamic>? ?? {};

              return _buildNotificationCard(
                id: doc.id,
                isRead: isRead,
                time: time,
                userName: userName,
                personName: personName,
                updateType: updateType,
                updateData: updateData,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required bool isRead,
    required DateTime? time,
    required String userName,
    required String personName,
    required String updateType,
    required Map<String, dynamic> updateData,
  }) {
    final formattedTime = time != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(time)
        : 'Unknown time';

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _firestore.collection('admin_notifications').doc(id).update({
            'isRead': true,
          });
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: isRead ? Colors.grey[800] : Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      color: isRead ? Colors.grey[400] : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: isRead ? Colors.grey[500] : Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Updated record for: $personName',
                style: TextStyle(
                  color: isRead ? Colors.grey[400] : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (updateType == 'person_update' && updateData.isNotEmpty)
                _buildUpdateDetails(updateData, isRead),
              if (!isRead)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'New',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateDetails(Map<String, dynamic> updateData, bool isRead) {
    final updatedFields = List<String>.from(updateData['updatedFields'] ?? []);
    final oldValues = updateData['oldValues'] as Map<String, dynamic>? ?? {};
    final newValues = updateData['newValues'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.grey, height: 1),
        const SizedBox(height: 8),
        ...updatedFields.map((field) {
          final oldValue = oldValues[field]?.toString() ?? '';
          final newValue = newValues[field]?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: isRead ? Colors.grey[400] : Colors.white,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '• ${field.replaceAll('_', ' ')}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '$oldValue → '),
                  TextSpan(
                    text: newValue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
