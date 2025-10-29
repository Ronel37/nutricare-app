import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyBmiProgressPage extends StatefulWidget {
  @override
  State<MonthlyBmiProgressPage> createState() => _MonthlyBmiProgressPageState();
}

class _MonthlyBmiProgressPageState extends State<MonthlyBmiProgressPage> with TickerProviderStateMixin {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedTimeRange = '6months';
  // ignore: unused_field
  String _selectedChartType = 'bmi';
  String _filterAgeGroup = 'all'; // all, children, adults
  String _filterSex = 'all'; // all, male, female

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "User not logged in",
            style: TextStyle(fontSize: 18, color: Colors.redAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A3D00), Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.analytics, size: 24, color: Colors.white),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Analytics",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "Overall User Growth Analysis",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          _buildTimeRangeSelector(),
          SizedBox(width: 8),
          _buildAgeFilter(),
          SizedBox(width: 8),
          _buildSexFilter(),
          SizedBox(width: 8),
          _buildExportButton(),
          SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
            child: FutureBuilder<QuerySnapshot>(
              future: usersCollection.get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final usersData = snapshot.data?.docs;
                if (usersData == null || usersData.isEmpty) {
                  return _buildEmptyState();
                }

                return FutureBuilder<Map<String, dynamic>>(
                  future: _fetchOverallAnalytics(usersData),
                  builder: (context, analyticsSnapshot) {
                    if (analyticsSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (analyticsSnapshot.hasError) {
                      return _buildErrorState();
                    }

                    final analyticsData = analyticsSnapshot.data ?? {};
                    return _buildProfessionalDashboard(analyticsData);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            "No user data found",
            style: TextStyle(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            "Add user records to see analytics",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // New professional dashboard methods
  Widget _buildTimeRangeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeRange,
          dropdownColor: Colors.grey[900],
          style: TextStyle(color: Colors.white, fontSize: 12),
          items: [
            DropdownMenuItem(value: '3months', child: Text('3 Months')),
            DropdownMenuItem(value: '6months', child: Text('6 Months')),
            DropdownMenuItem(value: '1year', child: Text('1 Year')),
            DropdownMenuItem(value: 'all', child: Text('All Time')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTimeRange = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterAgeGroup,
          dropdownColor: Colors.grey[900],
          style: TextStyle(color: Colors.white, fontSize: 12),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Ages')),
            DropdownMenuItem(value: 'children', child: Text('≤5 years')),
            DropdownMenuItem(value: 'adults', child: Text('>5 years')),
          ],
          onChanged: (value) {
            setState(() {
              _filterAgeGroup = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSexFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterSex,
          dropdownColor: Colors.grey[900],
          style: TextStyle(color: Colors.white, fontSize: 12),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Sex')),
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
          ],
          onChanged: (value) {
            setState(() {
              _filterSex = value!;
            });
          },
        ),
      ),
    );
  }



  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D00), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () async {
          try {
            final usersData = await usersCollection.get();
            final analyticsData = await _fetchOverallAnalytics(usersData.docs);
            await _generateProfessionalReport(context, analyticsData);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error generating report: $e')),
            );
          }
        },
        icon: Icon(Icons.download, color: Colors.white, size: 20),
        tooltip: 'Export Report',
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF0A3D00),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            "Loading Analytics Data...",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          ),
          SizedBox(height: 24),
          Text(
            "Error Loading Data",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Please check your connection and try again",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: Icon(Icons.refresh),
            label: Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0A3D00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDashboard(Map<String, dynamic> analyticsData) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardHeader(analyticsData),
          SizedBox(height: 32),
          _buildStatsOverview(analyticsData),
          SizedBox(height: 32),
          _buildMalnutritionOverview(analyticsData),
          SizedBox(height: 32),
          _buildMainChart(analyticsData),
          SizedBox(height: 32),
          _buildAtRiskTable(analyticsData),
          SizedBox(height: 32),
          _buildUserInsights(analyticsData),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(Map<String, dynamic> analyticsData) {
    final totalUsers = analyticsData['totalUsers'] ?? 0;
    final totalPersons = analyticsData['totalPersons'] ?? 0;
    final lastUpdated = DateTime.now();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D00), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0A3D00).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analytics Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Comprehensive user growth and health analysis",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Live Data",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              _buildHeaderStat("Total Users", totalUsers.toString(), Icons.people),
              SizedBox(width: 24),
              _buildHeaderStat("Total Records", totalPersons.toString(), Icons.person),
              SizedBox(width: 24),
              _buildHeaderStat("Last Updated", DateFormat('MMM dd').format(lastUpdated), Icons.update),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> analyticsData) {
    final bmiStats = analyticsData['bmiStats'] ?? {};
    final growthStats = analyticsData['growthStats'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "BMI Distribution",
            [
              _buildStatItem("Underweight", bmiStats['underweight'] ?? 0, Colors.blue),
              _buildStatItem("Normal", bmiStats['normal'] ?? 0, Colors.green),
              _buildStatItem("Overweight", bmiStats['overweight'] ?? 0, Colors.orange),
              _buildStatItem("Obese", bmiStats['obese'] ?? 0, Colors.red),
            ],
            Icons.pie_chart,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Growth Metrics",
            [
              _buildStatItem("Children (≤5)", growthStats['children'] ?? 0, Colors.purple),
              _buildStatItem("Adults (>5)", growthStats['adults'] ?? 0, Colors.teal),
            ],
            Icons.trending_up,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, List<Widget> items, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart(Map<String, dynamic> analyticsData) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A3D00), Color(0xFF1B5E20)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BMI Category Distribution",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Overall user health status breakdown",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: _buildBMIBarChart(analyticsData),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIBarChart(Map<String, dynamic> analyticsData) {
    final bmiStats = analyticsData['bmiStats'] ?? {};
    final underweight = bmiStats['underweight'] ?? 0;
    final normal = bmiStats['normal'] ?? 0;
    final overweight = bmiStats['overweight'] ?? 0;
    final obese = bmiStats['obese'] ?? 0;

    final maxValue = [underweight, normal, overweight, obese].reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxValue > 0 ? maxValue * 1.2 : 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            tooltipPadding: EdgeInsets.all(12),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final categories = ['Underweight', 'Normal', 'Overweight', 'Obese'];
              final values = [underweight, normal, overweight, obese];
              
              return BarTooltipItem(
                '${categories[groupIndex]}\n${values[groupIndex]} users',
                TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final categories = ['Underweight', 'Normal', 'Overweight', 'Obese'];
                return Text(
                  categories[value.toInt()],
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 5 : 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[800]!.withOpacity(0.3),
              strokeWidth: 0.5,
            );
          },
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: underweight.toDouble(),
                color: Colors.blue,
                width: 40,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: normal.toDouble(),
                color: Colors.green,
                width: 40,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: overweight.toDouble(),
                color: Colors.orange,
                width: 40,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: obese.toDouble(),
                color: Colors.red,
                width: 40,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMalnutritionOverview(Map<String, dynamic> analyticsData) {
    final mal = analyticsData['malnutritionStats'] as Map<String, dynamic>? ?? {};
    final haz = (mal['haz'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()));
    final waz = (mal['waz'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()));
    final whz = (mal['whz'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()));

    final metrics = ['HAZ', 'WAZ', 'WHZ'];
    final severeCounts = [haz['severe'] ?? 0, waz['severe'] ?? 0, whz['severe'] ?? 0];
    final moderateCounts = [haz['moderate'] ?? 0, waz['moderate'] ?? 0, whz['moderate'] ?? 0];
    final normalCounts = [haz['normal'] ?? 0, waz['normal'] ?? 0, whz['normal'] ?? 0];

    final maxY = [
      ...severeCounts,
      ...moderateCounts,
      ...normalCounts,
    ].fold<int>(0, (p, c) => c > p ? c : p);
    // Calculate a nice rounded maxY with headroom so bars never exceed chart
    double _niceMaxY(int v) {
      if (v <= 0) return 10;
      // Choose step based on magnitude
      int step;
      if (v <= 10) step = 2; else if (v <= 25) step = 5; else if (v <= 100) step = 10; else step = 20;
      final rounded = ((v + step) / step).ceil() * step; // round up and add headroom
      return rounded.toDouble();
    }
    final double maxYDisplay = _niceMaxY(maxY);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sick, color: Colors.pinkAccent, size: 20),
              SizedBox(width: 8),
              Text(
                "Malnutrition (≤5 yrs) — HAZ/WAZ/WHZ",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              _legendDot(Colors.redAccent, 'Severe'),
              SizedBox(width: 12),
              _legendDot(Colors.orangeAccent, 'Moderate'),
              SizedBox(width: 12),
              _legendDot(Colors.greenAccent, 'Normal'),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxYDisplay,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[800]!.withOpacity(0.3), strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: TextStyle(color: Colors.white70, fontSize: 12)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i >= 0 && i < metrics.length) {
                        return Text(metrics[i], style: TextStyle(color: Colors.white70, fontSize: 12));
                      }
                      return const SizedBox.shrink();
                    },
                  )),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[700]!, width: 1)),
                barGroups: List.generate(3, (i) {
                  final total = (severeCounts[i] + moderateCounts[i] + normalCounts[i]).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: total,
                        width: 36,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                        rodStackItems: [
                          BarChartRodStackItem(0, severeCounts[i].toDouble(), Colors.redAccent),
                          BarChartRodStackItem(severeCounts[i].toDouble(), (severeCounts[i] + moderateCounts[i]).toDouble(), Colors.orangeAccent),
                          BarChartRodStackItem((severeCounts[i] + moderateCounts[i]).toDouble(), total, Colors.greenAccent),
                        ],
                        color: Colors.transparent,
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: EdgeInsets.all(10),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = metrics[group.x.toInt()];
                      return BarTooltipItem(
                        '$label\nSevere: ${severeCounts[group.x.toInt()]}\nModerate: ${moderateCounts[group.x.toInt()]}\nNormal: ${normalCounts[group.x.toInt()]}',
                        TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
  Widget _buildAtRiskTable(Map<String, dynamic> analyticsData) {
    final atRisk = (analyticsData['atRisk'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final allAtRisk = (analyticsData['allAtRisk'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('At-Risk Individuals', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Spacer(),
            if (allAtRisk.length > 5)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Text(
                  '${allAtRisk.length} total',
                  style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            SizedBox(width: 8),
            _riskBadge('Severe', Colors.redAccent),
            SizedBox(width: 8),
            _riskBadge('Moderate', Colors.orangeAccent),
            SizedBox(width: 8),
            _riskBadge('At Risk', Colors.amber),
          ]),
          SizedBox(height: 12),
          if (atRisk.isEmpty)
            Text('No at-risk individuals found', style: TextStyle(color: Colors.white70))
          else ...[
            // Show limited records (top 5)
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: atRisk.map((person) => _buildPersonRiskCard(person)).toList(),
              ),
            ),
            if (allAtRisk.length > 5) ...[
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _showAllAtRiskDialog(allAtRisk),
                  icon: Icon(Icons.visibility, size: 16),
                  label: Text('View All ${allAtRisk.length} At-Risk Individuals'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ]
        ],
      ),
    );
  }

  Widget _buildPersonRiskCard(Map<String, dynamic> person) {
    final String name = person['name'] ?? '-';
    final String age = (person['age'] ?? '-').toString();
    final String sex = ((person['sex'] ?? '-').toString()).toUpperCase();
    final DateTime? updated = person['updatedAt'] as DateTime?;
    final bool isChild = person['isChild'] == true;
    
    // Collect all risks for this person
    List<Map<String, dynamic>> risks = [];
    
    // BMI risk
    if (person['bmiRisk'] != null) {
      risks.add({
        'type': 'BMI',
        'value': person['bmi'],
        'risk': person['bmiRisk'],
        'color': _getRiskColor(person['bmiRisk']),
      });
    }
    
    // Anthropometric risks for children ≤5 years
    if (isChild) {
      if (person['hazRisk'] != null) {
        risks.add({
          'type': 'HAZ',
          'value': person['haz'],
          'risk': person['hazRisk'],
          'color': _getRiskColor(person['hazRisk']),
        });
      }
      if (person['wazRisk'] != null) {
        risks.add({
          'type': 'WAZ',
          'value': person['waz'],
          'risk': person['wazRisk'],
          'color': _getRiskColor(person['wazRisk']),
        });
      }
      if (person['whzRisk'] != null) {
        risks.add({
          'type': 'WHZ',
          'value': person['whz'],
          'risk': person['whzRisk'],
          'color': _getRiskColor(person['whzRisk']),
        });
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with person info
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Age: $age • Sex: $sex', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    if (updated != null)
                      Text('Updated: ${DateFormat('MMM d, yyyy').format(updated)}', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final String? userId = person['userId'] as String?;
                  final String? personId = person['personId'] as String?;
                  if (userId == null || personId == null) return;
                  await _generateIndividualReport(context, userId, personId);
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Risk metrics
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: risks.map((risk) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: risk['color'].withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: risk['color'].withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    risk['risk'].toString().contains('Severe') ? Icons.error : Icons.warning,
                    color: risk['color'],
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '${risk['type']}: ',
                    style: TextStyle(
                      color: risk['color'].withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${risk['value'] is num ? risk['value'].toStringAsFixed(risk['type'] == 'BMI' ? 1 : 2) : '-'}',
                    style: TextStyle(
                      color: risk['color'],
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    risk['risk'],
                    style: TextStyle(
                      color: risk['color'],
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String? risk) {
    if (risk == null) return Colors.grey;
    if (risk.contains('Severe')) return Colors.redAccent;
    if (risk.contains('Moderate') || risk.contains('Stunting') || risk.contains('Underweight') || risk.contains('Wasting')) return Colors.orangeAccent;
    return Colors.amber;
  }

  void _showAllAtRiskDialog(List<Map<String, dynamic>> allAtRisk) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'All At-Risk Individuals (${allAtRisk.length})',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: allAtRisk.map((person) => _buildPersonRiskCard(person)).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _generateAtRiskPDF(allAtRisk),
                      icon: Icon(Icons.picture_as_pdf, size: 16),
                      label: Text('Export to PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A3D00),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAtRiskPDF(List<Map<String, dynamic>> atRiskData) async {
    try {
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
      
      // ignore: unused_local_variable
      final headerStyle = pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      );
      
      // ignore: unused_local_variable
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
                  'At-Risk Individuals Report',
                  style: titleStyle,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated on: ${DateFormat('MMMM dd, yyyy - HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: gray),
              ),
              pw.SizedBox(height: 20),
              
              // At-Risk Individuals
              ...atRiskData.map((person) {
                final String name = person['name'] ?? '-';
                final String age = (person['age'] ?? '-').toString();
                final String sex = ((person['sex'] ?? '-').toString()).toUpperCase();
                final bool isChild = person['isChild'] == true;
                
                // Collect all risks for this person
                List<String> riskEntries = [];
                
                // BMI risk
                if (person['bmiRisk'] != null) {
                  final bmi = person['bmi'] as num?;
                  riskEntries.add('BMI: ${bmi?.toStringAsFixed(1) ?? '-'} (${person['bmiRisk']})');
                }
                
                // Anthropometric risks for children ≤5 years
                if (isChild) {
                  if (person['hazRisk'] != null) {
                    final haz = person['haz'] as num?;
                    riskEntries.add('HAZ: ${haz?.toStringAsFixed(2) ?? '-'} (${person['hazRisk']})');
                  }
                  if (person['wazRisk'] != null) {
                    final waz = person['waz'] as num?;
                    riskEntries.add('WAZ: ${waz?.toStringAsFixed(2) ?? '-'} (${person['wazRisk']})');
                  }
                  if (person['whzRisk'] != null) {
                    final whz = person['whz'] as num?;
                    riskEntries.add('WHZ: ${whz?.toStringAsFixed(2) ?? '-'} (${person['whzRisk']})');
                  }
                }
                
                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 16),
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.SizedBox(width: 8),
                          pw.Text('Age: $age', style: pw.TextStyle(fontSize: 10, color: gray)),
                          pw.SizedBox(width: 8),
                          pw.Text('Sex: $sex', style: pw.TextStyle(fontSize: 10, color: gray)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Risk Metrics:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(riskEntries.join(' • '), style: pw.TextStyle(fontSize: 9, color: gray)),
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
        name: 'At_Risk_Individuals_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Widget _riskBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _labeledCell(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildUserInsights(Map<String, dynamic> analyticsData) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[800]!, Colors.purple[900]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.lightbulb, color: Colors.white, size: 24),
              ),
              SizedBox(width: 16),
              Text(
                "Key Insights & Recommendations",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildInsightItem(
            "Health Status Overview",
            "Monitor users with high BMI values and provide targeted health recommendations.",
            Icons.health_and_safety,
            Colors.green,
          ),
          _buildInsightItem(
            "Growth Monitoring",
            "Track pediatric growth patterns for children under 5 years old.",
            Icons.child_care,
            Colors.blue,
          ),
          _buildInsightItem(
            "Data Quality",
            "Ensure regular data updates for accurate analytics and insights.",
            Icons.data_usage,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchOverallAnalytics(List<QueryDocumentSnapshot> usersData) async {
    try {
      int totalUsers = usersData.length;
      int totalPersons = 0;
      Map<String, int> bmiStats = {
        'underweight': 0,
        'normal': 0,
        'overweight': 0,
        'obese': 0,
      };
      Map<String, int> growthStats = {
        'children': 0,
        'adults': 0,
      };
      List<double> heights = [];
      List<double> weights = [];
      // malnutrition stats for children only (≤5 years)
      Map<String, int> hazStats = {'severe': 0, 'moderate': 0, 'normal': 0};
      Map<String, int> wazStats = {'severe': 0, 'moderate': 0, 'normal': 0};
      Map<String, int> whzStats = {'severe': 0, 'moderate': 0, 'normal': 0};
      // monthly BMI trend
      Map<String, List<double>> monthToBmis = {};
      // at-risk individuals (top 20) - grouped by person
      List<Map<String, dynamic>> atRisk = [];
      Map<String, Map<String, dynamic>> personRiskMap = {};

      // Fetch all persons per user in parallel
      final List<Future<QuerySnapshot>> personFutures = usersData.map((userDoc) {
        final userId = userDoc.id;
        return FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('persons')
            .get();
      }).toList();

      final List<QuerySnapshot> personSnapshots = await Future.wait(personFutures);

      for (final personSnapshot in personSnapshots) {
        totalPersons += personSnapshot.docs.length;
        
        for (var personDoc in personSnapshot.docs) {
          final person = personDoc.data() as Map<String, dynamic>;
          final dynamic bmiRaw = person['bmi'];
          final double? bmi = bmiRaw is num ? bmiRaw.toDouble() : null;
          final int? age = person['age'] as int?;
          final double? height = _toDouble(person['height']);
          final double? weight = _toDouble(person['weight']);
          final double? haz = _toDouble(person['haz']);
          final double? waz = _toDouble(person['waz']);
          final double? whz = _toDouble(person['whz']);
          final String? sexVal = (person['sex'] as String?)?.toLowerCase();
          final String first = (person['firstname'] ?? '').toString();
          final String last = (person['lastname'] ?? '').toString();
          final String name = (first + ' ' + last).trim().isEmpty ? (person['name'] ?? 'Person') : (first + ' ' + last).trim();
          final DateTime? ts = _parseTimestamp(person['timestamp']);
          final String personId = personDoc.id;
          final String ownerUserId = personSnapshot.docs.first.reference.parent.parent!.id;

          // Apply filters
          bool passesSex = _filterSex == 'all' || (sexVal == _filterSex);
          bool passesAge = _filterAgeGroup == 'all' || (_filterAgeGroup == 'children' ? (age ?? 99) <= 5 : (age ?? 0) > 5);
          if (!passesSex || !passesAge) {
            continue;
          }

          if (bmi != null) {
            if (bmi < 18.5) {
              bmiStats['underweight'] = bmiStats['underweight']! + 1;
            } else if (bmi < 25) {
              bmiStats['normal'] = bmiStats['normal']! + 1;
            } else if (bmi < 30) {
              bmiStats['overweight'] = bmiStats['overweight']! + 1;
            } else {
              bmiStats['obese'] = bmiStats['obese']! + 1;
            }
            // At-risk determination by BMI
            String? bmiRisk;
            if (bmi < 16) bmiRisk = 'Severely Underweight';
            else if (bmi < 18.5) bmiRisk = 'Underweight';
            else if (bmi >= 30) bmiRisk = 'Obese';
            
            // Initialize person risk entry if not exists
            if (!personRiskMap.containsKey(personId)) {
              personRiskMap[personId] = {
                'name': name,
                'age': age,
                'sex': sexVal ?? '-',
                'updatedAt': ts,
                'userId': ownerUserId,
                'personId': personId,
                'bmi': bmi,
                'bmiRisk': bmiRisk,
                'haz': null,
                'hazRisk': null,
                'waz': null,
                'wazRisk': null,
                'whz': null,
                'whzRisk': null,
                'isChild': (age ?? 99) <= 5,
              };
            } else {
              personRiskMap[personId]!['bmi'] = bmi;
              personRiskMap[personId]!['bmiRisk'] = bmiRisk;
            }
            // Monthly BMI trend
            if (ts != null) {
              final monthKey = DateFormat('MMMM yyyy').format(ts);
              monthToBmis.putIfAbsent(monthKey, () => []).add(bmi);
            }
          }

          if (age != null) {
            if (age <= 5) {
              growthStats['children'] = growthStats['children']! + 1;
            } else {
              growthStats['adults'] = growthStats['adults']! + 1;
            }
          }

          if (height != null) heights.add(height);
          if (weight != null) weights.add(weight);

          // Malnutrition stats for children only
          if ((age ?? 99) <= 5) {
            if (haz != null) {
              if (haz < -3) hazStats['severe'] = hazStats['severe']! + 1;
              else if (haz < -2) hazStats['moderate'] = hazStats['moderate']! + 1;
              else hazStats['normal'] = hazStats['normal']! + 1;
              // At-risk for HAZ
              String? hzRisk;
              if (haz < -3) hzRisk = 'Severe Stunting (HAZ)';
              else if (haz < -2) hzRisk = 'Stunting (HAZ)';
              
              // Update person risk entry with HAZ data
              if (!personRiskMap.containsKey(personId)) {
                personRiskMap[personId] = {
                  'name': name,
                  'age': age,
                  'sex': sexVal ?? '-',
                  'updatedAt': ts,
                  'userId': ownerUserId,
                  'personId': personId,
                  'bmi': null,
                  'bmiRisk': null,
                  'haz': haz,
                  'hazRisk': hzRisk,
                  'waz': null,
                  'wazRisk': null,
                  'whz': null,
                  'whzRisk': null,
                  'isChild': (age ?? 99) <= 5,
                };
              } else {
                personRiskMap[personId]!['haz'] = haz;
                personRiskMap[personId]!['hazRisk'] = hzRisk;
              }
            }
            if (waz != null) {
              if (waz < -3) wazStats['severe'] = wazStats['severe']! + 1;
              else if (waz < -2) wazStats['moderate'] = wazStats['moderate']! + 1;
              else wazStats['normal'] = wazStats['normal']! + 1;
              String? wzRisk;
              if (waz < -3) wzRisk = 'Severe Underweight (WAZ)';
              else if (waz < -2) wzRisk = 'Underweight (WAZ)';
              
              // Update person risk entry with WAZ data
              if (!personRiskMap.containsKey(personId)) {
                personRiskMap[personId] = {
                  'name': name,
                  'age': age,
                  'sex': sexVal ?? '-',
                  'updatedAt': ts,
                  'userId': ownerUserId,
                  'personId': personId,
                  'bmi': null,
                  'bmiRisk': null,
                  'haz': null,
                  'hazRisk': null,
                  'waz': waz,
                  'wazRisk': wzRisk,
                  'whz': null,
                  'whzRisk': null,
                  'isChild': (age ?? 99) <= 5,
                };
              } else {
                personRiskMap[personId]!['waz'] = waz;
                personRiskMap[personId]!['wazRisk'] = wzRisk;
              }
            }
            if (whz != null) {
              if (whz < -3) whzStats['severe'] = whzStats['severe']! + 1;
              else if (whz < -2) whzStats['moderate'] = whzStats['moderate']! + 1;
              else whzStats['normal'] = whzStats['normal']! + 1;
              String? whzRisk;
              if (whz < -3) whzRisk = 'Severe Wasting (WHZ)';
              else if (whz < -2) whzRisk = 'Wasting (WHZ)';
              
              // Update person risk entry with WHZ data
              if (!personRiskMap.containsKey(personId)) {
                personRiskMap[personId] = {
                  'name': name,
                  'age': age,
                  'sex': sexVal ?? '-',
                  'updatedAt': ts,
                  'userId': ownerUserId,
                  'personId': personId,
                  'bmi': null,
                  'bmiRisk': null,
                  'haz': null,
                  'hazRisk': null,
                  'waz': null,
                  'wazRisk': null,
                  'whz': whz,
                  'whzRisk': whzRisk,
                  'isChild': (age ?? 99) <= 5,
                };
              } else {
                personRiskMap[personId]!['whz'] = whz;
                personRiskMap[personId]!['whzRisk'] = whzRisk;
              }
            }
          }
        }
      }

      // Sort monthly trend chronologically
      final months = monthToBmis.keys.toList()
        ..sort((a, b) => DateFormat('MMMM yyyy').parse(a).compareTo(DateFormat('MMMM yyyy').parse(b)));
      final monthlyTrend = months.map((m) {
        final list = monthToBmis[m]!;
        final avg = list.reduce((a, b) => a + b) / list.length;
        return {'month': m, 'avgBmi': avg};
      }).toList();

      // Convert personRiskMap to atRisk list, filtering for people with any risk
      atRisk = personRiskMap.values.where((person) {
        return person['bmiRisk'] != null || 
               person['hazRisk'] != null || 
               person['wazRisk'] != null || 
               person['whzRisk'] != null;
      }).toList();
      
      // Sort at-risk list by risk severity and limit to top 5 for lightweight display
      atRisk.sort((a, b) {
        // Calculate risk score for sorting
        double getRiskScore(Map<String, dynamic> person) {
          double score = 0;
          // BMI risk scoring
          final bmi = person['bmi'] as num?;
          if (bmi != null) {
            if (bmi < 16) score += 10; // Severely underweight
            else if (bmi < 18.5) score += 5; // Underweight
            else if (bmi >= 30) score += 8; // Obese
          }
          // Z-score risk scoring (for children ≤5)
          if (person['isChild'] == true) {
            if (person['hazRisk']?.toString().contains('Severe') == true) score += 8;
            else if (person['hazRisk']?.toString().contains('Stunting') == true) score += 4;
            if (person['wazRisk']?.toString().contains('Severe') == true) score += 8;
            else if (person['wazRisk']?.toString().contains('Underweight') == true) score += 4;
            if (person['whzRisk']?.toString().contains('Severe') == true) score += 8;
            else if (person['whzRisk']?.toString().contains('Wasting') == true) score += 4;
          }
          return score;
        }
        return getRiskScore(b).compareTo(getRiskScore(a));
      });
      
      // Store all at-risk individuals for "View All" functionality
      final allAtRisk = List<Map<String, dynamic>>.from(atRisk);
      
      // Limit to top 5 for lightweight display
      if (atRisk.length > 5) atRisk = atRisk.sublist(0, 5);

      return {
        'totalUsers': totalUsers,
        'totalPersons': totalPersons,
        'bmiStats': bmiStats,
        'growthStats': {
          ...growthStats,
          'avgHeight': heights.isNotEmpty ? heights.reduce((a, b) => a + b) / heights.length : 0,
          'avgWeight': weights.isNotEmpty ? weights.reduce((a, b) => a + b) / weights.length : 0,
        },
        'malnutritionStats': {
          'haz': hazStats,
          'waz': wazStats,
          'whz': whzStats,
        },
        'monthlyBmiTrend': monthlyTrend,
        'atRisk': atRisk,
        'allAtRisk': allAtRisk, // Store all at-risk individuals for "View All" functionality
      };
    } catch (e) {
      print('Error fetching overall analytics: $e');
      return {};
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Future<void> _generateProfessionalReport(BuildContext context, Map<String, dynamic> analyticsData) async {
    try {
      final pdf = pw.Document();

      // Colors and styles
      final primary = PdfColor.fromInt(0xFF0A3D00);
      final gray = PdfColors.grey700;
      final titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
      final sectionTitle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
      final labelStyle = pw.TextStyle(fontSize: 10, color: gray);
      final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

      // Extract data
      final int totalUsers = (analyticsData['totalUsers'] ?? 0) as int;
      final int totalPersons = (analyticsData['totalPersons'] ?? 0) as int;
      final Map<String, dynamic> bmiStats = (analyticsData['bmiStats'] as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> mal = (analyticsData['malnutritionStats'] as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> haz = (mal['haz'] as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> waz = (mal['waz'] as Map<String, dynamic>? ?? {});
      final Map<String, dynamic> whz = (mal['whz'] as Map<String, dynamic>? ?? {});
      final List<dynamic> atRisk = (analyticsData['atRisk'] as List<dynamic>? ?? []);

      // Helper KPI widget
      pw.Widget kpiTile(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: labelStyle),
              pw.SizedBox(height: 4),
              pw.Text(value, style: valueStyle),
            ],
          ),
        );
      }

      // Header
      final now = DateTime.now();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 10,
                  height: 28,
                  decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(4)),
                ),
                pw.SizedBox(width: 10),
                pw.Text('Professional Analytics Report', style: titleStyle),
                pw.Spacer(),
                pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(now), style: pw.TextStyle(color: gray, fontSize: 10)),
              ],
            ),
          ),
          build: (ctx) => [
            // Summary KPIs
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(child: kpiTile('Total Users', totalUsers.toString())),
                pw.SizedBox(width: 12),
                pw.Expanded(child: kpiTile('Total Records', totalPersons.toString())),
              ],
            ),

            pw.SizedBox(height: 18),
            // BMI Distribution Table
            pw.Text('BMI Distribution', style: sectionTitle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Category', 'Count'],
              data: [
                ['Underweight', (bmiStats['underweight'] ?? 0).toString()],
                ['Normal', (bmiStats['normal'] ?? 0).toString()],
                ['Overweight', (bmiStats['overweight'] ?? 0).toString()],
                ['Obese', (bmiStats['obese'] ?? 0).toString()],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellHeight: 22,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
            ),

            pw.SizedBox(height: 18),
            // Pediatric Malnutrition Table
            pw.Text('Pediatric Malnutrition (≤5 yrs) — HAZ / WAZ / WHZ', style: sectionTitle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.center,
              headers: ['Metric', 'Severe', 'Moderate', 'Normal'],
              data: [
                ['HAZ', (haz['severe'] ?? 0).toString(), (haz['moderate'] ?? 0).toString(), (haz['normal'] ?? 0).toString()],
                ['WAZ', (waz['severe'] ?? 0).toString(), (waz['moderate'] ?? 0).toString(), (waz['normal'] ?? 0).toString()],
                ['WHZ', (whz['severe'] ?? 0).toString(), (whz['moderate'] ?? 0).toString(), (whz['normal'] ?? 0).toString()],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellHeight: 22,
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
              },
            ),

            pw.SizedBox(height: 18),
            // At-Risk Individuals Table
            pw.Text('At-Risk Individuals', style: sectionTitle),
            pw.SizedBox(height: 8),
            if (atRisk.isEmpty)
              pw.Text('No at-risk individuals found', style: pw.TextStyle(color: gray, fontSize: 11))
            else
              pw.Column(
                children: atRisk.map((person) {
                  final String name = (person['name'] ?? '-').toString();
                  final String age = (person['age'] ?? '-').toString();
                  final String sex = (person['sex'] ?? '-').toString().toUpperCase();
                  final DateTime? updated = person['updatedAt'] is DateTime ? person['updatedAt'] as DateTime : null;
                  final String updatedStr = updated != null ? DateFormat('dd MMM yyyy').format(updated) : '-';
                  final bool isChild = person['isChild'] == true;
                  
                  // Collect all risks for this person
                  List<String> riskEntries = [];
                  
                  // BMI risk
                  if (person['bmiRisk'] != null) {
                    final bmi = person['bmi'] as num?;
                    riskEntries.add('BMI: ${bmi?.toStringAsFixed(1) ?? '-'} (${person['bmiRisk']})');
                  }
                  
                  // Anthropometric risks for children ≤5 years
                  if (isChild) {
                    if (person['hazRisk'] != null) {
                      final haz = person['haz'] as num?;
                      riskEntries.add('HAZ: ${haz?.toStringAsFixed(2) ?? '-'} (${person['hazRisk']})');
                    }
                    if (person['wazRisk'] != null) {
                      final waz = person['waz'] as num?;
                      riskEntries.add('WAZ: ${waz?.toStringAsFixed(2) ?? '-'} (${person['wazRisk']})');
                    }
                    if (person['whzRisk'] != null) {
                      final whz = person['whz'] as num?;
                      riskEntries.add('WHZ: ${whz?.toStringAsFixed(2) ?? '-'} (${person['whzRisk']})');
                    }
                  }
                  
                  return pw.Container(
                    margin: pw.EdgeInsets.only(bottom: 8),
                    padding: pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            pw.SizedBox(width: 8),
                            pw.Text('Age: $age', style: pw.TextStyle(fontSize: 10, color: gray)),
                            pw.SizedBox(width: 8),
                            pw.Text('Sex: $sex', style: pw.TextStyle(fontSize: 10, color: gray)),
                            pw.Spacer(),
                            pw.Text('Updated: $updatedStr', style: pw.TextStyle(fontSize: 9, color: gray)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Risk Metrics:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(riskEntries.join(' • '), style: pw.TextStyle(fontSize: 9, color: gray)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
          footer: (ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              children: [
                pw.Text('NutriCare Analytics', style: pw.TextStyle(color: gray, fontSize: 10)),
                pw.Spacer(),
                pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: pw.TextStyle(color: gray, fontSize: 10)),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Professional_Analytics_Report.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: $e')),
      );
    }
  }

  Future<void> _generateIndividualReport(BuildContext context, String userId, String personId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('persons')
          .doc(personId)
          .get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person not found')),
        );
        return;
      }
      final p = doc.data() as Map<String, dynamic>;

      final String name = (((p['firstname'] ?? '') as String) + ' ' + ((p['lastname'] ?? '') as String)).trim().isEmpty
          ? (p['name'] ?? 'Person').toString()
          : (((p['firstname'] ?? '') as String) + ' ' + ((p['lastname'] ?? '') as String)).trim();
      final int? age = p['age'] is num ? (p['age'] as num).toInt() : null;
      final String sex = (p['sex'] ?? '-').toString().toUpperCase();
      final double? height = p['height'] is num ? (p['height'] as num).toDouble() : null;
      final double? weight = p['weight'] is num ? (p['weight'] as num).toDouble() : null;
      final double? bmi = p['bmi'] is num ? (p['bmi'] as num).toDouble() : null;
      final double? haz = p['haz'] is num ? (p['haz'] as num).toDouble() : null;
      final double? waz = p['waz'] is num ? (p['waz'] as num).toDouble() : null;
      final double? whz = p['whz'] is num ? (p['whz'] as num).toDouble() : null;
      final DateTime? updated = _parseTimestamp(p['timestamp']);

      final pdf = pw.Document();
      final primary = PdfColor.fromInt(0xFF0A3D00);
      final gray = PdfColors.grey700;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          header: (ctx) => pw.Row(children: [
            pw.Container(width: 10, height: 24, decoration: pw.BoxDecoration(color: primary, borderRadius: pw.BorderRadius.circular(4))),
            pw.SizedBox(width: 8),
            pw.Text('Individual Health Report', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Spacer(),
            pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()), style: pw.TextStyle(color: gray, fontSize: 10))
          ]),
          build: (ctx) => [
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Age: ${age ?? '-'}   Sex: $sex', style: pw.TextStyle(color: gray, fontSize: 11)),
                ])),
                pw.SizedBox(width: 12),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Updated: ${updated != null ? DateFormat('dd MMM yyyy').format(updated) : '-'}', style: pw.TextStyle(color: gray, fontSize: 10)),
                ])
              ]),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headers: ['Metric', 'Value', 'Notes'],
              data: [
                ['Height (cm)', height?.toStringAsFixed(1) ?? '-', ''],
                ['Weight (kg)', weight?.toStringAsFixed(1) ?? '-', ''],
                ['BMI', bmi?.toStringAsFixed(1) ?? '-', _bmiNote(bmi)],
                if ((age ?? 0) <= 5) ...[
                  ['HAZ (z)', haz?.toStringAsFixed(2) ?? '-', _zNote('HAZ', haz)],
                  ['WAZ (z)', waz?.toStringAsFixed(2) ?? '-', _zNote('WAZ', waz)],
                  ['WHZ (z)', whz?.toStringAsFixed(2) ?? '-', _zNote('WHZ', whz)],
                ]
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 22,
            ),
          ],
          footer: (ctx) => pw.Row(children: [
            pw.Text('NutriCare • Confidential', style: pw.TextStyle(color: gray, fontSize: 10)),
            pw.Spacer(),
            pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: pw.TextStyle(color: gray, fontSize: 10)),
          ]),
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '${name.replaceAll(' ', '_')}_Report.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating individual report: $e')),
      );
    }
  }

  String _bmiNote(double? bmi) {
    if (bmi == null) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obesity';
  }

  String _zNote(String metric, double? z) {
    if (z == null) return '';
    if (z < -3) return 'Severe low $metric';
    if (z < -2) return 'Low $metric';
    if (z > 3) return 'Severe high $metric';
    if (z > 2) return 'High $metric';
    return 'Normal';
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return null;
  }
}