import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/auth_controller/logout_controller.dart';
import 'package:wissal_app/pages/profile_page.dart/widgets/profile_info.dart';
import 'package:wissal_app/pages/profile_page.dart/widgets/settings_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final LogOutController logoutcontroller = Get.put(LogOutController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('settings'.tr),
        actions: [
          IconButton(
            onPressed: () => _showLogoutConfirmation(context, logoutcontroller),
            icon: Icon(
              Icons.logout_rounded,
              color: theme.colorScheme.error,
            ),
            tooltip: 'logout'.tr,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: const [
            ProfileInfo(),
            SizedBox(height: 8),
            SettingsSection(),
            SizedBox(height: 100), // Space for bottom navbar
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, LogOutController controller) {
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text('logout'.tr),
          ],
        ),
        content: Text('logout_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.LogOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }
}
