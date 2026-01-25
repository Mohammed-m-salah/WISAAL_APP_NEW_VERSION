import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math' as math;

/// واجهة معاينة الرسالة الصوتية قبل الإرسال
class VoiceMessagePreview extends StatefulWidget {
  final String audioPath;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final Duration? recordingDuration;

  const VoiceMessagePreview({
    super.key,
    required this.audioPath,
    required this.onSend,
    required this.onCancel,
    this.recordingDuration,
  });

  @override
  State<VoiceMessagePreview> createState() => _VoiceMessagePreviewState();
}

class _VoiceMessagePreviewState extends State<VoiceMessagePreview>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = true;

  late AnimationController _waveController;
  late StreamSubscription _stateSub;
  late StreamSubscription _positionSub;
  late StreamSubscription _durationSub;

  // موجات عشوائية للتصميم
  late List<double> _waveHeights;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _waveHeights = List.generate(30, (i) => 0.3 + math.Random().nextDouble() * 0.7);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // تحميل الملف الصوتي
      await _audioPlayer.setSourceDeviceFile(widget.audioPath);

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
          setState(() {
            _duration = dur;
            _isLoading = false;
          });
        }
      });

      // محاولة الحصول على المدة
      final duration = await _audioPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _isLoading = false;
        });
      } else if (widget.recordingDuration != null && mounted) {
        setState(() {
          _duration = widget.recordingDuration!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ خطأ في تحميل الصوت: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _stateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معاينة الرسالة الصوتية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // زر الإغلاق
              IconButton(
                onPressed: widget.onCancel,
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // مشغل الصوت
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // زر التشغيل/الإيقاف
                GestureDetector(
                  onTap: _isLoading ? null : _togglePlayPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPlaying
                            ? [Colors.red, Colors.red.shade700]
                            : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPlaying ? Colors.red : theme.colorScheme.primary)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // موجات الصوت والوقت
                Expanded(
                  child: Column(
                    children: [
                      // موجات الصوت
                      SizedBox(
                        height: 40,
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(_waveHeights.length, (i) {
                                final isActive = i / _waveHeights.length <= progress;
                                final animatedHeight = isPlaying
                                    ? _waveHeights[i] * (0.5 + 0.5 * math.sin(_waveController.value * math.pi * 2 + i * 0.3))
                                    : _waveHeights[i];

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: 3,
                                  height: 10 + 25 * animatedHeight,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.primary.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // شريط التقدم
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                          minHeight: 4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // الوقت
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontFeatures: const [FontFeature.tabularFigures()],
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

          const SizedBox(height: 20),

          // أزرار الإرسال والإلغاء
          Row(
            children: [
              // زر الإلغاء
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _audioPlayer.stop();
                    widget.onCancel();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('إلغاء'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // زر الإرسال
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _audioPlayer.stop();
                    widget.onSend();
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('إرسال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// مؤشر التسجيل المحسن
class RecordingIndicator extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onCancel;

  const RecordingIndicator({
    super.key,
    required this.duration,
    this.onCancel,
  });

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // أيقونة التسجيل النابضة
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.5 + 0.5 * _pulseController.value),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3 * _pulseController.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // مدة التسجيل
          Text(
            _formatDuration(widget.duration),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          // نص "جاري التسجيل"
          Text(
            'جاري التسجيل...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
          ),
          if (widget.onCancel != null) ...[
            const SizedBox(width: 16),
            // زر الإلغاء
            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
