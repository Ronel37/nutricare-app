import 'package:flutter/material.dart';
import 'dart:math';

import 'package:nutricare_app/pages/user/converter.dart';
import 'package:nutricare_app/utils/responsive_util.dart';

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({Key? key}) : super(key: key);

  @override
  _BMICalculatorPageState createState() => _BMICalculatorPageState();
}

class _BMICalculatorPageState extends State<BMICalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double _bmi = 0;
  String _bmiCategory = '';
  Color _bmiColor = Colors.white;
  bool _hasCalculated = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _resetFields() {
    setState(() {
      _heightController.clear();
      _weightController.clear();
      _bmi = 0;
      _bmiCategory = '';
      _bmiColor = Colors.white;
      _hasCalculated = false;
    });
  }

  void _calculateBMI() {
    if (_formKey.currentState!.validate()) {
      double height =
          double.parse(_heightController.text); 
      double weight = double.parse(_weightController.text);
      double bmi = weight / pow(height, 2); 

      setState(() {
        _bmi = bmi;
        _hasCalculated = true;

        if (bmi < 18.5) {
          _bmiCategory = 'Underweight';
          _bmiColor = Colors.blue[600]!;
        } else if (bmi >= 18.5 && bmi < 25) {
          _bmiCategory = 'Normal';
          _bmiColor = Colors.green[600]!;
        } else if (bmi >= 25 && bmi < 30) {
          _bmiCategory = 'Overweight';
          _bmiColor = Colors.orange[600]!;
        } else {
          _bmiCategory = 'Obese';
          _bmiColor = Colors.red[600]!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BMI Calculator',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 20),
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context)),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculate Your BMI',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Body Mass Index (BMI) is a measurement of body fat based on height and weight.',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                        color: Colors.grey[400],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MetricConverterPage()),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            size: ResponsiveUtil.getResponsiveIconSize(context, 20),
                            color: Colors.white,
                          ),
                          SizedBox(width: 2,),
                          Text(
                            'Metric Converter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.025),
                    Text(
                      'Height (m)',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _heightController,
                      hintText: 'Enter your height in Meters',
                      icon: Icons.height,
                    ),
                    SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.025),
                    Text(
                      'Weight (kg)',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: _weightController,
                      hintText: 'Enter your weight in kilograms',
                      icon: Icons.line_weight,
                    ),
                    SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.03),
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtil.isTablet(context) ? 60 : 50,
                      child: ElevatedButton(
                        onPressed: _calculateBMI,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'CALCULATE',
                          style: TextStyle(
                              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.03),
                    if (_hasCalculated) _buildResultSection(),
                    SizedBox(
                      height: 18,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtil.isTablet(context) ? 60 : 50,
                      child: TextButton(
                        onPressed: _resetFields,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: ResponsiveUtil.getResponsiveIconSize(context, 20),
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'REFRESH',
                              style: TextStyle(
                                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: Colors.white,
          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
          ),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context) * 0.8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _bmiColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Your BMI',
            style: TextStyle(
              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.01),
          Text(
            _bmi.toStringAsFixed(1),
            style: TextStyle(
              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 42),
              fontWeight: FontWeight.bold,
              color: _bmiColor,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: _bmiColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _bmiCategory,
              style: TextStyle(
                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: _bmiColor,
              ),
            ),
          ),
          SizedBox(height: 16),
          _buildCategoryDescription(),
        ],
      ),
    );
  }

  Widget _buildCategoryDescription() {
    String description = '';

    switch (_bmiCategory) {
      case 'Underweight':
        description =
            'You are underweight. Consider consulting with a healthcare professional for dietary guidance to help achieve a healthy weight.';
        break;
      case 'Normal':
        description =
            'You have a healthy weight. Maintain a balanced diet and regular physical activity to stay in this range.';
        break;
      case 'Overweight':
        description =
            'You are overweight. Consider adopting a healthier lifestyle with improved diet and increased physical activity.';
        break;
      case 'Obese':
        description =
            'You are in the obese category. It\'s advisable to consult with healthcare professionals for a personalized weight management plan.';
        break;
    }

    return Text(
      description,
      style: TextStyle(
        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
        color: Colors.grey[300],
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}
