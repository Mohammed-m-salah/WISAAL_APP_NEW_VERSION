import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wissal_app/config/colors.dart';
import 'package:wissal_app/model/message_sync_status.dart';
import 'package:wissal_app/widgets/message_status_indicator.dart';
import 'package:wissal_app/widgets/reaction_picker.dart';
import 'package:wissal_app/widgets/glass_snackbar.dart';
import 'package:wissal_app/controller/reactions_controller/reactions_controller.dart';

class ChatBubbel extends StatefulWidget {
  final String message;
  final bool isComming;
  final Color iscolor;
  final String time;
  final String status;
  final String imgUrl;
  final List<String>? imageUrls;
  final String audioUrl;
  final String senderName;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final VoidCallback? onForward;
  final VoidCallback? onSave;
  final bool isPinned;
  final bool isDeleted;
  final bool isEdited;
  final bool isHighlighted;
  final bool isSearchMatch;
  final bool isPinnedHighlight;
  final bool isForwarded;
  final String? forwardedFrom;
  final MessageSyncStatus? syncStatus;
  final VoidCallback? onRetry;
  final List<String>? reactions;
  final Function(String emoji)? onReact;
  final String? currentUserId;
  final String? deletedBy;
  final String? deletedByName;
  final String? searchQuery;

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
    this.onPin,
    this.onUnpin,
    this.onForward,
    this.onSave,
    this.isPinned = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.isHighlighted = false,
    this.isSearchMatch = false,
    this.isPinnedHighlight = false,
    this.isForwarded = false,
    this.forwardedFrom,
    this.syncStatus,
    this.onRetry,
    this.reactions,
    this.onReact,
    this.currentUserId,
    this.deletedBy,
    this.deletedByName,
    this.searchQuery,
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

