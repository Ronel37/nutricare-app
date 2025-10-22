// ignore: unused_import
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dataset_service.dart';

class GeminiService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static GenerativeModel? _model;
  static String? _apiKey;
  static String _currentModelName = 'gemini-1.5-pro-latest';
  static const List<String> _modelFallbackOrder = <String>[
    // Prefer PRO variants first
    'gemini-1.5-pro-latest',
    'gemini-1.5-pro-001',
    // Then try FLASH variants
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-001',
    'gemini-1.5-flash',
    // Additional options
    'gemini-2.0-flash',
    'gemini-1.0-pro',
  ];

  /// Initialize the Gemini service with API key
  static Future<void> initialize({String? apiKey}) async {
    if (apiKey != null) {
      _apiKey = apiKey;
      await _storage.write(key: _apiKeyStorageKey, value: apiKey);
    } else {
      _apiKey = await _storage.read(key: _apiKeyStorageKey);
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          'Gemini API key not found. Please set your API key first.');
    }

    _buildModel(_currentModelName);
    await _ensureWorkingModelSelected();
  }

  /// Set or update the API key
  static Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    await _storage.write(key: _apiKeyStorageKey, value: apiKey);
    _buildModel(_currentModelName);
  }

  static void _buildModel(String modelName) {
    _currentModelName = modelName;
    // Allow larger completions to avoid truncated responses. Use higher limits for 2.0 models.
    final int maxTokens =
        _currentModelName.startsWith('gemini-2.0') ? 8192 : 4096;
    _model = GenerativeModel(
      model: _currentModelName,
      apiKey: _apiKey!,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: maxTokens,
      ),
    );
  }

  static Future<void> _ensureWorkingModelSelected() async {
    if (_model == null) return;
    try {
      await _model!.generateContent([Content.text('ping')]);
      return;
    } catch (e) {
      if (!_looksLikeModelNotFound(e)) return;
    }

    for (final candidate in _modelFallbackOrder) {
      if (candidate == _currentModelName) continue;
      try {
        _buildModel(candidate);
        await _model!.generateContent([Content.text('ping')]);
        return;
      } catch (e) {
        if (!_looksLikeModelNotFound(e)) {
          // Different error (e.g., auth/network); stop probing
          break;
        }
      }
    }
  }

  static bool _looksLikeModelNotFound(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('not found') ||
        message.contains('unsupported') ||
        message.contains('not supported for generatecontent') ||
        message.contains('404');
  }

  static Future<GenerateContentResponse> _generateWithFallback(
    List<Content> content,
  ) async {
    if (_model == null) {
      await initialize();
    }

    // Try current model first
    try {
      return await _model!.generateContent(content);
    } catch (e) {
      if (!_looksLikeModelNotFound(e)) rethrow;
    }

    // Walk through fallbacks
    for (final candidate in _modelFallbackOrder) {
      if (candidate == _currentModelName) continue;
      try {
        _buildModel(candidate);
        return await _model!.generateContent(content);
      } catch (e) {
        if (!_looksLikeModelNotFound(e)) rethrow;
        // else try next candidate
      }
    }

    // If all failed with model-not-found, throw a clearer error
    throw Exception(
      'No supported Gemini model found for generateContent. Tried: ' +
          _modelFallbackOrder.join(', ') +
          '. Please check your API access and model availability.',
    );
  }

  /// Validate API key by attempting a minimal request against available models.
  /// Returns a human-readable status string.
  static Future<String> validateApiKeyAccess(String apiKey) async {
    try {
      await initialize(apiKey: apiKey);
      await _ensureWorkingModelSelected();
      // Try a simple generate call to confirm permissions
      final resp = await _generateWithFallback([Content.text('ping')]);
      final ok = (resp.text ?? '').isNotEmpty;
      return ok
          ? 'OK: API key valid. Using model: ' + _currentModelName
          : 'OK: API key valid. Model responded without text. Model: ' +
              _currentModelName;
    } catch (e) {
      return 'ERROR: ' + e.toString();
    } finally {
      // Do not retain provided key beyond validation flow
      await clearApiKey();
    }
  }

  /// Check if API key is set
  static Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyStorageKey);
    return key != null && key.isNotEmpty;
  }

  /// Get nutrition advice based on user input
  static Future<String> getNutritionAdvice(String userInput) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt = '''
You are a professional nutritionist and health expert. Provide helpful, accurate, and personalized nutrition advice based on the user's input. 

User's question/input: $userInput

Please provide:
1. Clear and practical nutrition advice
2. Specific recommendations when appropriate
3. Health considerations if relevant
4. Keep the response concise but informative (under 200 words)

Remember to always recommend consulting with healthcare professionals for serious health concerns.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate a response. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Get meal suggestions based on dietary preferences
  static Future<String> getMealSuggestions(String dietaryInfo) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt = '''
