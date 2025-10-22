import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditRecipePage extends StatefulWidget {
  final String docId;
  final String recipeName;
  final String recipeDetails;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final String bmiCategory;
  final String? foodCategory;

  const EditRecipePage({
    super.key,
    required this.docId,
    required this.recipeName,
    required this.recipeDetails,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.bmiCategory,
    this.foodCategory,
  });

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  late String _recipeName;
  late String _recipeDetails;
  late String _imageUrl;
  late List<String> _ingredients;
  late List<String> _instructions;

  String? _bmiCategory;
  String? _foodCategory;

  @override
  void initState() {
    super.initState();
    _recipeName = widget.recipeName;
    _recipeDetails = widget.recipeDetails;
    _imageUrl = widget.imageUrl;
    _ingredients = List.from(widget.ingredients);
    _instructions = List.from(widget.instructions);
    _bmiCategory = widget.bmiCategory;
    _foodCategory = widget.foodCategory;
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add('');
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructions.add('');
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }

  Future<void> _updateRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(widget.docId)
            .update({
          'name': _recipeName,
          'details': _recipeDetails,
          'imageUrl': _imageUrl,
          'ingredients': _ingredients,
          'instructions': _instructions,
          'bmiCategory': _bmiCategory,
          'foodCategory': _foodCategory,
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe updated successfully.'),
            backgroundColor: Color(0xFF0A3D00),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update recipe: ${e.toString()}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF1A5C1A),
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 16,
                vertical: isDesktop ? 24 : 16,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Recipe',
                            style: TextStyle(
                              fontSize: isDesktop ? 32 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isDesktop)
                            IconButton(
                              icon: const Icon(Icons.close, size: 28),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Update recipe details for better nutrition guidance',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Two-column layout for desktop
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildSectionTitle('Basic Information'),
                                  const SizedBox(height: 16),
                                  _buildInputField(
                                    label: 'Recipe Name',
                                    initialValue: _recipeName,
                                    hintText: 'Enter recipe name',
                                    icon: Icons.restaurant_menu,
                                    onSaved: (value) => _recipeName = value!,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputField(
                                    label: 'Image URL',
                                    initialValue: _imageUrl,
                                    hintText: 'Enter image URL',
                                    icon: Icons.image,
                                    onSaved: (value) => _imageUrl = value!,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildCategoryDropdown(),
                                  const SizedBox(height: 20),
                                  _buildFoodCategoryDropdown(),
                                  const SizedBox(height: 20),
                                  _buildTextArea(
                                    label: 'Recipe Details',
                                    initialValue: _recipeDetails,
                                    hintText: 'Enter recipe description and details',
                                    icon: Icons.description,
                                    onSaved: (value) => _recipeDetails = value!,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            // Right column
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildSectionTitle('Recipe Components'),
                                  const SizedBox(height: 16),
                                  _buildIngredientsSection(),
                                  const SizedBox(height: 24),
                                  _buildInstructionsSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Single column layout for mobile/tablet
                        _buildSectionTitle('Basic Information'),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Recipe Name',
                          initialValue: _recipeName,
                          hintText: 'Enter recipe name',
                          icon: Icons.restaurant_menu,
                          onSaved: (value) => _recipeName = value!,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Image URL',
                          initialValue: _imageUrl,
                          hintText: 'Enter image URL',
                          icon: Icons.image,
                          onSaved: (value) => _imageUrl = value!,
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 20),
                        _buildFoodCategoryDropdown(),
                        const SizedBox(height: 20),
                        _buildTextArea(
                          label: 'Recipe Details',
                          initialValue: _recipeDetails,
                          hintText: 'Enter recipe description and details',
                          icon: Icons.description,
                          onSaved: (value) => _recipeDetails = value!,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Recipe Components'),
                        const SizedBox(height: 16),
                        _buildIngredientsSection(),
                        const SizedBox(height: 24),
                        _buildInstructionsSection(),
                      ],
                      
                      const SizedBox(height: 32),
                      _buildActionButtons(isDesktop),
                      const SizedBox(height: 20),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String initialValue,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              },
          onSaved: onSaved,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required String initialValue,
    required String hintText,
    IconData? icon,
    void Function(String?)? onSaved,
    Function(String)? onChanged,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.white.withOpacity(0.7))
                : null,
            contentPadding: const EdgeInsets.all(16),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
          onSaved: onSaved,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BMI Category',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _bmiCategory,
              hint: const Text('Select BMI Category',
                  style: TextStyle(color: Colors.grey)),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category, color: Colors.white70),
                border: InputBorder.none,
              ),
              dropdownColor: const Color(0xFF1A5C1A),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a BMI category';
                }
                return null;
              },
              items: ['Underweight', 'Normal weight', 'Overweight', 'Obese']
                  .map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _bmiCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Food Category',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _foodCategory,
              hint: const Text('Select Food Category',
                  style: TextStyle(color: Colors.grey)),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.food_bank, color: Colors.white70),
                border: InputBorder.none,
              ),
              dropdownColor: const Color(0xFF1A5C1A),
              style: const TextStyle(color: Colors.white),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a food category';
                }
                return null;
              },
              items: ['Manna pack recipes', 'Local recipes'].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _foodCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._ingredients.asMap().entries.map((entry) {
          int index = entry.key;
          String ingredient = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Ingredient ${index + 1}',
                    initialValue: ingredient,
                    hintText: 'Enter ingredient',
                    icon: Icons.shopping_cart,
                    onChanged: (value) => _ingredients[index] = value,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeIngredient(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _addIngredient,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text(
                'ADD INGREDIENT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instructions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._instructions.asMap().entries.map((entry) {
          int index = entry.key;
          String instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextArea(
                    label: 'Step ${index + 1}',
                    initialValue: instruction,
                    hintText: 'Enter instruction',
                    onChanged: (value) => _instructions[index] = value,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _removeInstruction(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _addInstruction,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text(
                'ADD INSTRUCTION',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    return Row(
      children: [
        if (isDesktop) const Spacer(),
        Expanded(
          flex: isDesktop ? 2 : 1,
          child: ElevatedButton(
            onPressed: _updateRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A3D00),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'UPDATE RECIPE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (isDesktop) const SizedBox(width: 16),
        if (isDesktop)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('CANCEL'),
            ),
          ),
      ],
    );
  }
}