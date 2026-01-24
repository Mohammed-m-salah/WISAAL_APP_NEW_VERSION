import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double textMultiplier;
  static late double imageSizeMultiplier;
  static late double heightMultiplier;
  static late double widthMultiplier;
  static late bool isSmallScreen;
  static late bool isMediumScreen;
  static late bool isLargeScreen;
  static late bool isTablet;

  /// Initialize responsive values - call this in your main widget build
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // Calculate block sizes (percentage of screen)
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    // Multipliers based on standard design (375 x 812 - iPhone X)
    textMultiplier = blockSizeVertical;
    imageSizeMultiplier = blockSizeHorizontal;
    heightMultiplier = blockSizeVertical;
    widthMultiplier = blockSizeHorizontal;

    // Screen size flags
    isSmallScreen = screenWidth < 360;
    isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    isLargeScreen = screenWidth >= 600;
    isTablet = screenWidth >= 600;
  }

  /// Get responsive width
  static double w(double width) {
    return widthMultiplier * (width / 3.75);
  }

  /// Get responsive height
  static double h(double height) {
    return heightMultiplier * (height / 8.12);
  }

  /// Get responsive font size
  static double sp(double fontSize) {
    return textMultiplier * (fontSize / 8.12);
  }

  /// Get responsive radius
  static double r(double radius) {
    return widthMultiplier * (radius / 3.75);
  }

  /// Get responsive icon size
  static double iconSize(double size) {
    double base = widthMultiplier * (size / 3.75);
    // Clamp icon sizes to reasonable bounds
    return base.clamp(size * 0.8, size * 1.5);
  }

  /// Get responsive padding
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(w(all));
    }
    return EdgeInsets.only(
      left: left != null ? w(left) : (horizontal != null ? w(horizontal) : 0),
      right: right != null ? w(right) : (horizontal != null ? w(horizontal) : 0),
      top: top != null ? h(top) : (vertical != null ? h(vertical) : 0),
      bottom: bottom != null ? h(bottom) : (vertical != null ? h(vertical) : 0),
    );
  }

  /// Get responsive symmetric padding
  static EdgeInsets symmetricPadding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  /// Get responsive margin
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return padding(
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }

  /// Get responsive sized box width
  static SizedBox horizontalSpace(double width) {
    return SizedBox(width: w(width));
  }

  /// Get responsive sized box height
  static SizedBox verticalSpace(double height) {
    return SizedBox(height: h(height));
  }

  /// Get responsive avatar radius
  static double avatarRadius(double radius) {
    double base = w(radius);
    return base.clamp(radius * 0.8, radius * 1.3);
  }

  /// Get responsive container size
  static double containerSize(double size) {
    double base = w(size);
    return base.clamp(size * 0.8, size * 1.4);
  }

  /// Get grid cross axis count based on screen width
  static int gridCrossAxisCount({
    int smallScreen = 2,
    int mediumScreen = 3,
    int largeScreen = 4,
  }) {
    if (isSmallScreen) return smallScreen;
    if (isMediumScreen) return mediumScreen;
    return largeScreen;
  }

  /// Get responsive value based on screen size
  static T value<T>({
    required T small,
    required T medium,
    required T large,
  }) {
    if (isSmallScreen) return small;
    if (isMediumScreen) return medium;
    return large;
  }

  /// Get responsive font size with constraints
  static double fontSize(double size) {
    double scaled = sp(size);
    // Ensure readability with min/max constraints
    return scaled.clamp(size * 0.85, size * 1.3);
  }

  /// Get button height
  static double buttonHeight(double height) {
    return h(height).clamp(height * 0.9, height * 1.2);
  }

  /// Get button width
  static double buttonWidth(double width) {
    return w(width).clamp(width * 0.9, width * 1.3);
  }

  /// Get responsive border radius
  static BorderRadius borderRadius(double radius) {
    return BorderRadius.circular(r(radius));
  }

  /// Get dialog max height as percentage of screen
  static double dialogHeight(double percentage) {
    return screenHeight * percentage;
  }

  /// Get dialog max width as percentage of screen
  static double dialogWidth(double percentage) {
    return screenWidth * percentage;
  }
}

/// Extension for easy access to responsive values
extension ResponsiveExtension on num {
  /// Responsive width
  double get w => Responsive.w(toDouble());

  /// Responsive height
  double get h => Responsive.h(toDouble());

  /// Responsive font size
  double get sp => Responsive.fontSize(toDouble());

  /// Responsive radius
  double get r => Responsive.r(toDouble());
}
