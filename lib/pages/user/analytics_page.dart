import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  String? _selectedPersonId;
  String? _selectedPersonName;
  int? _selectedPersonAge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Growth Analytics',
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
                  'Professional Growth Analysis Dashboard',
                  style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_userId)
                        .collection('persons')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          height: 56,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF0A3D00), strokeWidth: 2),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text(
                          'No persons yet. Add records first.',
                          style: TextStyle(color: Colors.white70),
                        );
                      }

                      final persons = snapshot.data!.docs;

                      if (_selectedPersonId == null && persons.isNotEmpty) {
                        _selectedPersonId = persons.first.id;
                        final p = persons.first.data() as Map<String, dynamic>;
                        _selectedPersonName =
                            '${p['firstname'] ?? ''} ${p['lastname'] ?? ''}'
                                .trim();
                        _selectedPersonAge = p['age'] as int?;
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPersonId,
                                dropdownColor: Colors.grey[900],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                items: persons.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      '${data['firstname'] ?? ''} ${data['lastname'] ?? ''}'
                                          .trim();
                                  return DropdownMenuItem<String>(
                                    value: doc.id,
                                    child:
                                        Text(name.isEmpty ? 'Unnamed' : name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPersonId = value;
                                    final p = persons
                                        .firstWhere((e) => e.id == value)
                                        .data() as Map<String, dynamic>;
                                    _selectedPersonName =
                                        '${p['firstname'] ?? ''} ${p['lastname'] ?? ''}'
                                            .trim();
                                    _selectedPersonAge = p['age'] as int?;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[700]!, Colors.blue[900]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.analytics_outlined,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Analytics',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _selectedPersonId == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.analytics_outlined,
                                  size: 64, color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text(
                                'Select a person to view analytics',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : _SeparatedCharts(
                          userId: _userId,
                          personId: _selectedPersonId!,
                          personName: _selectedPersonName ?? 'Person',
                          personAge: _selectedPersonAge,
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

class _SeparatedCharts extends StatelessWidget {
  final String userId;
  final String personId;
  final String personName;
  final int? personAge;

  const _SeparatedCharts({
    required this.userId,
    required this.personId,
    required this.personName,
    this.personAge,
  });

  @override
  Widget build(BuildContext context) {
    final historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('persons')
        .doc(personId)
        .collection('updateHistory')
        .orderBy('updatedAt')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0A3D00), strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No growth data available for $personName',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add some records to see analytics',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final List<_Point> heightSeries = [];
        final List<_Point> weightSeries = [];
        final List<_Point> bmiSeries = [];
        final List<_Point> hazSeries = [];
        final List<_Point> wazSeries = [];
        final List<_Point> whzSeries = [];

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          final ts = (data['updatedAt'] ?? data['timestamp']);
          DateTime? date;
          if (ts is Timestamp) {
            date = ts.toDate();
          } else if (ts is int) {
            date = DateTime.fromMillisecondsSinceEpoch(ts);
          }
          if (date == null) continue;

          final height = _toDouble(data['height']);
          final weight = _toDouble(data['weight']);
          final bmi = _toDouble(data['bmi']);
          final haz = _toDouble(data['haz']);
          final waz = _toDouble(data['waz']);
          final whz = _toDouble(data['whz']);

          final x = date.millisecondsSinceEpoch.toDouble();
          if (height != null) heightSeries.add(_Point(x, height));
          if (weight != null) weightSeries.add(_Point(x, weight));
          if (bmi != null) bmiSeries.add(_Point(x, bmi));
          if (haz != null) hazSeries.add(_Point(x, haz));
          if (waz != null) wazSeries.add(_Point(x, waz));
          if (whz != null) whzSeries.add(_Point(x, whz));
        }

        // Sort all series
        heightSeries.sort((a, b) => a.x.compareTo(b.x));
        weightSeries.sort((a, b) => a.x.compareTo(b.x));
        bmiSeries.sort((a, b) => a.x.compareTo(b.x));
        hazSeries.sort((a, b) => a.x.compareTo(b.x));
        wazSeries.sort((a, b) => a.x.compareTo(b.x));
        whzSeries.sort((a, b) => a.x.compareTo(b.x));

        final isUnderFive = (personAge ?? 0) <= 5;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header with person info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUnderFive
                        ? [Colors.purple[800]!, Colors.purple[900]!]
                        : [Colors.blue[800]!, Colors.blue[900]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isUnderFive ? Icons.child_care : Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                personName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isUnderFive
                                    ? 'Pediatric Growth Analysis (≤5 years)'
                                    : 'Growth Analysis',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${docs.length} records',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Charts Grid - Made much bigger and better spaced
              LayoutBuilder(
                builder: (context, constraints) {
                  // Make charts much larger - single column on mobile, larger cards
                  final isWideScreen = constraints.maxWidth > 600;
                  final cardWidth = isWideScreen 
                      ? (constraints.maxWidth - 24) / 2  // 2 columns on wide screens
                      : constraints.maxWidth;           // 1 column on narrow screens
                  final cardHeight = isWideScreen 
                      ? cardWidth * 1.2  // Taller cards for wide screens
                      : cardWidth * 0.8; // Slightly shorter for single column
                  
                  return Wrap(
                    spacing: 16,
                    runSpacing: 24, // Increased spacing between rows
                    children: [
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildChartCard(
                          title: 'Height',
                          unit: 'meters',
                          icon: Icons.height,
                          color: Colors.cyan,
                          series: heightSeries,
                          isUnderFive: isUnderFive,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildChartCard(
                          title: 'Weight',
                          unit: 'kg',
                          icon: Icons.monitor_weight,
                          color: Colors.amber,
                          series: weightSeries,
                          isUnderFive: isUnderFive,
                        ),
                      ),
                      if (!isUnderFive)
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _buildChartCard(
                            title: 'BMI',
                            unit: 'kg/m²',
                            icon: Icons.fitness_center,
                            color: Colors.pinkAccent,
                            series: bmiSeries,
                            isUnderFive: isUnderFive,
                          ),
                        ),
                      if (isUnderFive)
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _buildChartCard(
                            title: 'HAZ',
                            unit: 'z-score',
                            icon: Icons.trending_up,
                            color: const Color(0xFF66BB6A),
                            series: hazSeries,
                            isUnderFive: isUnderFive,
                          ),
                        ),
                      if (isUnderFive)
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _buildChartCard(
                            title: 'WAZ',
                            unit: 'z-score',
                            icon: Icons.trending_up,
                            color: const Color(0xFFFF7043),
                            series: wazSeries,
                            isUnderFive: isUnderFive,
                          ),
                        ),
                      if (isUnderFive)
                        SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: _buildChartCard(
                            title: 'WHZ',
                            unit: 'z-score',
                            icon: Icons.trending_up,
                            color: const Color(0xFF29B6F6),
                            series: whzSeries,
                            isUnderFive: isUnderFive,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required IconData icon,
    required Color color,
    required List<_Point> series,
    required bool isUnderFive,
  }) {
    if (series.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              'No data',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    final allX = series.map((e) => e.x).toList();
    final allY = series.map((e) => e.y).toList();
    final computedMinX = allX.reduce((a, b) => a < b ? a : b);
    final computedMaxX = allX.reduce((a, b) => a > b ? a : b);
    final computedMinY = allY.reduce((a, b) => a < b ? a : b);
    final computedMaxY = allY.reduce((a, b) => a > b ? a : b);

    // Handle single data point case
    final double xRange = computedMaxX - computedMinX;
    final double yRange = computedMaxY - computedMinY;

    final double xPadding = xRange <= 0 ? 86400000.0 : xRange * 0.1; // 1 day in milliseconds for single point
    final double yPadding = yRange <= 0 ? 1.0 : yRange * 0.15;

    // ignore: unused_local_variable
    final double displayMinX = computedMinX - xPadding;
    // ignore: unused_local_variable
    final double displayMaxX = computedMaxX + xPadding;
    
    // For Z-score charts (HAZ, WAZ, WHZ), center around 0
    final bool isZScore = title == 'HAZ' || title == 'WAZ' || title == 'WHZ';
    final double displayMinY, displayMaxY;
    
    if (isZScore) {
      // Find the maximum absolute value and create symmetric range around 0
      final double maxAbsValue = allY.map((y) => y.abs()).reduce((a, b) => a > b ? a : b);
      final double paddedMax = maxAbsValue + (maxAbsValue * 0.2); // Add 20% padding
      displayMinY = -paddedMax;
      displayMaxY = paddedMax;
    } else {
      displayMinY = computedMinY - yPadding;
      displayMaxY = computedMaxY + yPadding;
    }

    // Ensure we have a valid Y range
    final double finalYRange = displayMaxY - displayMinY;
    final double safeDisplayMinY = finalYRange <= 0 ? displayMinY - 1.0 : displayMinY;
    final double safeDisplayMaxY = finalYRange <= 0 ? displayMaxY + 1.0 : displayMaxY;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Increased icon container
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28), // Larger icon
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20, // Larger title
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14, // Larger unit text
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${series.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14, // Larger badge text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Pediatric status chip for Z-score charts (≤5 years only)
            if (isUnderFive && (title == 'HAZ' || title == 'WAZ' || title == 'WHZ')) ...[
              Builder(
                builder: (context) {
                  if (series.isEmpty) return const SizedBox.shrink();
                  final double z = series.last.y;
                  String? label;
                  Color bg = Colors.green.withOpacity(0.15);
                  Color fg = Colors.green;

                  String metricLabel;
                  if (title == 'HAZ') {
                    metricLabel = 'Stunting';
                  } else if (title == 'WAZ') {
                    metricLabel = 'Underweight';
                  } else {
                    metricLabel = 'Wasting';
                  }

                  if (z < -3) {
                    label = 'Severe $metricLabel';
                    bg = Colors.red.withOpacity(0.15);
                    fg = Colors.redAccent;
                  } else if (z < -2) {
                    label = metricLabel;
                    bg = Colors.orange.withOpacity(0.15);
                    fg = Colors.orange;
                  } else {
                    label = 'Normal';
                    bg = Colors.green.withOpacity(0.15);
                    fg = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: fg.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                label == 'Normal' ? Icons.check_circle : Icons.info,
                                color: fg,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'z=${z.toStringAsFixed(2)}',
                                style: TextStyle(color: fg.withOpacity(0.9), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            if (title == 'BMI') ...[
              Builder(
                builder: (context) {
                  if (series.isEmpty) return const SizedBox.shrink();
                  final double bmi = series.last.y;
                  String label;
                  Color bg;
                  Color fg;

                  if (bmi < 18.5) {
                    label = 'Underweight';
                    bg = Colors.orange.withOpacity(0.15);
                    fg = Colors.orange;
                  } else if (bmi < 25) {
                    label = 'Normal BMI';
                    bg = Colors.green.withOpacity(0.15);
                    fg = Colors.green;
                  } else if (bmi < 30) {
                    label = 'Overweight';
                    bg = Colors.amber.withOpacity(0.15);
                    fg = Colors.amber;
                  } else {
                    label = 'Obesity';
                    bg = Colors.red.withOpacity(0.15);
                    fg = Colors.redAccent;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: fg.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                label == 'Normal BMI' ? Icons.check_circle : Icons.info,
                                color: fg,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'BMI ${bmi.toStringAsFixed(1)}',
                                style: TextStyle(color: fg.withOpacity(0.9), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20), // More space between header and chart
            Expanded(
              child: BarChart(
                BarChartData(
                  minY: safeDisplayMinY,
                  maxY: safeDisplayMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      // Highlight zero line for Z-score charts
                      if (isZScore && value == 0) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.6),
                          strokeWidth: 1.5,
                        );
                      }
                      return FlLine(
                        color: Colors.grey[800]!.withOpacity(0.3),
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey[700]!.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60, // Increased reserved space for larger text
                        interval: (safeDisplayMaxY - safeDisplayMinY) / 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12, // Larger axis text
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50, // Increased reserved space
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < series.length) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(series[index].x.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  DateFormat('MM/dd').format(dt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11, // Larger date text
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.all(12), // Larger tooltip padding
                      tooltipMargin: 12,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = DateTime.fromMillisecondsSinceEpoch(series[groupIndex].x.toInt());
                        final formatted = DateFormat('MMM d, yyyy').format(date);
                        return BarTooltipItem(
                          '$formatted\n${rod.toY.toStringAsFixed(2)} $unit${isZScore ? _getZScoreInterpretation(rod.toY) : ''}',
                          TextStyle(
                            color: Colors.white, 
                            fontSize: 14, // Larger tooltip text
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: series.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final value = point.y;
                    
                    // For Z-score charts, determine bar direction and color
                    Color barColor = color;
                    BorderRadius barRadius;
                    LinearGradient barGradient;
                    
                    if (isZScore) {
                      // Color coding for Z-scores
                      if (value < -2) {
                        barColor = Colors.red; // Severely below normal
                      } else if (value < -1) {
                        barColor = Colors.orange; // Below normal
                      } else if (value > 2) {
                        barColor = Colors.red; // Severely above normal
                      } else if (value > 1) {
                        barColor = Colors.orange; // Above normal
                      } else {
                        barColor = Colors.green; // Normal range
                      }
                      
                      // Set border radius based on positive/negative value
                      if (value >= 0) {
                        // Positive values - rounded top
                        barRadius = const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        );
                        barGradient = LinearGradient(
                          colors: [
                            barColor.withOpacity(0.7),
                            barColor,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        );
                      } else {
                        // Negative values - rounded bottom
                        barRadius = const BorderRadius.only(
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        );
                        barGradient = LinearGradient(
                          colors: [
                            barColor.withOpacity(0.7),
                            barColor,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        );
                      }
                    } else {
                      // Regular charts - always positive, rounded top
                      barRadius = const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      );
                      barGradient = LinearGradient(
                        colors: [
                          color.withOpacity(0.7),
                          color,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      );
                    }
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          fromY: isZScore ? 0 : safeDisplayMinY, // Start from 0 for Z-scores
                          toY: value,
                          color: barColor,
                          width: series.length > 10 ? 16 : series.length > 5 ? 24 : 32,
                          borderRadius: barRadius,
                          gradient: barGradient,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      return parsed;
    }
    return null;
  }

  String _getZScoreInterpretation(double zScore) {
    if (zScore < -3) {
      return '\nSeverely Low';
    } else if (zScore < -2) {
      return '\nLow';
    } else if (zScore < -1) {
      return '\nBelow Average';
    } else if (zScore > 3) {
      return '\nSeverely High';
    } else if (zScore > 2) {
      return '\nHigh';
    } else if (zScore > 1) {
      return '\nAbove Average';
    } else {
      return '\nNormal';
    }
  }
}

class _Point {
  final double x;
  final double y;
  _Point(this.x, this.y);
}