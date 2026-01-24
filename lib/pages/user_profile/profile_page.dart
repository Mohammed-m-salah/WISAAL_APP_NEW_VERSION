import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wissal_app/controller/auth_controller/logout_controller.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/user_profile/widgets/user_info.dart';

class UserProfilePage extends StatelessWidget {
  final UserModel userModel;
  const UserProfilePage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    LogOutController logoutcontroller = Get.put(LogOutController());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text('Back'),
      ),
      body: Column(
        children: [
          UserInfo(
              profileImage: userModel.profileimage ?? "",
              userName: userModel.name ?? "User",
              userEmail: userModel.email ?? ""),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {
                logoutcontroller.LogOut();
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onBackground,
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout),
                  const SizedBox(width: 8),
                  const Text(
                    'Logout',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
