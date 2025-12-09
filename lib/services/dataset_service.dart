import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PinggangPinoyData {
  final String? id;
  final String ageGroup;
  final String sex;
  final String goFoods;
  final String growFoods;
  final String glowVegetables;
  final String glowFruits;

  PinggangPinoyData({
    this.id,
    required this.ageGroup,
    required this.sex,
    required this.goFoods,
    required this.growFoods,
    required this.glowVegetables,
    required this.glowFruits,
  });

  Map<String, dynamic> toJson() {
    return {
      'ageGroup': ageGroup,
      'sex': sex,
      'goFoods': goFoods,
      'growFoods': growFoods,
      'glowVegetables': glowVegetables,
      'glowFruits': glowFruits,
    };
  }

  factory PinggangPinoyData.fromJson(Map<String, dynamic> json, {String? id}) {
    return PinggangPinoyData(
      id: id,
      ageGroup: (json['ageGroup'] ?? '').toString(),
      sex: (json['sex'] ?? '').toString(),
      goFoods: (json['goFoods'] ?? '').toString(),
      growFoods: (json['growFoods'] ?? '').toString(),
      glowVegetables: (json['glowVegetables'] ?? '').toString(),
      glowFruits: (json['glowFruits'] ?? '').toString(),
    );
  }
}

class DatasetService {
  static List<PinggangPinoyData> _pinggangPinoyData = [];
  static bool _isLoaded = false;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'pinggangPinoyDataset';

  /// Load the Pinggang Pinoy dataset from assets
  static Future<void> loadPinggangPinoyData() async {
    if (_isLoaded) return;

    try {
      // Always start with the bundled base dataset
      final String data = await rootBundle.loadString('assets/datasets/pinggang_pinoy.txt');
      final List<PinggangPinoyData> baseData = _parsePinggangPinoyData(data);

      // Then try to fetch any admin-added records from Firestore
      List<PinggangPinoyData> mergedData = List.from(baseData);
      try {
        final remote = await _fetchRemoteDataset();
        if (remote.isNotEmpty) {
          mergedData = _mergeDataset(baseData, remote);
          print('ℹ️ Loaded ${remote.length} admin-added dataset entries');
        }
      } catch (remoteError) {
        print('⚠️ Unable to load remote dataset, using asset only: $remoteError');
      }

      _pinggangPinoyData = mergedData;
      _isLoaded = true;
      print('✅ Pinggang Pinoy dataset ready: ${_pinggangPinoyData.length} entries');
    } catch (e) {
      print('❌ Error loading Pinggang Pinoy dataset: $e');
      print('🔄 Using fallback dataset...');
      _loadFallbackData();
    }
  }

