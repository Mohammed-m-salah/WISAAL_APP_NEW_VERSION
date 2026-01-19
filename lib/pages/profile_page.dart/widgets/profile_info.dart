import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/controller/profile_controller/update_profile_controller.dart';

class ProfileInfo extends StatefulWidget {
  const ProfileInfo({super.key});

  @override
  State<ProfileInfo> createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  final ProfileController profileController =
      Get.put(ProfileController(), permanent: true);
  final UpdateProfileController updateProfileController =
      Get.put(UpdateProfileController(), permanent: true);
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController(), permanent: true);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  final RxBool isEdit = false.obs;
  final RxString imagePath = "".obs;

  @override
  void initState() {
    super.initState();
    _loadAndInitControllers();
  }

  Future<void> _loadAndInitControllers() async {
    await profileController.getUserDetails();
    final user = profileController.currentUser.value;

    if (user != null) {
      nameController.text = user.name ?? '';
      emailController.text = user.email ?? '';
      phoneController.text = user.phonenumber ?? '';
      aboutController.text = user.about ?? '';
      imagePath.value = user.profileimage?.isNotEmpty == true
          ? user.profileimage!
          : "https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png";
    }

    setState(() {});
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      final picked =
                          await imagePickerController.pickImageFromCamera();
                      if (picked.isNotEmpty) {
                        imagePath.value = picked;
                      }
                    },
                  ),
                  _buildImageOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(context);
                      final picked =
                          await imagePickerController.pickImageFromGallery();
                      if (picked.isNotEmpty) {
                        imagePath.value = picked;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Obx(() {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  if (!isEdit.value) {
                    isEdit.value = true;
                  }
                  _showImagePickerOptions();
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: imagePath.value.startsWith("http")
                            ? Image.network(
                                imagePath.value,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.person, size: 50),
                              )
                            : File(imagePath.value).existsSync()
                                ? Image.file(
                                    File(imagePath.value),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person, size: 50),
                                  )
                                : const Icon(Icons.person, size: 50),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to change photo',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 10),

              // Input Fields
              _buildTextField(
                controller: nameController,
                label: "Name",
                icon: Icons.account_circle_sharp,
                isEdit: isEdit.value,
                context: context,
              ),
              _buildTextField(
                controller: aboutController,
                label: "About",
                icon: Icons.info,
                isEdit: isEdit.value,
                context: context,
              ),
              _buildTextField(
                controller: emailController,
                label: "Email",
                icon: Icons.alternate_email_outlined,
                isEdit: false,
                context: context,
              ),
              _buildTextField(
                controller: phoneController,
                label: "Phone",
                icon: Icons.call,
                isEdit: isEdit.value,
                context: context,
              ),

              const SizedBox(height: 10),

              profileController.isloading.value
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        width: 120,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isEdit.value) {
                              await updateProfileController.updateProfile(
                                imagePath.value,
                                nameController.text,
                                aboutController.text,
                                phoneController.text,
                              );
                            }
                            isEdit.toggle();
                          },
                          icon: Icon(isEdit.value ? Icons.save : Icons.edit),
                          label: Text(isEdit.value ? 'Save' : 'Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(45),
                          ),
                        ),
                      ),
                    ),

              const SizedBox(height: 10),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEdit,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        enabled: isEdit,
        controller: controller,
        style: TextStyle(
          color: isEdit ? Colors.white : Colors.grey.shade500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          filled: true,
          fillColor: isEdit
              ? Theme.of(context).colorScheme.background
              : Theme.of(context).colorScheme.primaryContainer,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
