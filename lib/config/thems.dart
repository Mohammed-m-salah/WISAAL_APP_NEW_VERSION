import 'package:flutter/material.dart';
import 'package:wissal_app/config/colors.dart';

var lightThem = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: lPrimaryColor,
    onPrimary: Colors.white,
    surface: lSurfaceColor,
    onSurface: lonBackgroundColor,
    primaryContainer: lContainerColor,
    onPrimaryContainer: lonContainerColor,
    secondary: lPrimaryColor,
    onSecondary: Colors.white,
    error: lErrorColor,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: lBackgroundColor,
  cardColor: lCardColor,
  dividerColor: lDividerColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: lSurfaceColor,
    foregroundColor: lonBackgroundColor,
    elevation: 0,
    centerTitle: true,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: lSurfaceColor,
    selectedItemColor: lPrimaryColor,
    unselectedItemColor: lonContainerColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lContainerColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: lonContainerColor),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      color: lPrimaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w800,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      color: lonBackgroundColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      color: lonBackgroundColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: lonBackgroundColor,
      fontFamily: 'Poppins',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: lonBackgroundColor,
      fontFamily: 'Poppins',
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      color: lonContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      color: lonContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    ),
    labelSmall: TextStyle(
      fontSize: 14,
      color: lonContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
    ),
  ),
);

var darktThem = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: dPrimaryColor,
    onPrimary: Colors.white,
    surface: dSurfaceColor,
    onSurface: donBackgroundColor,
    primaryContainer: dContainerColor,
    onPrimaryContainer: donContainerColor,
    secondary: dPrimaryColor,
    onSecondary: Colors.white,
    error: dErrorColor,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: dBackgroundColor,
  cardColor: dCardColor,
  dividerColor: dDividerColor,
  appBarTheme: const AppBarTheme(
    backgroundColor: dSurfaceColor,
    foregroundColor: donBackgroundColor,
    elevation: 0,
    centerTitle: true,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: dSurfaceColor,
    selectedItemColor: dPrimaryColor,
    unselectedItemColor: donContainerColor,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: dContainerColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: donContainerColor),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      color: dPrimaryColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w800,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      color: donBackgroundColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      color: donBackgroundColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: donBackgroundColor,
      fontFamily: 'Poppins',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: donBackgroundColor,
      fontFamily: 'Poppins',
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      color: donContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(
      fontSize: 14,
      color: donContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400,
    ),
    labelSmall: TextStyle(
      fontSize: 14,
      color: donContainerColor,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w300,
    ),
  ),
);