  // Reaction picker state
  bool _showReactionPicker = false;
  OverlayEntry? _reactionOverlay;

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
    // Remove overlay safely without setState
    _reactionOverlay?.remove();
    _reactionOverlay = null;
    super.dispose();
  }

  void _showReactionPickerOverlay(BuildContext context, Offset position) {
    if (!mounted) return;
    if (widget.onReact == null || widget.isDeleted) return;

    _hideReactionPicker();

    final isMe = widget.isComming;
    final screenWidth = MediaQuery.of(context).size.width;
    final currentReaction = ReactionsController.getCurrentUserReaction(
      widget.reactions,
      widget.currentUserId,
    );

    // Calculate position to show above the tap point, centered
    final pickerWidth = 320.0; // Approximate width of reaction picker
    double leftPosition = position.dx - (pickerWidth / 2);

    // Make sure it doesn't go off screen
    if (leftPosition < 8) leftPosition = 8;
    if (leftPosition + pickerWidth > screenWidth - 8) {
      leftPosition = screenWidth - pickerWidth - 8;
    }

    _reactionOverlay = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          // خلفية شفافة للإغلاق عند الضغط
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideReactionPicker,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          // شريط التفاعلات - يظهر فوق الرسالة
          Positioned(
            left: leftPosition,
            top: position.dy - 70,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 200),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.easeOut,
              builder: (animContext, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                child: ReactionPicker(
                  currentReaction: currentReaction,
                  onReactionSelected: (emoji) {
                    widget.onReact?.call(emoji);
                    _hideReactionPicker();
                  },
                  onRemoveReaction: currentReaction != null
                      ? () {
                          widget.onReact?.call('');
                          _hideReactionPicker();
                        }
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_reactionOverlay!);
      setState(() => _showReactionPicker = true);
    }
  }

  void _hideReactionPicker() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
    if (mounted) {
      setState(() => _showReactionPicker = false);
    }
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
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
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
        // React option
        if (widget.onReact != null)
          PopupMenuItem<String>(
            value: 'react',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('❤️', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                const Text('React',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (widget.isPinned && widget.onUnpin != null)
          PopupMenuItem<String>(
            value: 'unpin',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.push_pin, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Unpin',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.orange)),
              ],
            ),
          )
        else if (widget.onPin != null)
          PopupMenuItem<String>(
            value: 'pin',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.push_pin_outlined,
                      color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Pin',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (widget.onForward != null)
          PopupMenuItem<String>(
            value: 'forward',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.shortcut, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Forward',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (widget.onSave != null)
          PopupMenuItem<String>(
            value: 'save',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bookmark_add_outlined,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        // Copy option
        if (widget.message.trim().isNotEmpty)
          PopupMenuItem<String>(
            value: 'copy',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Copy',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
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
                  child: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Edit',
                    style: TextStyle(fontWeight: FontWeight.w500)),
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
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Delete',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.red)),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'react') {
        // Show reaction picker
        if (_tapDownDetails != null) {
          _showReactionPickerOverlay(context, _tapDownDetails!.globalPosition);
        }
      } else if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.message));
        GlassSnackbar.copied();
      } else if (value == 'pin') {
        widget.onPin?.call();
      } else if (value == 'unpin') {
        widget.onUnpin?.call();
      } else if (value == 'forward') {
        widget.onForward?.call();
      } else if (value == 'save') {
        widget.onSave?.call();
      } else if (value == 'edit') {
        widget.onEdit?.call();
      } else if (value == 'delete') {
        widget.onDelete?.call();
      }
    });
  }

  List<String> _getImageUrls() {
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      return widget.imageUrls!
          .where((url) => url.isNotEmpty && _isValidImageUrl(url))
          .toList();
    }
    if (widget.imgUrl.trim().isEmpty) return [];
    if (!_isValidImageUrl(widget.imgUrl)) return [];
    if (widget.imgUrl.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(widget.imgUrl);
        if (decoded is List) {
          return List<String>.from(decoded.where((e) =>
              e != null &&
              e.toString().isNotEmpty &&
              _isValidImageUrl(e.toString())));
        }
      } catch (_) {}
    }
    return [widget.imgUrl];
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
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

  void _showImageGallery(
      BuildContext context, List<String> images, int initialIndex) {
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

  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: double.infinity,
              height: 220,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                      size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
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

  Widget _buildGridLayout(BuildContext context, List<String> images,
      int displayCount, int remainingCount) {
    if (displayCount == 2) {
      return Row(
        children: [
          Expanded(child: _buildGridImage(context, images, 0)),
          const SizedBox(width: 2),
          Expanded(child: _buildGridImage(context, images, 1)),
        ],
      );
    } else if (displayCount == 3) {
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
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildMessageText(Color textColor) {
    final query = widget.searchQuery;
    final message = widget.message;

    // If no search query or not a match, return simple text
    if (query == null || query.isEmpty || !widget.isSearchMatch) {
      return Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    // Build highlighted text
    final lowerText = message.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: message.substring(start, index),
          style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: message.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.8),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 15,
          height: 1.4,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < message.length) {
      spans.add(TextSpan(
        text: message.substring(start),
        style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  TapDownDetails? _tapDownDetails;

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isComming;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isDeleted) {
      // Check if deleted by admin
      final deletedByAdmin = widget.deletedBy != null && widget.deletedBy!.isNotEmpty;
      final deleteMessage = deletedByAdmin
          ? 'تم الحذف من قبل المشرف ${widget.deletedByName ?? ''}'
          : 'تم حذف هذه الرسالة';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: deletedByAdmin
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                border: Border.all(
                    color: deletedByAdmin
                        ? Colors.red.withOpacity(0.3)
                        : Theme.of(context).dividerColor,
                    width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    deletedByAdmin ? Icons.admin_panel_settings : Icons.block,
                    size: 16,
                    color: deletedByAdmin
                        ? Colors.red.withOpacity(0.7)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      deleteMessage,
                      style: TextStyle(
                        color: deletedByAdmin
                            ? Colors.red.withOpacity(0.7)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Bubble colors - different colors for sent vs received
    var bubbleColor = isMe
        ? (isDark ? dSentBubbleColor : lSentBubbleColor)
        : (isDark ? dReceivedBubbleColor : lReceivedBubbleColor);

    // Search highlight
    if (widget.isHighlighted) {
      bubbleColor = Colors.amber.shade700;
    } else if (widget.isSearchMatch) {
      bubbleColor = isMe
          ? (isDark ? dSentBubbleColor : lSentBubbleColor).withOpacity(0.8)
          : (isDark ? dReceivedBubbleColor : lReceivedBubbleColor)
              .withOpacity(0.8);
    }

    final imageUrls = _getImageUrls();
    final hasImage = imageUrls.isNotEmpty;
    final hasMultipleImages = imageUrls.length > 1;
    final hasAudio = widget.audioUrl.trim().isNotEmpty;
    final hasText = widget.message.trim().isNotEmpty;
    final hasReactions =
        widget.reactions != null && widget.reactions!.isNotEmpty;

    // Text color based on bubble
    final textColor =
        isMe ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final secondaryTextColor = isMe
        ? Colors.white.withOpacity(0.7)
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTapDown: (details) => _tapDownDetails = details,
            onDoubleTapDown: (details) => _tapDownDetails = details,
            onDoubleTap: widget.onReact != null && !widget.isDeleted
                ? () {
                    if (_tapDownDetails != null) {
                      _showReactionPickerOverlay(
                        context,
                        _tapDownDetails!.globalPosition,
                      );
                    }
                  }
                : null,
            onLongPress: (widget.onDelete != null ||
                        widget.onEdit != null ||
                        widget.onPin != null ||
                        widget.onUnpin != null ||
                        widget.onForward != null ||
                        widget.onSave != null) &&
                    !widget.isDeleted
                ? () {
                    if (_tapDownDetails != null) {
                      _showMessageOptions(context, _tapDownDetails!);
                    }
                  }
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (widget.isPinnedHighlight)
                  Positioned(
                    top: -8,
                    right: isMe ? null : -8,
                    left: isMe ? -8 : null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.push_pin,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                Container(
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
                    border: widget.isHighlighted || widget.isPinnedHighlight
                        ? Border.all(
                            color: widget.isPinnedHighlight
                                ? Colors.amber
                                : Colors.amber.shade300,
                            width: widget.isPinnedHighlight ? 2.5 : 3,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: widget.isHighlighted || widget.isPinnedHighlight
                            ? Colors.amber.withOpacity(
                                widget.isPinnedHighlight ? 0.6 : 0.4)
                            : Colors.black.withOpacity(0.08),
                        blurRadius:
                            widget.isHighlighted || widget.isPinnedHighlight
                                ? 12
                                : 8,
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
                        // Forwarded indicator
                        if (widget.isForwarded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isMe
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface)
                                  .withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shortcut,
                                  size: 14,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Forwarded${widget.forwardedFrom != null ? ' from ${widget.forwardedFrom}' : ''}',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasImage)
                          hasMultipleImages
                              ? _buildImageGrid(context, imageUrls)
                              : _buildSingleImage(context, imageUrls.first),

                        if (hasAudio)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (isMe
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .primary)
                                          .withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _playerState == PlayerState.playing
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: textColor,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 32,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: List.generate(20, (index) {
                                            final progress =
                                                _duration.inMilliseconds > 0
                                                    ? _position.inMilliseconds /
                                                        _duration.inMilliseconds
                                                    : 0.0;
                                            final isActive =
                                                index / 20 <= progress;
                                            final baseHeight = index % 3 == 0
                                                ? 0.8
                                                : index % 2 == 0
                                                    ? 0.5
                                                    : 0.3;
                                            final waveHeight =
                                                8 + 12 * baseHeight;

                                            return Container(
                                              width: 3,
                                              height: waveHeight,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? textColor
                                                    : textColor
                                                        .withOpacity(0.4),
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(_position),
                                            style: TextStyle(
                                              color: secondaryTextColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(_duration),
                                            style: TextStyle(
                                              color: secondaryTextColor,
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

                        if (hasText)
                          Padding(
                            padding: EdgeInsets.only(
                              left: 14,
                              right: 14,
                              top: hasImage || hasAudio ? 8 : 12,
                              bottom: 8,
                            ),
                            child: _buildMessageText(textColor),
                          ),

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
                              if (widget.isEdited) ...[
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                widget.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                MessageStatusIndicator(
                                  status: widget.syncStatus,
                                  readStatus: widget.status,
                                  size: 16,
                                  onRetry: widget.syncStatus ==
                                          MessageSyncStatus.failed
                                      ? widget.onRetry
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasReactions)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 12,
                  right: isMe ? 12 : 0,
                ),
                child: ReactionsDisplay(
                  reactions: widget.reactions,
                  isMe: isMe,
                  onTap: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
                      'Failed to load image',
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
