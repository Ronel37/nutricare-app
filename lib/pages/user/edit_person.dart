import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_app/services/database.dart';
import 'package:nutricare_app/services/who_growth_service.dart';

class EditPerson extends StatefulWidget {
  final String documentId;
  final String firstname;
  final String lastname;
  final int age;
  final double bmi;
  final String bmiCategory;
  final double height;
  final double weight;

  const EditPerson({
    required this.documentId,
    required this.firstname,
    required this.lastname,
    required this.age,
    required this.bmi,
    required this.bmiCategory,
    required this.height,
    required this.weight,
    super.key,
  });

  @override
  State<EditPerson> createState() => _EditPersonState();
}

class _EditPersonState extends State<EditPerson> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstnameController;
  late TextEditingController lastnameController;
  late TextEditingController ageController;
  late TextEditingController heightController;
  late TextEditingController weightController;

  Color _getBmiColor() {
    switch (widget.bmiCategory) {
      case 'Underweight':
        return Colors.blue[600]!;
      case 'Normal weight':
        return Colors.green[600]!;
      case 'Overweight':
        return Colors.orange[600]!;
      case 'Obesity':
        return Colors.red[600]!;
      default:
        return Colors.white;
    }
  }

  @override
  void initState() {
    super.initState();

    firstnameController = TextEditingController(text: widget.firstname);
    lastnameController = TextEditingController(text: widget.lastname);
    ageController = TextEditingController(text: widget.age.toString());
    heightController = TextEditingController(text: widget.height.toString());
    weightController = TextEditingController(text: widget.weight.toString());
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> deletePerson() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              const Text("Delete Person", style: TextStyle(color: Colors.white)),
          content: const Text(
              "Are you sure you want to delete this record? This action cannot be undone.",
              style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('persons')
            .doc(widget.documentId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record deleted successfully.")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete record.")),
        );
      }
    }
  }

  // Updated _updatePersonInfo method
  Future<void> _updatePersonInfo() async {
    if (_formKey.currentState!.validate()) {
      final firstname = firstnameController.text.trim();
      final lastname = lastnameController.text.trim();
      final age = int.parse(ageController.text.trim());
      final height = double.parse(heightController.text.trim());
      final weight = double.parse(weightController.text.trim());

      final bmi = weight / (height * height);

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

      // Calculate anthropometric data for children <= 5 years
      double? haz;
      double? waz;
      double? whz;
      if (age <= 5) {
        final ageMonths = age * 12;
        final sex = Sex.male; // Default to male, you might want to get this from the person data
        final heightCm = height * 100;
        final weightKg = weight;
        haz = WhoGrowthService.hazZ(ageMonths: ageMonths, sex: sex, heightCm: heightCm);
        waz = WhoGrowthService.wazZ(ageMonths: ageMonths, sex: sex, weightKg: weightKg);
        whz = WhoGrowthService.whzZ(heightCm: heightCm, sex: sex, weightKg: weightKg);
      }

      try {
        final authService = AuthServices(); // Instantiate your AuthServices class
        final userId = FirebaseAuth.instance.currentUser!.uid;

        await authService.updatePersonInfo(
          userId: userId,
          personId: widget.documentId,
          name: '$firstname $lastname', // Combine first and last name
          age: age,
          weight: weight,
          height: height,
          haz: haz,
          waz: waz,
          whz: whz,
        );

        // Update the BMI and BMI category in Firestore as well.  This is a good idea to keep all data consistent.
        final Map<String, dynamic> updateData = {
          'firstname': firstname,
          'lastname': lastname,
          'age': age,
          'bmi': bmi,
          'bmiCategory': bmiCategory,
          'height': height,
          'weight': weight,
        };

        // Add anthropometric data for children <= 5 years
        if (haz != null) updateData['haz'] = haz;
        if (waz != null) updateData['waz'] = waz;
        if (whz != null) updateData['whz'] = whz;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('persons')
            .doc(widget.documentId)
            .update(updateData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Record updated successfully.")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update record.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update your information and recalculate your BMI',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BMI Result Card
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
                            'Current BMI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            widget.bmi.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: _getBmiColor(),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.bmiCategory,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getBmiColor(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Person Information Fields
                    const Text(
                      'First Name',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: firstnameController,
                      hintText: 'Enter first name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a first name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Last Name',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: lastnameController,
                      hintText: 'Enter last name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a last name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Age',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: ageController,
                      hintText: 'Enter age',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age <= 0) {
                          return 'Please enter a valid age';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Height (m)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: heightController,
                      hintText: 'Enter height in meters',
                      icon: Icons.height,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a height';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return 'Please enter a valid height';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Weight (kg)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInputField(
                      controller: weightController,
                      hintText: 'Enter weight in kilograms',
                      icon: Icons.line_weight,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a weight';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'Please enter a valid weight';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 35),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updatePersonInfo, // Use the updated method
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A3D00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'UPDATE',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton.icon(
                        onPressed: deletePerson,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'DELETE RECORD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.red, width: 1),
                          ),
                        ),
                      ),
                    ),
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator,
    );
  }
}