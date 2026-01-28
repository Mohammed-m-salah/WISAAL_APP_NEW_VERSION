import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Glass morphism snackbar helper
class GlassSnackbar {
  /// Show a glass snackbar
  static void show({
    required String title,
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Get.isDarkMode;

    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? (isDark ? Colors.white : Colors.black87),
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
      snackPosition: position,
      duration: duration,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      backgroundColor: Colors.transparent,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ]
            : [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6),
              ],
      ),
      barBlur: 10,
      overlayBlur: 0,
      snackStyle: SnackStyle.FLOATING,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
      animationDuration: const Duration(milliseconds: 400),
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  /// Show success snackbar
  static void success({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.green,
      duration: duration,
      position: position,
    );
  }

  /// Show error snackbar
  static void error({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      iconColor: Colors.red,
      duration: duration,
      position: position,
    );
  }

  /// Show warning snackbar
  static void warning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.warning_rounded,
      iconColor: Colors.orange,
      duration: duration,
      position: position,
    );
  }

  /// Show info snackbar
  static void info({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.info_rounded,
      iconColor: Colors.blue,
      duration: duration,
      position: position,
    );
  }

  /// Show copied snackbar
  static void copied({String message = 'تم النسخ'}) {
    show(
      title: message,
      message: '',
      icon: Icons.copy_rounded,
      iconColor: Colors.blue,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show deleted snackbar
  static void deleted({String message = 'تم الحذف'}) {
    show(
      title: message,
      message: '',
      icon: Icons.delete_rounded,
      iconColor: Colors.red,
      duration: const Duration(seconds: 2),
    );
  }
}
