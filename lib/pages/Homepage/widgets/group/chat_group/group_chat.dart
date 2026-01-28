import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/image_picker/image_picker.dart';
import 'package:wissal_app/controller/profile_controller/profile_controller.dart';
import 'package:wissal_app/controller/saved_messages_controller/saved_messages_controller.dart';
import 'package:wissal_app/controller/reactions_controller/reactions_controller.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/model/chat_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/group_info/group_info.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/chat_group/system_message_bubble.dart';
import 'package:wissal_app/pages/chat_page/widget/chat_pubbel.dart';
import 'package:wissal_app/widgets/reaction_picker.dart';
import 'package:wissal_app/widgets/voice_recorder_widget.dart';
import 'package:wissal_app/widgets/message_seen_sheet.dart';
import 'package:wissal_app/widgets/mute_settings_sheet.dart';
import 'package:wissal_app/services/notifications/notification_service.dart';
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
  final SavedMessagesController savedMessagesController =
      Get.put(SavedMessagesController());
  final auth = Supabase.instance.client.auth;

  final TextEditingController messageController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late GroupModel _group;
  String get _currentUserId => auth.currentUser?.id ?? '';

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchMatchIndices = [];
  int _currentSearchIndex = 0;
  List<ChatModel> _currentMessages = [];
  Timer? _debounceTimer;
  final Map<int, GlobalKey> _messageKeys = {};

  bool _isVoiceLocked = false;
  String? _recordedAudioPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  DateTime? _recordingStartTime;
  double _voiceDragOffset = 0;

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
    searchController.dispose();
    _debounceTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // Voice recording methods
  void _startVoiceRecording() async {
    _recordingStartTime = DateTime.now();
    await chatcontroller.start_record();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null && mounted) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
      }
    });
  }

  void _stopVoiceRecording(bool cancelled) async {
    _recordingTimer?.cancel();
    if (cancelled) {
      await chatcontroller.stop_record();
      setState(() {
        _recordingDuration = Duration.zero;
        _voiceDragOffset = 0;
        _isVoiceLocked = false;
        _recordedAudioPath = null;
      });
      return;
    }

    final audioPath = await chatcontroller.stop_record();
    if (audioPath != null && audioPath.isNotEmpty) {
      if (_isVoiceLocked) {
        setState(() {
          _recordedAudioPath = audioPath;
        });
      } else {
        groupController.selectedAudioPath.value = audioPath;
        groupController.sendGroupMessage(_group.id, '', isVoice: true);
        setState(() {
          _recordingDuration = Duration.zero;
          _voiceDragOffset = 0;
        });
      }
    }
  }

  void _lockVoiceRecording() {
    setState(() {
      _isVoiceLocked = true;
      _voiceDragOffset = 0;
    });
  }

  void _cancelLockedRecording() {
    _recordingTimer?.cancel();
    chatcontroller.stop_record();
    setState(() {
      _recordingDuration = Duration.zero;
      _isVoiceLocked = false;
      _recordedAudioPath = null;
    });
  }

  void _sendLockedRecording() {
    if (_recordedAudioPath != null && _recordedAudioPath!.isNotEmpty) {
      groupController.selectedAudioPath.value = _recordedAudioPath!;
      groupController.sendGroupMessage(_group.id, '', isVoice: true);
    }
    setState(() {
      _recordingDuration = Duration.zero;
      _isVoiceLocked = false;
      _recordedAudioPath = null;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        searchController.clear();
        _searchQuery = '';
        _searchMatchIndices.clear();
        _currentSearchIndex = 0;
        _messageKeys.clear();
      }
    });
  }

  Future<void> _showMuteSettings() async {
    final groupId = _group.id;
    final notificationService = NotificationService();

    // Get current mute settings
    final currentSettings =
        await notificationService.getCurrentUserMuteSettings(
      targetId: groupId ?? '',
      targetType: 'group',
    );

    if (!mounted) return;

    await showMuteSettingsSheet(
      context: context,
      targetId: groupId ?? '',
      targetType: 'group',
      targetName: _group.name ?? 'Group',
      currentSettings: currentSettings,
    );
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search for 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateSearchMatches(query);
    });
  }

  void _updateSearchMatches(String query) {
    if (!mounted) return;

    setState(() {
      _searchQuery = query.toLowerCase().trim();
      _searchMatchIndices.clear();
      _currentSearchIndex = 0;

      if (_searchQuery.isNotEmpty && _currentMessages.isNotEmpty) {
        for (int i = 0; i < _currentMessages.length; i++) {
          final message = _currentMessages[i];
          final messageText = message.message?.toLowerCase() ?? '';
          final senderName = message.senderName?.toLowerCase() ?? '';

          // Search in message text and sender name
          if (messageText.contains(_searchQuery) ||
              senderName.contains(_searchQuery)) {
            _searchMatchIndices.add(i);
          }
        }

        // Auto-scroll to first result
        if (_searchMatchIndices.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollToCurrentMatch();
          });
        }
      }
    });
  }

  void _navigateToSearchResult(int direction) {
    if (_searchMatchIndices.isEmpty) return;

    setState(() {
      _currentSearchIndex += direction;
      if (_currentSearchIndex < 0) {
        _currentSearchIndex = _searchMatchIndices.length - 1;
      } else if (_currentSearchIndex >= _searchMatchIndices.length) {
        _currentSearchIndex = 0;
      }
    });

    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_searchMatchIndices.isEmpty || !scrollController.hasClients) return;

    final targetIndex = _searchMatchIndices[_currentSearchIndex];
    final key = _messageKeys[targetIndex];

    if (key?.currentContext != null) {
      // Use Scrollable.ensureVisible for precise scrolling
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // Center the item
      );
    } else {
      // Fallback to estimated position
      final totalMessages = _currentMessages.length;
      final position = (totalMessages - 1 - targetIndex) * 85.0;

      scrollController.animateTo(
        position.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  GlobalKey _getKeyForIndex(int index) {
    if (!_messageKeys.containsKey(index)) {
      _messageKeys[index] = GlobalKey();
    }
    return _messageKeys[index]!;
  }

  Widget _buildHighlightedText(String text, String query, ThemeData theme) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.6),
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: spans,
      ),
    );
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

  /// Build loading skeleton for messages
  Widget _buildLoadingSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final bubbleColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;

    return ListView.builder(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (context, index) {
        final isMe = index % 3 == 0;
        final widthFactor = 0.4 + (index % 4) * 0.1;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * widthFactor,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Container(
                    width: 60,
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          icon: Icon(_isSearching ? Icons.close : Icons.arrow_back,
              color: Colors.white),
          onPressed: _isSearching ? _toggleSearch : () => Get.back(),
        ),
        title: _isSearching
            ? _buildSearchField(theme)
            : InkWell(
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
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        actions: _isSearching
            ? [
                // Search results counter or "no results" message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _searchQuery.isEmpty
                          ? const SizedBox.shrink(key: ValueKey('empty'))
                          : _searchMatchIndices.isNotEmpty
                              ? Container(
                                  key: const ValueKey('results'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentSearchIndex + 1}/${_searchMatchIndices.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('no_results'),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'لا توجد نتائج',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),
                // Navigation buttons (only show when there are results)
                if (_searchMatchIndices.length > 1) ...[
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up,
                        color: Colors.white),
                    onPressed: () => _navigateToSearchResult(-1),
                    tooltip: 'السابق',
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white),
                    onPressed: () => _navigateToSearchResult(1),
                    tooltip: 'التالي',
                  ),
                ],
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () => Get.to(() => GroupInfo(groupModel: _group))
                      ?.then((_) => _loadGroupData()),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'mute') {
                      _showMuteSettings();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_off, size: 20),
                          const SizedBox(width: 8),
                          Text(Trans('mute_notifications').tr),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
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
                  initialData:
                      groupController.getCachedGroupMessages(_group.id),
                  builder: (context, snapshot) {
                    // Show skeleton while loading if no cached data
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        (snapshot.data == null || snapshot.data!.isEmpty)) {
                      return _buildLoadingSkeleton();
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
                              Trans('no_messages').tr,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Trans('start_conversation').tr,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!;
                    _currentMessages = messages;
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
                        final isAdmin = _group.isAdmin(_currentUserId);

                        // Check if this is a search match
                        final isSearchMatch =
                            _searchMatchIndices.contains(index);
                        final isCurrentSearchMatch = isSearchMatch &&
                            _searchMatchIndices.isNotEmpty &&
                            _currentSearchIndex < _searchMatchIndices.length &&
                            _searchMatchIndices[_currentSearchIndex] == index;

                        if (message.isSystemMessage) {
                          return SystemMessageBubble(
                            message: message.message ?? '',
                            time: message.timeStamp != null
                                ? DateFormat('hh:mm a')
                                    .format(DateTime.parse(message.timeStamp!))
                                : '',
                          );
                        }

                        Widget? highlightedMessageWidget;
                        if (_searchQuery.isNotEmpty && isSearchMatch) {
                          highlightedMessageWidget = _buildHighlightedText(
                            message.message ?? '',
                            _searchQuery,
                            theme,
                          );
                        }

                        return AnimatedContainer(
                          key: _getKeyForIndex(index),
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isCurrentSearchMatch
                                ? theme.colorScheme.primary.withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: GestureDetector(
                            onLongPress: () =>
                                _showMessageOptions(message, isSender, isAdmin),
                            child: Column(
                              crossAxisAlignment: isSender
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Show sender name for group messages (only for other users)
                                if (!isSender &&
                                    message.senderName != null &&
                                    message.senderName!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        right: 16, bottom: 2, top: 8),
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
                                  isComming: isSender,
                                  iscolor: Colors.amber,
                                  time: message.timeStamp != null
                                      ? DateFormat('hh:mm a').format(
                                          DateTime.parse(message.timeStamp!))
                                      : '',
                                  status: isSender
                                      ? _getMessageStatus(message)
                                      : '',
                                  imgUrl: _getValidImageUrl(message.imageUrl),
                                  isDeleted: message.isDeleted ?? false,
                                  isEdited: message.isEdited ?? false,
                                  isForwarded: message.isForwarded ?? false,
                                  forwardedFrom: message.forwardedFrom,
                                  deletedBy: message.deletedBy,
                                  deletedByName: message.deletedByName,
                                  isHighlighted: isCurrentSearchMatch,
                                  isSearchMatch: isSearchMatch,
                                  searchQuery: _searchQuery,
                                  reactions: message.reactions,
                                  currentUserId: _currentUserId,
                                  onReact: (emoji) =>
                                      _handleReaction(message, emoji),
                                  onDelete: (isSender || isAdmin)
                                      ? () => _confirmDeleteMessage(
                                          message, isAdmin && !isSender)
                                      : null,
                                  onEdit: isSender &&
                                          (message.message?.isNotEmpty ?? false)
                                      ? () => _showEditDialog(message)
                                      : null,
                                  onForward: () => _showForwardDialog(message),
                                  onSave: () => _saveMessage(message),
                                ),
                              ],
                            ),
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

    // Show voice recording overlay when recording
    if (chatcontroller.isRecording.value && !_isVoiceLocked) {
      return VoiceRecorderOverlay(
        isRecording: chatcontroller.isRecording.value,
        duration: _recordingDuration,
        dragOffset: _voiceDragOffset,
        isLocked: _isVoiceLocked,
        onCancel: () => _stopVoiceRecording(true),
        onLock: _lockVoiceRecording,
        onSend: _sendLockedRecording,
        onDragUpdate: (offset) => setState(() => _voiceDragOffset = offset),
      );
    }

    if (_isVoiceLocked && _recordedAudioPath == null) {
      return VoiceRecorderOverlay(
        isRecording: true,
        duration: _recordingDuration,
        dragOffset: 0,
        isLocked: true,
        onCancel: _cancelLockedRecording,
        onLock: () {},
        onSend: _sendLockedRecording,
        onDragUpdate: (_) {},
      );
    }

    if (_recordedAudioPath != null) {
      return QuickVoicePreview(
        audioPath: _recordedAudioPath!,
        duration: _recordingDuration,
        onSend: _sendLockedRecording,
        onCancel: _cancelLockedRecording,
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
            // Mic button with slide to cancel
            if (!chatcontroller.isTyping.value)
              VoiceRecordButton(
                isRecording: chatcontroller.isRecording.value,
                onStartRecording: _startVoiceRecording,
                onStopRecording: _stopVoiceRecording,
                onLockRecording: _lockVoiceRecording,
                onDragUpdate: (offset) {
                  setState(() => _voiceDragOffset = offset);
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

  String _getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return '';
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '';
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

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: searchController,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'بحث في الرسائل...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withOpacity(0.6),
          size: 22,
        ),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: searchController.text.isNotEmpty
              ? IconButton(
                  key: const ValueKey('clear'),
                  icon:
                      const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () {
                    searchController.clear();
                    _onSearchChanged('');
                    setState(() {});
                  },
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ),
      onChanged: (value) {
        setState(() {}); // Update UI for clear button
        _onSearchChanged(value);
      },
    );
  }

  void _handleReaction(ChatModel message, String emoji) {
    if (message.id == null) return;
    if (emoji.isEmpty) {
      groupController.removeGroupReaction(message.id!);
    } else {
      groupController.addGroupReaction(message.id!, emoji);
    }
  }

  void _saveMessage(ChatModel message) {
    savedMessagesController.saveGroupMessage(message, _group.name ?? 'مجموعة');
  }

  void _showEditDialog(ChatModel message) {
    final editController = TextEditingController(text: message.message);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'أدخل النص الجديد',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              Navigator.pop(dialogContext);
              if (newText.isNotEmpty && newText != message.message) {
                await groupController.editGroupMessage(message.id!, newText);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(ChatModel message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحويل الرسالة'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            final groups = groupController.groupList
                .where((g) => g.id != _group.id)
                .toList();

            if (groups.isEmpty) {
              return const Center(
                child: Text('لا توجد مجموعات أخرى'),
              );
            }

            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: group.profileUrl.isNotEmpty
                        ? NetworkImage(group.profileUrl)
                        : null,
                    child: group.profileUrl.isEmpty
                        ? const Icon(Icons.group)
                        : null,
                  ),
                  title: Text(group.name ?? 'مجموعة'),
                  subtitle: Text('${group.memberCount} عضو'),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await groupController.forwardGroupMessage(
                      message: message,
                      toGroupId: group.id,
                    );
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatModel message, bool isSender, bool isAdmin) {
    if (message.isDeleted == true) return;

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

              // React option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('❤️', style: TextStyle(fontSize: 20)),
                ),
                title: const Text('تفاعل'),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message);
                },
              ),

              // Forward option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shortcut, color: Colors.green),
                ),
                title: const Text('تحويل'),
                onTap: () {
                  Navigator.pop(context);
                  _showForwardDialog(message);
                },
              ),

              // Save option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_add_outlined,
                      color: Colors.blue),
                ),
                title: const Text('حفظ'),
                onTap: () {
                  Navigator.pop(context);
                  _saveMessage(message);
                },
              ),

              // Info option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.info_outline,
                      color: theme.colorScheme.primary),
                ),
                title: const Text('معلومات الرسالة'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageInfo(message);
                },
              ),

              // Edit option (only for sender)
              if (isSender && (message.message?.isNotEmpty ?? false)) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.orange),
                  ),
                  title: const Text('تعديل'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(message);
                  },
                ),
              ],

              // Delete option
              if (isSender || isAdmin) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(
                    isAdmin && !isSender ? 'حذف (كمشرف)' : 'حذف الرسالة',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(message, isAdmin && !isSender);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionPicker(ChatModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ReactionEmoji.all.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _handleReaction(message, emoji);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageInfo(ChatModel message) async {
    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    final seenBy = await groupController.getMessageSeenBy(message.id ?? '');
    final deliveredTo =
        await groupController.getMessageDeliveredTo(message.id ?? '');

    // Close loading indicator
    Get.back();

    if (!mounted) return;

    // Show the message seen sheet
    showMessageSeenSheet(
      context: context,
      message: message,
      groupMembers: _group.groupMembers,
      currentUserId: _currentUserId,
      seenByIds: seenBy,
      deliveredToIds: deliveredTo,
    );
  }

  void _confirmDeleteMessage(ChatModel message, [bool asAdmin = false]) {
    Get.defaultDialog(
      title: asAdmin ? "حذف الرسالة كمشرف" : "حذف الرسالة",
      middleText: asAdmin
          ? "سيتم عرض اسمك كمشرف قام بحذف هذه الرسالة"
          : "هل أنت متأكد من حذف هذه الرسالة؟",
      textCancel: "إلغاء",
      textConfirm: "حذف",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await groupController.deleteGroupMessage(
          _group.id,
          message.id!,
          isAdmin: asAdmin,
        );
      },
    );
  }
}
