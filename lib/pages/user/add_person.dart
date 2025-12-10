import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:nutricare_app/pages/user/converter.dart';
import 'dart:convert';
import 'dart:io';
import 'bmi_result.dart';
import 'package:nutricare_app/services/who_growth_service.dart';

class AddPerson extends StatefulWidget {
  const AddPerson({super.key});

  @override
  State<AddPerson> createState() => _AddPersonState();
}

class _AddPersonState extends State<AddPerson> {
  @override
  void initState() {
    super.initState();
    // Rebuild chips preview when user types other dietary preferences
    dietaryPreferenceController.addListener(() => setState(() {}));
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dietaryPreferenceController = TextEditingController();
  final TextEditingController healthGoalsController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  
  // Additional form fields
  String? _selectedSex;
  String? _selectedDietaryPreference;
  String? _selectedHealthGoal;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final String cloudName = "dxelb9tzi";
  // Use your unsigned upload preset name configured in Cloudinary
  final String uploadPreset = "flutter_upload";

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest("POST", url)
        ..fields["upload_preset"] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = json.decode(responseData) as Map<String, dynamic>;
        final secureUrl = jsonData["secure_url"] as String?;
        return secureUrl;
      } else {
        print("Cloudinary upload failed ${response.statusCode}: $responseData");
        return null;
      }
    } catch (e) {
      print("Cloudinary upload error: $e");
      return null;
    }
  }

  void _resetFields() {
    setState(() {
      firstnameController.clear();
      lastnameController.clear();
      ageController.clear();
      heightController.clear();
      weightController.clear();
      addressController.clear();
      dietaryPreferenceController.clear();
      healthGoalsController.clear();
      _imageFile = null;
      _selectedSex = null;
      _selectedDietaryPreference = null;
      _selectedHealthGoal = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Person Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add information to calculate BMI and track health progress.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 5),
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
                            size: 20,
                            color: Colors.white,
                          ),
                          SizedBox(width: 2,),
                          Text(
                            'Metric Converter',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Center(
                    //   child: Column(
                    //     children: [
                    //       GestureDetector(
                    //         onTap: _pickImage,
                    //         child: Container(
                    //           width: 100,
                    //           height: 100,
                    //           decoration: BoxDecoration(
                    //             color: Colors.grey[900],
                    //             shape: BoxShape.circle,
                    //             image: _imageFile != null
                    //                 ? DecorationImage(
                    //                     image: FileImage(_imageFile!),
                    //                     fit: BoxFit.cover,
                    //                   )
                    //                 : null,
                    //           ),
                    //           child: _imageFile == null
                    //               ? Icon(
                    //                   Icons.add_a_photo,
                    //                   size: 40,
                    //                   color: Colors.grey[600],
                    //                 )
                    //               : null,
                    //         ),
                    //       ),
                    //       const SizedBox(height: 8),
                    //       Text(
                    //         'Profile Photo',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           color: Colors.grey[400],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 25),
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: firstnameController,
                      hintText: 'Enter first name',
                      icon: Icons.person,
                      type: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: lastnameController,
                      hintText: 'Enter last name',
                      icon: Icons.person_outline,
                      type: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: ageController,
                      hintText: 'Enter age',
                      icon: Icons.cake,
                      type: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: addressController,
                      hintText: 'Enter address',
                      icon: Icons.location_on,
                      type: TextInputType.streetAddress,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Body Measurements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: heightController,
                      hintText: 'Enter height in meters',
                      icon: Icons.height,
                      type: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: weightController,
                      hintText: 'Enter weight in kilograms',
                      icon: Icons.line_weight,
                      type: TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSexDropdown(),
                    const SizedBox(height: 16),
                    _buildDietaryPreferenceDropdown(),
                    const SizedBox(height: 16),
                    _buildHealthGoalDropdown(),
                    const SizedBox(height: 16),
                    _buildUnderFiveIndicatorsHint(),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: dietaryPreferenceController,
                      hintText: 'Other dietary preferences (optional)',
                      icon: Icons.restaurant,
                      type: TextInputType.text,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tip: separate multiple with commas (e.g., gluten-free, low-sodium, lactose-free)',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDietaryChipsPreview(),
                    const SizedBox(height: 8),
                    _buildQuickAddDietaryChips(),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: healthGoalsController,
                      hintText: 'Specific health goals (optional)',
                      icon: Icons.fitness_center,
                      type: TextInputType.text,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final firstname = firstnameController.text.trim();
                            final lastname = lastnameController.text.trim();
                            final age = int.tryParse(ageController.text.trim());
                            final height =
                                double.tryParse(heightController.text.trim());
                            final weight =
                                double.tryParse(weightController.text.trim());
                            final address = addressController.text.trim();
                            final dietaryPreference = dietaryPreferenceController.text.trim();
                            final healthGoals = healthGoalsController.text.trim();

                            String? imageUrl;
                            if (_imageFile != null) {
                              imageUrl = await _uploadImage(_imageFile!);
                            }

                            final bmi = weight! / (height! * height);
                            String bmiCategory = '';
                            if (bmi < 18.5) {
                              bmiCategory = 'Underweight';
                            } else if (bmi >= 18.5 && bmi < 24.9) {
                              bmiCategory = 'Normal weight';
                            } else if (bmi >= 25 && bmi < 29.9) {
                              bmiCategory = 'Overweight';
                            } else {
                              bmiCategory = 'Obesity';
                            }

                            // WHO z-scores for <= 5 years old
                            double? haz;
                            double? waz;
                            double? whz;
                            if ((age ?? 0) <= 60) { // age in months condition later; convert years->months
                              final ageMonths = (age ?? 0) * 12;
                              final sex = (_selectedSex ?? 'Male').toLowerCase() == 'female' ? Sex.female : Sex.male;
                              final heightCm = (height * 100);
                              final weightKg = weight;
                              haz = WhoGrowthService.hazZ(ageMonths: ageMonths, sex: sex, heightCm: heightCm);
                              waz = WhoGrowthService.wazZ(ageMonths: ageMonths, sex: sex, weightKg: weightKg);
                              whz = WhoGrowthService.whzZ(heightCm: heightCm, sex: sex, weightKg: weightKg);
                            }

                            final personRef = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('persons')
                                .add({
                              'firstname': firstname,
                              'lastname': lastname,
                              'age': age,
                              'height': height,
                              'weight': weight,
                              'bmi': bmi,
                              'bmiCategory': bmiCategory,
                              'profilePic': imageUrl,
                              'address': address,
                              'sex': _selectedSex,
                              'dietaryPreference': _selectedDietaryPreference,
                              'healthGoal': _selectedHealthGoal,
                              'dietaryPreferenceText': dietaryPreference.isNotEmpty ? dietaryPreference : null,
                              'healthGoalsText': healthGoals.isNotEmpty ? healthGoals : null,
                              // Anthropometric indicators for <=5 years old (placeholders)
                              'isUnderFive': (age ?? 0) <= 5,
                              'haz': haz,
                              'waz': waz,
                              'whz': whz,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data Recorded Successfully"),
                                backgroundColor: Colors.black,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BMIResult(
                                  height: height,
                                  weight: weight,
                                  personId: personRef.id,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'GET BMI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CLEAR FORM',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
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
    required TextInputType type,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
      ),
      validator: (value) {
        // Make these specific fields optional
        if (controller == dietaryPreferenceController || controller == healthGoalsController) {
          return null;
        }

        if (value == null || value.isEmpty) {
          return 'This field is required';
        }

        if (controller == ageController) {
          final age = int.tryParse(value);
          if (age == null) {
            return 'Please enter a valid number';
          }
          if (age <= 0) {
            return 'Age must be greater than 0';
          }
        }

        if (controller == heightController || controller == weightController) {
          final measurement = double.tryParse(value);
          if (measurement == null) {
            return 'Please enter a valid number';
          }
          if (measurement <= 0) {
            return 'Value must be greater than 0';
          }
        }

        return null;
      },
    );
  }

  Widget _buildDietaryChipsPreview() {
    final raw = dietaryPreferenceController.text.trim();
    if (raw.isEmpty) return const SizedBox.shrink();
    final tokens = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tokens
          .map((t) => Chip(
                label: Text(t, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.grey[800],
                deleteIconColor: Colors.white70,
                onDeleted: () {
                  final updated = tokens.where((e) => e != t).join(', ');
                  dietaryPreferenceController.text = updated;
                },
              ))
          .toList(),
    );
  }

  Widget _buildQuickAddDietaryChips() {
    const suggestions = <String>[
      'Low-sodium',
      'Lactose-free',
      'Nut-free',
      'Shellfish-free',
      'Low-FODMAP',
      'Diabetic-friendly',
      'High-protein',
      'Low-fat',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions
          .map((s) => ActionChip(
                label: Text(s),
                backgroundColor: Colors.grey[900],
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () {
                  final raw = dietaryPreferenceController.text.trim();
                  final parts = raw.isEmpty
                      ? <String>[]
                      : raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  if (!parts.contains(s)) {
                    parts.add(s);
                    dietaryPreferenceController.text = parts.join(', ');
                  }
                },
              ))
          .toList(),
    );
  }

  Widget _buildSexDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedSex,
        decoration: InputDecoration(
          hintText: 'Select sex',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.person, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[900],
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'Male', child: Text('Male')),
          DropdownMenuItem(value: 'Female', child: Text('Female')),
          DropdownMenuItem(value: 'Other', child: Text('Other')),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedSex = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select sex';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDietaryPreferenceDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDietaryPreference,
        decoration: InputDecoration(
          hintText: 'Select dietary preference',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.restaurant, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[900],
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'No restrictions', child: Text('No restrictions')),
          DropdownMenuItem(value: 'Vegetarian', child: Text('Vegetarian')),
          DropdownMenuItem(value: 'Vegan', child: Text('Vegan')),
          DropdownMenuItem(value: 'Pescatarian', child: Text('Pescatarian')),
          DropdownMenuItem(value: 'Gluten-free', child: Text('Gluten-free')),
          DropdownMenuItem(value: 'Dairy-free', child: Text('Dairy-free')),
          DropdownMenuItem(value: 'Low-carb', child: Text('Low-carb')),
          DropdownMenuItem(value: 'Keto', child: Text('Keto')),
          DropdownMenuItem(value: 'Paleo', child: Text('Paleo')),
          DropdownMenuItem(value: 'Halal', child: Text('Halal')),
          DropdownMenuItem(value: 'Kosher', child: Text('Kosher')),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedDietaryPreference = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select dietary preference';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildHealthGoalDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedHealthGoal,
        decoration: InputDecoration(
          hintText: 'Select health goal',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.fitness_center, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[900],
        ),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        items: const [
          DropdownMenuItem(value: 'Maintain current weight', child: Text('Maintain current weight')),
          DropdownMenuItem(value: 'Lose weight', child: Text('Lose weight')),
          DropdownMenuItem(value: 'Gain weight', child: Text('Gain weight')),
          DropdownMenuItem(value: 'Build muscle', child: Text('Build muscle')),
          DropdownMenuItem(value: 'Improve energy', child: Text('Improve energy')),
          DropdownMenuItem(value: 'Better digestion', child: Text('Better digestion')),
          DropdownMenuItem(value: 'Heart health', child: Text('Heart health')),
          DropdownMenuItem(value: 'Diabetes management', child: Text('Diabetes management')),
          DropdownMenuItem(value: 'General wellness', child: Text('General wellness')),
        ],
        onChanged: (String? value) {
          setState(() {
            _selectedHealthGoal = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select health goal';
          }
          return null;
        },
      ),
    );
  }

  // Informational hint for anthropometric indicators (for <=5 years old)
  Widget _buildUnderFiveIndicatorsHint() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For children 5 years old and below, additional anthropometric indicators may be assessed: HAZ (stunting), WHZ (wasting), and WAZ (underweight).',
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
