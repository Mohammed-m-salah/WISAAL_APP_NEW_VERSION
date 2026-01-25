import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageMembersPage extends StatefulWidget {
  final GroupModel group;
  final int initialTab;

  const ManageMembersPage({
    super.key,
    required this.group,
    this.initialTab = 0,
  });

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GroupController _groupController = Get.put(GroupController());
  final ContactController _contactController = Get.put(ContactController());
  final auth = Supabase.instance.client.auth;

  late GroupModel _group;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<UserModel> _selectedToAdd = [];

  String get _currentUserId => auth.currentUser?.id ?? '';
  bool get _isOwner => _group.isOwner(_currentUserId);
  bool get _isAdmin => _group.isAdmin(_currentUserId);

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(
      length: _isAdmin ? 2 : 1,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _isAdmin ? 1 : 0),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final updatedGroup = await _groupController.getGroupById(_group.id);
    if (updatedGroup != null && mounted) {
      setState(() => _group = updatedGroup);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: const Text('إدارة الأعضاء', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        bottom: _isAdmin
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'الأعضاء الحاليين'),
                  Tab(text: 'إضافة أعضاء'),
                ],
              )
            : null,
      ),
      body: _isAdmin
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentMembersTab(theme),
                _buildAddMembersTab(theme),
              ],
            )
          : _buildCurrentMembersTab(theme),
      floatingActionButton: _tabController.index == 1 && _selectedToAdd.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addSelectedMembers,
              backgroundColor: theme.colorScheme.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'إضافة ${_selectedToAdd.length}',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildCurrentMembersTab(ThemeData theme) {
    // Sort members: owner first, then admins, then regular members
    final sortedMembers = List<GroupMember>.from(_group.groupMembers)
      ..sort((a, b) {
        if (a.isOwner) return -1;
        if (b.isOwner) return 1;
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return a.name.compareTo(b.name);
      });

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'البحث في الأعضاء...',
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

        // Stats
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(theme, 'إجمالي', _group.memberCount.toString()),
              _buildStat(theme, 'المشرفين', _group.adminCount.toString()),
              _buildStat(theme, 'الأعضاء', (_group.memberCount - _group.adminCount).toString()),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Members list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sortedMembers.length,
            itemBuilder: (context, index) {
              final member = sortedMembers[index];
              if (_searchQuery.isNotEmpty &&
                  !member.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
                return const SizedBox.shrink();
              }
              return _buildMemberCard(theme, member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(ThemeData theme, GroupMember member) {
    final isCurrentUser = member.odId == _currentUserId;
    final canManage = _isAdmin && !member.isOwner && !isCurrentUser;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: member.profileImage != null
                  ? NetworkImage(member.profileImage!)
                  : null,
              child: member.profileImage == null
                  ? Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            if (member.isOwner)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, size: 12, color: Colors.white),
                ),
              )
            else if (member.isAdmin)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield, size: 12, color: Colors.white),
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
                  fontWeight: member.isAdmin ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            _buildRoleBadge(theme, member),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.isMuted)
              Row(
                children: [
                  const Icon(Icons.volume_off, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'مكتوم',
                    style: TextStyle(color: Colors.red[400], fontSize: 12),
                  ),
                  if (member.mutedUntil != null) ...[
                    const Text(' - ', style: TextStyle(fontSize: 12)),
                    Text(
                      'حتى ${_formatDateTime(member.mutedUntil!)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            Text(
              'انضم في ${_formatDate(member.joinedAt)}',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) => _handleMemberAction(action, member),
                itemBuilder: (context) => [
                  if (!member.isAdmin)
                    const PopupMenuItem(
                      value: 'promote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward, size: 18),
                          SizedBox(width: 8),
                          Text('ترقية إلى مشرف'),
                        ],
                      ),
                    )
                  else if (_isOwner)
                    const PopupMenuItem(
                      value: 'demote',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 18),
                          SizedBox(width: 8),
                          Text('إزالة صلاحيات المشرف'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  if (!member.isMuted)
                    const PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(Icons.volume_off, size: 18),
                          SizedBox(width: 8),
                          Text('كتم العضو'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'unmute',
                      child: Row(
                        children: [
                          Icon(Icons.volume_up, size: 18),
                          SizedBox(width: 8),
                          Text('إلغاء الكتم'),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('إزالة من المجموعة', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildRoleBadge(ThemeData theme, GroupMember member) {
    if (member.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text('المالك', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else if (member.isAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text('مشرف', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAddMembersTab(ThemeData theme) {
    return Column(
      children: [
        // Selected members chips
        if (_selectedToAdd.isNotEmpty)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedToAdd.length,
              itemBuilder: (context, index) {
                final user = _selectedToAdd[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundImage: user.profileimage != null
                          ? NetworkImage(user.profileimage!)
                          : null,
                      child: user.profileimage == null
                          ? Text(user.name?[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    label: Text(user.name ?? ''),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _selectedToAdd.remove(user));
                    },
                  ),
                );
              },
            ),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'البحث عن جهات اتصال...',
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

        // Contacts list
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _contactController.getContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final contacts = snapshot.data ?? [];
              // Filter out existing members
              final existingMemberIds = _group.groupMembers.map((m) => m.odId).toSet();
              final availableContacts = contacts
                  .where((c) => !existingMemberIds.contains(c.id))
                  .where((c) {
                    if (_searchQuery.isEmpty) return true;
                    return (c.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
                  })
                  .toList();

              if (availableContacts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_disabled, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'لا توجد نتائج'
                            : 'جميع جهات اتصالك أعضاء بالفعل',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: availableContacts.length,
                itemBuilder: (context, index) {
                  final contact = availableContacts[index];
                  final isSelected = _selectedToAdd.any((u) => u.id == contact.id);

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedToAdd.removeWhere((u) => u.id == contact.id);
                        } else {
                          _selectedToAdd.add(contact);
                        }
                      });
                    },
                    leading: CircleAvatar(
                      backgroundImage: contact.profileimage != null
                          ? NetworkImage(contact.profileimage!)
                          : null,
                      child: contact.profileimage == null
                          ? Text(contact.name?[0].toUpperCase() ?? '?')
                          : null,
                    ),
                    title: Text(contact.name ?? 'غير معروف'),
                    subtitle: Text(contact.about ?? contact.email ?? ''),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedToAdd.add(contact);
                          } else {
                            _selectedToAdd.removeWhere((u) => u.id == contact.id);
                          }
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleMemberAction(String action, GroupMember member) async {
    switch (action) {
      case 'promote':
        await _groupController.promoteToAdmin(_group.id, member.odId);
        break;
      case 'demote':
        await _groupController.demoteFromAdmin(_group.id, member.odId);
        break;
      case 'mute':
        _showMuteDurationDialog(member);
        return;
      case 'unmute':
        await _groupController.unmuteMember(_group.id, member.odId);
        break;
      case 'remove':
        _confirmRemoveMember(member);
        return;
    }
    _loadGroupData();
  }

  void _showMuteDurationDialog(GroupMember member) {
    Get.dialog(
      AlertDialog(
        title: const Text('كتم العضو'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اختر مدة كتم ${member.name}'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('ساعة واحدة'),
              leading: const Icon(Icons.access_time),
              onTap: () async {
                Get.back();
                await _groupController.muteMember(
                  _group.id,
                  member.odId,
                  duration: const Duration(hours: 1),
                );
                _loadGroupData();
              },
            ),
            ListTile(
              title: const Text('يوم واحد'),
              leading: const Icon(Icons.today),
              onTap: () async {
                Get.back();
                await _groupController.muteMember(
                  _group.id,
                  member.odId,
                  duration: const Duration(days: 1),
                );
                _loadGroupData();
              },
            ),
            ListTile(
              title: const Text('أسبوع'),
              leading: const Icon(Icons.date_range),
              onTap: () async {
                Get.back();
                await _groupController.muteMember(
                  _group.id,
                  member.odId,
                  duration: const Duration(days: 7),
                );
                _loadGroupData();
              },
            ),
            ListTile(
              title: const Text('دائم'),
              leading: const Icon(Icons.block),
              onTap: () async {
                Get.back();
                await _groupController.muteMember(_group.id, member.odId);
                _loadGroupData();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
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
              await _groupController.removeMemberFromGroup(_group.id, member.odId);
              _loadGroupData();
            },
            child: const Text('إزالة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedToAdd.isEmpty) return;

    final success = await _groupController.addMembersToGroup(_group.id, _selectedToAdd);
    if (success) {
      setState(() => _selectedToAdd.clear());
      _loadGroupData();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
