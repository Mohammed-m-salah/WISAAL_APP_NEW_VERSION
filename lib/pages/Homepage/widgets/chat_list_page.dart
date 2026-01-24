import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/archived_chats/archived_chats_page.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ContactController contactController = Get.put(ContactController());

  String formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '12:00';
    return '${timestamp.hour.toString().padLeft(2, '0')} : ${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _openChat(UserModel user) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('error'.tr, 'login_required'.tr);
      return;
    }
    Get.to(() => ChatPage(userModel: user));
  }

  Widget _buildChatTile(ChatRoomModel room) {
    if (room.receiver == null) return const SizedBox();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey(room.id),
        onTap: () => _openChat(room.receiver!),
        child: ChatTile(
          imgUrl: room.receiver!.profileimage ??
              'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
          name: room.receiver!.name ?? 'user name',
          lastChat: room.lastMessage ?? 'no_messages'.tr,
          lastTime: formatTimestamp(room.lastMessageTimeStamp),
          isPinned: room.isPinned,
          onPin: () => contactController.pinChatRoom(room.id!),
          onUnpin: () => contactController.unpinChatRoom(room.id!),
          onDelete: () => contactController.deleteChatRoom(room.id!),
          onArchive: () {
            contactController.archiveChatRoom(room.id!);
            Get.snackbar(
              'success'.tr,
              'chat_archived'.tr,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => contactController.getChatRoomList(),
      child: Obx(() {
        if (contactController.isLoading.value) {
          return const ChatListSkeleton();
        }

        if (contactController.chatRoomList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 150),
                  child: Text('no_messages'.tr),
                ),
              ),
            ],
          );
        }

        // فصل الغرف المثبتة وغير المثبتة
        final pinnedRooms = contactController.chatRoomList
            .where((r) => r.isPinned)
            .toList();
        final unpinnedRooms = contactController.chatRoomList
            .where((r) => !r.isPinned)
            .toList();

        return CustomScrollView(
          slivers: [
            // قسم المحادثات المؤرشفة (زر للانتقال)
            if (contactController.archivedChatRoomList.isNotEmpty)
              SliverToBoxAdapter(
                child: InkWell(
                  onTap: () => Get.to(() => const ArchivedChatsPage()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.archive,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'archived_chats'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${contactController.archivedChatRoomList.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // قسم الغرف المثبتة (قابل لإعادة الترتيب)
            if (pinnedRooms.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin, size: 18, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${'pinned_chats'.tr} (${pinnedRooms.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'long_press_to_drag'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverReorderableList(
                itemCount: pinnedRooms.length,
                onReorder: (oldIndex, newIndex) {
                  contactController.reorderPinnedRooms(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final room = pinnedRooms[index];
                  return ReorderableDragStartListener(
                    key: ValueKey(room.id),
                    index: index,
                    child: _buildChatTile(room),
                  );
                },
              ),
              // خط فاصل
              if (unpinnedRooms.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.grey.shade300),
                  ),
                ),
            ],
            // قسم الغرف غير المثبتة
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final room = unpinnedRooms[index];
                  return _buildChatTile(room);
                },
                childCount: unpinnedRooms.length,
              ),
            ),
          ],
        );
      }),
    );
  }
}
