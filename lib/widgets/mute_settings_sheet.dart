import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/notification_controller/notification_controller.dart';
import 'package:wissal_app/model/mute_settings_model.dart';

/// Bottom sheet for mute settings
class MuteSettingsSheet extends StatefulWidget {
  final String targetId;
  final String targetType; // 'chat' or 'group'
  final String targetName;
  final MuteSettingsModel? currentSettings;

  const MuteSettingsSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
    this.currentSettings,
  });

  @override
  State<MuteSettingsSheet> createState() => _MuteSettingsSheetState();
}

class _MuteSettingsSheetState extends State<MuteSettingsSheet> {
  final NotificationController _notificationController = Get.find();

  MuteDuration _selectedDuration = MuteDuration.oneHour;
  bool _allowMentions = true;
  bool _allowPinned = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    if (widget.currentSettings != null) {
      _allowMentions = widget.currentSettings!.allowMentions;
      _allowPinned = widget.currentSettings!.allowPinned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCurrentlyMuted = widget.currentSettings?.isCurrentlyMuted ?? false;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrentlyMuted
                        ? Icons.notifications_off
                        : Icons.notifications,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mute_notifications'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.targetName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Current status
          if (isCurrentlyMuted)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'muted_until'.trParams({
                        'time': widget.currentSettings!.remainingTimeText,
                      }),
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: _unmute,
                    child: Text(
                      'unmute'.tr,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Duration options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'mute_duration'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Duration chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: MuteDuration.values.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return ChoiceChip(
                        label: Text(
                          Get.locale?.languageCode == 'ar'
                              ? duration.label
                              : duration.labelEn,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedDuration = duration);
                          }
                        },
                        selectedColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Exceptions
                  Text(
                    'exceptions'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'exceptions_hint'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Allow mentions
                  if (widget.targetType == 'group')
                    _buildSwitchTile(
                      icon: Icons.alternate_email,
                      iconColor: Colors.blue,
                      title: 'allow_mentions'.tr,
                      subtitle: 'allow_mentions_hint'.tr,
                      value: _allowMentions,
                      onChanged: (value) {
                        setState(() => _allowMentions = value);
                      },
                    ),

                  // Allow pinned
                  _buildSwitchTile(
                    icon: Icons.push_pin,
                    iconColor: Colors.amber,
                    title: 'allow_pinned'.tr,
                    subtitle: 'allow_pinned_hint'.tr,
                    value: _allowPinned,
                    onChanged: (value) {
                      setState(() => _allowPinned = value);
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _mute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.notifications_off, size: 18),
                              const SizedBox(width: 8),
                              Text('mute'.tr),
                            ],
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

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Future<void> _mute() async {
    setState(() => _isLoading = true);

    try {
      final success = await _notificationController.mute(
        targetId: widget.targetId,
        targetType: widget.targetType,
        duration: _selectedDuration,
        allowMentions: _allowMentions,
        allowPinned: _allowPinned,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unmute() async {
    setState(() => _isLoading = true);

    try {
      final success = await _notificationController.unmute(
        targetId: widget.targetId,
        targetType: widget.targetType,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Show mute settings bottom sheet
Future<bool?> showMuteSettingsSheet({
  required BuildContext context,
  required String targetId,
  required String targetType,
  required String targetName,
  MuteSettingsModel? currentSettings,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MuteSettingsSheet(
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
      currentSettings: currentSettings,
    ),
  );
}
