import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/auth_controller/logout_controller.dart';
import 'package:wissal_app/pages/profile_page.dart/widgets/profile_info.dart';
import 'package:wissal_app/pages/profile_page.dart/widgets/settings_section.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    LogOutController logoutcontroller = Get.put(LogOutController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text('profile'.tr),
        actions: [
          IconButton(
              onPressed: () {
                logoutcontroller.LogOut();
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ProfileInfo(),
            const SettingsSection(),
          ],
        ),
      ),
    );
  }
}
