import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/controller/profile_controller/update_profile_controller.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

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

  @override
  void initState() {
    super.initState();
    profileController.getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      // Show skeleton while loading
      if (profileController.isloading.value) {
        return const ProfileSkeleton();
      }

      final user = profileController.currentUser.value;
      final imageUrl = user?.profileimage?.isNotEmpty == true
          ? user!.profileimage!
          : null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.scaffoldBackgroundColor,
                  ],
          ),
        ),
        child: Column(
          children: [
            // Profile Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(theme),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildDefaultAvatar(theme);
                        },
                      )
                    : _buildDefaultAvatar(theme),
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user?.name ?? 'user'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // Email
            Text(
              user?.email ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),

            const SizedBox(height: 20),

            // Edit Button
            OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('edit_profile'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    final user = profileController.currentUser.value;
    return Container(
      width: 120,
      height: 120,
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          (user?.name ?? 'U')[0].toUpperCase(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 48,
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = profileController.currentUser.value;
    final theme = Theme.of(context);

    final nameController = TextEditingController(text: user?.name ?? '');
    final aboutController = TextEditingController(text: user?.about ?? '');
    final phoneController = TextEditingController(text: user?.phonenumber ?? '');
    final RxString imagePath = (user?.profileimage ?? '').obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.edit, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'edit_profile'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Profile Image
                Obx(() => GestureDetector(
                      onTap: () => _showImagePickerOptions(imagePath),
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildEditImage(imagePath.value, theme),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 20),

                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'name'.tr,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // About Field
                TextField(
                  controller: aboutController,
                  decoration: InputDecoration(
                    labelText: 'bio'.tr,
                    prefixIcon: const Icon(Icons.info_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Phone Field
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone'.tr,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                            onPressed: profileController.isloading.value
                                ? null
                                : () async {
                                    await updateProfileController.updateProfile(
                                      imagePath.value,
                                      nameController.text,
                                      aboutController.text,
                                      phoneController.text,
                                    );
                                    await profileController.getUserDetails();
                                    Get.back();
                                    Get.snackbar(
                                      'success'.tr,
                                      'profile_updated'.tr,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: profileController.isloading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('save'.tr),
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditImage(String imagePath, ThemeData theme) {
    if (imagePath.isEmpty) {
      return Container(
        color: theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.person,
          size: 50,
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person,
          size: 50,
          color: theme.colorScheme.primary,
        ),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }

    return Icon(
      Icons.person,
      size: 50,
      color: theme.colorScheme.primary,
    );
  }

  void _showImagePickerOptions(RxString imagePath) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
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
              Text(
                'change_photo'.tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageOption(
                    icon: Icons.camera_alt,
                    label: 'camera'.tr,
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
                    label: 'gallery'.tr,
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
}
