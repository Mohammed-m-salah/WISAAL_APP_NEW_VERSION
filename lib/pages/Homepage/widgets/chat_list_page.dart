import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/saved_messages_controller/saved_messages_controller.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/archived_chats/archived_chats_page.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/pages/saved_messages/saved_messages_page.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';
import 'package:wissal_app/utils/responsive.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ContactController contactController = Get.put(ContactController());
  final SavedMessagesController savedController =
      Get.put(SavedMessagesController());

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
        if (contactController.isLoading.value ||
            !contactController.hasLoadedInitially.value) {
          return const ChatListSkeleton();
        }

        if (contactController.chatRoomList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: Responsive.h(150)),
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: Responsive.iconSize(64),
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      Responsive.verticalSpace(16),
                      Text(
                        'no_messages'.tr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: Responsive.fontSize(16),
                        ),
                      ),
                      Responsive.verticalSpace(8),
                      Text(
                        'start_chatting'.tr,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: Responsive.fontSize(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final pinnedRooms =
            contactController.chatRoomList.where((r) => r.isPinned).toList();
        final unpinnedRooms =
            contactController.chatRoomList.where((r) => !r.isPinned).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: InkWell(
                onTap: () => Get.to(() => const SavedMessagesPage()),
                child: Container(
                  padding:
                      Responsive.symmetricPadding(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: Responsive.containerSize(50),
                        height: Responsive.containerSize(50),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.blue.shade700],
                          ),
                          borderRadius: Responsive.borderRadius(12),
                        ),
                        child: Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: Responsive.iconSize(24),
                        ),
                      ),
                      Responsive.horizontalSpace(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'saved_messages'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.fontSize(16),
                              ),
                            ),
                            Responsive.verticalSpace(2),
                            Obx(() {
                              final lastMsg = savedController.lastSavedMessage;
                              return Text(
                                lastMsg?.message ?? 'saved_messages_hint'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: Responsive.fontSize(13),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      Obx(() {
                        if (savedController.savedMessagesCount > 0) {
                          return Container(
                            padding: Responsive.symmetricPadding(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: Responsive.borderRadius(12),
                            ),
                            child: Text(
                              '${savedController.savedMessagesCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.fontSize(12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      }),
                    ],
                  ),
                ),
              ),
            ),
            if (contactController.archivedChatRoomList.isNotEmpty)
              SliverToBoxAdapter(
                child: InkWell(
                  onTap: () => Get.to(() => const ArchivedChatsPage()),
                  child: Container(
                    padding: Responsive.symmetricPadding(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: Responsive.padding(all: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: Responsive.borderRadius(10),
                          ),
                          child: Icon(
                            Icons.archive,
                            color: Theme.of(context).colorScheme.primary,
                            size: Responsive.iconSize(20),
                          ),
                        ),
                        Responsive.horizontalSpace(12),
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
                          padding: Responsive.symmetricPadding(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: Responsive.borderRadius(12),
                          ),
                          child: Text(
                            '${contactController.archivedChatRoomList.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.fontSize(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Responsive.horizontalSpace(8),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (pinnedRooms.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: Responsive.padding(left: 16, right: 16, top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.push_pin,
                          size: Responsive.iconSize(18),
                          color: Color(0xff092E34)),
                      Responsive.horizontalSpace(8),
                      Text(
                        '${'pinned_chats'.tr} (${pinnedRooms.length})',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff092E34)),
                      ),
                      const Spacer(),
                      Text(
                        'long_press_to_drag'.tr,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(11),
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
              if (unpinnedRooms.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: Responsive.symmetricPadding(
                        horizontal: 16, vertical: 8),
                    child: Divider(color: Colors.grey.shade300),
                  ),
                ),
            ],
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
