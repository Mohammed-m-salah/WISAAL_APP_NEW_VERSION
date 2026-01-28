import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/chat_model.dart';

/// A bottom sheet widget that displays who has seen and received a message
class MessageSeenSheet extends StatelessWidget {
  final ChatModel message;
  final List<GroupMember> groupMembers;
  final String currentUserId;
  final List<String> seenByIds;
  final List<String> deliveredToIds;

  const MessageSeenSheet({
    super.key,
    required this.message,
    required this.groupMembers,
    required this.currentUserId,
    required this.seenByIds,
    required this.deliveredToIds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Categorize members
    final seenMembers = <GroupMember>[];
    final deliveredMembers = <GroupMember>[];
    final pendingMembers = <GroupMember>[];

    for (final member in groupMembers) {
      // Skip the sender
      if (member.odId == message.senderId) continue;

      if (seenByIds.contains(member.odId)) {
        seenMembers.add(member);
      } else if (deliveredToIds.contains(member.odId)) {
        deliveredMembers.add(member);
      } else {
        pendingMembers.add(member);
      }
    }

    final totalRecipients = groupMembers.length - 1; // Exclude sender

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'message_info'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message.timeStamp != null
                            ? DateFormat('dd/MM/yyyy - hh:mm a')
                                .format(DateTime.parse(message.timeStamp!))
                            : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
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

          // Stats summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.done_all,
                  iconColor: Colors.blue,
                  count: seenMembers.length,
                  total: totalRecipients,
                  label: 'seen'.tr,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  icon: Icons.done,
                  iconColor: Colors.grey,
                  count: deliveredMembers.length,
                  total: totalRecipients,
                  label: 'delivered'.tr,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  context,
                  icon: Icons.access_time,
                  iconColor: Colors.orange,
                  count: pendingMembers.length,
                  total: totalRecipients,
                  label: 'pending'.tr,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Members list
          Flexible(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all, size: 18),
                            const SizedBox(width: 4),
                            Text('${seenMembers.length}'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done, size: 18),
                            const SizedBox(width: 4),
                            Text('${deliveredMembers.length}'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 4),
                            Text('${pendingMembers.length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildMembersList(
                          context,
                          seenMembers,
                          emptyMessage: 'no_one_seen'.tr,
                          statusIcon: Icons.done_all,
                          statusColor: Colors.blue,
                          statusText: 'seen'.tr,
                        ),
                        _buildMembersList(
                          context,
                          deliveredMembers,
                          emptyMessage: 'no_one_received'.tr,
                          statusIcon: Icons.done,
                          statusColor: Colors.grey,
                          statusText: 'delivered'.tr,
                        ),
                        _buildMembersList(
                          context,
                          pendingMembers,
                          emptyMessage: 'everyone_received'.tr,
                          statusIcon: Icons.access_time,
                          statusColor: Colors.orange,
                          statusText: 'pending'.tr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required int count,
    required int total,
    required String label,
  }) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 2),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 10,
                color: iconColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    List<GroupMember> members, {
    required String emptyMessage,
    required IconData statusIcon,
    required Color statusColor,
    required String statusText,
  }) {
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isCurrentUser = member.odId == currentUserId;

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: member.profileImage != null &&
                    member.profileImage!.isNotEmpty
                ? NetworkImage(member.profileImage!)
                : null,
            child: member.profileImage == null || member.profileImage!.isEmpty
                ? Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'you'.tr,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
              if (member.role == MemberRole.admin ||
                  member.role == MemberRole.owner) ...[
                const SizedBox(width: 8),
                Icon(
                  member.role == MemberRole.owner
                      ? Icons.star
                      : Icons.admin_panel_settings,
                  size: 14,
                  color: member.role == MemberRole.owner
                      ? Colors.amber
                      : Colors.blue,
                ),
              ],
            ],
          ),
          subtitle: Text(
            _getRoleText(member.role),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRoleText(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return 'group_owner'.tr;
      case MemberRole.admin:
        return 'group_admin'.tr;
      case MemberRole.member:
        return 'member'.tr;
    }
  }
}

/// Shows the message seen bottom sheet
Future<void> showMessageSeenSheet({
  required BuildContext context,
  required ChatModel message,
  required List<GroupMember> groupMembers,
  required String currentUserId,
  required List<String> seenByIds,
  required List<String> deliveredToIds,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MessageSeenSheet(
      message: message,
      groupMembers: groupMembers,
      currentUserId: currentUserId,
      seenByIds: seenByIds,
      deliveredToIds: deliveredToIds,
    ),
  );
}
