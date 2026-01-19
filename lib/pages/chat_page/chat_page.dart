import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/pages/call_page/Audio_call_page.dart';
import 'package:wissal_app/pages/chat_page/widget/chat_pubbel.dart';
import 'package:wissal_app/pages/user_profile/profile_page.dart';

import '../../controller/call_controller/call_controller.dart';
import '../../controller/status_controller/status_controller.dart';

class ChatPage extends StatefulWidget {
  final UserModel userModel;
  const ChatPage({super.key, required this.userModel});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late ChatController chatcontroller;
  late CallController callController;
  late StatusController statusController;
  late ProfileController profileController;
  late ImagePickerController imagePickerController;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();

    chatcontroller = Get.put(ChatController());
    callController = Get.put(CallController());
    statusController = Get.put(StatusController());
    profileController = Get.put(ProfileController());
    imagePickerController = Get.put(ImagePickerController());

    // تهيئة أنيميشن النقاط المتحركة
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeChat();

    messageController.addListener(() {
      chatcontroller.isTyping.value = messageController.text.trim().isNotEmpty;
      if (messageController.text.trim().isNotEmpty) {
        chatcontroller.setTypingStatus(widget.userModel.id!);
      }
    });
  }

  void _initializeChat() {
    try {
      String roomId = chatcontroller.getRoomId(widget.userModel.id!);

      if (roomId.isNotEmpty) {
        chatcontroller.currentChatRoomId.value = roomId;
        // بدء الاستماع لحالة الكتابة
        chatcontroller.listenToTypingStatus(widget.userModel.id!);
      } else {
        print("⚠️ لم يتمكن من إنشاء Room ID");
        Get.back();
        Get.snackbar("خطأ", "يجب تسجيل الدخول أولاً");
      }
    } catch (e) {
      print("❌ خطأ في تهيئة الدردشة: $e");
      Get.back();
    }
  }

  @override
  void dispose() {
    chatcontroller.stopListeningToTypingStatus(widget.userModel.id!);
    chatcontroller.clearTypingStatus(widget.userModel.id!);
    _typingAnimationController.dispose();
    messageController.dispose();
    scrollController.dispose();
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

  Widget _buildTypingDots() {
    return SizedBox(
      width: 30,
      height: 16,
      child: AnimatedBuilder(
        animation: _typingAnimationController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              // Stagger the animation for each dot
              final delay = index * 0.2;
              final animValue = (_typingAnimationController.value + delay) % 1.0;

              // Create a bouncing effect using sine wave
              final bounce = (animValue < 0.5)
                  ? animValue * 2
                  : 2 - (animValue * 2);

              return Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.5 + (bounce * 0.5)),
                    shape: BoxShape.circle,
                    boxShadow: bounce > 0.5
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userModel = widget.userModel;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
        title: InkWell(
          onTap: () {
            Get.to(() => UserProfilePage(userModel: userModel));
          },
          child: Row(
            children: [
              ClipOval(
                child: Image.network(
                  userModel.profileimage ??
                      'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userModel.name ?? "user_name",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // عرض حالة الكتابة أو حالة الاتصال
                  Obx(() {
                    // إذا كان المستخدم الآخر يكتب، أظهر "يكتب..."
                    if (chatcontroller.isOtherUserTyping.value) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "يكتب",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 4),
                          _buildTypingDots(),
                        ],
                      );
                    }
                    // وإلا أظهر حالة الاتصال
                    return StreamBuilder<UserModel>(
                      stream: chatcontroller.getStatus(userModel.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            "جاري التحقق...",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400,
                                ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.hasError) {
                          return Text(
                            "غير متصل",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                ),
                          );
                        }

                        final user = snapshot.data!;
                        final isOnline = user.status ?? false;

                        return Text(
                          isOnline ? "متصل" : "غير متصل",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: isOnline ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w400,
                              ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(AudioCallPage(target: userModel));
              callController.callAction(
                  userModel, profileController.currentUser.value);
            },
            icon: const Icon(Icons.call, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.video_call, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatModel>>(
                  stream: chatcontroller.getMessages(userModel.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Error loading messages"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No Messages"));
                    }

                    final messages = snapshot.data!.reversed.toList();

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      scrollToBottom();
                    });

                    final currentUserId =
                        profileController.currentUser.value.id ??
                            Supabase.instance.client.auth.currentUser?.id ??
                            '';

                    return ListView.builder(
                      reverse: true,
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMyMessage = message.senderId == currentUserId;

                        return ChatBubbel(
                          senderName: message.senderName ?? '',
                          audioUrl: message.audioUrl ?? "",
                          message: message.message ?? '',
                          isComming: isMyMessage,
                          iscolor: Colors.amber,
                          time: message.timeStamp != null
                              ? DateFormat('hh:mm a').format(
                                  DateTime.parse(message.timeStamp!),
                                )
                              : '',
                          status: "Read",
                          imgUrl: message.imageUrl ?? "",
                          imageUrls: message.imageUrls,
                          onDelete: isMyMessage
                              ? () {
                                  Get.defaultDialog(
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
                                      Get.back(); // إغلاق النافذة
                                    },
                                  );
                                }
                              : null,
                        );
                      },
                    );
                  },
                ),

                // عرض الصور المختارة قبل الإرسال - تصميم احترافي
                Obx(
                  () => chatcontroller.selectedImagePaths.isNotEmpty
                      ? Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.55,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          chatcontroller.selectedImagePaths
                                              .clear();
                                        },
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.red.withOpacity(0.8),
                                        ),
                                      ),
                                      Obx(() => Text(
                                            'Send ${chatcontroller.selectedImagePaths.length} ${chatcontroller.selectedImagePaths.length == 1 ? 'Image' : 'Images'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )),
                                      IconButton(
                                        onPressed: () async {
                                          final path =
                                              await imagePickerController
                                                  .pickImageFromGallery();
                                          if (path.isNotEmpty) {
                                            chatcontroller.selectedImagePaths
                                                .add(path);
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.add_photo_alternate,
                                            color: Colors.white),
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.blue.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Images Preview Grid
                                Flexible(
                                  child: Obx(() {
                                    final images =
                                        chatcontroller.selectedImagePaths;
                                    if (images.length == 1) {
                                      // Single image - show large
                                      return Container(
                                        margin: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.file(
                                                File(images.first),
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: GestureDetector(
                                                onTap: () {
                                                  chatcontroller
                                                      .selectedImagePaths
                                                      .removeAt(0);
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // Multiple images - show grid
                                      return Container(
                                        margin: const EdgeInsets.all(12),
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                          ),
                                          itemCount: images.length,
                                          itemBuilder: (context, index) {
                                            return Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.file(
                                                    File(images[index]),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      chatcontroller
                                                          .selectedImagePaths
                                                          .removeAt(index);
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.6),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Image number badge
                                                Positioned(
                                                  bottom: 4,
                                                  left: 4,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                      '${index + 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  }),
                                ),
                                // Caption hint
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Add a caption below...',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // حقل الإدخال والأزرار - تصميم احترافي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // زر التسجيل الصوتي
                  Obx(() {
                    final isRecording = chatcontroller.isRecording.value;
                    return GestureDetector(
                      onLongPressStart: (_) async {
                        if (!isRecording) {
                          await chatcontroller.start_record();
                        }
                      },
                      onLongPressEnd: (_) async {
                        if (chatcontroller.isRecording.value) {
                          await chatcontroller.stop_record();
                          await chatcontroller.sendVoiceMessage(
                            widget.userModel.id!,
                            widget.userModel,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isRecording
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: isRecording
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isRecording ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),

                  // حقل الإدخال
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // زر المرفقات
                          Obx(
                            () => chatcontroller.selectedImagePaths.isEmpty
                                ? IconButton(
                                    onPressed: _showAttachmentOptions,
                                    icon: const Icon(
                                      Icons.attach_file,
                                      color: Colors.white70,
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          chatcontroller.selectedImagePaths
                                              .clear();
                                        },
                                        icon: const Icon(
                                          Icons.photo_library,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${chatcontroller.selectedImagePaths.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                          // حقل النص
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              maxLines: 5,
                              minLines: 1,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالة...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // زر الإرسال
                  Obx(() {
                    final canSend = chatcontroller.isTyping.value ||
                        chatcontroller.selectedImagePaths.isNotEmpty;
                    final isSending = chatcontroller.isSending.value;

                    return GestureDetector(
                      onTap: isSending
                          ? null
                          : () {
                              if (messageController.text.trim().isNotEmpty ||
                                  chatcontroller
                                      .selectedImagePaths.isNotEmpty) {
                                chatcontroller.sendMessage(
                                  widget.userModel.id!,
                                  messageController.text.trim(),
                                  widget.userModel,
                                );
                                messageController.clear();
                                chatcontroller.isTyping.value = false;
                              }
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: canSend
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: isSending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // مؤشر التسجيل
          Obx(() {
            if (chatcontroller.isRecording.value) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red.withOpacity(0.1),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        color: Colors.red, size: 12),
                    SizedBox(width: 8),
                    Text(
                      'جاري التسجيل... اترك للإرسال',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'إرفاق ملف',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('اختر من المعرض'),
                subtitle: const Text('يمكنك اختيار صور متعددة'),
                onTap: () async {
                  Navigator.pop(context);
                  final path =
                      await imagePickerController.pickImageFromGallery();
                  if (path.isNotEmpty) {
                    chatcontroller.selectedImagePaths.add(path);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('التقط صورة'),
                subtitle: const Text('استخدم الكاميرا'),
                onTap: () async {
                  Navigator.pop(context);
                  final path =
                      await imagePickerController.pickImageFromCamera();
                  if (path.isNotEmpty) {
                    chatcontroller.selectedImagePaths.add(path);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
