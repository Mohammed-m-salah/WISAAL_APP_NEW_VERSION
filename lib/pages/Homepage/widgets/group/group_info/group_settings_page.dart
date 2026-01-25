import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupSettingsPage extends StatefulWidget {
  final GroupModel group;

  const GroupSettingsPage({super.key, required this.group});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final GroupController _groupController = Get.put(GroupController());
  final auth = Supabase.instance.client.auth;

  late GroupModel _group;
  late GroupSettings _settings;
  bool _hasChanges = false;

  String get _currentUserId => auth.currentUser?.id ?? '';
  bool get _isOwner => _group.isOwner(_currentUserId);

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _settings = _group.settings;
  }

  void _updateSettings(GroupSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    try {
      final db = Supabase.instance.client;
      await db.from('groups').update({
        'settings': _settings.toJson(),
      }).eq('id', _group.id);

      await _groupController.getGroups();
      Get.snackbar('تم', 'تم حفظ الإعدادات بنجاح',
          backgroundColor: Colors.green, colorText: Colors.white);
      setState(() => _hasChanges = false);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حفظ الإعدادات',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: const Text('إعدادات المجموعة', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              Get.back();
            }
          },
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Messages settings
          _buildSection(
            theme,
            title: 'إعدادات الرسائل',
            icon: Icons.message,
            children: [
              _buildSwitchTile(
                theme,
                icon: Icons.lock,
                title: 'قفل المجموعة',
                subtitle: 'فقط المشرفين يمكنهم إرسال الرسائل',
                value: _settings.isLocked,
                onChanged: (value) {
                  _updateSettings(_settings.copyWith(isLocked: value));
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Permissions settings
          _buildSection(
            theme,
            title: 'الصلاحيات',
            icon: Icons.security,
            children: [
              _buildSwitchTile(
                theme,
                icon: Icons.edit,
                title: 'تعديل معلومات المجموعة',
                subtitle: _settings.onlyAdminsCanEditInfo
                    ? 'فقط المشرفين يمكنهم تعديل الاسم والصورة'
                    : 'جميع الأعضاء يمكنهم تعديل الاسم والصورة',
                value: _settings.onlyAdminsCanEditInfo,
                onChanged: _isOwner
                    ? (value) {
                        _updateSettings(_settings.copyWith(onlyAdminsCanEditInfo: value));
                      }
                    : null,
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                theme,
                icon: Icons.person_add,
                title: 'إضافة أعضاء',
                subtitle: _settings.onlyAdminsCanAddMembers
                    ? 'فقط المشرفين يمكنهم إضافة أعضاء جدد'
                    : 'جميع الأعضاء يمكنهم إضافة أعضاء جدد',
                value: _settings.onlyAdminsCanAddMembers,
                onChanged: _isOwner
                    ? (value) {
                        _updateSettings(_settings.copyWith(onlyAdminsCanAddMembers: value));
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Member limit settings
          if (_isOwner)
            _buildSection(
              theme,
              title: 'الحدود',
              icon: Icons.groups,
              children: [
                ListTile(
                  leading: Icon(Icons.people, color: theme.colorScheme.primary),
                  title: const Text('الحد الأقصى للأعضاء'),
                  subtitle: Text(_settings.maxMembers != null
                      ? '${_settings.maxMembers} عضو'
                      : 'غير محدود'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showMaxMembersDialog,
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Info section
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملاحظة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بعض الإعدادات متاحة فقط لمالك المجموعة',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Current settings summary
          _buildSection(
            theme,
            title: 'ملخص الإعدادات',
            icon: Icons.summarize,
            children: [
              _buildInfoTile(
                theme,
                icon: _settings.isLocked ? Icons.lock : Icons.lock_open,
                title: 'حالة المجموعة',
                value: _settings.isLocked ? 'مقفلة' : 'مفتوحة',
                valueColor: _settings.isLocked ? Colors.red : Colors.green,
              ),
              const Divider(height: 1),
              _buildInfoTile(
                theme,
                icon: Icons.edit,
                title: 'تعديل المعلومات',
                value: _settings.onlyAdminsCanEditInfo ? 'المشرفين فقط' : 'الجميع',
              ),
              const Divider(height: 1),
              _buildInfoTile(
                theme,
                icon: Icons.person_add,
                title: 'إضافة أعضاء',
                value: _settings.onlyAdminsCanAddMembers ? 'المشرفين فقط' : 'الجميع',
              ),
              const Divider(height: 1),
              _buildInfoTile(
                theme,
                icon: Icons.groups,
                title: 'الحد الأقصى',
                value: _settings.maxMembers?.toString() ?? 'غير محدود',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: valueColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showMaxMembersDialog() {
    final controller = TextEditingController(
      text: _settings.maxMembers?.toString() ?? '',
    );

    Get.dialog(
      AlertDialog(
        title: const Text('الحد الأقصى للأعضاء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأعضاء',
                hintText: 'اتركه فارغاً لعدد غير محدود',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اتركه فارغاً لإلغاء الحد',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                _updateSettings(_settings.copyWith(clearMaxMembers: true));
              } else {
                final maxMembers = int.tryParse(text);
                if (maxMembers != null && maxMembers < _group.memberCount) {
                  Get.snackbar(
                    'خطأ',
                    'الحد الأقصى يجب أن يكون أكبر من عدد الأعضاء الحاليين',
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                  return;
                }
                _updateSettings(_settings.copyWith(maxMembers: maxMembers));
              }
              Get.back();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('تغييرات غير محفوظة'),
        content: const Text('لديك تغييرات غير محفوظة. هل تريد حفظها قبل المغادرة؟'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            child: const Text('تجاهل'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _saveSettings();
              Get.back();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
