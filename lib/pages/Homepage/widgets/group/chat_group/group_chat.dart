import 'dart:io';
import 'package:flutter/material.dart';
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
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupChat extends StatefulWidget {
  final GroupModel groupModel;
  const GroupChat({super.key, required this.groupModel});

  @override
  State<GroupChat> createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  final ChatController chatcontroller = Get.put(ChatController());
  final ProfileController profileController = Get.put(ProfileController());
  final GroupController groupController = Get.put(GroupController());
  final ImagePickerController imagePickerController =
      Get.put(ImagePickerController());
  final auth = Supabase.instance.client.auth;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late GroupModel _group;
  String get _currentUserId => auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _group = widget.groupModel;
    _loadGroupData();
    _markMessagesAsSeen();
  }

  Future<void> _loadGroupData() async {
    final updatedGroup = await groupController.getGroupById(_group.id);
    if (updatedGroup != null && mounted) {
      setState(() => _group = updatedGroup);
    }
  }

  Future<void> _markMessagesAsSeen() async {
    await groupController.markAllMessagesAsSeenInGroup(_group.id);
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

  bool get _canSendMessage => _group.canSendMessage(_currentUserId);
  bool get _isLocked => _group.settings.isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: InkWell(
          onTap: () => Get.to(() => GroupInfo(groupModel: _group))
              ?.then((_) => _loadGroupData()),
          child: Row(
            children: [
              ClipOval(
                child: Image.network(
                  _group.profileUrl.isNotEmpty
                      ? _group.profileUrl
                      : 'https://i.ibb.co/V04vrTtV/blank-profile-picture-973460-1280.png',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 45,
                    height: 45,
                    color: theme.colorScheme.primary,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _group.name ?? "المجموعة",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isLocked) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.lock,
                              color: Colors.white70, size: 14),
                        ],
                      ],
                    ),
                    Text(
                      '${_group.memberCount} عضو',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => Get.to(() => GroupInfo(groupModel: _group))
                ?.then((_) => _loadGroupData()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Lock banner
          if (_isLocked && !_group.isAdmin(_currentUserId))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'المجموعة مقفلة - فقط المشرفين يمكنهم الإرسال',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatModel>>(
                  stream: groupController.getGroupMessages(_group.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child:
                              Text("خطأ في تحميل الرسائل: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد رسائل بعد',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ابدأ المحادثة!',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => scrollToBottom());

                    return ListView.builder(
                      reverse: true,
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isSender = message.senderId ==
                            profileController.currentUser.value.id;

                        return GestureDetector(
                          onLongPress: () =>
                              _showMessageOptions(message, isSender),
                          child: Column(
                            crossAxisAlignment: isSender
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Show sender name for group messages
                              if (!isSender &&
                                  message.senderName != null &&
                                  message.senderName!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, bottom: 2, top: 8),
                                  child: Text(
                                    message.senderName!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ChatBubbel(
                                key: ValueKey('group_msg_${message.id}'),
                                senderName: '',
                                message: message.message ?? '',
                                audioUrl: message.audioUrl ?? '',
                                isComming: !isSender,
                                iscolor: Colors.amber,
                                time: message.timeStamp != null
                                    ? DateFormat('hh:mm a').format(
                                        DateTime.parse(message.timeStamp!))
                                    : '',
                                status:
                                    isSender ? _getMessageStatus(message) : '',
                                imgUrl: message.imageUrl ?? "",
                                onDelete: isSender
                                    ? () => _confirmDeleteMessage(message)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                // Image preview
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
                        color: theme.colorScheme.primaryContainer,
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

          // Input area
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    if (!_canSendMessage) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: theme.colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'لا يمكنك الإرسال في هذه المجموعة',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() {
        return Row(
          children: [
            // Mic / Emoji button
            if (!chatcontroller.isTyping.value)
              GestureDetector(
                onLongPress: () async {
                  if (!chatcontroller.isRecording.value) {
                    await chatcontroller.start_record();
                  }
                },
                onLongPressUp: () async {
                  if (chatcontroller.isRecording.value) {
                    final audioPath = await chatcontroller.stop_record();
                    if (audioPath != null && audioPath.isNotEmpty) {
                      groupController.selectedAudioPath.value = audioPath;
                      groupController.sendGroupMessage(_group.id, '',
                          isVoice: true);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chatcontroller.isRecording.value
                        ? Colors.red
                        : theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    chatcontroller.isRecording.value
                        ? Icons.mic
                        : Icons.mic_none,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  filled: true,
                  fillColor: theme.colorScheme.primaryContainer,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: chatcontroller.selectedImagePaths.isEmpty
                        ? Icon(Icons.image,
                            color: Colors.white.withOpacity(0.7))
                        : const Icon(Icons.close, color: Colors.amber),
                    onPressed: () {
                      if (chatcontroller.selectedImagePaths.isEmpty) {
                        _showImagePicker();
                      } else {
                        chatcontroller.selectedImagePaths.clear();
                      }
                    },
                  ),
                ),
                onChanged: (val) {
                  chatcontroller.isTyping.value = val.trim().isNotEmpty;
                },
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Obx(() {
              if (groupController.isSending.value) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              return GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    final img = chatcontroller.selectedImagePaths.isNotEmpty
        ? chatcontroller.selectedImagePaths.first
        : '';

    if (text.isNotEmpty || img.isNotEmpty) {
      groupController.selectedImagePath.value = img;
      groupController.sendGroupMessage(_group.id, text);
      messageController.clear();
      chatcontroller.selectedImagePaths.clear();
      chatcontroller.isTyping.value = false;
    } else {
      Get.snackbar(
        'تنبيه',
        'لا يمكنك إرسال رسالة فارغة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
      );
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("اختر من المعرض"),
              onTap: () async {
                Navigator.pop(context);
                final path = await imagePickerController.pickImageFromGallery();
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
                final path = await imagePickerController.pickImageFromCamera();
                if (path.isNotEmpty) {
                  chatcontroller.selectedImagePaths.add(path);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getMessageStatus(ChatModel message) {
    return 'Sent';
  }

  void _showMessageOptions(ChatModel message, bool isSender) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                title: const Text('معلومات الرسالة'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageInfo(message);
                },
              ),
              if (isSender) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('حذف الرسالة',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(message);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageInfo(ChatModel message) async {
    final seenBy = await groupController.getMessageSeenBy(message.id ?? '');
    final deliveredTo =
        await groupController.getMessageDeliveredTo(message.id ?? '');

    if (!mounted) return;

    Get.dialog(
      AlertDialog(
        title: const Text('معلومات الرسالة'),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'شاهدوا'),
                    Tab(text: 'استلموا'),
                  ],
                ),
                SizedBox(
                  height: 200,
                  child: TabBarView(
                    children: [
                      _buildUserList(seenBy),
                      _buildUserList(deliveredTo),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<String> userIds) {
    if (userIds.isEmpty) {
      return const Center(
        child: Text('لا يوجد', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final odId = userIds[index];
        final member = FirstWhereExt(_group.groupMembers)
            .firstWhereOrNull((m) => m.odId == odId);

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: member?.profileImage != null
                ? NetworkImage(member!.profileImage!)
                : null,
            child: member?.profileImage == null
                ? Text(member?.name.isNotEmpty == true
                    ? member!.name[0].toUpperCase()
                    : '?')
                : null,
          ),
          title: Text(
            member?.name ?? 'مستخدم غير معروف',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: odId == _currentUserId
              ? const Text('(أنت)',
                  style: TextStyle(fontSize: 12, color: Colors.grey))
              : null,
        );
      },
    );
  }

  void _confirmDeleteMessage(ChatModel message) {
    Get.defaultDialog(
      title: "حذف الرسالة",
      middleText: "هل أنت متأكد من حذف هذه الرسالة؟",
      textCancel: "إلغاء",
      textConfirm: "حذف",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await Supabase.instance.client
              .from('group_chats')
              .delete()
              .eq('id', message.id!);
          Get.back();
          Get.snackbar('تم', 'تم حذف الرسالة',
              backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar('خطأ', 'فشل حذف الرسالة',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
    );
  }
}
