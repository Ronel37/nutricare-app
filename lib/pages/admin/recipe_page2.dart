import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/admin/edit_recipe2.dart';

class RecipePage2 extends StatefulWidget {
  const RecipePage2({super.key});

  @override
  State<RecipePage2> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  // ignore: unused_field
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBmiCategory = 'All';

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1000;
    double padding = isWideScreen ? screenWidth * 0.1 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: RecipeSearchDelegate(_firestore),
              );
            },
          ),
        ],
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
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? padding : 16.0,
                vertical: 12.0,
              ),
              color: Colors.black.withOpacity(0.7),
              child: Row(
                children: [
                  if (isWideScreen) 
                    const Text('Filters:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 12),
                  // Food Category Filter
                  _buildFilterDropdown(
                    value: _selectedCategory,
                    items: ['All', 'Manna pack recipes', 'Local recipes'],
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                    icon: Icons.category,
                  ),
                  const SizedBox(width: 12),
                  // BMI Category Filter
                  _buildFilterDropdown(
                    value: _selectedBmiCategory,
                    items: ['All', 'Underweight', 'Normal weight', 'Overweight', 'Obese'],
                    onChanged: (value) => setState(() => _selectedBmiCategory = value!),
                    icon: Icons.monitor_weight,
                  ),
                  const Spacer(),
                  // Sort Button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'name_asc',
                        child: Text('Sort by Name (A-Z)'),
                      ),
                      const PopupMenuItem(
                        value: 'name_desc',
                        child: Text('Sort by Name (Z-A)'),
                      ),
                    ],
                    onSelected: (value) {
                      // Implement sorting logic
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _firestore.collection('recipes').get(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading recipes',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final recipes = snapshot.data!.docs;

                  if (recipes.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Apply filters
                  var filteredRecipes = recipes.where((recipe) {
                    final data = recipe.data() as Map<String, dynamic>;
                    final categoryMatch = _selectedCategory == 'All' || 
                        data['foodCategory'] == _selectedCategory;
                    final bmiMatch = _selectedBmiCategory == 'All' || 
                        data['bmiCategory'] == _selectedBmiCategory;
                    return categoryMatch && bmiMatch;
                  }).toList();

                  if (filteredRecipes.isEmpty) {
                    return _buildNoResultsState();
                  }

                  // Group recipes by category if wide screen
                  if (isWideScreen) {
                    return _buildWideLayout(filteredRecipes, padding);
                  } else {
                    return _buildMobileLayout(filteredRecipes, padding);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        icon: Icon(icon, color: Colors.grey),
        dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_meals, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0A3D00),
            ),
            child: const Text('Add New Recipe'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No recipes match your filters',
            style: TextStyle(fontSize: 18, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _selectedCategory = 'All';
              _selectedBmiCategory = 'All';
            }),
            child: const Text(
              'Clear filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(List<DocumentSnapshot> recipes, double padding) {
    // Group recipes by category
    Map<String, List<DocumentSnapshot>> categorizedRecipes = {};
    categorizedRecipes['All'] = recipes;
    
    for (var recipe in recipes) {
      final data = recipe.data() as Map<String, dynamic>;
      String category = data['foodCategory'] ?? 'Other';
      
      if (!categorizedRecipes.containsKey(category)) {
        categorizedRecipes[category] = [];
      }
      categorizedRecipes[category]!.add(recipe);
    }

    return DefaultTabController(
      length: categorizedRecipes.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: categorizedRecipes.keys.map((category) {
              return Tab(
                text: '$category (${categorizedRecipes[category]!.length})',
              );
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: categorizedRecipes.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final recipe = entry.value[index];
                      final data = recipe.data() as Map<String, dynamic>;
                      return _buildRecipeCard(
                        data['name'],
                        data['details'],
                        data['imageUrl'],
                        data['ingredients'],
                        data['instructions'],
                        data['bmiCategory'],
                        recipe.id,
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<DocumentSnapshot> recipes, double padding) {
    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        ...recipes.map((recipe) {
          final data = recipe.data() as Map<String, dynamic>;
          return _buildRecipeCard(
            data['name'],
            data['details'],
            data['imageUrl'],
            data['ingredients'],
            data['instructions'],
            data['bmiCategory'],
            recipe.id,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecipeCard(
    String recipeName,
    String recipeDetails,
    String image,
    List<dynamic> ingredients,
    List<dynamic> instructions,
    String bmiCategory,
    String docId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage2(
                recipeName: recipeName,
                recipeDetails: recipeDetails,
                imageUrl: image,
                ingredients: List<String>.from(ingredients),
                instructions: List<String>.from(instructions),
                bmiCategory: bmiCategory,
                docId: docId,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0A3D00),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // BMI Category Tag
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getBmiCategoryColor(bmiCategory),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      bmiCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Name
                  Text(
                    recipeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Recipe description
                  Text(
                    recipeDetails,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Meta info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ingredients count
                      Chip(
                        label: Text('${ingredients.length} ingredients'),
                        backgroundColor: Colors.grey[200],
                        labelStyle: const TextStyle(fontSize: 12),
                      ),

                      // View button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailPage2(
                                recipeName: recipeName,
                                recipeDetails: recipeDetails,
                                imageUrl: image,
                                ingredients: List<String>.from(ingredients),
                                instructions: List<String>.from(instructions),
                                bmiCategory: bmiCategory,
                                docId: docId,
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                        child: const Text('VIEW RECIPE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate {
  final FirebaseFirestore firestore;

  RecipeSearchDelegate(this.firestore);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('recipes')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs;

        if (results.isEmpty) {
          return const Center(child: Text('No recipes found'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final recipe = results[index];
            final data = recipe.data() as Map<String, dynamic>;
            return ListTile(
              leading: Image.network(
                data['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.restaurant);
                },
              ),
              title: Text(data['name']),
              subtitle: Text(data['bmiCategory']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailPage2(
                      recipeName: data['name'],
                      recipeDetails: data['details'],
                      imageUrl: data['imageUrl'],
                      ingredients: List<String>.from(data['ingredients']),
                      instructions: List<String>.from(data['instructions']),
                      bmiCategory: data['bmiCategory'],
                      docId: recipe.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class RecipeDetailPage2 extends StatelessWidget {
  final String recipeName;
  final String recipeDetails;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final String bmiCategory;
  final String docId;

  const RecipeDetailPage2({
    super.key,
    required this.recipeName,
    required this.recipeDetails,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.bmiCategory,
    required this.docId,
  });

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

  Future<void> _deleteRecipe(BuildContext context) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this recipe?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('DELETE', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(docId)
            .delete();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recipe deleted successfully.'),
            backgroundColor: Color(0xFF0A3D00),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete recipe.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _deleteRecipe(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: isWideScreen ? 400 : 300,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  height: isWideScreen ? 400 : 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getBmiCategoryColor(bmiCategory),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bmiCategory,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 100 : 20,
                vertical: 30,
              ),
              child: isWideScreen
                  ? _buildWideContentLayout()
                  : _buildMobileContentLayout(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditRecipePage(
                docId: docId,
                recipeName: recipeName,
                recipeDetails: recipeDetails,
                imageUrl: imageUrl,
                ingredients: List<String>.from(ingredients),
                instructions: List<String>.from(instructions),
                bmiCategory: bmiCategory,
              ),
            ),
          );
        },
        backgroundColor: Color(0xFF0A3D00),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildWideContentLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Description and Ingredients)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSectionCard(
                title: 'About This Recipe',
                icon: Icons.info_outline,
                child: Text(
                  recipeDetails,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Ingredients',
                icon: Icons.restaurant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ingredients.map((ingredient) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right Column (Instructions)
        Expanded(
          flex: 3,
          child: _buildSectionCard(
            title: 'Instructions',
            icon: Icons.format_list_numbered,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(instructions.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFF0A3D00),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          instructions[index],
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileContentLayout() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'About This Recipe',
          icon: Icons.info_outline,
          child: Text(
            recipeDetails,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Ingredients',
          icon: Icons.restaurant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ingredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionCard(
          title: 'Instructions',
          icon: Icons.format_list_numbered,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(instructions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(0xFF0A3D00),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instructions[index],
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF0A3D00),),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}