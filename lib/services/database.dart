import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:nutricare_app/services/email_notification_service.dart';
import 'package:nutricare_app/services/sms_notification_service.dart';

class AuthServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final CollectionReference adminChangesCollection = 
      FirebaseFirestore.instance.collection('admin_changes');
  final CollectionReference adminNotificationsCollection = 
      FirebaseFirestore.instance.collection('admin_notifications');
  final CollectionReference userTrailCollection = 
      FirebaseFirestore.instance.collection('user_trail');

  final key = encrypt.Key.fromLength(32);
  final iv = encrypt.IV.fromLength(16);

  String encryptPassword(String password) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(password, iv: iv).base64;
  }

  // User
  Future<String> signUpUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Send email verification with better error handling
        try {
          await credential.user!.sendEmailVerification();
          print("✅ Email verification sent to: $email");
          print("📧 Firebase Auth Domain: ${FirebaseAuth.instance.app.options.authDomain}");
        } catch (emailError) {
          print("❌ Error sending email verification: $emailError");
          print("🔍 Error details: ${emailError.toString()}");
          // Continue with signup even if email fails
        }

        String encryptedPassword = encryptPassword(password);

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'encryptedPassword': encryptedPassword,
          'uid': credential.user!.uid,
          'emailVerified': false,
          'signupDate': FieldValue.serverTimestamp(),
        });

        await logUserActivity(name, 'Signed Up');
        res = "success";
      }
    } catch (e) {
      print("Signup error: $e");
      return e.toString();
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!userCredential.user!.emailVerified) {
          res = "Please verify your email before logging in.";
          await _auth.signOut();
        } else {
          DocumentSnapshot userSnapshot = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          Map<String, dynamic>? userData =
              userSnapshot.data() as Map<String, dynamic>?;

          if (userData != null && userData['role'] == 'admin') {
            res = "admin";
          } else {
            res = "success";
          }

          await logUserActivity(userData!['name'], 'Logged In');
          
          // Send professional login success notification email
          try {
            await EmailNotificationService().sendLoginSuccessNotification(
              userEmail: email,
              userName: userData['name'] ?? 'User',
              loginTime: DateTime.now().toIso8601String(),
              deviceInfo: EmailNotificationService().getDeviceInfo(),
            );
            print('✅ Login notification email sent successfully');
          } catch (emailError) {
            print('❌ Failed to send login notification email: $emailError');
            // Don't fail the login if email sending fails
          }

          // Send SMS notification if user has phone number
          try {
            String? userPhone = userData['phoneNumber'];
            if (userPhone != null && userPhone.isNotEmpty) {
              bool smsSent = await SMSNotificationService.sendLoginSuccessSMS(
                phoneNumber: userPhone,
                userName: userData['name'] ?? 'User',
                loginTime: DateTime.now().toIso8601String(),
              );
              if (smsSent) {
                print('✅ Login notification SMS sent successfully');
              } else {
                print('❌ Failed to send login notification SMS');
              }
            } else {
              print('ℹ️ No phone number found for user, skipping SMS notification');
            }
          } catch (smsError) {
            print('❌ SMS notification error: $smsError');
            // Don't fail the login if SMS sending fails
          }
        }
      } else {
        res = 'Please fill in all fields';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> logUserActivity(String userName, String action) async {
    try {
      await userTrailCollection.add({
        'userName': userName,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error logging user activity: $e");
    }
  }

  // Resend email verification with better error handling
  Future<String> resendEmailVerification() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null && !currentUser.emailVerified) {
        await currentUser.sendEmailVerification();
        print("Resend verification email sent to: ${currentUser.email}");
        return "Verification email sent successfully. Please check your inbox and spam folder.";
      } else if (currentUser != null && currentUser.emailVerified) {
        return "Email is already verified";
      } else {
        return "No user logged in";
      }
    } catch (e) {
      print("Error resending verification email: $e");
      return "Error sending verification email: ${e.toString()}";
    }
  }

  // Send verification email to specific email address
  Future<String> sendVerificationToEmail(String email) async {
    try {
      // First check if user exists
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isEmpty) {
        return "No account found with this email address";
      }

      // Send password reset email which also triggers verification
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent to: $email");
      return "Verification email sent successfully. Please check your inbox and spam folder.";
    } catch (e) {
      print("Error sending verification to email: $e");
      return "Error sending verification email: ${e.toString()}";
    }
  }

  // Check email verification status
  Future<bool> checkEmailVerificationStatus() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        return currentUser.emailVerified;
      }
      return false;
    } catch (e) {
      print("Error checking email verification status: $e");
      return false;
    }
  }

  // Manual verification bypass for testing (remove in production)
  Future<String> bypassEmailVerification(String email) async {
    try {
      // This is for testing only - remove in production
      if (email == 'test@nutricare.com') {
        User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Update Firestore to mark as verified
          await _firestore.collection('users').doc(currentUser.uid).update({
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          return "Email verification bypassed for testing";
        }
      }
      return "Bypass not allowed for this email";
    } catch (e) {
      return "Error bypassing verification: ${e.toString()}";
    }
  }

  // Admin 
  Future<String> createAdminAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user!.sendEmailVerification();

        String encryptedPassword = encryptPassword(password);

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'encryptedPassword': encryptedPassword,
          'uid': credential.user!.uid,
          'role': 'admin',
        });
        
        await logUserActivity(name, 'Created Admin Account');
        res = "Admin account created successfully";
      } else {
        res = 'Please fill in all fields';
      }
    } catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> logAdminChange({
    required String adminId,
    required String changeType,
    required String description,
    Map<String, dynamic>? changeData,
  }) async {
    try {
      DocumentSnapshot adminDoc = await _firestore.collection('users').doc(adminId).get();
      Map<String, dynamic>? adminData = adminDoc.data() as Map<String, dynamic>?;

      await adminChangesCollection.add({
        'adminId': adminId,
        'adminName': adminData?['name'] ?? 'Admin',
        'changeType': changeType,
        'description': description,
        'data': changeData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'readByUsers': [],
      });
    } catch (e) {
      print('Error logging admin change: $e');
    }
  }

  // Notification
  Future<void> logUserUpdateForAdmin({
    required String userId,
    required String userName,
    required String personName,
    required String updateType,
    Map<String, dynamic>? updateData,
  }) async {
    try {
      await adminNotificationsCollection.add({
        'userId': userId,
        'userName': userName,
        'personName': personName,
        'updateType': updateType,
        'data': updateData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error logging user update for admin: $e');
    }
  }

  Stream<QuerySnapshot> getAdminNotificationsStream() {
    return adminNotificationsCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await adminNotificationsCollection.doc(notificationId).update({'isRead': true});
  }

  Stream<QuerySnapshot> getAdminChangesStream() {
    return adminChangesCollection
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markAdminChangeAsRead({
    required String changeId, 
    required String userId
  }) async {
    await adminChangesCollection.doc(changeId).update({
      'readByUsers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> addPersonToUser({
    required String userId,
    required String name,
    required int age,
    required double weight,
    required double height,
    double? haz,
    double? waz,
    double? whz,
  }) async {
    try {
      double bmi = weight / ((height / 100) * (height / 100));

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String userName = userData?['name'] ?? 'User';

      final Map<String, dynamic> personData = {
        'name': name,
        'age': age,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'bmiCategory': _getBmiCategory(bmi),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Add anthropometric data for children <= 5 years
      if (haz != null) personData['haz'] = haz;
      if (waz != null) personData['waz'] = waz;
      if (whz != null) personData['whz'] = whz;

      final personRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .add(personData);

      final Map<String, dynamic> historyData = {
        'name': name,
        'age': age,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'updatedAt': FieldValue.serverTimestamp(),
        'updateType': 'creation',
      };

      // Add anthropometric data to history
      if (haz != null) historyData['haz'] = haz;
      if (waz != null) historyData['waz'] = waz;
      if (whz != null) historyData['whz'] = whz;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(personRef.id)
          .collection('updateHistory')
          .add(historyData);

      await logUserUpdateForAdmin(
        userId: userId,
        userName: userName,
        personName: name,
        updateType: 'person_creation',
        updateData: {
          'personId': personRef.id,
          'age': age,
          'weight': weight,
          'height': height,
          'bmi': bmi,
        },
      );
    } catch (e) {
      print('Error adding person: $e');
      rethrow;
    }
  }

  Future<void> updatePersonInfo({
    required String userId,
    required String personId,
    String? name,
    int? age,
    double? weight,
    double? height,
    double? haz,
    double? waz,
    double? whz,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      final Map<String, dynamic> historyData = {
        'updatedAt': FieldValue.serverTimestamp(),
        'updateType': 'modification',
      };

      DocumentSnapshot personDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(personId)
          .get();

      Map<String, dynamic>? personData = personDoc.data() as Map<String, dynamic>?;
      if (personData == null) throw Exception('Person not found');

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      String userName = userData?['name'] ?? 'User';

      Map<String, dynamic> changedFields = {};
      Map<String, dynamic> oldValues = {};

      if ((weight != null || height != null)) {
        double currentWeight = weight ?? personData['weight'];
        double currentHeight = height ?? personData['height'];
        double bmi = currentWeight / (currentHeight * currentHeight);

        updates['bmi'] = bmi;
        updates['bmiCategory'] = _getBmiCategory(bmi);
        historyData['bmi'] = bmi;

        if (weight != null && weight != personData['weight']) {
          oldValues['weight'] = personData['weight'];
          changedFields['weight'] = weight;
        }
        if (height != null && height != personData['height']) {
          oldValues['height'] = personData['height'];
          changedFields['height'] = height;
        }
      }

      if (name != null && name != personData['name']) {
        updates['name'] = name;
        historyData['name'] = name;
        oldValues['name'] = personData['name'];
        changedFields['name'] = name;
      }
      if (age != null && age != personData['age']) {
        updates['age'] = age;
        historyData['age'] = age;
        oldValues['age'] = personData['age'];
        changedFields['age'] = age;
      }
      if (weight != null) {
        updates['weight'] = weight;
        historyData['weight'] = weight;
      }
      if (height != null) {
        updates['height'] = height;
        historyData['height'] = height;
      }

      // Add anthropometric data for children <= 5 years
      if (haz != null) {
        updates['haz'] = haz;
        historyData['haz'] = haz;
      }
      if (waz != null) {
        updates['waz'] = waz;
        historyData['waz'] = waz;
      }
      if (whz != null) {
        updates['whz'] = whz;
        historyData['whz'] = whz;
      }

      if (updates.isNotEmpty) {
        updates['lastUpdated'] = FieldValue.serverTimestamp();

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('persons')
            .doc(personId)
            .update(updates);

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('persons')
            .doc(personId)
            .collection('updateHistory')
            .add(historyData);

        if (changedFields.isNotEmpty) {
          await logUserUpdateForAdmin(
            userId: userId,
            userName: userName,
            personName: updates['name'] ?? personData['name'],
            updateType: 'person_update',
            updateData: {
              'personId': personId,
              'changedFields': changedFields,
              'oldValues': oldValues,
              'newValues': updates,
            },
          );
        }
      }
    } catch (e) {
      print('Error updating person info: $e');
      rethrow;
    }
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 24.9) return 'Normal weight';
    if (bmi >= 25 && bmi < 29.9) return 'Overweight';
    return 'Obesity';
  }

  Future<List<Map<String, dynamic>>> getPersonUpdateHistory({
    required String userId,
    required String personId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(personId)
          .collection('updateHistory')
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error fetching update history: $e");
      return [];
    }
  }

  // Recipe 
  Future<void> uploadRecipe({
    required String name,
    required String details,
    required String imageUrl,
    required List<String> ingredients,
    required List<String> instructions,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      DocumentReference recipeRef = await _firestore.collection('recipes').add({
        'name': name,
        'details': details,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'instructions': instructions,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await logAdminChange(
        adminId: user.uid,
        changeType: 'recipe',
        description: 'Added new recipe: $name',
        changeData: {
          'recipeId': recipeRef.id,
          'name': name,
          'imageUrl': imageUrl,
        },
      );
    } catch (e) {
      print('Error uploading recipe: $e');
      rethrow;
    }
  }

  // Nutrition Tip 
  Future<void> uploadNutritionTip({
    required String title,
    required String details,
    required String imageUrl,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      DocumentReference tipRef = await _firestore.collection('nutritionTips').add({
        'title': title,
        'details': details,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await logAdminChange(
        adminId: user.uid,
        changeType: 'nutritionTip',
        description: 'Added new nutrition tip: $title',
        changeData: {
          'tipId': tipRef.id,
          'title': title,
          'imageUrl': imageUrl,
        },
      );
    } catch (e) {
      print('Error uploading nutrition tip: $e');
      rethrow;
    }
  }

  // Feedback 
  Future<void> addFeedback({
    required String userName,
    required String feedbackMessage,
    required double rating,
  }) async {
    await _firestore.collection('feedbacks').add({
      'userName': userName,
      'message': feedbackMessage,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Recipe 
  Future<void> saveRecipeToCollection({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .doc(recipeId)
          .set({
        'recipeId': recipeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving recipe to collection: $e");
    }
  }

  Future<List<String>> getSavedRecipeIds(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error fetching saved recipes: $e");
      return [];
    }
  }

  Future<void> saveRecipeOnClick({
    required String recipeId,
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .doc(recipeId)
          .set({
        'recipeId': recipeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving recipe: $e');
    }
  }

  Future<void> removeRecipeFromCollection({
    required String userId,
    required String recipeId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedRecipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      print("Error removing recipe from collection: $e");
    }
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}