You are a professional nutritionist. Based on the following dietary information, suggest healthy meal options:

Dietary Information: $dietaryInfo

Please provide:
1. 3-5 meal suggestions with brief descriptions
2. Include main nutrients each meal provides
3. Consider any dietary restrictions mentioned
4. Keep suggestions practical and easy to prepare
5. Format as a numbered list

Keep the response under 300 words.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate meal suggestions. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Get general health and nutrition tips
  static Future<String> getHealthTips() async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt = '''
You are a professional nutritionist. Provide 5 practical health and nutrition tips that are easy to follow for everyday life. 

Format as a numbered list with brief explanations. Focus on:
1. Balanced eating habits
2. Hydration
3. Portion control
4. Nutrient variety
5. Healthy lifestyle practices

Keep each tip concise (1-2 sentences) and the total response under 200 words.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate health tips. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Analyze food item for nutritional content
  static Future<String> analyzeFoodItem(String foodItem) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt = '''
You are a professional nutritionist. Analyze the following food item and provide nutritional information:

Food Item: $foodItem

Please provide:
1. Main nutrients and their approximate amounts
2. Health benefits
3. Potential concerns (if any)
4. Serving size recommendations
5. How it fits into a balanced diet

Keep the response informative but concise (under 250 words).
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not analyze this food item. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// General chat with the AI nutritionist
  static Future<String> chatWithAI(String message) async {
    if (_model == null) {
      await initialize();
    }

    try {
      final prompt = '''
You are a friendly and knowledgeable AI nutritionist assistant. Respond to the user's message in a helpful, professional, and encouraging way. 

User's message: $message

Guidelines:
- Be conversational and supportive
- Provide accurate nutrition information
- Keep responses concise (under 200 words)
- Always recommend consulting healthcare professionals for serious concerns
- Use a warm, encouraging tone
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not process your message. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Get personalized nutrition recommendations based on user profile and Pinggang Pinoy guidelines
  static Future<String> getPersonalizedRecommendations({
    required String ageGroup,
    required String sex,
    String? dietaryPreferences,
    String? healthGoals,
    String? activityLevel,
  }) async {
    if (_model == null) {
      await initialize();
    }

    // Load dataset if not already loaded
    if (!DatasetService.isLoaded()) {
      await DatasetService.loadPinggangPinoyData();
    }

    final dataset = DatasetService.getFormattedDataset();
    final userData = DatasetService.getDataForAgeGroup(ageGroup, sex);

    try {
      final prompt = '''
You are a professional Filipino nutritionist using the Pinggang Pinoy guidelines. Based on the user's profile and the official Pinggang Pinoy dataset, provide personalized nutrition recommendations.

USER PROFILE:
- Age Group: $ageGroup
- Sex: $sex
- Dietary Preferences: ${dietaryPreferences ?? 'Not specified'}
- Health Goals: ${healthGoals ?? 'General health maintenance'}
- Activity Level: ${activityLevel ?? 'Moderate'}

PINGGANG PINOY DATASET:
$dataset

RECOMMENDATIONS FOR THIS USER:
${userData != null ? '''
Based on Pinggang Pinoy guidelines for $ageGroup ($sex):

GO (Rice & Alternatives): ${userData.goFoods}
GROW (Fish & Alternatives): ${userData.growFoods}
GLOW (Vegetables): ${userData.glowVegetables}
GLOW (Fruits): ${userData.glowFruits}
''' : 'Using general Pinggang Pinoy guidelines:'}

Please provide:
1. Specific food recommendations based on Pinggang Pinoy guidelines
2. Portion sizes appropriate for the age group
3. Meal planning suggestions
4. Tips for incorporating Filipino foods
5. Any special considerations for the age group

Format the response as a structured recommendation with clear sections. Keep it practical and culturally appropriate for Filipino families.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate recommendations. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Get meal suggestions based on Pinggang Pinoy guidelines
  static Future<String> getMealSuggestionsFromDataset({
    required String ageGroup,
    required String sex,
    String? mealType,
    String? preferences,
  }) async {
    if (_model == null) {
      await initialize();
    }

    if (!DatasetService.isLoaded()) {
      await DatasetService.loadPinggangPinoyData();
    }

    final userData = DatasetService.getDataForAgeGroup(ageGroup, sex);

    try {
      final prompt = '''
You are a Filipino nutritionist creating meal suggestions based on Pinggang Pinoy guidelines.

USER PROFILE:
- Age Group: $ageGroup
- Sex: $sex
- Meal Type: ${mealType ?? 'Any meal'}
- Preferences: ${preferences ?? 'No specific preferences'}

PINGGANG PINOY GUIDELINES FOR THIS USER:
${userData != null ? '''
GO (Rice & Alternatives): ${userData.goFoods}
GROW (Fish & Alternatives): ${userData.growFoods}
GLOW (Vegetables): ${userData.glowVegetables}
GLOW (Fruits): ${userData.glowFruits}
''' : 'Using general Pinggang Pinoy guidelines'}

Please suggest 3-5 specific meal combinations that:
1. Follow Pinggang Pinoy guidelines
2. Include appropriate portion sizes for the age group
3. Use common Filipino ingredients
4. Are practical and easy to prepare
5. Include specific food items from the guidelines

Format each meal suggestion with:
- Meal name
- Ingredients with portions
- Brief preparation notes
- Nutritional benefits

Keep suggestions culturally appropriate and family-friendly.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate meal suggestions. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Analyze a specific food item against Pinggang Pinoy guidelines
  static Future<String> analyzeFoodAgainstGuidelines({
    required String foodItem,
    required String ageGroup,
    required String sex,
  }) async {
    if (_model == null) {
      await initialize();
    }

    if (!DatasetService.isLoaded()) {
      await DatasetService.loadPinggangPinoyData();
    }

    final userData = DatasetService.getDataForAgeGroup(ageGroup, sex);

    try {
      final prompt = '''
You are a Filipino nutritionist analyzing a food item against Pinggang Pinoy guidelines.

FOOD ITEM TO ANALYZE: $foodItem
USER PROFILE: $ageGroup ($sex)

PINGGANG PINOY GUIDELINES FOR THIS USER:
${userData != null ? '''
GO (Rice & Alternatives): ${userData.goFoods}
GROW (Fish & Alternatives): ${userData.growFoods}
GLOW (Vegetables): ${userData.glowVegetables}
GLOW (Fruits): ${userData.glowFruits}
''' : 'Using general Pinggang Pinoy guidelines'}

Please analyze:
1. Which Pinggang Pinoy category this food belongs to (GO/GROW/GLOW)
2. How it fits into the recommended guidelines
3. Appropriate portion size for the age group
4. Nutritional benefits
5. How to incorporate it into a balanced Filipino meal
6. Any modifications needed for the specific age group

Provide practical advice for Filipino families.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not analyze this food item. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Get daily nutrition tips based on Pinggang Pinoy
  static Future<String> getDailyNutritionTips({
    required String ageGroup,
    required String sex,
  }) async {
    if (_model == null) {
      await initialize();
    }

    if (!DatasetService.isLoaded()) {
      await DatasetService.loadPinggangPinoyData();
    }

    final userData = DatasetService.getDataForAgeGroup(ageGroup, sex);

    try {
      final prompt = '''
You are a Filipino nutritionist providing daily nutrition tips based on Pinggang Pinoy guidelines.

USER PROFILE: $ageGroup ($sex)

PINGGANG PINOY GUIDELINES FOR THIS USER:
${userData != null ? '''
GO (Rice & Alternatives): ${userData.goFoods}
GROW (Fish & Alternatives): ${userData.growFoods}
GLOW (Vegetables): ${userData.glowVegetables}
GLOW (Fruits): ${userData.glowFruits}
''' : 'Using general Pinggang Pinoy guidelines'}

Provide 5 practical daily nutrition tips that:
1. Are specific to the age group and sex
2. Follow Pinggang Pinoy principles
3. Include specific Filipino foods
4. Are easy to implement daily
5. Address common nutrition challenges for this age group

Format as numbered tips with brief explanations. Keep it practical and encouraging.
''';

      final content = [Content.text(prompt)];
      final response = await _generateWithFallback(content);
      return response.text ??
          'Sorry, I could not generate nutrition tips. Please try again.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Clear stored API key
  static Future<void> clearApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
    _apiKey = null;
    _model = null;
  }
}
