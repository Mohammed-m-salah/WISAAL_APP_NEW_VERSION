// Keep your imports unchanged
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/group_info/group_info.dart';
import 'package:wissal_app/pages/chat_page/widget/chat_pubbel.dart';

class GroupChat extends StatefulWidget {
  final GroupModel groupModel;
  const GroupChat({super.key, required this.groupModel});

  @override
  State<GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  final ChatController chatcontroller = Get.find();
  final ProfileController profileController = Get.find();
  final GroupController groupController = Get.find();
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    chatcontroller.currentChatRoomId.value =
        chatcontroller.getRoomId(widget.groupModel.id);
  }

  @override
  void dispose() {
    scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupModel = widget.groupModel;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            InkWell(
              onTap: () {
                Get.to(GroupInfo(groupModel: groupModel));
              },
              child: ClipOval(
                child: Image.network(
                  groupModel.profileUrl ??
                      'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupModel.name ?? "user_name",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "online",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [
          IconButton(
              icon: Icon(Icons.call, color: Colors.white), onPressed: null),
          IconButton(
              icon: Icon(Icons.video_call, color: Colors.white),
              onPressed: null),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatModel>>(
                  stream: groupController.getGroupMessages(groupModel.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("خطأ في تحميل الرسائل"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("لا توجد رسائل"));
                    }

                    final messages = snapshot.data!;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => scrollToBottom());

                    return ListView.builder(
                      reverse: true,
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isSender = message.senderId ==
                            profileController.currentUser.value.id;

                        return ChatBubbel(
                          senderName: message.senderName ?? '',
                          message: message.message ?? '',
                          audioUrl: message.audioUrl ?? '',
                          isComming: !isSender,
                          iscolor: Colors.amber,
                          time: message.timeStamp != null
                              ? DateFormat('hh:mm a')
                                  .format(DateTime.parse(message.timeStamp!))
                              : '',
                          status: "Read",
                          imgUrl: message.imageUrl ?? "",
                          onDelete: isSender
                              ? () => Get.defaultDialog(
                                    title: "حذف الرسالة",
                                    middleText:
                                        "هل أنت متأكد من حذف هذه الرسالة؟",
                                    textCancel: "إلغاء",
                                    textConfirm: "حذف",
                                    confirmTextColor: Colors.white,
                                    onConfirm: () async {
                                      await chatcontroller.deleteMessage(
                                        message.id!,
                                        chatcontroller.currentChatRoomId.value,
                                      );
                                      Get.back();
                                    },
                                  )
                              : null,
                        );
                      },
                    );
                  },
                ),
                Obx(() {
                  if (chatcontroller.selectedImagePaths.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final selectedImage = chatcontroller.selectedImagePaths.first;
                  if (!File(selectedImage).existsSync()) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    bottom: 70,
                    left: 10,
                    right: 10,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: FileImage(File(selectedImage)),
                          fit: BoxFit.contain,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            chatcontroller.selectedImagePaths.clear();
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Text Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Obx(() {
              return TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.primaryContainer,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: chatcontroller.isTyping.value
                      ? IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined,
                              color: Colors.white),
                          onPressed: () {
                            // TODO: Add emoji picker here
                          },
                        )
                      : GestureDetector(
                          onLongPress: () async {
                            if (!chatcontroller.isRecording.value) {
                              await chatcontroller.start_record();
                            }
                          },
                          onTap: () async {
                            if (chatcontroller.isRecording.value) {
                              await chatcontroller.stop_record();
                            }
                          },
                          child: Icon(
                            chatcontroller.isRecording.value
                                ? Icons.stop
                                : Icons.mic,
                            color: Colors.white,
                          ),
                        ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: chatcontroller.selectedImagePaths.isEmpty
                            ? SvgPicture.asset(
                                'assets/icons/mynaui_image.svg',
                                height: 25,
                              )
                            : const Icon(Icons.close, color: Colors.amber),
                        onPressed: () async {
                          if (chatcontroller.selectedImagePaths.isEmpty) {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (_) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo),
                                    title: const Text("اختر من المعرض"),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final path = await imagePickerController
                                          .pickImageFromGallery();
                                      if (path.isNotEmpty) {
                                        chatcontroller.selectedImagePaths.add(path);
                                      }
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text("استخدم الكاميرا"),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      final path = await imagePickerController
                                          .pickImageFromCamera();
                                      if (path.isNotEmpty) {
                                        chatcontroller.selectedImagePaths.add(path);
                                        print("📷 صورة الكاميرا: $path");
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          } else {
                            chatcontroller.selectedImagePaths.clear();
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Obx(() {
                          if (groupController.isSending.value) {
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            );
                          } else {
                            return InkWell(
                              onTap: () {
                                final text = messageController.text.trim();
                                final img = chatcontroller.selectedImagePaths.isNotEmpty
                                    ? chatcontroller.selectedImagePaths.first
                                    : '';

                                if (text.isNotEmpty || img.isNotEmpty) {
                                  groupController.selectedImagePath.value = img;
                                  groupController.sendGroupMessage(
                                    groupModel.id,
                                    text,
                                  );
                                  messageController.clear();
                                  chatcontroller.selectedImagePaths.clear();
                                  chatcontroller.isTyping.value = false;
                                } else {
                                  Get.snackbar(
                                    'تنبيه',
                                    'لا يمكنك إرسال رسالة فارغة',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor:
                                        Colors.white.withOpacity(.1),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 2),
                                    margin: const EdgeInsets.all(12),
                                    borderRadius: 10,
                                  );
                                }
                              },
                              child:
                                  const Icon(Icons.send, color: Colors.white),
                            );
                          }
                        }),
                      ),
                    ],
                  ),
                ),
                onChanged: (val) {
                  chatcontroller.isTyping.value = val.trim().isNotEmpty;
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
