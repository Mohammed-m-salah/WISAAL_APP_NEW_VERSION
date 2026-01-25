import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/home_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final GroupController _groupController = Get.put(GroupController());
  final ContactController _contactController = Get.put(ContactController());
  final ImagePickerController _imageController = Get.put(ImagePickerController());

  int _currentPage = 0;
  String _imagePath = '';
  String _searchQuery = '';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    _groupController.clearSelectedMembers();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_nameController.text.trim().isEmpty) {
        Get.snackbar('تنبيه', 'يرجى إدخال اسم المجموعة',
          backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
    }

    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال اسم المجموعة');
      return;
    }

    final group = await _groupController.createGroup(
      groupName: _nameController.text.trim(),
      description: _descController.text.trim(),
      imagePath: _imagePath,
    );

    if (group != null) {
      Get.offAll(() => HomePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousPage,
        ),
        title: Text(
          _currentPage == 0 ? 'إنشاء مجموعة' : 'إضافة أعضاء',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_currentPage == 0)
            TextButton(
              onPressed: _nextPage,
              child: const Text('التالي', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildGroupInfoPage(theme),
          _buildMembersPage(theme),
        ],
      ),
    );
  }

  // =============== صفحة معلومات المجموعة ===============
  Widget _buildGroupInfoPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // صورة المجموعة
          GestureDetector(
            onTap: () async {
              final path = await _imageController.pickImageFromGallery();
              if (path.isNotEmpty) {
                setState(() => _imagePath = path);
              }
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
                image: _imagePath.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(_imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _imagePath.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'إضافة صورة',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 30),

          // اسم المجموعة
          TextField(
            controller: _nameController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'اسم المجموعة',
              hintText: 'أدخل اسم المجموعة',
              prefixIcon: Icon(Icons.group, color: theme.colorScheme.primary),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // وصف المجموعة (اختياري)
          TextField(
            controller: _descController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'وصف المجموعة (اختياري)',
              hintText: 'أدخل وصف للمجموعة',
              prefixIcon: Icon(Icons.description, color: theme.colorScheme.primary),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ملاحظة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ستكون أنت مالك المجموعة ويمكنك إدارة الأعضاء والإعدادات',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============== صفحة اختيار الأعضاء ===============
  Widget _buildMembersPage(ThemeData theme) {
    return Column(
      children: [
        // الأعضاء المختارين
        Obx(() {
          if (_groupController.selectedMembers.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _groupController.selectedMembers.length,
              itemBuilder: (context, index) {
                final member = _groupController.selectedMembers[index];
                return _buildSelectedMemberChip(member, theme);
              },
            ),
          );
        }),

        // شريط البحث
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'البحث عن جهات الاتصال...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // قائمة جهات الاتصال
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _contactController.getContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final contacts = snapshot.data ?? [];
              final filteredContacts = contacts.where((c) {
                if (_searchQuery.isEmpty) return true;
                return (c.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (filteredContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد جهات اتصال',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return _buildContactTile(contact, theme);
                },
              );
            },
          ),
        ),

        // زر الإنشاء
        Obx(() {
          return Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _groupController.isLoading.value ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _groupController.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'إنشاء المجموعة (${_groupController.selectedMembers.length} عضو)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedMemberChip(UserModel member, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: member.profileimage != null
                    ? NetworkImage(member.profileimage!)
                    : null,
                child: member.profileimage == null
                    ? Text(member.name?.substring(0, 1).toUpperCase() ?? '?')
                    : null,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _groupController.selectMember(member),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              member.name ?? '',
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(UserModel contact, ThemeData theme) {
    return Obx(() {
      final isSelected = _groupController.selectedMembers.any((m) => m.id == contact.id);

      return ListTile(
        onTap: () => _groupController.selectMember(contact),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: contact.profileimage != null
                  ? NetworkImage(contact.profileimage!)
                  : null,
              child: contact.profileimage == null
                  ? Text(contact.name?.substring(0, 1).toUpperCase() ?? '?')
                  : null,
            ),
            if (isSelected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(
          contact.name ?? 'غير معروف',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(contact.about ?? contact.email ?? ''),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
      );
    });
  }
}
