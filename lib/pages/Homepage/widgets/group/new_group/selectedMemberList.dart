import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';

class SelectedMembers extends StatelessWidget {
  const SelectedMembers({super.key});

  @override
  Widget build(BuildContext context) {
    // استدعاء الكنترولر
    GroupController groupController = Get.put(GroupController());

    return Obx(
      () => groupController.selectedMembers.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: groupController.selectedMembers.map((user) {
                  final hasValidImage = user.profileimage != null &&
                      user.profileimage!.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: hasValidImage
                              ? NetworkImage(user.profileimage!)
                              : null,
                          // إذا ما في صورة، نعرض أيقونة افتراضية داخل الـ CircleAvatar
                          child: hasValidImage
                              ? null
                              : const Icon(
                                  Icons.account_circle,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              // إزالة المستخدم من القائمة عند الضغط على الايقونة
                              groupController.selectedMembers.remove(user);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
