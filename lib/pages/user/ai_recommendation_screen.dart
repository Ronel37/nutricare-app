import 'package:flutter/material.dart';
import '../../services/gemini_service.dart';
import '../../services/dataset_service.dart';
import '../../reusable_widget/button.dart';
import '../../reusable_widget/textfield3.dart';

class AIRecommendationScreen extends StatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  State<AIRecommendationScreen> createState() => _AIRecommendationScreenState();
}

class _AIRecommendationScreenState extends State<AIRecommendationScreen> {
  final TextEditingController _dietaryPreferencesController =
      TextEditingController();
  final TextEditingController _healthGoalsController = TextEditingController();
  final TextEditingController _foodItemController = TextEditingController();

  String _selectedAgeGroup = '19-59 years (Adults) - Male';
  String _selectedSex = 'Male';
  String _selectedMealType = 'Any meal';
  String _selectedRecommendationType = 'personalized';

  bool _isLoading = false;
  String _aiResponse = '';
  bool _hasApiKey = false;

  final List<String> _ageGroups = [
    'Pregnant Women',
    'Lactating Women',
    '3-5 years (Kids)',
    '6-9 years (Kids)',
    '10-12 years (Kids)',
    '13-18 years (Teens) - Male',
    '13-18 years (Teens) - Female',
    '19-59 years (Adults) - Male',
    '19-59 years (Adults) - Female',
    '60 years old and above - Male',
    '61 years old and above - Female',
  ];

