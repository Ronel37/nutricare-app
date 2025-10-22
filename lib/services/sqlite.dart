// import 'dart:async';
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:path/path.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class LocalDatabaseService {
//   static Database? _database;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

//   // Stream controllers for sync status
//   final _syncController = StreamController<String>.broadcast();
//   Stream<String> get syncStatus => _syncController.stream;

//   // Singleton pattern
//   static final LocalDatabaseService _instance =
//       LocalDatabaseService._internal();
//   factory LocalDatabaseService() => _instance;
//   LocalDatabaseService._internal();

//   // Initialize encryption keys securely
//   Future<void> _initEncryption() async {
//     // Try to retrieve keys from secure storage
//     String? storedKey = await _secureStorage.read(key: 'encryption_key');
//     String? storedIv = await _secureStorage.read(key: 'encryption_iv');

//     if (storedKey == null || storedIv == null) {
//       // Generate new keys if not found
//       final key = encrypt.Key.fromSecureRandom(32);
//       final iv = encrypt.IV.fromSecureRandom(16);

//       // Store keys securely
//       await _secureStorage.write(
//           key: 'encryption_key', value: base64Encode(key.bytes));
//       await _secureStorage.write(
//           key: 'encryption_iv', value: base64Encode(iv.bytes));
//     } else {
//       // Use existing keys
//     }
//   }

//   Future<Database> get database async {
//     if (_database != null) return _database!;
//     await _initEncryption(); // Ensure encryption is initialized
//     _database = await _initDatabase();
//     return _database!;
//   }

//   Future<Database> _initDatabase() async {
//     String path = join(await getDatabasesPath(), 'recipe_app.db');
//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: _createDb,
//       onConfigure: (db) async {
//         // Enable foreign keys
//         await db.execute('PRAGMA foreign_keys = ON');
//       },
//     );
//   }

//   Future<void> _createDb(Database db, int version) async {
//     // Create users table
//     await db.execute('''
//       CREATE TABLE users(
//         uid TEXT PRIMARY KEY,
//         name TEXT NOT NULL,
//         email TEXT NOT NULL,
//         encryptedPassword TEXT NOT NULL,
//         role TEXT,
//         lastSynced INTEGER
//       )
//     ''');

//     // Create recipes table
//     await db.execute('''
//       CREATE TABLE recipes(
//         id TEXT PRIMARY KEY,
//         name TEXT NOT NULL,
//         details TEXT NOT NULL,
//         imageUrl TEXT NOT NULL,
//         timestamp INTEGER,
//         lastSynced INTEGER
//       )
//     ''');

//     // Create recipe_ingredients table
//     await db.execute('''
//       CREATE TABLE recipe_ingredients(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         recipeId TEXT NOT NULL,
//         ingredient TEXT NOT NULL,
//         FOREIGN KEY (recipeId) REFERENCES recipes(id) ON DELETE CASCADE
//       )
//     ''');

//     // Create recipe_instructions table
//     await db.execute('''
//       CREATE TABLE recipe_instructions(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         recipeId TEXT NOT NULL,
//         instruction TEXT NOT NULL,
//         stepNumber INTEGER NOT NULL,
//         FOREIGN KEY (recipeId) REFERENCES recipes(id) ON DELETE CASCADE
//       )
//     ''');

//     // Create nutrition_tips table
//     await db.execute('''
//       CREATE TABLE nutrition_tips(
//         id TEXT PRIMARY KEY,
//         title TEXT NOT NULL,
//         details TEXT NOT NULL,
//         imageUrl TEXT NOT NULL,
//         timestamp INTEGER,
//         lastSynced INTEGER
//       )
//     ''');

//     // Create feedbacks table
//     await db.execute('''
//       CREATE TABLE feedbacks(
//         id TEXT PRIMARY KEY,
//         userName TEXT NOT NULL,
//         message TEXT NOT NULL,
//         rating REAL NOT NULL,
//         timestamp INTEGER,
//         isUploaded INTEGER DEFAULT 0
//       )
//     ''');

//     // Create saved_recipes table
//     await db.execute('''
//       CREATE TABLE saved_recipes(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         userId TEXT NOT NULL,
//         recipeId TEXT NOT NULL,
//         savedAt INTEGER,
//         isUploaded INTEGER DEFAULT 0,
//         UNIQUE(userId, recipeId)
//       )
//     ''');

//     // Create persons table
//     await db.execute('''
//       CREATE TABLE persons(
//         id TEXT PRIMARY KEY,
//         userId TEXT NOT NULL,
//         name TEXT NOT NULL,
//         age INTEGER NOT NULL,
//         weight REAL NOT NULL,
//         height REAL NOT NULL,
//         timestamp INTEGER,
//         isUploaded INTEGER DEFAULT 0
//       )
//     ''');

//     // Create sync_queue table for storing pending operations
//     await db.execute('''
//       CREATE TABLE sync_queue(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         operation TEXT NOT NULL,
//         collection TEXT NOT NULL,
//         documentId TEXT,
//         data TEXT NOT NULL,
//         timestamp INTEGER
//       )
//     ''');

//     // Create user_trail table
//     await db.execute('''
//       CREATE TABLE user_trail(
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         userName TEXT NOT NULL,
//         action TEXT NOT NULL,
//         timestamp INTEGER,
//         isUploaded INTEGER DEFAULT 0
//       )
//     ''');
//   }

//   // ===================== USER METHODS =====================

//   Future<void> saveCurrentUser(
//       User firebaseUser, String name, String encryptedPassword,
//       {String? role}) async {
//     final db = await database;

//     await db.insert(
//       'users',
//       {
//         'uid': firebaseUser.uid,
//         'name': name,
//         'email': firebaseUser.email,
//         'encryptedPassword': encryptedPassword,
//         'role': role ?? 'user',
//         'lastSynced': DateTime.now().millisecondsSinceEpoch,
//       },
//       conflictAlgorithm: ConflictAlgorithm.replace,
//     );
//   }

//   Future<Map<String, dynamic>?> getCurrentUserData() async {
//     final db = await database;
//     final User? currentUser = _auth.currentUser;

//     if (currentUser == null) return null;

//     final List<Map<String, dynamic>> results = await db.query(
//       'users',
//       where: 'uid = ?',
//       whereArgs: [currentUser.uid],
//     );

//     return results.isNotEmpty ? results.first : null;
//   }

//   // ===================== RECIPE METHODS =====================

//   Future<bool> saveRecipe(
//       String id,
//       String name,
//       String details,
//       String imageUrl,
//       List<String> ingredients,
//       List<String> instructions,
//       int timestamp) async {
//     final db = await database;

//     try {
//       await db.transaction((txn) async {
//         // Insert recipe
//         await txn.insert(
//           'recipes',
//           {
//             'id': id,
//             'name': name,
//             'details': details,
//             'imageUrl': imageUrl,
//             'timestamp': timestamp,
//             'lastSynced': DateTime.now().millisecondsSinceEpoch,
//           },
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );

