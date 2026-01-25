import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';

class GroupTitle extends StatefulWidget {
  const GroupTitle({super.key});

  @override
  State<GroupTitle> createState() => _GroupTitleState();
}

class _GroupTitleState extends State<GroupTitle> {
  final GroupController groupController = Get.put(GroupController());
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  final TextEditingController groupNameController = TextEditingController();
  final RxString imagePath = "".obs;
  RxString groupName = "".obs;

  @override
  void dispose() {
    groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Group',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          onPressed: () async {
            if (groupName.value.trim().isEmpty) {
              Get.snackbar(
                "Error",
                "Please enter a group name",
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
              return;
            }

            if (imagePath.value.trim().isEmpty) {
              Get.snackbar(
                "Error",
                "Please select a group image",
                colorText: Colors.white,
              );
              return;
            }

            if (groupController.selectedMembers.isEmpty) {
              Get.snackbar(
                "Error",
                "Please select at least one member for the group",
                colorText: Colors.white,
              );
              return;
            }

            groupController.isLoading.value = true;
            await groupController.creatGroup(
              groupName.value.trim(),
              imagePath.value,
            );
            groupController.isLoading.value = false;
            Get.back();
          },
          backgroundColor: groupName.value.trim().isEmpty
              ? Colors.grey
              : Theme.of(context).colorScheme.primary,
          child: groupController.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.check, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Obx(
                  () => GestureDetector(
                    onTap: () async {
                      final picked =
                          await imagePickerController.pickImageFromGallery();
                      if (picked.isNotEmpty) {
                        imagePath.value = picked;
                      }
                    },
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey,
                      ),
                      child: imagePath.value.isEmpty
                          ? const Icon(Icons.camera_alt,
                              size: 50, color: Colors.white)
                          : ClipOval(
                              child: imagePath.value.startsWith("http")
                                  ? Image.network(imagePath.value,
                                      fit: BoxFit.cover)
                                  : File(imagePath.value).existsSync()
                                      ? Image.file(File(imagePath.value),
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.broken_image,
                                          size: 50, color: Colors.white),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  onChanged: (value) {
                    groupName.value = value;
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.group),
                    hintText: 'Group Name',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: groupController.selectedMembers.length,
                itemBuilder: (context, index) {
                  final member = groupController.selectedMembers[index];
                  return ChatTile(
                    imgUrl: member.profileimage ??
                        'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                    name: member.name ?? 'غير معروف',
                    lastChat: member.about ?? 'لا يوجد وصف',
                    lastTime: '',
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
