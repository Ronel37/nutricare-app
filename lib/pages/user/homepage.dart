import 'package:flutter/material.dart';
import 'package:nutricare_app/pages/user/BMI_calculator.dart';
import 'package:nutricare_app/pages/user/add_person.dart';
import 'package:nutricare_app/pages/user/recipe.dart';
import 'package:nutricare_app/pages/user/analytics_page.dart';
import 'package:nutricare_app/pages/user/view_records.dart';
import 'package:nutricare_app/utils/responsive_util.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    // Get responsive values
    double horizontalPadding = ResponsiveUtil.getHorizontalPadding(context);
    double verticalPadding = ResponsiveUtil.getVerticalPadding(context);
    int gridColumns = ResponsiveUtil.getGridColumnCount(context);
    double childAspectRatio = ResponsiveUtil.getChildAspectRatio(context);

    return Scaffold(
        backgroundColor: Colors.black87,
        body: Container(
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 7,
                ),
                Center(
                  child: SizedBox(
                    width: ResponsiveUtil.screenWidth(context) * 0.55,
                    height: ResponsiveUtil.screenWidth(context) * 0.55,
                    child: CustomPaint(
                      painter: BMICategoryRingsPainter(),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BMI',
                              style: TextStyle(
                                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              'Categories',
                              style: TextStyle(
                                fontSize: ResponsiveUtil.getResponsiveFontSize(context, 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtil.screenHeight(context) * 0.03),
                _buildCategoryItem(
                  icon: Icons.circle,
                  color: Colors.blue[400]!,
                  title: 'Underweight',
                  range: '< 18.5',
                  description:
                      'May indicate malnutrition or other health issues.',
                ),
                _buildCategoryItem(
                  icon: Icons.circle,
                  color: Colors.green[400]!,
                  title: 'Normal',
                  range: '18.5 - 24.9',
                  description: 'Generally associated with optimal health.',
                ),
                _buildCategoryItem(
                  icon: Icons.circle,
                  color: Colors.orange[400]!,
                  title: 'Overweight',
                  range: '25.0 - 29.9',
                  description: 'Increased risk for various health conditions.',
                ),
                _buildCategoryItem(
                  icon: Icons.circle,
                  color: Colors.red[400]!,
                  title: 'Obese',
                  range: '≥ 30.0',
                  description: 'Higher risk for serious health problems.',
                ),
                _buildCategoryItem(
                  icon: Icons.warning_rounded,
                  color: Colors.yellow[400]!,
                  title: 'WAZ (Detects Underweight)',
                  range: '≤ 5 yrs old',
                  description: 'Weight for Age Z-score',
                ),
                _buildCategoryItem(
                  icon: Icons.warning_rounded,
                  color: Colors.yellow[400]!,
                  title: 'HAZ (Detects Stunting)',
                  range: '≤ 5 yrs old',
                  description: 'Height for Age Z-score',
                ),
                 _buildCategoryItem(
                  icon: Icons.warning_rounded,
                  color: Colors.yellow[400]!,
                  title: 'WHZ (Detects Wasting)',
                  range: '≤ 5 yrs old',
                  description: 'Weight for Height Z-score',
                ),
                SizedBox(height: 15),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BMICalculatorPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 49, 46, 46),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate, size: ResponsiveUtil.getResponsiveIconSize(context, 24)),
                        SizedBox(width: 10),
                        Text(
                          'Calculate BMI',
                          style: TextStyle(
                            fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Main GridView
                GridView.count(
                  crossAxisCount: gridColumns,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    // 1. Register a Person
                    _buildRegisterPersonCard(),

                    // 2. View Records
                    _buildRecordCard(),

                    // 3. Food Recipes
                    _buildRecipeCard(context),

                    // 4. Analytics
                    _buildAnalyticsCard(),
                  ],
                ),

                SizedBox(height: 80), // Space for bottom navigation
              ],
            ),
          ),
        ));
  }

  // Add Person card
  Widget _buildRegisterPersonCard() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context) * 0.75),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add the Person you want to be Monitored!',
            style: TextStyle(
              fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddPerson()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 42, 116, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: Colors.green,
                        width: 1,
                      )),
                ),
                child: Text(
                  'Click Here!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Records card
  Widget _buildRecordCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewPersons()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context) * 0.75),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI Records',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 19),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'View, edit, update and delete the persons you added.',
                  style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 13),
                      color: Colors.white70,
                      height: 1.4,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 5),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.list_alt_rounded,
                size: ResponsiveUtil.getResponsiveIconSize(context, 85),
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Food Recipes card
  Widget _buildRecipeCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipePage()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context) * 0.75),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food Recipes',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 19),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Local Recipes, Creative Manna Pack Recipes & more..',
                  style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 13),
                      color: Colors.white70,
                      height: 1.4,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 5),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.receipt_long_rounded,
                size: ResponsiveUtil.getResponsiveIconSize(context, 85),
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Analytics card
  Widget _buildAnalyticsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnalyticsPage()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtil.getHorizontalPadding(context) * 0.75),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Growth Chart',
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 19),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Track growth, weekly changes & anthropometric trends',
                  style: TextStyle(
                      fontSize: ResponsiveUtil.getResponsiveFontSize(context, 13),
                      color: Colors.white70,
                      height: 1.4,
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 5),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(
                Icons.analytics,
                size: ResponsiveUtil.getResponsiveIconSize(context, 85),
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required Color color,
    required String title,
    required String range,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: ResponsiveUtil.getResponsiveIconSize(context, 16)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveUtil.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        range,
                        style: TextStyle(
                          fontSize: ResponsiveUtil.getResponsiveFontSize(context, 12),
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: ResponsiveUtil.getResponsiveFontSize(context, 14),
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BMICategoryRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 15.0;

    // Draw the BMI category rings
    _drawRing(canvas, center, radius - 0 * strokeWidth, Colors.blue[900]!,
        Colors.blue[400]!, strokeWidth);
    _drawRing(canvas, center, radius - 1 * strokeWidth, Colors.green[900]!,
        Colors.green[400]!, strokeWidth);
    _drawRing(canvas, center, radius - 2 * strokeWidth, Colors.orange[900]!,
        Colors.orange[400]!, strokeWidth);
    _drawRing(canvas, center, radius - 3 * strokeWidth, Colors.red[900]!,
        Colors.red[400]!, strokeWidth);
  }

  void _drawRing(Canvas canvas, Offset center, double radius, Color bgColor,
      Color ringColor, double strokeWidth) {
    final Paint backgroundPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw only a portion of each ring to create a more dynamic visual
    double startAngle = -1.5708; // Start from the top (270 degrees in radians)

    // Calculate original ring radius based on the outer radius
    double outerRadius = center.dx;

    // Draw different arc lengths for each ring based on position
    if (radius >= outerRadius - strokeWidth * 0.5) {
      // Underweight (blue) - outermost ring
      _drawPartialRing(canvas, center, radius, ringPaint, startAngle, 0.5);
    } else if (radius >= outerRadius - strokeWidth * 1.5) {
      // Normal (green)
      _drawPartialRing(
          canvas, center, radius, ringPaint, startAngle + 1.0, 0.6);
    } else if (radius >= outerRadius - strokeWidth * 2.5) {
      // Overweight (orange)
      _drawPartialRing(
          canvas, center, radius, ringPaint, startAngle + 2.0, 0.5);
    } else {
      // Obese (red) - innermost ring
      _drawPartialRing(
          canvas, center, radius, ringPaint, startAngle + 3.0, 0.4);
    }
  }

  void _drawPartialRing(Canvas canvas, Offset center, double radius,
      Paint paint, double startAngle, double portion) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      portion * 2 * 3.14159,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
