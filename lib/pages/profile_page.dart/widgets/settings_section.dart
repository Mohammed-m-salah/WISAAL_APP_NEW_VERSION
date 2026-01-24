import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/theme_controller/theme_controller.dart';
import 'package:wissal_app/controller/locale_controller/locale_controller.dart';
import 'package:wissal_app/utils/responsive.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();
    final theme = Theme.of(context);

    return Container(
      margin: Responsive.margin(all: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: Responsive.borderRadius(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Responsive.padding(all: 16),
            child: Text(
              'settings'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),

          // Dark Mode Toggle
          Obx(() => _buildAnimatedToggleTile(
                context: context,
                icon: themeController.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconColor: themeController.isDarkMode
                    ? Colors.indigo
                    : Colors.orange,
                title: 'dark_mode'.tr,
                subtitle: themeController.isDarkMode
                    ? 'dark_mode_on'.tr
                    : 'light_mode_on'.tr,
                value: themeController.isDarkMode,
                onChanged: (value) {
                  themeController.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeColor: Colors.indigo,
                inactiveColor: Colors.orange,
                activeIcon: Icons.dark_mode_rounded,
                inactiveIcon: Icons.light_mode_rounded,
              )),

          const Divider(height: 1, indent: 70),

          // Language Toggle
          Obx(() => _buildLanguageToggleTile(
                context: context,
                localeController: localeController,
              )),
        ],
      ),
    );
  }

  Widget _buildAnimatedToggleTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required Color inactiveColor,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: Responsive.symmetricPadding(horizontal: 16, vertical: 8),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: Responsive.padding(all: 10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: Responsive.borderRadius(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(animation),
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: iconColor,
            size: Responsive.iconSize(24),
          ),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          subtitle,
          key: ValueKey(subtitle),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ),
      trailing: _AnimatedToggleSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        activeIcon: activeIcon,
        inactiveIcon: inactiveIcon,
      ),
    );
  }

  Widget _buildLanguageToggleTile({
    required BuildContext context,
    required LocaleController localeController,
  }) {
    final theme = Theme.of(context);
    final isArabic = localeController.currentLanguageCode == 'ar';

    return ListTile(
      contentPadding: Responsive.symmetricPadding(horizontal: 16, vertical: 8),
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: Responsive.padding(all: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          borderRadius: Responsive.borderRadius(12),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            isArabic ? '🇸🇦' : '🇺🇸',
            key: ValueKey(isArabic),
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
      title: Text(
        'language'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          localeController.currentLanguageName,
          key: ValueKey(localeController.currentLanguageName),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ),
      trailing: _LanguageToggleSwitch(
        isArabic: isArabic,
        onChanged: (value) {
          if (value) {
            localeController.setArabic();
          } else {
            localeController.setEnglish();
          }
        },
      ),
    );
  }
}

/// Animated Toggle Switch for Dark/Light mode
class _AnimatedToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _AnimatedToggleSwitch({
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 70,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: value
                ? [activeColor.withOpacity(0.8), activeColor]
                : [inactiveColor.withOpacity(0.8), inactiveColor],
          ),
          boxShadow: [
            BoxShadow(
              color: (value ? activeColor : inactiveColor).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background icons
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 8 : null,
              right: value ? null : 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  value ? inactiveIcon : activeIcon,
                  color: Colors.white.withOpacity(0.5),
                  size: 16,
                ),
              ),
            ),
            // Thumb
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: value ? 36 : 4,
              top: 4,
              bottom: 4,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: Icon(
                      value ? activeIcon : inactiveIcon,
                      key: ValueKey(value),
                      color: value ? activeColor : inactiveColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language Toggle Switch (EN/AR)
class _LanguageToggleSwitch extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<bool> onChanged;

  const _LanguageToggleSwitch({
    required this.isArabic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onChanged(!isArabic),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 80,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.primary.withOpacity(0.15),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // EN Label
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isArabic ? FontWeight.normal : FontWeight.bold,
                    color: isArabic
                        ? theme.hintColor
                        : theme.colorScheme.primary,
                  ),
                  child: const Text('EN'),
                ),
              ),
            ),
            // AR Label
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isArabic ? FontWeight.bold : FontWeight.normal,
                    color: isArabic
                        ? theme.colorScheme.primary
                        : theme.hintColor,
                  ),
                  child: const Text('AR'),
                ),
              ),
            ),
            // Sliding indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isArabic ? 42 : 4,
              top: 4,
              bottom: 4,
              child: Container(
                width: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isArabic ? '🇸🇦' : '🇺🇸',
                      key: ValueKey(isArabic),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
