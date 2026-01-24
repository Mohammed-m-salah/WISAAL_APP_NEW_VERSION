import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_tile.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/chat_group/group_chat.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

class GroupListPage extends StatelessWidget {
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final GroupController groupController = Get.put(GroupController());

    return RefreshIndicator(
      onRefresh: () => groupController.getGroups(),
      child: Obx(() {
        // Show skeleton while loading
        if (groupController.isLoading.value) {
          return const GroupListSkeleton();
        }

        // Show message if no groups
        if (groupController.groupList.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'no_groups'.tr,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Show groups list
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: groupController.groupList.length,
          itemBuilder: (context, index) {
            final group = groupController.groupList[index];

            final String groupName = group.name?.trim().isNotEmpty == true
                ? group.name!.trim()
                : 'group_name'.tr;

            final String lastChatText =
                group.lastMessage?.trim().isNotEmpty == true
                    ? group.lastMessage!.trim()
                    : 'no_messages'.tr;

            final String lastTimeText =
                group.lastMessageTime?.trim().isNotEmpty == true
                    ? _formatTime(group.lastMessageTime!)
                    : '';

            final String imageUrl = (group.profileUrl.trim().isNotEmpty &&
                    group.profileUrl.trim().startsWith('http'))
                ? group.profileUrl.trim()
                : '';

            return InkWell(
              onTap: () => Get.to(() => GroupChat(groupModel: group)),
              child: ChatTile(
                imgUrl: imageUrl,
                name: groupName,
                lastChat: lastChatText,
                lastTime: lastTimeText,
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString).toLocal();
      return TimeOfDay.fromDateTime(dateTime).format(Get.context!);
    } catch (e) {
      return '';
    }
  }
}
