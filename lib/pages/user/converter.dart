import 'package:flutter/material.dart';

class MetricConverterPage extends StatefulWidget {
  const MetricConverterPage({super.key});

  @override
  State<MetricConverterPage> createState() => _MetricConverterPageState();
}

class _MetricConverterPageState extends State<MetricConverterPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedHeightUnit = 'cm';
  String _selectedWeightUnit = 'g';
  String _convertedHeight = '';
  String _convertedWeight = '';

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _convertHeight() {
    if (_heightController.text.isEmpty) return;
    double inputHeight = double.tryParse(_heightController.text) ?? 0;
    double meters = 0;

    if (_selectedHeightUnit == 'cm') {
      meters = inputHeight / 100;
    } else if (_selectedHeightUnit == 'mm') {
      meters = inputHeight / 1000;
    }

    setState(() {
      _convertedHeight = '${meters.toStringAsFixed(2)} meters';
    });
  }

  void _convertWeight() {
    if (_weightController.text.isEmpty) return;
    double inputWeight = double.tryParse(_weightController.text) ?? 0;
    double kilograms = 0;

    if (_selectedWeightUnit == 'g') {
      kilograms = inputWeight / 1000;
    } else if (_selectedWeightUnit == 'mg') {
      kilograms = inputWeight / 1000000;
    }

    setState(() {
      _convertedWeight = '${kilograms.toStringAsFixed(2)} kilograms';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metric Converter', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Height Converter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter height',
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    dropdownColor: Colors.grey[900],
                    value: _selectedHeightUnit,
                    items: ['cm', 'mm'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedHeightUnit = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _convertHeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Convert to Meters',style: TextStyle(color: Colors.white),),
              ),
              const SizedBox(height: 10),
              Text(
                _convertedHeight,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Weight Converter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter weight',
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    dropdownColor: Colors.grey[900],
                    value: _selectedWeightUnit,
                    items: ['g', 'mg'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedWeightUnit = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _convertWeight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Convert to Kilograms',style: TextStyle(color: Colors.white),),
              ),
              const SizedBox(height: 10),
              Text(
                _convertedWeight,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
