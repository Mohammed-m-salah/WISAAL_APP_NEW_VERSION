import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ContactController contactController = Get.find<ContactController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text('archived_chats'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (contactController.isLoading.value) {
          return const ChatListSkeleton();
        }

        if (contactController.archivedChatRoomList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.archive_outlined,
                  size: 80,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'no_archived_chats'.tr,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'archived_chats_hint'.tr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: contactController.archivedChatRoomList.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final room = contactController.archivedChatRoomList[index];
            return _buildArchivedChatTile(context, room, contactController, isDark);
          },
        );
      }),
    );
  }

  Widget _buildArchivedChatTile(
    BuildContext context,
    ChatRoomModel room,
    ContactController controller,
    bool isDark,
  ) {
    if (room.receiver == null) return const SizedBox();

    final theme = Theme.of(context);
    final hasImage = room.receiver!.profileimage != null &&
        room.receiver!.profileimage!.isNotEmpty;

    return Dismissible(
      key: ValueKey(room.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.primary,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.unarchive, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              'unarchive'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await controller.unarchiveChatRoom(room.id!);
        Get.snackbar(
          'success'.tr,
          'chat_unarchived'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return false;
      },
      child: ListTile(
        onTap: () => _openChat(room.receiver!),
        onLongPress: () => _showOptionsMenu(context, room, controller),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: hasImage
              ? ClipOval(
                  child: Image.network(
                    room.receiver!.profileimage!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        (room.receiver!.name ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      );
                    },
                  ),
                )
              : Text(
                  (room.receiver!.name ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
        ),
        title: Text(
          room.receiver!.name ?? 'user'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          room.lastMessage ?? 'no_messages'.tr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(room.lastMessageTimeStamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.archive,
              size: 16,
              color: theme.hintColor,
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(UserModel user) {
    Get.to(() => ChatPage(userModel: user));
  }

  void _showOptionsMenu(
    BuildContext context,
    ChatRoomModel room,
    ContactController controller,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
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
            ListTile(
              leading: Icon(
                Icons.unarchive,
                color: theme.colorScheme.primary,
              ),
              title: Text('unarchive'.tr),
              onTap: () {
                Navigator.pop(context);
                controller.unarchiveChatRoom(room.id!);
                Get.snackbar(
                  'success'.tr,
                  'chat_unarchived'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'delete_chat'.tr,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, room, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ChatRoomModel room,
    ContactController controller,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('delete_chat'.tr),
        content: Text('delete_chat_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteChatRoom(room.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr;
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
