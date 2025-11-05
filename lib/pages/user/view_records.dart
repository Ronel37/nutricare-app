import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nutricare_app/pages/user/edit_person.dart';

class ViewPersons extends StatefulWidget {
  @override
  _ViewPersonsState createState() => _ViewPersonsState();
}

class _ViewPersonsState extends State<ViewPersons> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference personCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .collection('persons');

  // Track which person cards are expanded
  final Map<String, bool> _expandedCards = {};
  
  // Track history dropdown expansion
  bool _isHistoryExpanded = false;

  Color getBmiCategoryColor(String bmiCategory) {
    switch (bmiCategory) {
      case 'Underweight':
        return Colors.blue[600]!;
      case 'Normal weight':
      case 'Normal':
        return Colors.green[600]!;
      case 'Overweight':
        return Colors.orange[600]!;
      case 'Obesity':
      case 'Obese':
        return Colors.red[600]!;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorRow(String label, double? z) {
    Color color;
    String category;
    
    if (z == null) {
      color = Colors.grey;
      category = 'Not available';
    } else if (z < -3) {
      color = Colors.red;
      category = 'Severely low';
    } else if (z < -2) {
      color = Colors.orange;
      category = 'Moderately low';
    } else if (z < -1) {
      color = Colors.amber;
      category = 'Mildly low';
    } else if (z <= 1) {
      color = Colors.green;
      category = 'Normal';
    } else if (z <= 2) {
      color = Colors.orangeAccent;
      category = 'High';
    } else {
      color = Colors.redAccent;
      category = 'Very high';
    }
    
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle
          )
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Text(
          z == null ? '-' : z.toStringAsFixed(2),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        )
      ],
    );
  }

  Widget _buildHistoryItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BMI Records',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View and manage all your saved BMI calculations.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: personCollection
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0A3D00),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error fetching data",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final data = snapshot.data?.docs;

                      if (data == null || data.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off,
                                color: Colors.grey[600],
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No records found",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Calculate and save your BMI to see records here",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        children: [
                          // Main Records Section
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final person =
                                  data[index].data() as Map<String, dynamic>;
                              final documentId = data[index].id;
                              final rawBmiCategory =
                                  person['bmiCategory'] ?? 'Unknown';
                              final bmiCategory = rawBmiCategory == 'Normal weight'
                                  ? 'Normal'
                                  : rawBmiCategory == 'Obesity'
                                      ? 'Obese'
                                      : rawBmiCategory;
                              final bmi = person['bmi'] ?? 0.0;
                              final int? ageYears = (person['age'] as num?)?.toInt();
                              final bool isUnderFive = (ageYears ?? 99) <= 5;

                              _expandedCards.putIfAbsent(documentId, () => false);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 20.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF0A3D00).withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.grey[800]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _expandedCards[documentId] =
                                              !_expandedCards[documentId]!;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            // Avatar Section
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0A3D00),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: (person['profilePic'] != null &&
                                                      (person['profilePic'] as String).isNotEmpty &&
                                                      (person['profilePic'] as String).startsWith('http'))
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(16),
                                                      child: Image.network(
                                                        person['profilePic'],
                                                        fit: BoxFit.cover,
                                                        width: 70,
                                                        height: 70,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Center(
                                                            child: Text(
                                                              person['firstname']?[0] ?? 'N',
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 28,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        loadingBuilder: (context, child, loadingProgress) {
                                                          if (loadingProgress == null) return child;
                                                          return const Center(
                                                            child: CircularProgressIndicator(
                                                              color: Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        person['firstname']?[0] ?? 'N',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 28,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 20),

                                            // Content Section
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.grey[400],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          "${person['firstname']} ${person['lastname']}",
                                                          style: const TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                            letterSpacing: 0.5,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      _buildInfoRow(
                                                        Icons.cake,
                                                        "Age",
                                                        "${person['age']} years",
                                                      ),
                                                      const SizedBox(height: 6),
                                                      _buildInfoRow(
                                                        Icons.height,
                                                        "Height",
                                                        "${person['height']} m",
                                                      ),
                                                      const SizedBox(height: 6),
                                                      _buildInfoRow(
                                                        Icons.line_weight,
                                                        "Weight",
                                                        "${person['weight']} kg",
                                                      ),
                                                      if (person['sex'] != null) ...[
                                                        const SizedBox(height: 6),
                                                        _buildInfoRow(
                                                          Icons.person_outline,
                                                          "Sex",
                                                          "${person['sex']}",
                                                        ),
                                                      ],
                                                      if (person['dietaryPreference'] != null) ...[
                                                        const SizedBox(height: 6),
                                                        _buildInfoRow(
                                                          Icons.restaurant,
                                                          "Diet",
                                                          "${person['dietaryPreference']}",
                                                        ),
                                                      ],
                                                      if (person['healthGoal'] != null) ...[
                                                        const SizedBox(height: 6),
                                                        _buildInfoRow(
                                                          Icons.fitness_center,
                                                          "Goal",
                                                          "${person['healthGoal']}",
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      if (!isUnderFive)
                                                        Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 16,
                                                            vertical: 8),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              getBmiCategoryColor(
                                                                  bmiCategory),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  24),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: getBmiCategoryColor(bmiCategory).withOpacity(0.3),
                                                              blurRadius: 8,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(
                                                                  Icons.monitor_weight,
                                                                  size: 16,
                                                                  color: Colors.white,
                                                                ),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  "BMI: ${bmi.toStringAsFixed(1)}",
                                                                  style:
                                                                      const TextStyle(
                                                                        fontSize: 16,
                                                                    fontWeight:
                                                                        FontWeight.bold,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              bmiCategory,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Under-5 indicators for children <= 5 years old
                                                      if (person['isUnderFive'] == true && 
                                                          (person['haz'] != null || person['waz'] != null || person['whz'] != null))
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue[800],
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.child_care,
                                                                color: Colors.white,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              const Text(
                                                                "Under-5",
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      // Action buttons
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFF0A3D00),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: const Color(0xFF0A3D00).withOpacity(0.3),
                                                                  blurRadius: 6,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons.edit_rounded,
                                                                color: Colors.white,
                                                                size: 20,
                                                              ),
                                                              onPressed: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            EditPerson(
                                                                      documentId:
                                                                          documentId,
                                                                      firstname:
                                                                          person['firstname'] ??
                                                                              '',
                                                                      lastname:
                                                                          person['lastname'] ??
                                                                              '',
                                                                      age: person[
                                                                              'age'] ??
                                                                          0,
                                                                      bmi: person[
                                                                              'bmi'] ??
                                                                          0.0,
                                                                      bmiCategory:
                                                                          rawBmiCategory,
                                                                      height: person[
                                                                              'height'] ??
                                                                          0.0,
                                                                      weight: person[
                                                                              'weight'] ??
                                                                          0.0,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.red[800],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors.red[800]!.withOpacity(0.3),
                                                                  blurRadius: 6,
                                                                  offset: const Offset(0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons.delete_rounded,
                                                                color: Colors.white,
                                                                size: 20,
                                                              ),
                                                              onPressed: () async {
                                                                final confirm =
                                                                    await showDialog<
                                                                        bool>(
                                                                  context: context,
                                                                  builder:
                                                                      (context) =>
                                                                          AlertDialog(
                                                                    backgroundColor:
                                                                        Colors.grey[
                                                                            900],
                                                                    title:
                                                                        const Text(
                                                                      "Delete Record",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white),
                                                                    ),
                                                                    content:
                                                                        const Text(
                                                                      "Are you sure you want to delete this person record?",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white70),
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        child: const Text(
                                                                            "Cancel",
                                                                            style: TextStyle(
                                                                                color:
                                                                                    Colors.white)),
                                                                        onPressed: () =>
                                                                            Navigator.of(context)
                                                                                .pop(false),
                                                                      ),
                                                                      TextButton(
                                                                        child:
                                                                            const Text(
                                                                          "Delete",
                                                                          style: TextStyle(
                                                                              color:
                                                                                  Colors.red),
                                                                        ),
                                                                        onPressed: () =>
                                                                            Navigator.of(context)
                                                                                .pop(true),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );

                                                                if (confirm ==
                                                                    true) {
                                                                  await personCollection
                                                                      .doc(
                                                                          documentId)
                                                                      .delete();
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Under-5 Anthropometric Indicators Section (expandable)
                                    if (person['isUnderFive'] == true && 
                                        (person['haz'] != null || person['waz'] != null || person['whz'] != null))
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        height: _expandedCards[documentId]! ? null : 0,
                                        child: _expandedCards[documentId]!
                                            ? Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 16.0, vertical: 8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      "Under-5 Anthropometric Indicators:",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    if (person['haz'] != null)
                                                      _buildIndicatorRow('HAZ (Stunting)', person['haz']),
                                                    if (person['haz'] != null)
                                                      const SizedBox(height: 6),
                                                    if (person['waz'] != null)
                                                      _buildIndicatorRow('WAZ (Underweight)', person['waz']),
                                                    if (person['waz'] != null)
                                                      const SizedBox(height: 6),
                                                    if (person['whz'] != null)
                                                      _buildIndicatorRow('WHZ (Wasting)', person['whz']),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Z-score categories: < -3 severe, -3 to < -2 moderate, -2 to < -1 mild, -1 to 1 normal, 1 to 2 high, > 2 very high',
                                                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          // History Section Header
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isHistoryExpanded = !_isHistoryExpanded;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(top: 20, bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[800]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: const Color(0xFF0A3D00),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Update History',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  AnimatedRotation(
                                    turns: _isHistoryExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // History Content
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: _isHistoryExpanded ? null : 0,
                            child: _isHistoryExpanded
                                ? StreamBuilder<QuerySnapshot>(
                                    stream: personCollection
                                        .orderBy('timestamp', descending: true)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF0A3D00),
                                          ),
                                        );
                                      }

                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[800]!),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.history_edu,
                                                color: Colors.grey[600],
                                                size: 64,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                "No records found",
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Add person records to see history here",
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final data = snapshot.data!.docs;
                                      
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: data.length,
                                        itemBuilder: (context, index) {
                                          final person = data[index].data() as Map<String, dynamic>;
                                          final documentId = data[index].id;
                                          
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[900],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey[800]!),
                                            ),
                                            child: Column(
                                              children: [
                                                // Person Header
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[800],
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(12),
                                                      topRight: Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0A3D00),
                                                          borderRadius: BorderRadius.circular(8),
                                                          image: (person['profilePic'] != null && (person['profilePic'] as String).isNotEmpty && (person['profilePic'] as String).startsWith('http'))
                                                              ? DecorationImage(
                                                                  image: NetworkImage(person['profilePic']),
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : null,
                                                        ),
                                                        child: (person['profilePic'] == null || !(person['profilePic'] as String).startsWith('http') || (person['profilePic'] as String).isEmpty)
                                                            ? Center(
                                                                child: Text(
                                                                  person['firstname']?[0] ?? 'N',
                                                                  style: const TextStyle(
                                                                    color: Colors.white,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              "${person['firstname']} ${person['lastname']}",
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            if (((person['age'] as num?)?.toInt() ?? 99) > 5)
                                                              Text(
                                                                "BMI: ${(person['bmi'] ?? 0.0).toStringAsFixed(1)} - ${person['bmiCategory'] ?? 'Unknown'}",
                                                                style: TextStyle(
                                                                  color: Colors.grey[400],
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // History Items
                                                StreamBuilder<QuerySnapshot>(
                                                  stream: personCollection
                                                      .doc(documentId)
                                                      .collection('updateHistory')
                                                      .orderBy('updatedAt', descending: true)
                                                      .snapshots(),
                                                  builder: (context, historySnapshot) {
                                                        if (historySnapshot.connectionState == ConnectionState.waiting) {
                                                      return const Padding(
                                                            padding: EdgeInsets.all(16),
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            color: Color(0xFF0A3D00),
                                                                strokeWidth: 2,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                        if (!historySnapshot.hasData || historySnapshot.data!.docs.isEmpty) {
                                                          return Padding(
                                                            padding: const EdgeInsets.all(16),
                                                        child: Text(
                                                          "No update history available",
                                                          style: TextStyle(
                                                                color: Colors.grey[400],
                                                            fontSize: 14,
                                                          ),
                                                                textAlign: TextAlign.center,
                                                        ),
                                                      );
                                                    }

                                                        final historyData = historySnapshot.data!.docs;

                                                    return Padding(
                                                          padding: const EdgeInsets.all(12),
                                                      child: Column(
                                                            children: historyData.take(3).map((historyDoc) {
                                                              final history = historyDoc.data() as Map<String, dynamic>;
                                                              final updateType = history['updateType'] ?? 'modification';
                                                              final updatedAt = history['updatedAt'] as Timestamp;

                                                            return Container(
                                                                margin: const EdgeInsets.only(bottom: 8),
                                                                padding: const EdgeInsets.all(12),
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey[800],
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: updateType == 'creation' 
                                                                        ? Colors.green.withOpacity(0.3)
                                                                        : Colors.blue.withOpacity(0.3),
                                                                    width: 1,
                                                                  ),
                                                              ),
                                                              child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(
                                                                              horizontal: 8, vertical: 4),
                                                                          decoration: BoxDecoration(
                                                                            color: updateType == 'creation' 
                                                                                ? Colors.green[600]
                                                                                : Colors.blue[600],
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          child: Row(
                                                                            mainAxisSize: MainAxisSize.min,
                                                                            children: [
                                                                              Icon(
                                                                                updateType == 'creation' 
                                                                                    ? Icons.add_circle
                                                                                    : Icons.edit,
                                                                                color: Colors.white,
                                                                                size: 12,
                                                                              ),
                                                                              const SizedBox(width: 4),
                                                                        Text(
                                                                                updateType == 'creation' ? 'Created' : 'Updated',
                                                                                style: const TextStyle(
                                                                                  color: Colors.white,
                                                                                  fontSize: 10,
                                                                                  fontWeight: FontWeight.bold,
                                                                            ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                        ),
                                                                        const Spacer(),
                                                                    Text(
                                                                          _formatTimestamp(updatedAt),
                                                                          style: TextStyle(
                                                                            color: Colors.grey[400],
                                                                            fontSize: 10,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(height: 8),
                                                                    if (history['name'] != null)
                                                                      _buildHistoryItem(Icons.person, 'Name', history['name']),
                                                                    if (history['age'] != null)
                                                                      _buildHistoryItem(Icons.cake, 'Age', '${history['age']} years'),
                                                                    if (history['height'] != null)
                                                                      _buildHistoryItem(Icons.height, 'Height', '${history['height']} m'),
                                                                    if (history['weight'] != null)
                                                                      _buildHistoryItem(Icons.line_weight, 'Weight', '${history['weight']} kg'),
                                                                    if (history['sex'] != null)
                                                                      _buildHistoryItem(Icons.person_outline, 'Sex', history['sex']),
                                                                    if (history['dietaryPreference'] != null)
                                                                      _buildHistoryItem(Icons.restaurant, 'Diet', history['dietaryPreference']),
                                                                    if (history['healthGoal'] != null)
                                                                      _buildHistoryItem(Icons.fitness_center, 'Goal', history['healthGoal']),
                                                                    if (history['profilePic'] != null)
                                                                      _buildHistoryItem(Icons.photo_camera, 'Profile Picture', 'Updated'),
                                                                ],
                                                              ),
                                                            );
                                                          }).toList(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}