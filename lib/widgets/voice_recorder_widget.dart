import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

/// واجهة التسجيل الصوتي مع السحب للإلغاء
class VoiceRecorderOverlay extends StatefulWidget {
  final bool isRecording;
  final Duration duration;
  final double dragOffset;
  final bool isLocked;
  final VoidCallback onCancel;
  final VoidCallback onLock;
  final VoidCallback onSend;
  final Function(double) onDragUpdate;

  const VoiceRecorderOverlay({
    super.key,
    required this.isRecording,
    required this.duration,
    required this.dragOffset,
    required this.isLocked,
    required this.onCancel,
    required this.onLock,
    required this.onSend,
    required this.onDragUpdate,
  });

  @override
  State<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends State<VoiceRecorderOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _trashAnimController;
  late AnimationController _absorpController;
  late Animation<double> _trashScaleAnim;
  late Animation<double> _trashShakeAnim;
  late Animation<double> _absorpAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _trashAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _absorpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _trashScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trashAnimController, curve: Curves.elasticOut),
    );

    _trashShakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _trashAnimController, curve: Curves.easeInOut),
    );

    _absorpAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _absorpController, curve: Curves.easeIn),
    );
  }

  @override
  void didUpdateWidget(VoiceRecorderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    final screenWidth = MediaQuery.of(context).size.width;
    final cancelThreshold = screenWidth * 0.35;
    final isDragging = widget.dragOffset < -20;
    final isCancelling = widget.dragOffset < -cancelThreshold;

    // Show trash when dragging starts
    if (isDragging && !_trashAnimController.isAnimating && _trashAnimController.value == 0) {
      _trashAnimController.forward();
    } else if (!isDragging && _trashAnimController.value == 1) {
      _trashAnimController.reverse();
    }

    // Trigger absorb animation when cancelling
    if (isCancelling && !_absorpController.isAnimating && _absorpController.value == 0) {
      _absorpController.forward();
    } else if (!isCancelling && _absorpController.value > 0) {
      _absorpController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _trashAnimController.dispose();
    _absorpController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cancelThreshold = screenWidth * 0.35;
    final isCancelling = widget.dragOffset < -cancelThreshold;
    final dragProgress = (widget.dragOffset.abs() / cancelThreshold).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCancelling
            ? Colors.red.shade50
            : Color.lerp(theme.scaffoldBackgroundColor, Colors.red.shade50, dragProgress * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: widget.isLocked ? _buildLockedUI(theme) : _buildRecordingUI(theme, isCancelling, dragProgress),
      ),
    );
  }

  Widget _buildRecordingUI(ThemeData theme, bool isCancelling, double dragProgress) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // الحاوية المتحركة للإلغاء (سلة المهملات)
        Positioned(
          left: 0,
          child: AnimatedBuilder(
            animation: Listenable.merge([_trashAnimController, _absorpController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _trashScaleAnim.value * (1.0 + (isCancelling ? 0.2 : 0.0)),
                child: Transform.rotate(
                  angle: isCancelling
                      ? math.sin(_animController.value * math.pi * 4) * 0.1
                      : 0,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isCancelling
                          ? Colors.red.shade400
                          : Colors.red.shade100,
                      shape: BoxShape.circle,
                      boxShadow: isCancelling ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // أيقونة السلة
                        Icon(
                          isCancelling ? Icons.delete : Icons.delete_outline,
                          color: isCancelling ? Colors.white : Colors.red.shade400,
                          size: isCancelling ? 28 : 24,
                        ),
                        // تأثير الامتصاص
                        if (isCancelling)
                          ...List.generate(3, (index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + index * 100),
                              builder: (context, value, _) {
                                return Transform.scale(
                                  scale: 1.0 + value * 0.5,
                                  child: Opacity(
                                    opacity: (1.0 - value) * 0.5,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.red.shade300,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // المحتوى الرئيسي
        Row(
          children: [
            // مساحة للسلة
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.dragOffset < -20 ? 70 : 0,
            ),

            // أيقونة الميكروفون المتحركة
            AnimatedBuilder(
              animation: _absorpController,
              builder: (context, _) {
                final micOffset = isCancelling ? -30 * _absorpAnim.value : 0.0;
                final micScale = isCancelling ? 0.5 + 0.5 * _absorpAnim.value : 1.0;
                final micOpacity = isCancelling ? _absorpAnim.value : 1.0;

                return Transform.translate(
                  offset: Offset(widget.dragOffset + micOffset, 0),
                  child: Transform.scale(
                    scale: micScale,
                    child: Opacity(
                      opacity: micOpacity,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCancelling ? Colors.grey.shade300 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // مؤشر التسجيل
                            AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                return Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isCancelling
                                        ? Colors.grey
                                        : Colors.red.withOpacity(0.5 + 0.5 * _animController.value),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // الوقت
                            Text(
                              _formatDuration(widget.duration),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCancelling ? Colors.grey : Colors.red.shade700,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // نص السحب للإلغاء
            AnimatedOpacity(
              opacity: isCancelling ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أسهم متحركة
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          final delay = index * 0.2;
                          final opacity = (((_animController.value + delay) % 1.0) * 2)
                              .clamp(0.0, 1.0);
                          return Opacity(
                            opacity: 1.0 - opacity,
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  Text(
                    'اسحب للإلغاء',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        // رسالة الإلغاء
        if (isCancelling)
          Positioned(
            right: 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'إفلات للإلغاء',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLockedUI(ThemeData theme) {
    return Row(
      children: [
        // زر الحذف
        IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
          style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
        ),

        const SizedBox(width: 8),

        // مؤشر التسجيل
        AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5 + 0.5 * _animController.value),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // الوقت
        Text(
          _formatDuration(widget.duration),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),

        const Spacer(),

        // زر الإرسال
        GestureDetector(
          onTap: widget.onSend,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

/// زر التسجيل مع دعم السحب
class VoiceRecordButton extends StatefulWidget {
  final bool isRecording;
  final Function() onStartRecording;
  final Function(bool cancelled) onStopRecording;
  final Function() onLockRecording;
  final Function(double) onDragUpdate;
  final Widget child;

  const VoiceRecordButton({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onLockRecording,
    required this.onDragUpdate,
    required this.child,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  Offset _startPosition = Offset.zero;
  double _dragOffsetX = 0;
  double _dragOffsetY = 0;
  bool _isLocked = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cancelThreshold = screenWidth * 0.35;

    return GestureDetector(
      onLongPressStart: (details) {
        _startPosition = details.globalPosition;
        _dragOffsetX = 0;
        _dragOffsetY = 0;
        _isLocked = false;
        HapticFeedback.mediumImpact();
        widget.onStartRecording();
      },
      onLongPressMoveUpdate: (details) {
        if (_isLocked) return;

        final dx = details.globalPosition.dx - _startPosition.dx;
        final dy = details.globalPosition.dy - _startPosition.dy;

        _dragOffsetX = dx.clamp(-cancelThreshold * 1.2, 0);
        _dragOffsetY = dy.clamp(-80.0, 0.0);

        widget.onDragUpdate(_dragOffsetX);

        // قفل التسجيل عند السحب للأعلى
        if (_dragOffsetY < -60 && !_isLocked) {
          _isLocked = true;
          HapticFeedback.heavyImpact();
          widget.onLockRecording();
        }
      },
      onLongPressEnd: (details) {
        if (_isLocked) return;

        final isCancelled = _dragOffsetX < -cancelThreshold;
        if (isCancelled) {
          HapticFeedback.lightImpact();
        }

        widget.onStopRecording(isCancelled);
        widget.onDragUpdate(0);
        _dragOffsetX = 0;
        _dragOffsetY = 0;
      },
      child: widget.child,
    );
  }
}

/// معاينة الصوت المسجل
class QuickVoicePreview extends StatefulWidget {
  final String audioPath;
  final Duration duration;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const QuickVoicePreview({
    super.key,
    required this.audioPath,
    required this.duration,
    required this.onSend,
    required this.onCancel,
  });

  @override
  State<QuickVoicePreview> createState() => _QuickVoicePreviewState();
}

class _QuickVoicePreviewState extends State<QuickVoicePreview> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _posSub = _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.audioPath));
    }
  }

  String _formatDuration(Duration d) {
    return '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.duration.inMilliseconds > 0
        ? _position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // زر الحذف
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            iconSize: 22,
          ),

          // زر التشغيل
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // شريط التقدم والوقت
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text(_formatDuration(widget.duration), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // زر الإرسال
          GestureDetector(
            onTap: () {
              _player.stop();
              widget.onSend();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