//         // Delete old ingredients and instructions
//         await txn.delete('recipe_ingredients',
//             where: 'recipeId = ?', whereArgs: [id]);
//         await txn.delete('recipe_instructions',
//             where: 'recipeId = ?', whereArgs: [id]);

//         // Insert ingredients
//         for (var ingredient in ingredients) {
//           await txn.insert(
//             'recipe_ingredients',
//             {
//               'recipeId': id,
//               'ingredient': ingredient,
//             },
//           );
//         }

//         // Insert instructions
//         for (int i = 0; i < instructions.length; i++) {
//           await txn.insert(
//             'recipe_instructions',
//             {
//               'recipeId': id,
//               'instruction': instructions[i],
//               'stepNumber': i + 1,
//             },
//           );
//         }
//       });
//       return true;
//     } catch (e) {
//       print("Error saving recipe: $e");
//       return false;
//     }
//   }

//   Future<List<Map<String, dynamic>>> getAllRecipes() async {
//     final db = await database;
//     final List<Map<String, dynamic>> recipes =
//         await db.query('recipes', orderBy: 'timestamp DESC');

//     // For each recipe, get ingredients and instructions
//     final List<Map<String, dynamic>> result = [];

//     for (var recipe in recipes) {
//       final Map<String, dynamic> fullRecipe = Map<String, dynamic>.from(recipe);

