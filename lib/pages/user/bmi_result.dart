import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/user/recommendation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BMIResult extends StatelessWidget {
  final double height;
  final double weight;
  final String personId;

  const BMIResult({
    super.key,
    required this.height,
    required this.weight,
    required this.personId,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = weight / (height * height);
    String result;
    String bmiCategory;
    Color resultColor;
    String explanation;

    if (bmi < 18.5) {
      result = "Underweight";
      bmiCategory = 'Underweight';
      resultColor = Colors.blue[600]!;
      explanation =
          "You are underweight. Consider consulting with a healthcare professional about a balanced diet to gain healthy weight.";
    } else if (bmi < 24.9) {
      result = "Normal weight";
      bmiCategory = 'Normal weight';
      resultColor = Colors.green[600]!;
      explanation =
          "Your BMI is normal. Maintain a balanced diet and regular physical activity to stay healthy.";
    } else if (bmi < 29.9) {
      result = "Overweight";
      bmiCategory = 'Overweight';
      resultColor = Colors.orange[600]!;
      explanation =
          "You are overweight. Consider making lifestyle changes such as improved diet and increased physical activity.";
    } else {
      result = "Obese";
      bmiCategory = 'Obese';
      resultColor = Colors.red[600]!;
      explanation =
          "Your BMI indicates obesity. It's advisable to consult with a healthcare professional for personalized advice.";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Container(
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your BMI Results',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Body Mass Index measurement based on your height and weight.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your BMI Result',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          result,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          explanation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BMI Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildBmiCategoryItem(
                            'Underweight', '< 18.5', Colors.blue[600]!),
                        _buildBmiCategoryItem(
                            'Normal weight', '18.5 - 24.9', Colors.green[600]!),
                        _buildBmiCategoryItem(
                            'Overweight', '25.0 - 29.9', Colors.orange[600]!),
                        _buildBmiCategoryItem(
                            'Obesity', '≥ 30.0', Colors.red[600]!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildUnderFiveIndicatorsSection(),
                  SizedBox(height: 30,),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SolutionPage(
                              bmiCategory: bmiCategory,
                              personId: personId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3D00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'SEE RECOMMENDATIONS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBmiCategoryItem(String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            range,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnderFiveIndicatorsSection() {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();

    final persons = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('persons')
        .orderBy('timestamp', descending: true)
        .limit(1);

    return FutureBuilder<QuerySnapshot>(
      future: persons.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF0A3D00)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final int? ageYears = (data['age'] as num?)?.toInt();
        if (ageYears == null || ageYears > 5) {
          return const SizedBox.shrink();
        }

        final double? haz = (data['haz'] as num?)?.toDouble();
        final double? waz = (data['waz'] as num?)?.toDouble();
        final double? whz = (data['whz'] as num?)?.toDouble();

        String classify(double? z, {required List<double> thresholds, required List<String> labels}) {
          if (z == null) return 'Not available';
          if (z < thresholds[0]) return labels[0];
          if (z < thresholds[1]) return labels[1];
          if (z < thresholds[2]) return labels[2];
          if (z <= thresholds[3]) return labels[3];
          if (z <= thresholds[4]) return labels[4];
          return labels[5];
        }

        final thresholds = [-3.0, -2.0, -1.0, 1.0, 2.0, 3.0];
        final labels = [
          'Severely low',
          'Moderately low',
          'Mildly low',
          'Normal',
          'High',
          'Very high'
        ];

        final hazCat = classify(haz, thresholds: thresholds, labels: labels);
        final wazCat = classify(waz, thresholds: thresholds, labels: labels);
        final whzCat = classify(whz, thresholds: thresholds, labels: labels);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Under-5 Anthropometric Indicators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildIndicatorRow('HAZ (Stunting)', haz, hazCat),
              const SizedBox(height: 10),
              _buildIndicatorRow('WAZ (Underweight)', waz, wazCat),
              const SizedBox(height: 10),
              _buildIndicatorRow('WHZ (Wasting)', whz, whzCat),
              const SizedBox(height: 8),
              Text(
                'Z-score categories: < -3 severe, -3 to < -2 moderate, -2 to < -1 mild, -1 to 1 normal, 1 to 2 high, > 2 very high',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndicatorRow(String label, double? z, String category) {
    Color color;
    if (z == null) {
      color = Colors.grey;
    } else if (z < -3) {
      color = Colors.red;
    } else if (z < -2) {
      color = Colors.orange;
    } else if (z < -1) {
      color = Colors.amber;
    } else if (z <= 1) {
      color = Colors.green;
    } else if (z <= 2) {
      color = Colors.orangeAccent;
    } else {
      color = Colors.redAccent;
    }
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Text(
          z == null ? '-' : z.toStringAsFixed(2),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontFeatures: []),
        ),
        const SizedBox(width: 12),
        Text(
          category,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
        )
      ],
    );
  }
}
