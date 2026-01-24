import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/new_group/new_group.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

import '../../controller/chat_controller/chat_controller.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();
  final ContactController contactcontroller = Get.put(ContactController());
  final ProfileController profileController = Get.put(ProfileController());
  final ChatController chatcontroller = Get.put(ChatController());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      searchQuery.value = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openChat(UserModel user) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('error'.tr, 'login_required'.tr);
      return;
    }
    Get.to(() => ChatPage(userModel: user));
  }

  List<UserModel> get filteredContacts {
    if (searchQuery.value.isEmpty) {
      return contactcontroller.userList;
    }
    return contactcontroller.userList.where((user) {
      final name = (user.name ?? '').toLowerCase();
      final email = (user.email ?? '').toLowerCase();
      final query = searchQuery.value;
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Obx(() => isSearching.value
            ? _buildSearchField(isDark)
            : Text('contacts'.tr)),
        actions: [
          Obx(() => IconButton(
                icon: Icon(isSearching.value ? Icons.close : Icons.search),
                onPressed: () {
                  isSearching.value = !isSearching.value;
                  if (!isSearching.value) {
                    _searchController.clear();
                  }
                },
              )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => contactcontroller.getUserList(),
        child: Obx(() {
          final contacts = filteredContacts;

          return CustomScrollView(
          slivers: [
            // قسم الإجراءات السريعة
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActionCard(
                      icon: Icons.person_add_rounded,
                      title: 'new_contact'.tr,
                      subtitle: 'add_new_contact'.tr,
                      color: theme.colorScheme.primary,
                      onTap: () => _showAddContactDialog(),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      icon: Icons.group_add_rounded,
                      title: 'new_group'.tr,
                      subtitle: 'create_new_group'.tr,
                      color: Colors.teal,
                      onTap: () => Get.to(() => NewGroup()),
                    ),
                  ],
                ),
              ),
            ),

            // عنوان جهات الاتصال
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'contacts_on_app'.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${contacts.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // قائمة جهات الاتصال
            if (contactcontroller.isLoading.value)
              const SliverToBoxAdapter(
                child: ContactListSkeleton(),
              )
            else if (contacts.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(isDark),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final contact = contacts[index];
                    return _buildContactTile(contact, isDark);
                  },
                  childCount: contacts.length,
                ),
              ),

            // مساحة للـ bottom navbar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
        }),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.white,
      ),
      decoration: InputDecoration(
        hintText: 'search_contacts'.tr,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? color.withOpacity(0.15)
          : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(UserModel contact, bool isDark) {
    final theme = Theme.of(context);
    final isCurrentUser =
        contact.email == profileController.currentUser.value.email;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: contact.profileimage != null && contact.profileimage!.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  contact.profileimage!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      (contact.name ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 24,
                    );
                  },
                ),
              )
            : Text(
                (contact.name ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.name ?? 'user'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'you'.tr,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        contact.about ?? 'hey_there'.tr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.chat_bubble_outline_rounded,
          color: theme.colorScheme.primary,
        ),
        onPressed: () => _openChat(contact),
      ),
      onTap: () => _openChat(contact),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.value.isEmpty
                ? Icons.contacts_outlined
                : Icons.search_off_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.value.isEmpty
                ? 'no_contacts'.tr
                : 'no_results'.tr,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          if (searchQuery.value.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'invite_friends'.tr,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final emailController = TextEditingController();
    final theme = Theme.of(context);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text('add_contact'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'email'.tr,
                hintText: 'enter_email'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                Get.snackbar('error'.tr, 'enter_email'.tr);
                return;
              }

              Get.back();
              // البحث عن المستخدم بالإيميل
              await contactcontroller.searchUserByEmail(email);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }
}