  /// Fallback dataset in case asset loading fails
  static void _loadFallbackData() {
    _pinggangPinoyData = [
      PinggangPinoyData(
        ageGroup: 'Pregnant Women',
        sex: 'Not specified',
        goFoods: 'Any of the following: 1 & 1/2 cup of cooked rice, 6 pieces of small pandesal, 6 slices of small loaf bread, 1 & 1/2 cup of cooked noodles (ex. Pansit), 1 & 1/2 medium piece of root crop (ex. kamote)',
        growFoods: 'Any of the following: 2 piece (small size) medium variety of fish (ex. Galunggong), 3 slice of large variety of fish (ex. Bangus), 2 pieces of medium chicken leg, 3 serving of lean meat 30g each (ex. Chicken, pork, beef), 3 piece tokwa 6 × 6 × 2 cm each, 1 piece small chicken egg and 1-2 piece of any food items mentioned above',
        glowVegetables: '1-1 & 1/2 cups of cooked vegetables (ex. Malunggay, saluyot, gabi leaves, talinum, ampalaya, kalabasa, carrots, sitaw)',
        glowFruits: 'Any of the following: 1 medium size fruit (ex. Saging, dalanghita, mangga), 1 slice of big fruit (ex. Papaya, pinya, pakwan)',
      ),
      PinggangPinoyData(
        ageGroup: '19-59 years (Adults) - Male',
        sex: 'Male',
        goFoods: 'Any of the following: 1 & 1/2 cup of cooked rice, 6 pieces of small pandesal, 6 slices of small loaf bread, 1 & 1/2 cup of cooked noodles (ex. Pansit), 1 & 1/2 medium piece of root crop (ex. kamote)',
        growFoods: 'Any of the following: 2 piece (small size) medium variety of fish (ex. Galunggong), 2 slice of large variety of fish (ex. Bangus), 2 pieces of chicken leg, 2 serving of lean meat 30g each (ex. Chicken, pork, beef), 2 piece tokwa 6 × 6 × 2 cm each, 1 piece small chicken egg and 1 piece of any food items mentioned above',
        glowVegetables: '1-1 & 1/2 cups of cooked vegetables (ex. Malunggay, saluyot, gabi leaves, talinum, ampalaya, kalabasa, carrots, sitaw)',
        glowFruits: 'Any of the following: 1 medium size fruit (ex. Saging, dalanghita, mangga), 1 slice of big fruit (ex. Papaya, pinya, pakwan)',
      ),
      PinggangPinoyData(
        ageGroup: '19-59 years (Adults) - Female',
        sex: 'Female',
        goFoods: 'Any of the following: 1 & 1/2 cup of cooked rice, 4 pieces of small pandesal, 4 slices of small loaf bread, 1 cup of cooked noodles (ex. Pansit), 1 medium piece of root crop (ex. kamote)',
        growFoods: 'Any of the following: 2 piece (small size) medium variety of fish (ex. Galunggong), 2 slice of large variety of fish (ex. Bangus), 2 pieces of chicken leg, 2 serving of lean meat 30g each (ex. Chicken, pork, beef), 2 piece tokwa 6 × 6 × 2 cm each, 1 piece small chicken egg and 1 piece of any food items mentioned above',
        glowVegetables: '3/4 - 1 cups of cooked vegetables (ex. Malunggay, saluyot, gabi leaves, talinum, ampalaya, kalabasa, carrots, sitaw)',
        glowFruits: 'Any of the following: 1 medium size fruit (ex. Saging, dalanghita, mangga), 1 slice of big fruit (ex. Papaya, pinya, pakwan)',
      ),
      PinggangPinoyData(
        ageGroup: '3-5 years (Kids)',
        sex: 'Male & Female',
        goFoods: 'Any of the following: 1/2 cup of cooked rice, 2 pieces of small pandesal, 2 slices of small loaf bread, 1/2 cup of cooked noodles (ex. Pansit), 1/2 medium piece of root crop (ex. kamote)',
        growFoods: 'Any of the following: 1/2 piece (small size) medium variety of fish (ex. Galunggong), 1/2 slice of large variety of fish (ex. Bangus), 1/2 serving of lean meat 15g (ex. Chicken, pork, beef), 1/2 piece tokwa, 1/2 piece small chicken egg',
        glowVegetables: '1/2 cups of cooked vegetables (ex. Malunggay, saluyot, gabi leaves, talinum, ampalaya, kalabasa, carrots, sitaw)',
        glowFruits: 'Any of the following: 1/2 -1 medium size fruit (ex. Saging, dalanghita, mangga), 1/2 - 1 slice of big fruit (ex. Papaya, pinya, pakwan)',
      ),
    ];
    _isLoaded = true;
    print('✅ Fallback dataset loaded: ${_pinggangPinoyData.length} age groups');
  }

