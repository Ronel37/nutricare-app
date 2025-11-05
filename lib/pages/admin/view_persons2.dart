import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ViewPersons2 extends StatefulWidget {
  ViewPersons2({super.key});

  @override
  _ViewPersons2State createState() => _ViewPersons2State();
}

class _ViewPersons2State extends State<ViewPersons2> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _showOnlyActiveUsers = true;

  Color getBmiCategoryColor(String bmiCategory) {
    switch (bmiCategory) {
      case 'Underweight':
        return Colors.blue.shade700;
      case 'Normal weight':
        return Colors.green;
      case 'Overweight':
        return Colors.orange.shade700;
      case 'Obese':
      case 'Obesity':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getBmiCategoryIcon(String bmiCategory) {
    switch (bmiCategory) {
      case 'Underweight':
        return '⚠️';
      case 'Normal weight':
        return '✓';
      case 'Overweight':
        return '⚠️';
      case 'Obese':
      case 'Obesity':
        return '⚠️';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Person Records Management',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateAllPersonsPDF,
            tooltip: 'Export All Records to PDF',
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
        child: Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search users by email...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Users List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: usersCollection.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
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

                    final usersData = snapshot.data?.docs;

                    if (usersData == null || usersData.isEmpty) {
                      return Center(
                        child: Text(
                          "No records found",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    // Filter users based on search query
                    final filteredUsers = usersData.where((userDoc) {
                      final userEmail = (userDoc['email'] ?? '').toString().toLowerCase();
                      return _searchQuery.isEmpty || userEmail.contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No users found matching ",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, userIndex) {
                        final userDoc = filteredUsers[userIndex];
                        final userId = userDoc.id;
                        final userEmail = userDoc['email'] ?? 'No email';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      title: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(0xFF0A3D00),
                              child: Text(
                                userEmail[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('persons')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, personSnapshot) {
                            if (personSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              );
                            }

                            if (personSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Error fetching person data",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            final personsData = personSnapshot.data?.docs;

                            if (personsData == null || personsData.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  "No person records found",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _getCrossAxisCount(context),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.3,
                                ),
                                itemCount: personsData.length,
                                itemBuilder: (context, personIndex) {
                                  final personDoc = personsData[personIndex];
                                  final person =
                                      personDoc.data() as Map<String, dynamic>;
                                  final bmiCategory =
                                      person['bmiCategory'] ?? 'Unknown';
                                  final double bmi = (person['bmi'] is num)
                                      ? (person['bmi'] as num).toDouble()
                                      : 0.0;
                                  final firstName =
                                      (person['firstname'] ?? 'N/A').toString();
                                  final lastName = person['lastname'] ?? '';
                                  final int? age = person['age'] is num
                                      ? (person['age'] as num).toInt()
                                      : int.tryParse((person['age'] ?? '').toString());
                                  final String sex = (person['sex'] ?? '-').toString();
                                  final heightVal = person['height'];
                                  final weightVal = person['weight'];
                                  final String height = heightVal == null
                                      ? 'N/A'
                                      : (heightVal is num
                                          ? heightVal.toString()
                                          : heightVal.toString());
                                  final String weight = weightVal == null
                                      ? 'N/A'
                                      : (weightVal is num
                                          ? weightVal.toString()
                                          : weightVal.toString());
                                  final double? haz = person['haz'] is num
                                      ? (person['haz'] as num).toDouble()
                                      : null;
                                  final double? waz = person['waz'] is num
                                      ? (person['waz'] as num).toDouble()
                                      : null;
                                  final double? whz = person['whz'] is num
                                      ? (person['whz'] as num).toDouble()
                                      : null;
                                  final timestamp = person['timestamp'] != null
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                          person['timestamp'].millisecondsSinceEpoch)
                                      : null;
                                  final bool isUnderFive = (age ?? 0) <= 5;

                                  return Card(
                                    elevation: 4,
                                    color: Colors.grey[800],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SingleChildScrollView(
                                        physics: const ClampingScrollPhysics(),
                                        primary: false,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor:
                                                    Color(0xFF0A3D00),
                                                child: Text(
                                                  (firstName.isNotEmpty ? firstName[0] : '?').toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '$firstName $lastName',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getBmiCategoryColor(
                                                          bmiCategory)
                                                      .withOpacity(0.8),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  bmiCategory,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _buildChip('Age: ${age ?? 'N/A'}', Icons.cake, Colors.blueGrey),
                                              _buildChip('Sex: ${sex.toUpperCase()}', Icons.person, Colors.teal),
                                              if (isUnderFive)
                                                _buildChip('≤5 yrs', Icons.child_care, Colors.purple),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (timestamp != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                'Recorded: ${timestamp.toLocal().toString().split(' ')[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              return Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                              children: [
                                                _buildInfoTile(
                                                  'Height',
                                                  '$height cm',
                                                  Icons.height,
                                                ),
                                                _buildInfoTile(
                                                  'Weight',
                                                  '$weight kg',
                                                  Icons.monitor_weight_outlined,
                                                ),
                                              if (!isUnderFive)
                                                _buildInfoTile(
                                                  'BMI',
                                                  bmi.toStringAsFixed(1),
                                                  Icons.analytics_outlined,
                                                  highlight: true,
                                                  color: getBmiCategoryColor(
                                                      bmiCategory),
                                                ),
                                                if (!isUnderFive)
                                                  _buildInfoTile(
                                                    'BMI',
                                                    bmi.toStringAsFixed(1),
                                                    Icons.analytics_outlined,
                                                    highlight: true,
                                                    color: getBmiCategoryColor(
                                                        bmiCategory),
                                                  ),
                                                  if (isUnderFive && haz != null)
                                                    _buildZScoreTile('HAZ', haz),
                                                  if (isUnderFive && waz != null)
                                                    _buildZScoreTile('WAZ', waz),
                                                  if (isUnderFive && whz != null)
                                                    _buildZScoreTile('WHZ', whz),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                          // PDF Generation Button
                                          Center(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _generateIndividualPersonPDF(userId, personDoc.id, person),
                                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                                              label: const Text('Generate PDF'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0A3D00),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ),
                                    ),
                                  );
                                },
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
          ),
        ),
      ),
    ]),
    )
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 4;
    if (width > 1000) return 3;
    if (width > 700) return 2;
    return 1;
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    bool highlight = false,
    Color? color,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: highlight ? color : Colors.grey[400],
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? color : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildZScoreTile(String label, double value) {
    Color color;
    IconData icon;
    if (value < -3) {
      color = Colors.redAccent;
      icon = Icons.arrow_downward;
    } else if (value < -2) {
      color = Colors.orangeAccent;
      icon = Icons.south;
    } else if (value > 3) {
      color = Colors.redAccent;
      icon = Icons.arrow_upward;
    } else if (value > 2) {
      color = Colors.orangeAccent;
      icon = Icons.north;
    } else {
      color = Colors.greenAccent;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text('z=${value.toStringAsFixed(2)}', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // PDF Generation Methods
  Future<void> _generateAllPersonsPDF() async {
    try {
      // Get all users and their persons
      final usersSnapshot = await usersCollection.get();
      final List<Map<String, dynamic>> allPersons = [];
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userEmail = userDoc['email'] ?? 'Unknown';
        
        final personsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('persons')
            .get();
            
        for (var personDoc in personsSnapshot.docs) {
          final person = personDoc.data() as Map<String, dynamic>;
          allPersons.add({
            'userEmail': userEmail,
            'userId': userId,
            'personId': personDoc.id,
            ...person,
          });
        }
      }
      
      if (allPersons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No person records found to export')),
        );
        return;
      }
      
      await _generatePDF(allPersons, 'All Person Records');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _generatePersonPDF(String userId, List<QueryDocumentSnapshot> persons) async {
    try {
      final List<Map<String, dynamic>> personData = [];
      
      for (var personDoc in persons) {
        final person = personDoc.data() as Map<String, dynamic>;
        personData.add({
          'userId': userId,
          'personId': personDoc.id,
          ...person,
        });
      }
      
      if (personData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No person records found to export')),
        );
        return;
      }
      
      await _generatePDF(personData, 'Person Records');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _generateIndividualPersonPDF(String userId, String personId, Map<String, dynamic> person) async {
    try {
      // Get user email
      final userDoc = await usersCollection.doc(userId).get();
      final userEmail = userDoc['email'] ?? 'Unknown';
      
      final personData = [{
        'userId': userId,
        'personId': personId,
        'userEmail': userEmail,
        ...person,
      }];
      
      await _generatePDF(personData, 'Individual Person Record');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _generatePDF(List<Map<String, dynamic>> persons, String title) async {
    final pdf = pw.Document();
    
    // Colors
    final primaryColor = PdfColor.fromInt(0xFF0A3D00);
    final gray = PdfColors.grey600;
    
    // Styles
    final titleStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    
    final headerStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    
    final normalStyle = pw.TextStyle(fontSize: 12, color: PdfColors.black);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Text(
                title,
                style: titleStyle,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Generated on: ${DateFormat('MMMM dd, yyyy - HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 10, color: gray),
            ),
            pw.SizedBox(height: 20),
            
            // Person Records
            ...persons.map((person) {
              final firstName = person['firstname'] ?? 'N/A';
              final lastName = person['lastname'] ?? '';
              final fullName = '$firstName $lastName'.trim();
              final age = person['age']?.toString() ?? 'N/A';
              final sex = person['sex']?.toString().toUpperCase() ?? 'N/A';
              final bmi = person['bmi']?.toStringAsFixed(1) ?? 'N/A';
              final bmiCategory = person['bmiCategory'] ?? 'Unknown';
              final height = person['height']?.toString() ?? 'N/A';
              final weight = person['weight']?.toString() ?? 'N/A';
              final userEmail = person['userEmail'] ?? 'Unknown';
              
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          fullName,
                          style: headerStyle,
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: _getBmiColor(bmiCategory),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            bmiCategory,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('User: $userEmail', style: normalStyle),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Age: $age', style: normalStyle),
                              pw.Text('Sex: $sex', style: normalStyle),
                              pw.Text('Height: $height cm', style: normalStyle),
                              pw.Text('Weight: $weight kg', style: normalStyle),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (((person['age'] as int?) ?? int.tryParse(person['age']?.toString() ?? '') ?? 0) > 5)
                                pw.Text('BMI: $bmi', style: normalStyle),
                              if (person['haz'] != null)
                                pw.Text('HAZ: ${person['haz'].toStringAsFixed(2)}', style: normalStyle),
                              if (person['waz'] != null)
                                pw.Text('WAZ: ${person['waz'].toStringAsFixed(2)}', style: normalStyle),
                              if (person['whz'] != null)
                                pw.Text('WHZ: ${person['whz'].toStringAsFixed(2)}', style: normalStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ];
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }

  PdfColor _getBmiColor(String bmiCategory) {
    switch (bmiCategory) {
      case 'Underweight':
        return PdfColors.blue;
      case 'Normal weight':
        return PdfColors.green;
      case 'Overweight':
        return PdfColors.orange;
      case 'Obese':
      case 'Obesity':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
}