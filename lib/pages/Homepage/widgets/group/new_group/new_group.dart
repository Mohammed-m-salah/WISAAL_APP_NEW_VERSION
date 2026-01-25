import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/new_group/group_title.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/new_group/selectedMemberList.dart';
import '../../../../../model/user_model.dart';

class NewGroup extends StatelessWidget {
  NewGroup({super.key});

  final ContactController contactController = Get.put(ContactController());
  final GroupController groupController = Get.put(GroupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Group',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: Obx(() {
        final isEnabled = groupController.selectedMembers.isNotEmpty;

        return FloatingActionButton(
          backgroundColor: isEnabled
              ? Theme.of(context).colorScheme.primary
              : const Color(0xff35384A),
          onPressed: () {
            if (isEnabled) {
              Get.to(() => const GroupTitle());
            } else {
              Get.snackbar(
                "تنبيه",
                "يرجى اختيار عضو واحد على الأقل قبل إنشاء المجموعة.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.8),
                colorText: Colors.white,
              );
            }
          },
          child: const Icon(Icons.arrow_forward),
        );
      }),
      body: Column(
        children: [
          SelectedMembers(),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: contactController.getContacts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("❌ Error loading contacts"));
                }

                final users = snapshot.data;

                if (users == null || users.isEmpty) {
                  return const Center(child: Text("📭 لا يوجد محادثات سابقة"));
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    // final isSelected = groupController.groupMembers
                    //     .any((member) => member.id == user.id);

                    // طباعة رابط الصورة للمراجعة
                    print('User image URL: ${user.profileimage}');

                    return InkWell(
                      onTap: () {
                        groupController.selectMember(user);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: ChatTile(
                          imgUrl: user.profileimage ??
                              'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                          name: user.name ?? 'غير معروف',
                          lastChat: user.about ?? 'لا يوجد وصف',
                          lastTime: '',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
