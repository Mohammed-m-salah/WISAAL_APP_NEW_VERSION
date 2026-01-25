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
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCancelling ? Colors.red.shade50 : theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: widget.isLocked ? _buildLockedUI(theme) : _buildRecordingUI(theme, isCancelling),
      ),
    );
  }

  Widget _buildRecordingUI(ThemeData theme, bool isCancelling) {
    return Row(
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
        const SizedBox(width: 12),

        // الوقت
        Text(
          _formatDuration(widget.duration),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCancelling ? Colors.grey : Colors.red.shade700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        const Spacer(),

        // نص السحب للإلغاء أو أيقونة الإلغاء
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isCancelling
              ? Row(
                  key: const ValueKey('cancel'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red.shade400, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('slide'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, color: Colors.grey.shade500, size: 20),
                    Text(
                      'اسحب للإلغاء',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
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