//       final ingredients = await db.query(
//         'recipe_ingredients',
//         where: 'recipeId = ?',
//         whereArgs: [recipe['id']],
//       );

//       final instructions = await db.query(
//         'recipe_instructions',
//         where: 'recipeId = ?',
//         whereArgs: [recipe['id']],
//         orderBy: 'stepNumber ASC',
//       );

//       fullRecipe['ingredients'] =
//           ingredients.map((i) => i['ingredient'].toString()).toList();
//       fullRecipe['instructions'] =
//           instructions.map((i) => i['instruction'].toString()).toList();

//       result.add(fullRecipe);
//     }

//     return result;
//   }

//   Future<Map<String, dynamic>?> getRecipeById(String id) async {
//     final db = await database;
//     final List<Map<String, dynamic>> recipes = await db.query(
//       'recipes',
//       where: 'id = ?',
//       whereArgs: [id],
//     );

//     if (recipes.isEmpty) return null;

//     final recipe = Map<String, dynamic>.from(recipes.first);

//     // Get ingredients
//     final ingredients = await db.query(
//       'recipe_ingredients',
//       where: 'recipeId = ?',
//       whereArgs: [id],
//     );

//     // Get instructions
//     final instructions = await db.query(
//       'recipe_instructions',
//       where: 'recipeId = ?',
//       whereArgs: [id],
//       orderBy: 'stepNumber ASC',
//     );

//     recipe['ingredients'] =
//         ingredients.map((i) => i['ingredient'].toString()).toList();
//     recipe['instructions'] =
//         instructions.map((i) => i['instruction'].toString()).toList();

//     return recipe;
//   }

//   // ===================== NUTRITION TIP METHODS =====================

//   Future<bool> saveNutritionTip(String id, String title, String details,
//       String imageUrl, int timestamp) async {
//     final db = await database;

//     try {
//       await db.insert(
//         'nutrition_tips',
//         {
//           'id': id,
//           'title': title,
//           'details': details,
//           'imageUrl': imageUrl,
//           'timestamp': timestamp,
//           'lastSynced': DateTime.now().millisecondsSinceEpoch,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//       return true;
//     } catch (e) {
//       print("Error saving nutrition tip: $e");
//       return false;
//     }
//   }