  final List<String> _mealTypes = [
    'Any meal',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  // ignore: unused_field
  final List<String> _recommendationTypes = [
    'personalized',
    'meal_suggestions',
    'food_analysis',
    'daily_tips',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatus();
    _loadDataset();
    _autoSetupAPIKey();
  }

  Future<void> _autoSetupAPIKey() async {
    // Auto-setup the API key if not already set
    if (!_hasApiKey) {
      try {
        await GeminiService.setApiKey(
            'AIzaSyBKuk_SL9FBGU2n4Jx3T9BAGHS3A5xxlKQ');
        setState(() {
          _hasApiKey = true;
        });
      } catch (e) {
        print('Auto-setup failed: $e');
      }
    }
  }

  Future<void> _checkApiKeyStatus() async {
    final hasKey = await GeminiService.hasApiKey();
    setState(() {
      _hasApiKey = hasKey;
    });
  }

  Future<void> _loadDataset() async {
    await DatasetService.loadPinggangPinoyData();
  }

  Future<void> _getRecommendations() async {
    if (!_hasApiKey) {
      _showSnackBar(
          'AI features are being set up. Please wait a moment and try again.',
          Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResponse = '';
    });

    try {
      String response = '';

      switch (_selectedRecommendationType) {
        case 'personalized':
          response = await GeminiService.getPersonalizedRecommendations(
            ageGroup: _selectedAgeGroup,
            sex: _selectedSex,
            dietaryPreferences:
                _dietaryPreferencesController.text.trim().isEmpty
                    ? null
                    : _dietaryPreferencesController.text.trim(),
            healthGoals: _healthGoalsController.text.trim().isEmpty
                ? null
                : _healthGoalsController.text.trim(),
          );
          break;
        case 'meal_suggestions':
          response = await GeminiService.getMealSuggestionsFromDataset(
            ageGroup: _selectedAgeGroup,
            sex: _selectedSex,
            mealType:
                _selectedMealType == 'Any meal' ? null : _selectedMealType,
            preferences: _dietaryPreferencesController.text.trim().isEmpty
                ? null
                : _dietaryPreferencesController.text.trim(),
          );
          break;
        case 'food_analysis':
          if (_foodItemController.text.trim().isEmpty) {
            _showSnackBar('Please enter a food item to analyze', Colors.red);
            setState(() {
              _isLoading = false;
            });
            return;
          }
          response = await GeminiService.analyzeFoodAgainstGuidelines(
            foodItem: _foodItemController.text.trim(),
            ageGroup: _selectedAgeGroup,
            sex: _selectedSex,
          );
          break;
        case 'daily_tips':
          response = await GeminiService.getDailyNutritionTips(
            ageGroup: _selectedAgeGroup,
            sex: _selectedSex,
          );
          break;
      }

      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _aiResponse = 'Error: ${e.toString()}';
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Recommendations',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Status (simplified)
              if (!_hasApiKey)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade400),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Setting up AI features...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_hasApiKey) const SizedBox(height: 20),

              // User Profile Section
              Container(
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
                      color: const Color(0xFF0A3D00).withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'User Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Age Group Dropdown
                      const Text('Age Group:',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedAgeGroup,
                        dropdownColor: Colors.grey[900],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[700]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.grey[850],
                        ),
                        items: _ageGroups.map((String ageGroup) {
                          return DropdownMenuItem<String>(
                            value: ageGroup,
                            child: Text(ageGroup,
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAgeGroup = newValue!;
                            // Update sex based on age group
                            if (newValue.contains('Male')) {
                              _selectedSex = 'Male';
                            } else if (newValue.contains('Female')) {
                              _selectedSex = 'Female';
                            } else if (newValue.contains('Kids') ||
                                newValue.contains('Pregnant') ||
                                newValue.contains('Lactating')) {
                              _selectedSex = 'Not specified';
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sex Display
                      Text('Sex: $_selectedSex',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      const SizedBox(height: 16),

                      // Dietary Preferences
                      TextFieldInpute3(
                        textEditingController: _dietaryPreferencesController,
                        labelText: 'Dietary preferences (optional)',
                      ),
                      const SizedBox(height: 16),

                      // Health Goals
                      TextFieldInpute3(
                        textEditingController: _healthGoalsController,
                        labelText: 'Health goals (optional)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recommendation Type Section
              Container(
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
                      color: const Color(0xFF0A3D00).withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Recommendation Type',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Recommendation Type Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildRecommendationTypeButton(
                              'Personalized Recommendations', 'personalized'),
                          _buildRecommendationTypeButton(
                              'Meal Suggestions', 'meal_suggestions'),
                          _buildRecommendationTypeButton(
                              'Food Analysis', 'food_analysis'),
                          _buildRecommendationTypeButton(
                              'Daily Tips', 'daily_tips'),
                        ],
                      ),

                      // Additional fields based on recommendation type
                      if (_selectedRecommendationType ==
                          'meal_suggestions') ...[
                        const SizedBox(height: 16),
                        const Text('Meal Type:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedMealType,
                          dropdownColor: Colors.grey[900],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: Colors.grey[850],
                          ),
                          items: _mealTypes.map((String mealType) {
                            return DropdownMenuItem<String>(
                              value: mealType,
                              child: Text(mealType,
                                  style: const TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMealType = newValue!;
                            });
                          },
                        ),
                      ],

                      if (_selectedRecommendationType == 'food_analysis') ...[
                        const SizedBox(height: 16),
                        TextFieldInpute3(
                          textEditingController: _foodItemController,
                          labelText: 'Enter food item to analyze',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Generate Button
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0A3D00)),
                      ),
                    )
                  : MyButton(
                      text: 'Generate AI Recommendations',
                      onTab: _hasApiKey
                          ? _getRecommendations
                          : () {
                              _showSnackBar(
                                  'AI features are being set up. Please wait a moment and try again.',
                                  Colors.orange);
                            },
                    ),
              const SizedBox(height: 20),

              // AI Response Section
              if (_aiResponse.isNotEmpty) ...[
                Container(
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
                        color: const Color(0xFF0A3D00).withOpacity(0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.psychology, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'AI Recommendations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFormattedContentDark(context, _aiResponse),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Styled formatter for dark NutriCare theme
  Widget _buildFormattedContentDark(BuildContext context, String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      if (RegExp(r'^\d+\.').hasMatch(line)) {
        widgets.add(_buildNumberedItemDark(context, line));
      } else if (RegExp(r'^[-*•]').hasMatch(line)) {
        widgets.add(_buildBulletItemDark(context, line));
      } else if (line.startsWith('#') ||
          (line.toUpperCase() == line && line.length > 3)) {
        widgets
            .add(_buildHeaderDark(context, line.replaceFirst('#', '').trim()));
      } else if (_containsSpecialKeywords(line)) {
        widgets.add(_buildNoteDark(context, line));
      } else {
        widgets.add(_buildRichTextDark(context, line));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildNumberedItemDark(BuildContext context, String line) {
    final number = RegExp(r'^\d+').firstMatch(line)?.group(0) ?? '';
    final text = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: const Color(0xFF0A3D00),
              borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildRichTextDark(context, text)),
      ]),
    );
  }

  Widget _buildBulletItemDark(BuildContext context, String line) {
    final text = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
                color: Colors.white70, shape: BoxShape.circle)),
        Expanded(child: _buildRichTextDark(context, text)),
      ]),
    );
  }

  Widget _buildHeaderDark(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(children: [
        const Icon(Icons.star, color: Color(0xFF0A3D00), size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _buildNoteDark(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF0A3D00).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF0A3D00).withOpacity(0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.lightbulb_outline, color: Color(0xFF0A3D00), size: 18),
        const SizedBox(width: 8),
        Expanded(child: _buildRichTextDark(context, text)),
      ]),
    );
  }

  Widget _buildRichTextDark(BuildContext context, String line) {
    // Auto-bold "Label: value" and support **bold** segments
    if (line.contains(':') && !line.startsWith('-') && !line.startsWith('*')) {
      final idx = line.indexOf(':');
      if (idx > 0 && idx < line.length - 1) {
        line =
            '**${line.substring(0, idx).trim()}**: ${line.substring(idx + 1).trim()}';
      }
    }

    final parts = line.split('**');
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
          fontSize: 16,
          height: 1.6,
        ),
      ));
      bold = !bold;
    }
    return Text.rich(TextSpan(children: spans));
  }

  bool _containsSpecialKeywords(String text) {
    final keywords = [
      'tip:',
      'note:',
      'important:',
      'remember:',
      'warning:',
      'caution:',
      'benefit:',
      'advantage:',
      'recommendation:',
      'suggestion:',
      'key:',
      'essential:',
      'crucial:',
      'vital:'
    ];
    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }

  Widget _buildRecommendationTypeButton(String label, String value) {
    final isSelected = _selectedRecommendationType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecommendationType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A3D00) : Colors.grey[850],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A3D00) : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dietaryPreferencesController.dispose();
    _healthGoalsController.dispose();
    _foodItemController.dispose();
    super.dispose();
  }
}
