import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wissal_app/model/user_model.dart';
import 'package:wissal_app/widgets/skeleton_loading.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel user;

  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final db = Supabase.instance.client;
  final auth = Supabase.instance.client.auth;

  final RxBool isLoading = true.obs;
  final RxList<String> sharedImages = <String>[].obs;
  final RxList<Map<String, dynamic>> sharedVoices = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> sharedDocuments = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> sharedLinks = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSharedMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedMedia() async {
    isLoading.value = true;
    try {
      final currentUserId = auth.currentUser?.id;
      if (currentUserId == null) return;

      // جلب جميع الرسائل بين المستخدمين
      final messages = await db
          .from('chats')
          .select()
          .or('and(senderId.eq.$currentUserId,reciverId.eq.${widget.user.id}),and(senderId.eq.${widget.user.id},reciverId.eq.$currentUserId)')
          .order('timeStamp', ascending: false);

      // تصنيف الوسائط
      for (final msg in messages) {
        final message = msg['message'] as String? ?? '';
        final imageUrl = msg['imageUrl'] as String?;
        final audioUrl = msg['audioUrl'] as String?;
        final fileUrl = msg['fileUrl'] as String?;
        final fileName = msg['fileName'] as String?;
        final timestamp = msg['timeStamp'] as String?;

        // الصور
        if (imageUrl != null && imageUrl.isNotEmpty) {
          sharedImages.add(imageUrl);
        }

        // الرسائل الصوتية
        if (audioUrl != null && audioUrl.isNotEmpty) {
          sharedVoices.add({
            'url': audioUrl,
            'timestamp': timestamp,
            'senderId': msg['senderId'],
          });
        }

        // المستندات
        if (fileUrl != null && fileUrl.isNotEmpty) {
          sharedDocuments.add({
            'url': fileUrl,
            'name': fileName ?? 'document'.tr,
            'timestamp': timestamp,
          });
        }

        // الروابط (استخراج الروابط من النص)
        final urlRegex = RegExp(
          r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
        );
        final matches = urlRegex.allMatches(message);
        for (final match in matches) {
          sharedLinks.add({
            'url': match.group(0),
            'message': message,
            'timestamp': timestamp,
          });
        }
      }
    } catch (e) {
      print('Error loading shared media: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(theme, isDark),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Get.back(),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                  onPressed: () => _showMoreOptions(context),
                ),
              ],
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.hintColor,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(icon: const Icon(Icons.photo), text: 'media'.tr),
                    Tab(icon: const Icon(Icons.mic), text: 'audio'.tr),
                    Tab(icon: const Icon(Icons.insert_drive_file), text: 'docs'.tr),
                    Tab(icon: const Icon(Icons.link), text: 'links'.tr),
                  ],
                ),
                theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: Obx(() {
          if (isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMediaGrid(),
              _buildVoicesList(),
              _buildDocumentsList(),
              _buildLinksList(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final hasImage = widget.user.profileimage != null &&
        widget.user.profileimage!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Profile Image
            Hero(
              tag: 'profile_${widget.user.id}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          widget.user.profileimage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              widget.user.name ?? 'user'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Email or About
            Text(
              widget.user.about ?? widget.user.email ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.chat,
                  label: 'message'.tr,
                  onTap: () => Get.back(),
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.call,
                  label: 'call'.tr,
                  onTap: () {},
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.videocam,
                  label: 'video'.tr,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white24,
      child: Center(
        child: Text(
          (widget.user.name ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    if (sharedImages.isEmpty) {
      return _buildEmptyState(
        Icons.photo_library_outlined,
        'no_shared_media'.tr,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: sharedImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageViewer(index),
          child: Hero(
            tag: 'image_$index',
            child: Image.network(
              sharedImages[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoicesList() {
    if (sharedVoices.isEmpty) {
      return _buildEmptyState(
        Icons.mic_none,
        'no_shared_audio'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sharedVoices.length,
      itemBuilder: (context, index) {
        final voice = sharedVoices[index];
        final isMe = voice['senderId'] == auth.currentUser?.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'you'.tr : widget.user.name ?? 'user'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatTimestamp(voice['timestamp']),
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill),
                color: Theme.of(context).colorScheme.primary,
                iconSize: 40,
                onPressed: () {
                  // Play audio
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    if (sharedDocuments.isEmpty) {
      return _buildEmptyState(
        Icons.folder_open,
        'no_shared_docs'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sharedDocuments.length,
      itemBuilder: (context, index) {
        final doc = sharedDocuments[index];
        final fileName = doc['name'] as String;
        final extension = fileName.split('.').last.toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileColor(extension),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  extension.length > 4 ? extension.substring(0, 4) : extension,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatTimestamp(doc['timestamp']),
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(doc['url']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinksList() {
    if (sharedLinks.isEmpty) {
      return _buildEmptyState(
        Icons.link_off,
        'no_shared_links'.tr,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sharedLinks.length,
      itemBuilder: (context, index) {
        final link = sharedLinks[index];
        final url = link['url'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link, color: Colors.blue),
            ),
            title: Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
            subtitle: Text(
              _formatTimestamp(link['timestamp']),
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
            ),
            onTap: () => _openLink(url),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(int initialIndex) {
    Get.to(
      () => ImageViewerPage(
        images: sharedImages,
        initialIndex: initialIndex,
      ),
      transition: Transition.fade,
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text('block_user'.tr),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: Text('report'.tr),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'yesterday'.tr;
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// Image Viewer Page
class ImageViewerPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final pageController = PageController(initialPage: initialIndex);
    final currentIndex = initialIndex.obs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Obx(() => Text(
              '${currentIndex.value + 1} / ${images.length}',
              style: const TextStyle(color: Colors.white),
            )),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: images.length,
        onPageChanged: (index) => currentIndex.value = index,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Hero(
                tag: 'image_$index',
                child: Image.network(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Sliver Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