//   Future<bool> saveTipsToCollection(String userId, String tipId) async {
//     final db = await database;
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     try {
//       await db.insert(
//         'saved_tips',
//         {
//           'userId': userId,
//           'tipId': tipId,
//           'savedAt': timestamp,
//           'isUploaded': 0,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );

//       // Prepare data for Firestore
//       final Map<String, dynamic> firestoreData = {
//         'tipId': tipId,
//         'savedAt': timestamp,
//       };

//       await _addToSyncQueue(
//         'create',
//         'users/$userId/savedTips',
//         tipId,
//         firestoreData,
//       );

//       // Attempt to sync
//       syncWithFirebase();
//       return true;
//     } catch (e) {
//       print("Error saving tip to collection: $e");
//       return false;
//     }
//   }

//   Future<List<Map<String, dynamic>>> getAllNutritionTips() async {
//     final db = await database;
//     return await db.query('nutrition_tips', orderBy: 'timestamp DESC');
//   }

//   // ===================== FEEDBACK METHODS =====================

//   Future<bool> saveFeedback(
//       String userName, String message, double rating) async {
//     final db = await database;

//     final id = DateTime.now().millisecondsSinceEpoch.toString();
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     try {
//       await db.insert(
//         'feedbacks',
//         {
//           'id': id,
//           'userName': userName,
//           'message': message,
//           'rating': rating,
//           'timestamp': timestamp,
//           'isUploaded': 0,
//         },
//       );

//       // Add to sync queue - proper JSON serialization
//       final Map<String, dynamic> firestoreData = {
//         'userName': userName,
//         'message': message,
//         'rating': rating,
//         'timestamp': timestamp, // Store timestamp as int for now
//       };

//       await _addToSyncQueue(
//         'create',
//         'feedbacks',
//         id,
//         firestoreData,
//       );

//       // Try to sync immediately
//       syncWithFirebase();
//       return true;
//     } catch (e) {
//       print("Error saving feedback: $e");
//       return false;
//     }
//   }

//   // ===================== SAVED RECIPES METHODS =====================

//   Future<bool> saveRecipeToCollection(String userId, String recipeId) async {
//     final db = await database;
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     try {
//       await db.insert(
//         'saved_recipes',
//         {
//           'userId': userId,
//           'recipeId': recipeId,
//           'savedAt': timestamp,
//           'isUploaded': 0,
//         },
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );

//       // Add to sync queue with proper JSON
//       final Map<String, dynamic> firestoreData = {
//         'recipeId': recipeId,
//         'savedAt': timestamp,
//       };

//       await _addToSyncQueue(
//         'create',
//         'users/$userId/savedRecipes',
//         recipeId,
//         firestoreData,
//       );

//       // Try to sync immediately
//       syncWithFirebase();
//       return true;
//     } catch (e) {
//       print("Error saving recipe to collection: $e");
//       return false;
//     }
//   }

//   Future<List<String>> getSavedRecipeIds(String userId) async {
//     final db = await database;

//     final savedRecipes = await db.query(
//       'saved_recipes',
//       columns: ['recipeId'],
//       where: 'userId = ?',
//       whereArgs: [userId],
//     );

//     return savedRecipes.map((recipe) => recipe['recipeId'].toString()).toList();
//   }

//   Future<List<Map<String, dynamic>>> getSavedRecipes(String userId) async {
//     final savedRecipeIds = await getSavedRecipeIds(userId);

//     if (savedRecipeIds.isEmpty) return [];

//     // Get full recipe details for each saved recipe
//     List<Map<String, dynamic>> savedRecipes = [];

//     for (var id in savedRecipeIds) {
//       final recipe = await getRecipeById(id);
//       if (recipe != null) {
//         savedRecipes.add(recipe);
//       }
//     }

//     return savedRecipes;
//   }

//   // ===================== PERSON METHODS =====================

//   Future<bool> savePerson(
//       String userId, String name, int age, double weight, double height) async {
//     final db = await database;

//     final id = DateTime.now().millisecondsSinceEpoch.toString();
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     try {
//       await db.insert(
//         'persons',
//         {
//           'id': id,
//           'userId': userId,
//           'name': name,
//           'age': age,
//           'weight': weight,
//           'height': height,
//           'timestamp': timestamp,
//           'isUploaded': 0,
//         },
//       );

//       // Add to sync queue with proper JSON
//       final Map<String, dynamic> firestoreData = {
//         'name': name,
//         'age': age,
//         'weight': weight,
//         'height': height,
//         'timestamp': timestamp,
//       };

//       await _addToSyncQueue(
//         'create',
//         'users/$userId/persons',
//         id,
//         firestoreData,
//       );

//       // Try to sync immediately
//       syncWithFirebase();
//       return true;
//     } catch (e) {
//       print("Error saving person: $e");
//       return false;
//     }
//   }

//   Future<List<Map<String, dynamic>>> getPersonsForUser(String userId) async {
//     final db = await database;

//     return await db.query(
//       'persons',
//       where: 'userId = ?',
//       whereArgs: [userId],
//       orderBy: 'timestamp DESC',
//     );
//   }

//   // ===================== USER TRAIL METHODS =====================

//   Future<bool> logUserActivity(String userName, String action) async {
//     final db = await database;
//     final timestamp = DateTime.now().millisecondsSinceEpoch;

//     try {
//       final id = await db.insert(
//         'user_trail',
//         {
//           'userName': userName,
//           'action': action,
//           'timestamp': timestamp,
//           'isUploaded': 0,
//         },
//       );

//       // Add to sync queue with proper JSON
//       final Map<String, dynamic> firestoreData = {
//         'userName': userName,
//         'action': action,
//         'timestamp': timestamp,
//       };

//       await _addToSyncQueue(
//         'create',
//         'user_trail',
//         id.toString(),
//         firestoreData,
//       );

//       // Try to sync immediately
//       syncWithFirebase();
//       return true;
//     } catch (e) {
//       print("Error logging user activity: $e");
//       return false;
//     }
//   }

//   // ===================== SYNC METHODS =====================

//   Future<void> _addToSyncQueue(String operation, String collection,
//       String? documentId, Map<String, dynamic> data) async {
//     final db = await database;

//     // Properly serialize the data to JSON
//     final String jsonData = jsonEncode(data);

//     await db.insert(
//       'sync_queue',
//       {
//         'operation': operation,
//         'collection': collection,
//         'documentId': documentId,
//         'data': jsonData,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       },
//     );
//   }

//   Future<void> syncWithFirebase() async {
//     // Check for internet connection
//     var connectivityResult = await Connectivity().checkConnectivity();
//     if (connectivityResult == ConnectivityResult.none) {
//       _syncController.add(
//           "No internet connection. Changes will sync when you're back online.");
//       return;
//     }

//     // Check if user is authenticated
//     if (_auth.currentUser == null) {
//       _syncController.add("User not authenticated. Please login.");
//       return;
//     }

//     _syncController.add("Syncing with server...");

//     try {
//       final db = await database;

//       // Get pending operations from sync queue
//       final pendingOperations =
//           await db.query('sync_queue', orderBy: 'timestamp ASC');

//       int successCount = 0;

//       for (var operation in pendingOperations) {
//         try {
//           final opType = operation['operation'].toString();
//           final collection = operation['collection'].toString();
//           final documentId = operation['documentId']?.toString();
//           final jsonData = operation['data'].toString();

//           // Properly parse the JSON data
//           Map<String, dynamic> data = jsonDecode(jsonData);

//           // Convert timestamp integers to Firebase Timestamps for server
//           if (data.containsKey('timestamp') && data['timestamp'] is int) {
//             data['timestamp'] =
//                 Timestamp.fromMillisecondsSinceEpoch(data['timestamp']);
//           }

//           // Apply the operation to Firestore
//           if (opType == 'create') {
//             if (documentId != null && documentId.isNotEmpty) {
//               await _firestore.collection(collection).doc(documentId).set(data);
//             } else {
//               await _firestore.collection(collection).add(data);
//             }
//           } else if (opType == 'update') {
//             await _firestore
//                 .collection(collection)
//                 .doc(documentId)
//                 .update(data);
//           } else if (opType == 'delete') {
//             await _firestore.collection(collection).doc(documentId).delete();
//           }

//           // Delete the operation from the queue
//           await db.delete(
//             'sync_queue',
//             where: 'id = ?',
//             whereArgs: [operation['id']],
//           );

//           // Update the isUploaded status in the respective tables
//           if (collection == 'feedbacks') {
//             await db.update(
//               'feedbacks',
//               {'isUploaded': 1},
//               where: 'id = ?',
//               whereArgs: [documentId],
//             );
//           } else if (collection == 'user_trail') {
//             await db.update(
//               'user_trail',
//               {'isUploaded': 1},
//               where: 'id = ?',
//               whereArgs: [operation['id']],
//             );
//           } else if (collection.contains('savedRecipes')) {
//             final parts = collection.split('/');
//             if (parts.length >= 2) {
//               final userId = parts[1];

//               await db.update(
//                 'saved_recipes',
//                 {'isUploaded': 1},
//                 where: 'userId = ? AND recipeId = ?',
//                 whereArgs: [userId, documentId],
//               );
//             }
//           } else if (collection.contains('persons')) {
//             await db.update(
//               'persons',
//               {'isUploaded': 1},
//               where: 'id = ?',
//               whereArgs: [documentId],
//             );
//           }

//           successCount++;
//         } catch (e) {
//           print("Error processing sync operation: $e");
//         }
//       }

//       // Download latest data from Firestore
//       await _downloadLatestData();

//       _syncController.add("Sync completed. $successCount items synchronized.");
//     } catch (e) {
//       _syncController.add("Sync failed: ${e.toString()}");
//     }
//   }

//   Future<void> _downloadLatestData() async {
//     final db = await database;
//     final currentUser = _auth.currentUser;

//     if (currentUser == null) return;

//     try {
//       // Get user data
//       final userDoc =
//           await _firestore.collection('users').doc(currentUser.uid).get();
//       if (userDoc.exists && userDoc.data() != null) {
//         await saveCurrentUser(
//           currentUser,
//           userDoc.data()!['name'] ?? '',
//           userDoc.data()!['encryptedPassword'] ?? '',
//           role: userDoc.data()!['role'],
//         );
//       }

//       // Get recipes
//       final recipesSnapshot = await _firestore.collection('recipes').get();
//       for (var doc in recipesSnapshot.docs) {
//         final data = doc.data();
//         if (data.containsKey('name') &&
//             data.containsKey('details') &&
//             data.containsKey('imageUrl') &&
//             data.containsKey('ingredients') &&
//             data.containsKey('instructions')) {
//           // Handle Firestore timestamp to int conversion
//           int timestamp;
//           if (data['timestamp'] is Timestamp) {
//             timestamp = (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
//           } else {
//             timestamp = DateTime.now().millisecondsSinceEpoch;
//           }

//           await saveRecipe(
//             doc.id,
//             data['name'],
//             data['details'],
//             data['imageUrl'],
//             List<String>.from(data['ingredients'] ?? []),
//             List<String>.from(data['instructions'] ?? []),
//             timestamp,
//           );
//         }
//       }

//       // Get nutrition tips
//       final tipsSnapshot = await _firestore.collection('nutritionTips').get();
//       for (var doc in tipsSnapshot.docs) {
//         final data = doc.data();
//         if (data.containsKey('title') &&
//             data.containsKey('details') &&
//             data.containsKey('imageUrl')) {
//           // Handle Firestore timestamp to int conversion
//           int timestamp;
//           if (data['timestamp'] is Timestamp) {
//             timestamp = (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
//           } else {
//             timestamp = DateTime.now().millisecondsSinceEpoch;
//           }

//           await saveNutritionTip(
//             doc.id,
//             data['title'],
//             data['details'],
//             data['imageUrl'],
//             timestamp,
//           );
//         }
//       }

//       // Get saved recipes for current user
//       final savedRecipesSnapshot = await _firestore
//           .collection('users')
//           .doc(currentUser.uid)
//           .collection('savedRecipes')
//           .get();

//       for (var doc in savedRecipesSnapshot.docs) {
//         final data = doc.data();

//         // Handle Firestore timestamp to int conversion
//         int savedAt;
//         if (data['savedAt'] is Timestamp) {
//           savedAt = (data['savedAt'] as Timestamp).millisecondsSinceEpoch;
//         } else {
//           savedAt = DateTime.now().millisecondsSinceEpoch;
//         }

//         await db.insert(
//           'saved_recipes',
//           {
//             'userId': currentUser.uid,
//             'recipeId': doc.id,
//             'savedAt': savedAt,
//             'isUploaded': 1,
//           },
//           conflictAlgorithm: ConflictAlgorithm.replace,
//         );
//       }
//     } catch (e) {
//       print("Error downloading data from Firebase: $e");
//     }
//   }

//   // ===================== INITIALIZATION =====================

//   Future<void> initializeDatabase() async {
//     await database; // Make sure database is created

//     // Start periodic sync
//     Timer.periodic(Duration(minutes: 15), (timer) {
//       syncWithFirebase();
//     });

//     // Start connectivity listener for auto-sync
//     Connectivity().onConnectivityChanged.listen((result) {
//       if (result != ConnectivityResult.none) {
//         // Connected to the internet, try to sync
//         syncWithFirebase();
//       }
//     });

//     // Initial sync
//     syncWithFirebase();
//   }

//   // Close the database when no longer needed
//   Future<void> closeDatabase() async {
//     if (_database != null && _database!.isOpen) {
//       await _database!.close();
//       _database = null;
//     }

//     // Close stream controller
//     if (!_syncController.isClosed) {
//       await _syncController.close();
//     }
//   }
// }
