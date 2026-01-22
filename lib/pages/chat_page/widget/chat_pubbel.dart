import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ChatBubbel extends StatefulWidget {
  final String message;
  final bool isComming;
  final Color iscolor;
  final String time;
  final String status;
  final String imgUrl;
  final List<String>? imageUrls; // قائمة الصور المجمعة
  final String audioUrl;
  final String senderName;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isDeleted;
  final bool isEdited;
  final bool isHighlighted;
  final bool isSearchMatch;

  const ChatBubbel({
    super.key,
    required this.message,
    required this.isComming,
    required this.iscolor,
    required this.time,
    required this.status,
    required this.imgUrl,
    this.imageUrls,
    required this.audioUrl,
    required this.senderName,
    this.onDelete,
    this.onEdit,
    this.isDeleted = false,
    this.isEdited = false,
    this.isHighlighted = false,
    this.isSearchMatch = false,
  });

  @override
  State<ChatBubbel> createState() => _ChatBubbelState();
}

class _ChatBubbelState extends State<ChatBubbel> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  late final StreamSubscription _stateSub;
  late final StreamSubscription _positionSub;
  late final StreamSubscription _durationSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_playerState == PlayerState.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showMessageOptions(BuildContext context, TapDownDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        if (widget.onEdit != null && widget.message.trim().isNotEmpty)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Edit', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Delete', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'edit') {
        widget.onEdit!();
      } else if (value == 'delete') {
        widget.onDelete!();
      }
    });
  }

  /// الحصول على قائمة الصور من imageUrls أو من imgUrl
  List<String> _getImageUrls() {
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      return widget.imageUrls!;
    }
    if (widget.imgUrl.trim().isEmpty) return [];
    // محاولة تحليل كـ JSON array
    if (widget.imgUrl.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(widget.imgUrl);
        if (decoded is List) {
          return List<String>.from(decoded.where((e) => e != null && e.toString().isNotEmpty));
        }
      } catch (_) {}
    }
    return [widget.imgUrl];
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// عرض معرض الصور
  void _showImageGallery(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryViewer(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// عرض صورة واحدة
  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, imageUrl),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 220,
                color: Colors.grey.shade800,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity,
              height: 220,
              color: Colors.grey.shade800,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'فشل تحميل الصورة',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض شبكة الصور المتعددة
  Widget _buildImageGrid(BuildContext context, List<String> images) {
    final imageCount = images.length;
    final displayCount = imageCount > 4 ? 4 : imageCount;
    final remainingCount = imageCount - 4;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      child: SizedBox(
        height: imageCount == 2 ? 150 : 220,
        child: _buildGridLayout(context, images, displayCount, remainingCount),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, List<String> images, int displayCount, int remainingCount) {
    if (displayCount == 2) {
      // صورتان جنبًا إلى جنب
      return Row(
        children: [
          Expanded(child: _buildGridImage(context, images, 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildGridImage(context, images, 1)),
        ],
      );
    } else if (displayCount == 3) {
      // صورة كبيرة على اليسار وصورتان صغيرتان على اليمين
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildGridImage(context, images, 0),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGridImage(context, images, 1)),
                const SizedBox(height: 2),
                Expanded(child: _buildGridImage(context, images, 2)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 صور أو أكثر - شبكة 2x2
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImage(context, images, 0)),
                const SizedBox(width: 2),
                Expanded(child: _buildGridImage(context, images, 1)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridImage(context, images, 2)),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildGridImage(context, images, 3),
                      if (remainingCount > 0)
                        GestureDetector(
                          onTap: () => _showImageGallery(context, images, 3),
                          child: Container(
                            color: Colors.black.withOpacity(0.6),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildGridImage(BuildContext context, List<String> images, int index) {
    return GestureDetector(
      onTap: () => _showImageGallery(context, images, index),
      child: Image.network(
        images[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade800,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.broken_image, color: Colors.white54),
        ),
      ),
    );
  }

  TapDownDetails? _tapDownDetails;

  @override
  Widget build(BuildContext context) {
    // الرسائل المرسلة تظهر على اليمين، المستلمة على اليسار
    final isMe = widget.isComming;

    // إذا كانت الرسالة محذوفة
    if (widget.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: Border.all(color: Colors.grey.shade600, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'This message was deleted',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    var bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primaryContainer;

    // تمييز الرسالة الحالية في البحث
    if (widget.isHighlighted) {
      bubbleColor = Colors.amber.shade700;
    } else if (widget.isSearchMatch) {
      bubbleColor = isMe
          ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8);
    }

    final imageUrls = _getImageUrls();
    final hasImage = imageUrls.isNotEmpty;
    final hasMultipleImages = imageUrls.length > 1;
    final hasAudio = widget.audioUrl.trim().isNotEmpty;
    final hasText = widget.message.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTapDown: (details) => _tapDownDetails = details,
            onLongPress: (widget.onDelete != null || widget.onEdit != null) && !widget.isDeleted
                ? () {
                    if (_tapDownDetails != null) {
                      _showMessageOptions(context, _tapDownDetails!);
                    }
                  }
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: hasAudio ? 200 : 80,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: widget.isHighlighted
                    ? Border.all(color: Colors.amber.shade300, width: 3)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: widget.isHighlighted
                        ? Colors.amber.withOpacity(0.4)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: widget.isHighlighted ? 12 : 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصور - عرض مفرد أو شبكة
                    if (hasImage)
                      hasMultipleImages
                          ? _buildImageGrid(context, imageUrls)
                          : _buildSingleImage(context, imageUrls.first),

                    // الرسالة الصوتية
                    if (hasAudio)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // زر التشغيل/الإيقاف
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _playerState == PlayerState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // شريط التقدم والمدة
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // شريط الموجة الصوتية
                                  SizedBox(
                                    height: 32,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(20, (index) {
                                        final progress = _duration.inMilliseconds > 0
                                            ? _position.inMilliseconds /
                                                _duration.inMilliseconds
                                            : 0.0;
                                        final isActive = index / 20 <= progress;
                                        final baseHeight = index % 3 == 0
                                            ? 0.8
                                            : index % 2 == 0
                                                ? 0.5
                                                : 0.3;
                                        final waveHeight = 8 + 12 * baseHeight;

                                        return Container(
                                          width: 3,
                                          height: waveHeight,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // الوقت
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_position),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_duration),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // النص
                    if (hasText)
                      Padding(
                        padding: EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: hasImage || hasAudio ? 8 : 12,
                          bottom: 8,
                        ),
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),

                    // الوقت وحالة القراءة وأيقونة التعديل
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 14,
                        right: 14,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // أيقونة التعديل
                          if (widget.isEdited) ...[
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            widget.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              widget.status == "Read"
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 16,
                              color: widget.status == "Read"
                                  ? Colors.blue.shade300
                                  : Colors.white.withOpacity(0.6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// معرض عرض الصور مع التمرير
class _ImageGalleryViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'فشل تحميل الصورة',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              height: 80,
              color: Colors.black.withOpacity(0.8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          widget.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade800,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }
}