  static Future<List<PinggangPinoyData>> _fetchRemoteDataset() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    return snapshot.docs
        .map((doc) => PinggangPinoyData.fromJson(doc.data(), id: doc.id))
        .toList();
  }

  static List<PinggangPinoyData> _mergeDataset(
    List<PinggangPinoyData> base,
    List<PinggangPinoyData> remote,
  ) {
    final Map<String, PinggangPinoyData> merged = {};
    for (final item in base) {
      merged[_makeKey(item)] = item;
    }
    for (final item in remote) {
      // Admin-added data overrides bundled defaults for the same age group/sex
      merged[_makeKey(item)] = item;
    }
    return merged.values.toList();
  }

  static String _makeKey(PinggangPinoyData data) {
    return '${data.ageGroup.toLowerCase().trim()}|${data.sex.toLowerCase().trim()}';
  }

  /// Parse the raw dataset text into structured data
  static List<PinggangPinoyData> _parsePinggangPinoyData(String rawData) {
    List<PinggangPinoyData> data = [];
    List<String> lines = rawData.split('\n');
    
    String currentAgeGroup = '';
    String currentSex = '';
    String currentGoFoods = '';
    String currentGrowFoods = '';
    String currentGlowVegetables = '';
    String currentGlowFruits = '';

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty) continue;

      // Check if this is an age group header
      if (line.contains('years') || line.contains('Pregnant') || line.contains('Lactating')) {
        // Save previous data if exists
        if (currentAgeGroup.isNotEmpty) {
          data.add(PinggangPinoyData(
            ageGroup: currentAgeGroup,
            sex: currentSex,
            goFoods: currentGoFoods,
            growFoods: currentGrowFoods,
            glowVegetables: currentGlowVegetables,
            glowFruits: currentGlowFruits,
          ));
        }
        
        // Reset for new age group
        currentAgeGroup = line;
        currentSex = '';
        currentGoFoods = '';
        currentGrowFoods = '';
        currentGlowVegetables = '';
        currentGlowFruits = '';
      }
      // Check for sex information
      else if (line.startsWith('Sex:')) {
        currentSex = line.replaceFirst('Sex:', '').trim();
      }
      // Check for Go foods
      else if (line.startsWith('Go (Rice & Alternatives):')) {
        currentGoFoods = line.replaceFirst('Go (Rice & Alternatives):', '').trim();
      }
      // Check for Grow foods
      else if (line.startsWith('Grow (Fish & Alternatives):')) {
        currentGrowFoods = line.replaceFirst('Grow (Fish & Alternatives):', '').trim();
      }
      // Check for Glow vegetables
      else if (line.startsWith('Glow (Vegetables):')) {
        currentGlowVegetables = line.replaceFirst('Glow (Vegetables):', '').trim();
      }
      // Check for Glow fruits
      else if (line.startsWith('Glow (Fruits):')) {
        currentGlowFruits = line.replaceFirst('Glow (Fruits):', '').trim();
      }
    }

    // Add the last entry
    if (currentAgeGroup.isNotEmpty) {
      data.add(PinggangPinoyData(
        ageGroup: currentAgeGroup,
        sex: currentSex,
        goFoods: currentGoFoods,
        growFoods: currentGrowFoods,
        glowVegetables: currentGlowVegetables,
        glowFruits: currentGlowFruits,
      ));
    }

    return data;
  }

  /// Get all loaded Pinggang Pinoy data
  static List<PinggangPinoyData> getPinggangPinoyData() {
    return List.from(_pinggangPinoyData);
  }

  /// Get data for a specific age group and sex
  static PinggangPinoyData? getDataForAgeGroup(String ageGroup, String sex) {
    return _pinggangPinoyData.firstWhere(
      (data) => data.ageGroup.toLowerCase().contains(ageGroup.toLowerCase()) && 
                 data.sex.toLowerCase().contains(sex.toLowerCase()),
      orElse: () => _pinggangPinoyData.first, // fallback to first entry
    );
  }

  /// Get formatted dataset for AI processing
  static String getFormattedDataset() {
    if (_pinggangPinoyData.isEmpty) return '';

    String formatted = 'PINGGANG PINOY NUTRITION GUIDELINES:\n\n';
    
    for (var data in _pinggangPinoyData) {
      formatted += 'Age Group: ${data.ageGroup}\n';
      formatted += 'Sex: ${data.sex}\n';
      formatted += 'Go (Rice & Alternatives): ${data.goFoods}\n';
      formatted += 'Grow (Fish & Alternatives): ${data.growFoods}\n';
      formatted += 'Glow (Vegetables): ${data.glowVegetables}\n';
      formatted += 'Glow (Fruits): ${data.glowFruits}\n\n';
    }

    return formatted;
  }

  /// Get specific food recommendations based on category
  static List<String> getFoodsByCategory(String category) {
    List<String> foods = [];
    
    for (var data in _pinggangPinoyData) {
      switch (category.toLowerCase()) {
        case 'go':
        case 'rice':
        case 'carbohydrates':
          foods.addAll(data.goFoods.split(', '));
          break;
        case 'grow':
        case 'protein':
        case 'fish':
        case 'meat':
          foods.addAll(data.growFoods.split(', '));
          break;
        case 'glow':
        case 'vegetables':
          foods.addAll(data.glowVegetables.split(', '));
          break;
        case 'fruits':
          foods.addAll(data.glowFruits.split(', '));
          break;
      }
    }
    
    return foods.toSet().toList(); // Remove duplicates
  }

  /// Check if dataset is loaded
  static bool isLoaded() {
    return _isLoaded;
  }

  /// Get age groups available in the dataset
  static List<String> getAgeGroups() {
    return _pinggangPinoyData.map((data) => data.ageGroup).toSet().toList();
  }

  /// Get available sexes in the dataset
  static List<String> getSexes() {
    return _pinggangPinoyData.map((data) => data.sex).toSet().toList();
  }

  /// Add a new dataset entry (admin)
  static Future<void> addPinggangPinoyEntry(
    PinggangPinoyData data, {
    String? createdBy,
  }) async {
    await _firestore.collection(_collectionName).add({
      ...data.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      if (createdBy != null) 'createdBy': createdBy,
    });

    // Ensure subsequent AI calls use the fresh dataset
    await refreshDataset();
  }

  /// Stream admin-added dataset entries from Firestore
  static Stream<List<PinggangPinoyData>> streamRemoteDataset() {
    return _firestore
        .collection(_collectionName)
        .orderBy('ageGroup')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PinggangPinoyData.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Force a reload of the dataset (asset + remote)
  static Future<void> refreshDataset() async {
    _isLoaded = false;
    _pinggangPinoyData = [];
    await loadPinggangPinoyData();
  }
}
