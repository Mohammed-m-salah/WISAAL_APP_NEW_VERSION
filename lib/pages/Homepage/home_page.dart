import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wissal_app/controller/chat_controller/chat_controller.dart';
import 'package:wissal_app/controller/contact_controller/contact_controller.dart';
import 'package:wissal_app/controller/group_controller/group_controller.dart';
import 'package:wissal_app/controller/status_controller/status_controller.dart';
import 'package:wissal_app/controller/theme_controller/theme_controller.dart';
import 'package:wissal_app/model/ChatRoomModel.dart';
import 'package:wissal_app/model/Group_model.dart';
import 'package:wissal_app/pages/Homepage/widgets/call_list_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/chat_list_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/groups_list_page.dart';
import 'package:wissal_app/pages/Homepage/widgets/group/chat_group/group_chat.dart';
import 'package:wissal_app/pages/chat_page/chat_page.dart';
import 'package:wissal_app/widgets/connectivity_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ChatController chatController = Get.put(ChatController());
  final StatusController statusController = Get.put(StatusController());
  final ContactController contactController = Get.put(ContactController());
  final GroupController groupController = Get.put(GroupController());
  final ThemeController themeController = Get.find<ThemeController>();
  late TabController _tabController;

  // Search
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    chatController.listenToIncomingMessages();
    _tabController = TabController(length: 3, vsync: this);

    searchController.addListener(() {
      searchQuery.value = searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    isSearching.value = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    isSearching.value = false;
    searchController.clear();
    searchQuery.value = '';
    searchFocusNode.unfocus();
  }

  List<ChatRoomModel> get filteredChats {
    if (searchQuery.value.isEmpty) {
      return contactController.chatRoomList.toList();
    }
    return contactController.chatRoomList.where((room) {
      final name = room.receiver?.name?.toLowerCase() ?? '';
      return name.contains(searchQuery.value);
    }).toList();
  }

  List<GroupModel> get filteredGroups {
    if (searchQuery.value.isEmpty) {
      return groupController.groupList.toList();
    }
    return groupController.groupList.where((group) {
      final name = group.name?.toLowerCase() ?? '';
      return name.contains(searchQuery.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            'assets/icons/Vector.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: Text('app_name'.tr),
        actions: [
          // Theme Toggle Button
          Obx(() => IconButton(
                onPressed: () => themeController.toggleTheme(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    themeController.isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey(themeController.isDarkMode),
                  ),
                ),
                tooltip: themeController.isDarkMode
                    ? 'light_mode'.tr
                    : 'dark_mode'.tr,
              )),
          IconButton(
            onPressed: _openSearch,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'chats'.tr),
            Tab(text: 'groups'.tr),
            Tab(text: 'calls'.tr),
          ],
        ),
      ),
      body: Obx(() => Stack(
            children: [
              Column(
                children: [
                  const ConnectivityBanner(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: const [
                        ChatListPage(),
                        GroupListPage(),
                        CallListPage(),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSearching.value)
                GestureDetector(
                  onTap: _closeSearch,
                  child: Container(
                    color: Colors.black54,
                    child: Column(
                      children: [
                        Material(
                          elevation: 8,
                          child: Container(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                            child: SafeArea(
                              bottom: false,
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _closeSearch,
                                    icon: const Icon(Icons.arrow_back,
                                        color: Colors.white),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: TextField(
                                        controller: searchController,
                                        focusNode: searchFocusNode,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          hintText: 'search_hint'.tr,
                                          hintStyle: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.6)),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 20, vertical: 12),
                                          suffixIcon: Obx(() => searchQuery
                                                  .value.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.white70),
                                                  onPressed: () {
                                                    searchController.clear();
                                                  },
                                                )
                                              : const SizedBox.shrink()),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {},
                            child: Obx(() {
                              final chats = filteredChats;
                              final groups = filteredGroups;

                              if (chats.isEmpty && groups.isEmpty) {
                                return Container(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            searchQuery.value.isEmpty
                                                ? Icons.chat_bubble_outline
                                                : Icons.search_off,
                                            size: 60,
                                            color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          searchQuery.value.isEmpty
                                              ? 'no_messages'.tr
                                              : '${'search'.tr}: "${searchController.text}"',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: ListView(
                                  padding: const EdgeInsets.only(top: 8),
                                  children: [
                                    if (chats.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Icon(Icons.chat_bubble_outline,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            const SizedBox(width: 8),
                                            Text(
                                              searchQuery.value.isEmpty
                                                  ? '${'all_chats'.tr} (${chats.length})'
                                                  : '${'chats'.tr} (${chats.length})',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...chats
                                          .map((room) => _buildChatTile(room)),
                                    ],
                                    if (groups.isNotEmpty) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        child: Row(
                                          children: [
                                            Icon(Icons.group_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary),
                                            const SizedBox(width: 8),
                                            Text(
                                              searchQuery.value.isEmpty
                                                  ? '${'groups'.tr} (${groups.length})'
                                                  : '${'groups'.tr} (${groups.length})',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...groups.map(
                                          (group) => _buildGroupTile(group)),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          )),
    );
  }

  Widget _buildChatTile(ChatRoomModel room) {
    if (room.receiver == null) return const SizedBox();
    final theme = Theme.of(context);
    final hasImage = room.receiver!.profileimage != null &&
        room.receiver!.profileimage!.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        child: hasImage
            ? ClipOval(
                child: Image.network(
                  room.receiver!.profileimage!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      (room.receiver!.name ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 22,
                    );
                  },
                ),
              )
            : Text(
                (room.receiver!.name ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
      title: _highlightText(room.receiver!.name ?? 'User', searchQuery.value),
      subtitle: Text(
        room.lastMessage ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        _closeSearch();
        Get.to(() => ChatPage(userModel: room.receiver!));
      },
    );
  }

  Widget _buildGroupTile(GroupModel group) {
    final theme = Theme.of(context);
    final hasImage = group.profileUrl.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.primary,
        child: hasImage
            ? ClipOval(
                child: Image.network(
                  group.profileUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.group, color: Colors.white, size: 22);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Icon(Icons.group, color: Colors.white, size: 22);
                  },
                ),
              )
            : const Icon(Icons.group, color: Colors.white, size: 22),
      ),
      title: _highlightText(group.name ?? 'Group', searchQuery.value),
      subtitle: Text(
        '${group.members.length} ${'members'.tr}',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        _closeSearch();
        Get.to(() => GroupChat(groupModel: group));
      },
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);

    final lowerText = text.toLowerCase();
    final index = lowerText.indexOf(query);

    if (index == -1) return Text(text);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: Colors.yellow.withOpacity(0.4),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
