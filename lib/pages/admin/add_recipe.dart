import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/admin/recipe_page2.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _bmiCategory;
  String? _foodCategory;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  Future<void> _addRecipe() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _firestore.collection('recipes').add({
          'name': _nameController.text,
          'details': _detailsController.text,
          'imageUrl': _imageUrlController.text,
          'bmiCategory': _bmiCategory,
          'foodCategory': _foodCategory,
          'ingredients': _ingredientsController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
          'instructions': _instructionsController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
        });

        _resetFields();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe added successfully!'),
            backgroundColor: Color(0xFF0A3D00),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add recipe: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _resetFields() {
    setState(() {
      _nameController.clear();
      _detailsController.clear();
      _imageUrlController.clear();
      _ingredientsController.clear();
      _instructionsController.clear();
      _bmiCategory = null;
      _foodCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Manage Recipes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.list, color: Colors.white),
            label: const Text('View Recipes',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecipePage2()),
              );
            },
          ),
        ],
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal:
                  isWideScreen ? MediaQuery.of(context).size.width * 0.1 : 16.0,
              vertical: 24.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 32),
                      isWideScreen
                          ? _buildWideFormLayout()
                          : _buildMobileFormLayout(),
                      const SizedBox(height: 32),
                      _buildActionButtons(isWideScreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create New Recipe',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add nutritious recipes for different BMI categories',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildWideFormLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildInputFieldWithLabel(
                    label: 'Recipe Name',
                    controller: _nameController,
                    hintText: 'Enter recipe name',
                    icon: Icons.restaurant_menu,
                  ),
                  const SizedBox(height: 20),
                  _buildInputFieldWithLabel(
                    label: 'Image URL',
                    controller: _imageUrlController,
                    hintText: 'Enter image URL',
                    icon: Icons.image,
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdownWithLabel(
                    label: 'BMI Category',
                    value: _bmiCategory,
                    items: [
                      'Underweight',
                      'Normal weight',
                      'Overweight',
                      'Obese'
                    ],
                    icon: Icons.category,
                    onChanged: (value) => setState(() => _bmiCategory = value),
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryDropdownWithLabel(
                    label: 'Food Category',
                    value: _foodCategory,
                    items: ['Manna pack recipes', 'Local recipes'],
                    icon: Icons.food_bank,
                    onChanged: (value) => setState(() => _foodCategory = value),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildTextAreaWithLabel(
                    label: 'Recipe Details',
                    controller: _detailsController,
                    hintText: 'Enter recipe description and details',
                    icon: Icons.description,
                  ),
                  const SizedBox(height: 20),
                  _buildTextAreaWithLabel(
                    label: 'Ingredients',
                    controller: _ingredientsController,
                    hintText: 'Enter ingredients, separated by commas',
                    icon: Icons.shopping_cart,
                  ),
                  const SizedBox(height: 20),
                  _buildTextAreaWithLabel(
                    label: 'Instructions',
                    controller: _instructionsController,
                    hintText:
                        'Enter step-by-step instructions, separated by commas',
                    icon: Icons.format_list_numbered,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFormLayout() {
    return Column(
      children: [
        _buildInputFieldWithLabel(
          label: 'Recipe Name',
          controller: _nameController,
          hintText: 'Enter recipe name',
          icon: Icons.restaurant_menu,
        ),
        const SizedBox(height: 20),
        _buildInputFieldWithLabel(
          label: 'Image URL',
          controller: _imageUrlController,
          hintText: 'Enter image URL',
          icon: Icons.image,
        ),
        const SizedBox(height: 20),
        _buildCategoryDropdownWithLabel(
          label: 'BMI Category',
          value: _bmiCategory,
          items: ['Underweight', 'Normal weight', 'Overweight', 'Obese'],
          icon: Icons.category,
          onChanged: (value) => setState(() => _bmiCategory = value),
        ),
        const SizedBox(height: 20),
        _buildCategoryDropdownWithLabel(
          label: 'Food Category',
          value: _foodCategory,
          items: ['Manna pack recipes', 'Local recipes'],
          icon: Icons.food_bank,
          onChanged: (value) => setState(() => _foodCategory = value),
        ),
        const SizedBox(height: 20),
        _buildTextAreaWithLabel(
          label: 'Recipe Details',
          controller: _detailsController,
          hintText: 'Enter recipe description and details',
          icon: Icons.description,
        ),
        const SizedBox(height: 20),
        _buildTextAreaWithLabel(
          label: 'Ingredients',
          controller: _ingredientsController,
          hintText: 'Enter ingredients, separated by commas',
          icon: Icons.shopping_cart,
        ),
        const SizedBox(height: 20),
        _buildTextAreaWithLabel(
          label: 'Instructions',
          controller: _instructionsController,
          hintText: 'Enter step-by-step instructions, separated by commas',
          icon: Icons.format_list_numbered,
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isWideScreen) {
    return Row(
      children: [
        if (isWideScreen) Spacer(),
        Expanded(
          flex: isWideScreen ? 2 : 1,
          child: ElevatedButton(
            onPressed: _addRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0A3D00),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'SAVE RECIPE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (isWideScreen) SizedBox(width: 16),
        if (isWideScreen)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _resetFields,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20, color: Colors.white),
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
        if (isWideScreen) Spacer(),
      ],
    );
  }

  Widget _buildInputFieldWithLabel({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextAreaWithLabel({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 0, left: 10, right: 10),
              child: Icon(icon, color: Colors.grey),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdownWithLabel({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: value,
              hint: Text('Select $label', style: TextStyle(color: Colors.grey)),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a $label';
                }
                return null;
              },
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child:
                      Text(item, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
