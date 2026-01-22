import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';

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
      Get.snackbar('خطأ', 'يجب تسجيل الدخول أولاً');
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
          lastChat: room.lastMessage ?? 'لا توجد رسالة',
          lastTime: formatTimestamp(room.lastMessageTimeStamp),
          isPinned: room.isPinned,
          onPin: () => contactController.pinChatRoom(room.id!),
          onUnpin: () => contactController.unpinChatRoom(room.id!),
          onDelete: () => contactController.deleteChatRoom(room.id!),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (contactController.chatRoomList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 150),
                  child: Text('لا توجد محادثات حالياً'),
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
                        'المحادثات المثبتة (${pinnedRooms.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'اضغط مطولاً للسحب',
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
