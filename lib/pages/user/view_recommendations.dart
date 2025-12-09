import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/user/recommendation.dart';

class PersonRecommendationsView extends StatelessWidget {
  final String personId;
  final String personName;
  final String? bmiCategory;

  const PersonRecommendationsView({
    super.key,
    required this.personId,
    required this.personName,
    this.bmiCategory,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final personDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('persons')
        .doc(personId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$personName Recommendations',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: personDoc.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0A3D00)),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildEmptyState(
                context,
                message: 'This person record could not be found.',
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final personalRec = data['aiPersonalRecommendation'] as String?;
            final mealSuggestions = data['aiMealSuggestions'] as String?;
            final nutritionTips = data['aiNutritionTips'] as String?;
            final updatedAt = data['aiRecommendationUpdatedAt'] as Timestamp?;

            final combinedDiet = _combineText(
              data['dietaryPreference'] as String?,
              data['dietaryPreferenceText'] as String?,
            );
            final combinedGoal = _combineText(
              data['healthGoal'] as String?,
              data['healthGoalsText'] as String?,
            );

            final hasAnyRecommendations =
                personalRec != null || mealSuggestions != null || nutritionTips != null;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPersonHeader(
                      name: personName,
                      bmi: data['bmi'] as num?,
                      bmiCategory: data['bmiCategory'] as String? ?? bmiCategory,
                      age: data['age'] as num?,
                      sex: data['sex'] as String?,
                      diet: combinedDiet,
                      goal: combinedGoal,
                      updatedAt: updatedAt,
                    ),
                    const SizedBox(height: 16),
                    if (!hasAnyRecommendations)
                      _buildEmptyState(
                        context,
                        message:
                            'No personal recommendations have been recorded for this person yet.',
                        actionLabel: 'Generate recommendations',
                        onAction: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SolutionPage(
                                bmiCategory:
                                    (data['bmiCategory'] as String?) ?? 'Normal weight',
                                personId: personId,
                              ),
                            ),
                          );
                        },
                      )
                    else ...[
                      if (personalRec != null)
                        _buildRecommendationCard(
                          title: 'Personalized Recommendation',
                          content: personalRec,
                          icon: Icons.psychology,
                          color: Colors.green,
                        ),
                      if (mealSuggestions != null)
                        _buildRecommendationCard(
                          title: 'Meal Suggestions',
                          content: mealSuggestions,
                          icon: Icons.restaurant_menu,
                          color: Colors.orange,
                        ),
                      if (nutritionTips != null)
                        _buildRecommendationCard(
                          title: 'Daily Nutrition Tips',
                          content: nutritionTips,
                          icon: Icons.lightbulb,
                          color: Colors.purple,
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonHeader({
    required String name,
    required num? bmi,
    required String? bmiCategory,
    required num? age,
    required String? sex,
    required String? diet,
    required String? goal,
    required Timestamp? updatedAt,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (sex != null && sex.isNotEmpty)
                _buildChip(icon: Icons.person_outline, label: 'Sex', value: sex),
              if (age != null)
                _buildChip(
                    icon: Icons.cake, label: 'Age', value: '${age.toStringAsFixed(0)} yrs'),
              if (bmi != null && bmiCategory != null)
                _buildChip(
                  icon: Icons.monitor_weight,
                  label: 'BMI',
                  value: '${bmi.toStringAsFixed(1)} ($bmiCategory)',
                ),
              if (diet != null && diet.isNotEmpty)
                _buildChip(icon: Icons.restaurant, label: 'Diet', value: diet),
              if (goal != null && goal.isNotEmpty)
                _buildChip(icon: Icons.flag, label: 'Goal', value: goal),
            ],
          ),
          if (updatedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Updated ${_formatTimestamp(updatedAt)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
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
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_alt, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A3D00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _combineText(String? primary, String? secondary) {
    final parts = <String>[];
    if (primary != null && primary.trim().isNotEmpty) {
      parts.add(primary.trim());
    }
    if (secondary != null && secondary.trim().isNotEmpty) {
      parts.add(secondary.trim());
    }
    return parts.join(', ');
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}

