import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/theme_controller/theme_controller.dart';
import 'package:wissal_app/controller/locale_controller/locale_controller.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final localeController = Get.find<LocaleController>();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'settings'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const Divider(height: 1),

          // Theme Setting
          Obx(() => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeController.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text('theme'.tr),
                subtitle: Text(themeController.themeModeLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, themeController),
              )),

          const Divider(height: 1, indent: 70),

          // Language Setting
          Obx(() => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text('language'.tr),
                subtitle: Text(localeController.currentLanguageName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, localeController),
              )),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text('theme'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => _buildThemeOption(
                  context,
                  ThemeMode.system,
                  'system_mode'.tr,
                  Icons.settings_suggest,
                  controller,
                )),
            Obx(() => _buildThemeOption(
                  context,
                  ThemeMode.light,
                  'light_mode'.tr,
                  Icons.light_mode,
                  controller,
                )),
            Obx(() => _buildThemeOption(
                  context,
                  ThemeMode.dark,
                  'dark_mode'.tr,
                  Icons.dark_mode,
                  controller,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    ThemeController controller,
  ) {
    final isSelected = controller.themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        controller.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text('select_language'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => _buildLanguageOption(
                  context,
                  'English',
                  'en',
                  controller,
                )),
            Obx(() => _buildLanguageOption(
                  context,
                  'العربية',
                  'ar',
                  controller,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    String langCode,
    LocaleController controller,
  ) {
    final isSelected = controller.currentLanguageCode == langCode;
    return ListTile(
      leading: Text(
        langCode == 'en' ? '🇺🇸' : '🇸🇦',
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        if (langCode == 'en') {
          controller.setEnglish();
        } else {
          controller.setArabic();
        }
        Navigator.pop(context);
      },
    );
  }
}
