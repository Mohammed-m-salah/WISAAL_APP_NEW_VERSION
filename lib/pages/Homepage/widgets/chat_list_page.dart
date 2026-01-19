import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final ContactController contactController = Get.put(ContactController());
    return RefreshIndicator(
      onRefresh: () => contactController.getChatRoomList(),
      child: Obx(() {
        if (contactController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (contactController.chatRoomList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(), // مهم
            children: const [
              Center(
                  child: Padding(
                padding: EdgeInsets.only(top: 150),
                child: Text('لا توجد محادثات حالياً'),
              )),
            ],
          );
        }

        return ListView.builder(
          itemCount: contactController.chatRoomList.length,
          itemBuilder: (context, index) {
            final e = contactController.chatRoomList[index];
            if (e.receiver == null) return const SizedBox();

            return InkWell(
              onTap: () {
                _openChat(e.receiver!);
              },
              child: ChatTile(
                imgUrl: e.receiver!.profileimage ??
                    'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                name: e.receiver!.name ?? 'user name',
                lastChat: e.lastMessage ?? 'لا توجد رسالة',
                lastTime: formatTimestamp(e.lastMessageTimeStamp),
              ),
            );
          },
        );
      }),
    );
  }
}
