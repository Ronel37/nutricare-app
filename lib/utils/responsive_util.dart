import 'package:flutter/material.dart';

class ResponsiveUtil {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getHorizontalPadding(BuildContext context) {
    double width = screenWidth(context);
    if (width > 600) {
      return width * 0.1; 
    } else {
      return 20.0; 
    }
  }

  static double getVerticalPadding(BuildContext context) {
    double height = screenHeight(context);
    if (height > 1000) {
      return height * 0.05; 
    } else {
      return 15.0; 
    }
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    double width = screenWidth(context);
    double scaleFactor = width / 375.0; 
    double calculatedSize = baseFontSize * scaleFactor;
    
    return calculatedSize.clamp(baseFontSize * 0.8, baseFontSize * 1.4);
  }

  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    double width = screenWidth(context);
    double scaleFactor = width / 375.0;
    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.3);
  }

  static int getGridColumnCount(BuildContext context) {
    double width = screenWidth(context);
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 500) return 2;
    return 2; 
  }

  static double getResponsiveCardHeight(BuildContext context) {
    double height = screenHeight(context);
    if (height > 800) {
      return height * 0.18;
    } else {
      return 130;
    }
  }

  static double getChildAspectRatio(BuildContext context) {
    double width = screenWidth(context);
    if (width > 600) {
      return 1.1; 
    } else {
      return 0.85; 
    }
  }

  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }
} 