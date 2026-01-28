import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/group_info/manage_members_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/group_info/group_settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupInfo extends StatefulWidget {
  final GroupModel groupModel;
  const GroupInfo({super.key, required this.groupModel});

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  final GroupController _groupController = Get.put(GroupController());
  final ImagePickerController _imageController =
      Get.put(ImagePickerController());
  final auth = Supabase.instance.client.auth;

  late GroupModel _group;

  @override
  void initState() {
    super.initState();
    _group = widget.groupModel;
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final updatedGroup = await _groupController.getGroupById(_group.id);
    if (updatedGroup != null) {
      setState(() => _group = updatedGroup);
    }
  }

  String get _currentUserId => auth.currentUser?.id ?? '';
  bool get _isOwner => _group.isOwner(_currentUserId);
  bool get _isAdmin => _group.isAdmin(_currentUserId);
  bool get _canEdit => _group.canEditInfo(_currentUserId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = _group.name ?? "اسم المجموعة";
    final String profileUrl = _group.profileUrl.isNotEmpty
        ? _group.profileUrl
        : "https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header with image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.colorScheme.primaryContainer,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              if (_canEdit)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_name',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('تعديل الاسم'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit_description',
                      child: Row(
                        children: [
                          Icon(Icons.description),
                          SizedBox(width: 8),
                          Text('تعديل الوصف'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'change_image',
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt),
                          SizedBox(width: 8),
                          Text('تغيير الصورة'),
                        ],
                      ),
                    ),
                    if (_isAdmin) ...[
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'toggle_lock',
                        child: Row(
                          children: [
                            Icon(_group.settings.isLocked
                                ? Icons.lock_open
                                : Icons.lock),
                            const SizedBox(width: 8),
                            Text(_group.settings.isLocked
                                ? 'فتح المجموعة'
                                : 'قفل المجموعة'),
                          ],
                        ),
                      ),
                    ],
                    if (_isOwner) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete_group',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف المجموعة',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'group_image_${_group.id}',
                    child: Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.primaryContainer,
                        child: const Icon(Icons.group,
                            size: 80, color: Colors.white54),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (_group.settings.isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.lock,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('مقفلة',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_group.memberCount} عضو',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                if (_group.description != null &&
                    _group.description!.isNotEmpty)
                  _buildSection(
                    theme,
                    icon: Icons.info_outline,
                    title: 'الوصف',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        _group.description!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                if (_isAdmin)
                  _buildSection(
                    theme,
                    icon: Icons.settings,
                    title: 'إعدادات المجموعة',
                    child: Column(
                      children: [
                        _buildSettingTile(
                          theme,
                          icon: _group.settings.isLocked
                              ? Icons.lock
                              : Icons.lock_open,
                          title: 'قفل المجموعة',
                          subtitle: _group.settings.isLocked
                              ? 'فقط المشرفين يمكنهم الإرسال'
                              : 'الجميع يمكنهم الإرسال',
                          trailing: Switch(
                            value: _group.settings.isLocked,
                            onChanged: (value) => _toggleGroupLock(),
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.tune,
                              color: theme.colorScheme.primary),
                          title: const Text('المزيد من الإعدادات'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Get.to(() => GroupSettingsPage(group: _group)),
                        ),
                      ],
                    ),
                  ),

                _buildSection(
                  theme,
                  icon: Icons.people,
                  title: 'الأعضاء',
                  trailing: _canEdit
                      ? TextButton.icon(
                          onPressed: () =>
                              Get.to(() => ManageMembersPage(group: _group))
                                  ?.then((_) => _loadGroupData()),
                          icon: const Icon(Icons.manage_accounts, size: 18),
                          label: const Text('إدارة'),
                        )
                      : null,
                  child: Column(
                    children: [
                      // Admins first
                      ..._group.groupMembers
                          .where((m) => m.isAdmin)
                          .map((member) => _buildMemberTile(theme, member)),
                      // Then regular members
                      ..._group.groupMembers
                          .where((m) => !m.isAdmin)
                          .take(5) // Show only first 5 regular members
                          .map((member) => _buildMemberTile(theme, member)),
                      // Show more if there are more members
                      if (_group.groupMembers.where((m) => !m.isAdmin).length >
                          5)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '+${_group.groupMembers.where((m) => !m.isAdmin).length - 5}',
                              style:
                                  TextStyle(color: theme.colorScheme.primary),
                            ),
                          ),
                          title: const Text('عرض جميع الأعضاء'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Get.to(() => ManageMembersPage(group: _group)),
                        ),
                    ],
                  ),
                ),

                // Actions
                _buildSection(
                  theme,
                  icon: Icons.more_horiz,
                  title: 'المزيد',
                  child: Column(
                    children: [
                      if (_group.canAddMembers(_currentUserId))
                        ListTile(
                          leading: Icon(Icons.person_add,
                              color: theme.colorScheme.primary),
                          title: const Text('إضافة أعضاء'),
                          onTap: () => _showAddMembersDialog(),
                        ),
                      if (!_isOwner)
                        ListTile(
                          leading: const Icon(Icons.exit_to_app,
                              color: Colors.orange),
                          title: const Text('مغادرة المجموعة'),
                          onTap: () => _confirmLeaveGroup(),
                        ),
                    ],
                  ),
                ),

                // Created info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'تم الإنشاء في ${_formatDate(_group.createdAt)}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
    );
  }

  Widget _buildMemberTile(ThemeData theme, GroupMember member) {
    final isCurrentUser = member.odId == _currentUserId;
    final canManage = _isAdmin && !member.isOwner && !isCurrentUser;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: member.profileImage != null
                ? NetworkImage(member.profileImage!)
                : null,
            child: member.profileImage == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          if (member.isMuted)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.volume_off, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.name + (isCurrentUser ? ' (أنت)' : ''),
              style: TextStyle(
                fontWeight:
                    member.isAdmin ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (member.isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'المالك',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold),
              ),
            )
          else if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'مشرف',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      trailing: canManage
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (action) => _handleMemberAction(action, member),
              itemBuilder: (context) => [
                if (!member.isAdmin)
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('ترقية إلى مشرف'),
                  )
                else if (_isOwner)
                  const PopupMenuItem(
                    value: 'demote',
                    child: Text('إزالة صلاحيات المشرف'),
                  ),
                PopupMenuItem(
                  value: member.isMuted ? 'unmute' : 'mute',
                  child: Text(member.isMuted ? 'إلغاء الكتم' : 'كتم العضو'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('إزالة من المجموعة',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit_name':
        _showEditNameDialog();
        break;
      case 'edit_description':
        _showEditDescriptionDialog();
        break;
      case 'change_image':
        _changeGroupImage();
        break;
      case 'toggle_lock':
        _toggleGroupLock();
        break;
      case 'delete_group':
        _confirmDeleteGroup();
        break;
    }
  }

  Future<void> _handleMemberAction(String action, GroupMember member) async {
    switch (action) {
      case 'promote':
        await _groupController.promoteToAdmin(_group.id, member.odId);
        _loadGroupData();
        break;
      case 'demote':
        await _groupController.demoteFromAdmin(_group.id, member.odId);
        _loadGroupData();
        break;
      case 'mute':
        await _groupController.muteMember(_group.id, member.odId);
        _loadGroupData();
        break;
      case 'unmute':
        await _groupController.unmuteMember(_group.id, member.odId);
        _loadGroupData();
        break;
      case 'remove':
        _confirmRemoveMember(member);
        break;
    }
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _group.name);
    Get.dialog(
      AlertDialog(
        title: const Text('تعديل اسم المجموعة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'اسم المجموعة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _groupController.updateGroupName(
                    _group.id, controller.text.trim());
                Get.back();
                _loadGroupData();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditDescriptionDialog() {
    final controller = TextEditingController(text: _group.description);
    Get.dialog(
      AlertDialog(
        title: const Text('تعديل وصف المجموعة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'الوصف',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _groupController.updateGroupDescription(
                  _group.id, controller.text.trim());
              Get.back();
              _loadGroupData();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeGroupImage() async {
    final path = await _imageController.pickImageFromGallery();
    if (path.isNotEmpty) {
      await _groupController.updateGroupImage(_group.id, path);
      await _loadGroupData();
    }
  }

  Future<void> _toggleGroupLock() async {
    await _groupController.toggleGroupLock(_group.id);
    _loadGroupData();
  }

  void _confirmDeleteGroup() {
    Get.dialog(
      AlertDialog(
        title: const Text('حذف المجموعة'),
        content: const Text(
            'هل أنت متأكد من حذف هذه المجموعة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              final success = await _groupController.deleteGroup(_group.id);
              if (success) {
                Get.back();
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(GroupMember member) {
    Get.dialog(
      AlertDialog(
        title: const Text('إزالة عضو'),
        content: Text('هل أنت متأكد من إزالة ${member.name} من المجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              await _groupController.removeMemberFromGroup(
                  _group.id, member.odId);
              _loadGroupData();
            },
            child: const Text('إزالة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    Get.dialog(
      AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: const Text('هل أنت متأكد من مغادرة هذه المجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Get.back();
              final success = await _groupController.leaveGroup(_group.id);
              if (success) {
                Get.back();
                Get.back();
              }
            },
            child: const Text('مغادرة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMembersDialog() {
    Get.to(() => ManageMembersPage(group: _group, initialTab: 1))
        ?.then((_) => _loadGroupData());
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
