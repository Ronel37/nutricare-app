// ignore: unused_import
import 'dart:convert';
import 'package:flutter/services.dart';

class PinggangPinoyData {
  final String ageGroup;
  final String sex;
  final String goFoods;
  final String growFoods;
  final String glowVegetables;
  final String glowFruits;

  PinggangPinoyData({
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
}

class DatasetService {
  static List<PinggangPinoyData> _pinggangPinoyData = [];
  static bool _isLoaded = false;

  /// Load the Pinggang Pinoy dataset from assets
  static Future<void> loadPinggangPinoyData() async {
    if (_isLoaded) return;

    try {
      final String data = await rootBundle.loadString('assets/datasets/pinggang_pinoy.txt');
      _pinggangPinoyData = _parsePinggangPinoyData(data);
      _isLoaded = true;
      print('✅ Pinggang Pinoy dataset loaded successfully: ${_pinggangPinoyData.length} age groups');
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
}
