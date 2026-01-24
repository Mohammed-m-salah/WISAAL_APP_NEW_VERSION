import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/theme_controller/theme_controller.dart';
import 'package:wissal_app/pages/Homepage/home_page.dart';
import 'package:wissal_app/pages/contact_page/contact_page.dart';
import 'package:wissal_app/pages/profile_page.dart/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  final ThemeController themeController = Get.find<ThemeController>();
  final RxInt currentIndex = 0.obs;

  final List<Widget> pages = [
    const HomePage(),
    const ContactPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Obx(() => IndexedStack(
            index: currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Obx(() => _buildGlassNavBar(isDark)),
    );
  }

  Widget _buildGlassNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.chat_bubble_rounded,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.contacts_rounded,
                  isDark: isDark,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.settings_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = currentIndex.value == index;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? primaryColor
                  : isDark
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
