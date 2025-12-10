// ignore_for_file: unused_local_variable
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/user/home_screen.dart';
import 'package:nutricare_app/utils/responsive_util.dart';
import 'package:nutricare_app/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SolutionPage extends StatefulWidget {
  final String bmiCategory;
  final String personId;

  const SolutionPage({
    super.key,
    required this.bmiCategory,
    required this.personId,
  });

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  
  // AI recommendation state
  String? _aiRecommendations;
  String? _aiMealSuggestions;
  String? _aiNutritionTips;
  bool _isLoadingAI = false;
  double _accuracyScore = 0.0; // 0.0 - 1.0 estimated confidence
  String? _userAgeGroup;
  String? _userSex;
  String? _userDietary; // combined selected + custom
  String? _userHealthGoal; // combined selected + custom

  @override
  void initState() {
    super.initState();
    _loadUserDataAndGenerateAI();
  }

  Future<void> _loadUserDataAndGenerateAI() async {
    try {
      // Load the specific person that was just added so we can tie AI output to them
      final personSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(widget.personId)
          .get();

      if (personSnap.exists) {
        final data = personSnap.data() as Map<String, dynamic>;
        final age = data['age'] as int?;
        final sex = data['sex'] as String?;
        final dietaryPreference = data['dietaryPreference'] as String?;
        final healthGoal = data['healthGoal'] as String?;
        final dietaryPreferenceText = data['dietaryPreferenceText'] as String?;
        final healthGoalsText = data['healthGoalsText'] as String?;
        
        // Determine age group based on age
        if (age != null) {
          if (age >= 3 && age <= 5) {
            _userAgeGroup = '3-5 years (Kids)';
          } else if (age >= 19 && age <= 59) {
            _userAgeGroup = '19-59 years (Adults)';
          } else if (age >= 60) {
            _userAgeGroup = '60+ years (Elderly)';
          } else {
            _userAgeGroup = '19-59 years (Adults)'; // Default fallback
          }
        }
        
        // Use the actual sex from the form, with fallback
        _userSex = sex ?? 'Male';
        
        // Build combined dietary and goal strings for display and AI
        final dietaryParts = <String>[];
        if (dietaryPreference != null && dietaryPreference.trim().isNotEmpty) dietaryParts.add(dietaryPreference.trim());
        if (dietaryPreferenceText != null && dietaryPreferenceText.trim().isNotEmpty) dietaryParts.add(dietaryPreferenceText.trim());
        _userDietary = dietaryParts.isNotEmpty ? dietaryParts.join(', ') : null;

        final goalParts = <String>[];
        if (healthGoal != null && healthGoal.trim().isNotEmpty) goalParts.add(healthGoal.trim());
        if (healthGoalsText != null && healthGoalsText.trim().isNotEmpty) goalParts.add(healthGoalsText.trim());
        _userHealthGoal = goalParts.isNotEmpty ? goalParts.join(', ') : null;
        
        // Generate AI recommendations
        await _generateAIRecommendations();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _generateAIRecommendations() async {
    if (_userAgeGroup == null || _userSex == null) return;
    
    setState(() {
      _isLoadingAI = true;
      _accuracyScore = 0.0;
    });

    try {
      // Initialize Gemini service
      await GeminiService.initialize();
      
      // Get user data for more personalized recommendations
      final personSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(widget.personId)
          .get();
      
      String? dietaryPreference;
      String? healthGoal;
      
      if (personSnap.exists) {
        final data = personSnap.data() as Map<String, dynamic>;
        dietaryPreference = data['dietaryPreference'] as String?;
        healthGoal = data['healthGoal'] as String?;
        final dietaryPreferenceText = data['dietaryPreferenceText'] as String?;
        final healthGoalsText = data['healthGoalsText'] as String?;
        // combine with custom texts if any
        final dietaryParts = <String>[];
        if (dietaryPreference != null && dietaryPreference.trim().isNotEmpty) dietaryParts.add(dietaryPreference.trim());
        if (dietaryPreferenceText != null && dietaryPreferenceText.trim().isNotEmpty) dietaryParts.add(dietaryPreferenceText.trim());
        dietaryPreference = dietaryParts.isNotEmpty ? dietaryParts.join(', ') : null;

        final goalParts = <String>[];
        if (healthGoal != null && healthGoal.trim().isNotEmpty) goalParts.add(healthGoal.trim());
        if (healthGoalsText != null && healthGoalsText.trim().isNotEmpty) goalParts.add(healthGoalsText.trim());
        healthGoal = goalParts.isNotEmpty ? goalParts.join(', ') : null;
      }
      final accuracyScore = _calculateAccuracyScore(
        dietaryPreference: dietaryPreference,
        healthGoal: healthGoal,
      );
      
      // Generate personalized recommendations
      final recommendations = await GeminiService.getPersonalizedRecommendations(
        ageGroup: _userAgeGroup!,
        sex: _userSex!,
        dietaryPreferences: dietaryPreference,
        healthGoals: healthGoal ?? 'General health maintenance',
        activityLevel: 'Moderate',
      );
      
      // Generate meal suggestions
      final mealSuggestions = await GeminiService.getMealSuggestionsFromDataset(
        ageGroup: _userAgeGroup!,
        sex: _userSex!,
        mealType: 'All meals',
        preferences: dietaryPreference ?? 'Filipino cuisine',
      );
      
      // Generate daily nutrition tips
      final nutritionTips = await GeminiService.getDailyNutritionTips(
        ageGroup: _userAgeGroup!,
        sex: _userSex!,
      );

      // Persist the personalized recommendation (and extras) to the person record
      await _saveRecommendationsToPerson(
        personalRecommendation: recommendations,
        mealSuggestions: mealSuggestions,
        nutritionTips: nutritionTips,
      );

      setState(() {
        _aiRecommendations = recommendations;
        _aiMealSuggestions = mealSuggestions;
        _aiNutritionTips = nutritionTips;
        _isLoadingAI = false;
        _accuracyScore = accuracyScore;
      });
    } catch (e) {
      print('Error generating AI recommendations: $e');
      setState(() {
        _isLoadingAI = false;
        _accuracyScore = 0.0;
      });
    }
  }

  Future<void> _saveRecommendationsToPerson({
    required String personalRecommendation,
    String? mealSuggestions,
    String? nutritionTips,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(widget.personId)
          .update({
        'aiPersonalRecommendation': personalRecommendation,
        if (mealSuggestions != null) 'aiMealSuggestions': mealSuggestions,
        if (nutritionTips != null) 'aiNutritionTips': nutritionTips,
        'aiRecommendationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Keep UI responsive even if persistence fails
      print('Error saving AI recommendations: $e');
    }
  }

  Color getBmiCategoryColor(String bmiCategory) {
    switch (bmiCategory) {
      case 'Underweight':
        return Colors.blue.shade700;
      case 'Normal weight':
        return Colors.green;
      case 'Overweight':
        return Colors.orange.shade700;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = ResponsiveUtil.getHorizontalPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Recommendations',
          style: TextStyle(
            color: Colors.white, 
            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 20)
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
        child: ListView(
          padding: EdgeInsets.all(padding),
          children: [
            // Header section
            Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtil.getVerticalPadding(context) * 0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalized Recommendations',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01),
                  Row(
                    children: [
                      Text(
                        'Based on your BMI category: ',
                        style: TextStyle(
                          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                          color: Colors.grey[400],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtil.screenWidth(context) * 0.03,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getBmiCategoryColor(widget.bmiCategory)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: getBmiCategoryColor(widget.bmiCategory),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.bmiCategory,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),

            // AI-Powered Recommendations Section
            _buildAIRecommendationsSection(context),

            SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.03),

            // Back to Home Button
            Container(
              margin: EdgeInsets.symmetric(vertical: ResponsiveUtil.screenHeight(context) * 0.02),
              width: double.infinity,
              height: ResponsiveUtil.isTablet(context) ? 65 : 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Colors.green.shade800,
                      width: 1,
                    ),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: Colors.white,
                      size: ResponsiveUtil.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.02),
                    Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIRecommendationsSection(BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Section header
                  Padding(
          padding: EdgeInsets.symmetric(vertical: ResponsiveUtil.getVerticalPadding(context) * 0.8),
                    child: Row(
                      children: [
                        Icon(
                Icons.psychology,
                color: Colors.white,
                size: ResponsiveUtil.getResponsiveIconSize(context, 24),
              ),
              SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.02),
              Expanded(
                child: Text(
                  'AI-Powered Recommendations',
                  style: TextStyle(
                            color: Colors.white,
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 22),
                            fontWeight: FontWeight.bold,
                          ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                        ),
                        ),
              SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.01),
                        Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtil.screenWidth(context) * 0.015,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue,
                    width: 1,
                  ),
                          ),
                          child: Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.blue,
                              fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider for visual separation
                  Divider(color: Colors.grey[800]),

        // AI Recommendations Content
        if (_isLoadingAI)
          Container(
            padding: EdgeInsets.all(ResponsiveUtil.screenWidth(context) * 0.05),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: const Color(0xFF0A3D00),
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
                  Text(
                    'Generating personalized recommendations...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_aiRecommendations != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_userAgeGroup != null || _userSex != null || _userDietary != null || _userHealthGoal != null)
                Padding(
                  padding: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.01),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_userSex != null)
                        _buildTagChip(context, label: 'Sex', value: _userSex!),
                      if (_userAgeGroup != null)
                        _buildTagChip(context, label: 'Age', value: _userAgeGroup!),
                      if (_userDietary != null)
                        _buildTagChip(context, label: 'Diet', value: _userDietary!),
                      if (_userHealthGoal != null)
                        _buildTagChip(context, label: 'Goal', value: _userHealthGoal!),
                    ],
                  ),
                ),
              _buildAccuracyBadge(context),
              SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
              // Personalized Recommendations
              _buildAICard(
                context,
                title: 'Personalized Nutrition Plan',
                content: _aiRecommendations!,
                icon: Icons.assignment,
                color: Colors.green,
              ),
              
              SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
              
              // Meal Suggestions
              if (_aiMealSuggestions != null)
                _buildAICard(
                  context,
                  title: 'AI Meal Suggestions',
                  content: _aiMealSuggestions!,
                  icon: Icons.restaurant_menu,
                  color: Colors.orange,
                ),
              
              SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
              
              // Daily Nutrition Tips
              if (_aiNutritionTips != null)
                _buildAICard(
                  context,
                  title: 'Daily Nutrition Tips',
                  content: _aiNutritionTips!,
                  icon: Icons.lightbulb,
                  color: Colors.purple,
                ),
            ],
          )
        else
          Container(
            padding: EdgeInsets.all(ResponsiveUtil.screenWidth(context) * 0.05),
            child: Center(
            child: Column(
              children: [
                Icon(
                    Icons.error_outline,
                  size: 64,
                  color: Colors.grey[600],
                ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
                Text(
                    'Unable to generate AI recommendations',
                  style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                    color: Colors.grey[400],
                  ),
                ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01),
                  Text(
                    'Please check your internet connection and try again',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.02),
                  ElevatedButton(
                    onPressed: () {
                      _generateAIRecommendations();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A3D00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  ),
                ),
              ],
            ),
            ),
          ),
      ],
    );
  }

  Widget _buildAICard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
                  padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
              children: [
            // Header
                          Row(
                  children: [
                              Icon(
                  icon,
                  color: color,
                  size: ResponsiveUtil.getResponsiveIconSize(context, 20),
                ),
                SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.02),
                Expanded(
                  child: Text(
                    title,
                                  style: TextStyle(
                                color: Colors.white,
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 18),
                                    fontWeight: FontWeight.bold,
                                  ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.01),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtil.screenWidth(context) * 0.02,
                    vertical: 4,
                  ),
                        decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                      child: Text(
                    'AI',
                    style: TextStyle(
                      color: color,
                          fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 10),
                    ),
                      ),
                    ),
                  ],
                ),

            SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01),
            
            // Divider
            Divider(color: Colors.grey[700]),
            
            SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01),
            
            // Content
            _buildFormattedContent(context, content),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyBadge(BuildContext context) {
    final percent = (_accuracyScore * 100).clamp(0, 100).toStringAsFixed(0);
    const Color accent = Color(0xFF2CE674); // brighter green accent

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, color: accent, size: 18),
            SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.01),
            Text(
              'Estimated accuracy: $percent%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.008),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _accuracyScore.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }

  double _calculateAccuracyScore({
    String? dietaryPreference,
    String? healthGoal,
  }) {
    double score = 0.72; // base confidence using Pinggang Pinoy dataset

    if ((dietaryPreference ?? '').trim().isNotEmpty) {
      score += 0.08;
    }
    if ((healthGoal ?? '').trim().isNotEmpty) {
      score += 0.08;
    }
    if (_userAgeGroup != null) {
      score += 0.06;
    }
    if (_userSex != null) {
      score += 0.06;
    }

    if (score > 0.98) score = 0.98;
    if (score < 0.6) score = 0.6;
    return score;
  }

  Widget _buildFormattedContent(BuildContext context, String content) {
    // Split content into lines and process each line
    List<String> lines = content.split('\n');
    List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01));
        continue;
      }

      // Check if line is a numbered list item (1., 2., etc.)
      if (RegExp(r'^\d+\.').hasMatch(line)) {
        widgets.add(_buildNumberedListItem(context, line, i));
      }
      // Check if line is a bullet point (-, *, •)
      else if (RegExp(r'^[-*•]').hasMatch(line)) {
        widgets.add(_buildBulletListItem(context, line));
      }
      // Check if line is a header (starts with # or is in caps)
      else if (line.startsWith('#') || line.toUpperCase() == line && line.length > 3) {
        widgets.add(_buildHeaderText(context, line));
      }
      // Check if line contains special keywords for styling
      else if (_containsSpecialKeywords(line)) {
        widgets.add(_buildSpecialText(context, line));
      }
      // Regular paragraph
      else {
        widgets.add(_buildRichTextParagraph(context, line));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildNumberedListItem(BuildContext context, String line, int index) {
    String number = RegExp(r'^\d+').firstMatch(line)?.group(0) ?? '';
    String text = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.008),
      child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                          Container(
            width: 24,
            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A3D00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                                  style: TextStyle(
                                    color: Colors.white,
                  fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
          SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.02),
          Expanded(
                        child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                height: 1.5,
              ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildBulletListItem(BuildContext context, String line) {
    String text = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
    
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.008),
      child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(
              top: ResponsiveUtil.screenHeight(context) * 0.006,
              right: ResponsiveUtil.screenWidth(context) * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
                        style: TextStyle(
                          color: Colors.grey[300],
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context, String line) {
    String text = line.replaceFirst('#', '').trim();
    
    return Container(
      margin: EdgeInsets.only(
        top: ResponsiveUtil.screenHeight(context) * 0.01,
        bottom: ResponsiveUtil.screenHeight(context) * 0.008,
                            ),
                            child: Row(
                              children: [
          Icon(
            Icons.star,
            color: const Color(0xFF0A3D00),
            size: ResponsiveUtil.getResponsiveIconSize(context, 16),
          ),
          SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.01),
          Expanded(
                        child: Text(
              text,
                                  style: TextStyle(
                            color: Colors.white,
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                height: 1.3,
                                  ),
                        ),
                      ),
                    ],
                  ),
    );
  }

  Widget _buildSpecialText(BuildContext context, String line) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.008),
      padding: EdgeInsets.all(ResponsiveUtil.screenWidth(context) * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF0A3D00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0A3D00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          Icon(
            Icons.lightbulb_outline,
            color: const Color(0xFF0A3D00),
            size: ResponsiveUtil.getResponsiveIconSize(context, 16),
          ),
          SizedBox(width: ResponsiveUtil.screenWidth(context) * 0.02),
          Expanded(
                          child: Text(
              line,
              style: TextStyle(
                color: Colors.grey[200],
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRegularText(BuildContext context, String line) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.008),
      child: Text(
        line,
                        style: TextStyle(
                          color: Colors.grey[300],
          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
          height: 1.5,
        ),
      ),
    );
  }

  bool _containsSpecialKeywords(String text) {
    List<String> keywords = [
      'tip:', 'note:', 'important:', 'remember:', 'warning:', 'caution:',
      'benefit:', 'advantage:', 'recommendation:', 'suggestion:',
      'key:', 'essential:', 'crucial:', 'vital:'
    ];
    
    String lowerText = text.toLowerCase();
    return keywords.any((keyword) => lowerText.contains(keyword));
  }

  // Renders a small tag-like chip for profile attributes
  Widget _buildTagChip(BuildContext context, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
        color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
            '$label: ',
                                  style: TextStyle(
              color: Colors.grey[300],
                                    fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 12),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                                  color: Colors.white,
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 12),
                                ),
              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
    );
  }

  // Parses **bold** segments and label: value emphasis
  Widget _buildRichTextParagraph(BuildContext context, String line) {
    // If the line contains a label like "Title: content", bold the label
    if (line.contains(':') && !line.startsWith('-') && !line.startsWith('*')) {
      final idx = line.indexOf(':');
      if (idx > 0 && idx < line.length - 1) {
        final label = line.substring(0, idx).trim();
        final rest = line.substring(idx + 1).trim();
        return _buildRichText(context, '**$label**: $rest');
      }
    }
    return _buildRichText(context, line);
  }

  Widget _buildRichText(BuildContext context, String text) {
    // Split by ** to toggle bold segments
    final parts = text.split('**');
    final spans = <TextSpan>[];
    bool bold = false;
    for (final part in parts) {
      if (part.isEmpty) {
        bold = !bold;
        continue;
      }
      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          color: Colors.grey[300],
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
          height: 1.6,
        ),
      ));
      bold = !bold;
    }

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtil.screenHeight(context) * 0.008),
      child: Text.rich(TextSpan(children: spans)),
    );
  }
}



