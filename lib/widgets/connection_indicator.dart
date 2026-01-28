import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';

/// Connection status banner that shows at the top of the screen
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Obx(() {
      if (connectivity.isOnline.value) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.red.shade700,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'لا يوجد اتصال بالإنترنت'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Connection status indicator (small dot)
class ConnectionDot extends StatelessWidget {
  final double size;

  const ConnectionDot({super.key, this.size = 10});

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Obx(() {
      final isOnline = connectivity.isOnline.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOnline ? Colors.green : Colors.red,
          boxShadow: [
            BoxShadow(
              color: (isOnline ? Colors.green : Colors.red).withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    });
  }
}

/// User online status indicator
class UserStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeen;
  final double size;
  final bool showBorder;

  const UserStatusIndicator({
    super.key,
    required this.isOnline,
    this.lastSeen,
    this.size = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.green : Colors.grey,
        border: showBorder
            ? Border.all(
                color: isDark ? Colors.grey[900]! : Colors.white,
                width: 2,
              )
            : null,
        boxShadow: isOnline
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  String getStatusText() {
    if (isOnline) return 'متصل الآن'.tr;
    if (lastSeen == null) return 'غير متصل'.tr;

    final now = DateTime.now();
    final diff = now.difference(lastSeen!);

    if (diff.inMinutes < 1) return 'كان متصلاً منذ لحظات'.tr;
    if (diff.inMinutes < 60) return 'كان متصلاً منذ ${diff.inMinutes} دقيقة'.tr;
    if (diff.inHours < 24) return 'كان متصلاً منذ ${diff.inHours} ساعة'.tr;
    if (diff.inDays < 7) return 'كان متصلاً منذ ${diff.inDays} يوم'.tr;

    return 'غير متصل'.tr;
  }
}

/// Animated syncing indicator
class SyncingIndicator extends StatefulWidget {
  final bool isSyncing;
  final String? message;

  const SyncingIndicator({
    super.key,
    this.isSyncing = false,
    this.message,
  });

  @override
  State<SyncingIndicator> createState() => _SyncingIndicatorState();
}

class _SyncingIndicatorState extends State<SyncingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSyncing) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.sync,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Connection aware wrapper widget
class ConnectionAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final bool showBanner;

  const ConnectionAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    final connectivity = Get.find<ConnectivityService>();

    return Obx(() {
      final isOnline = connectivity.isOnline.value;

      return Column(
        children: [
          if (showBanner) const ConnectionBanner(),
          Expanded(
            child: isOnline ? child : (offlineWidget ?? child),
          ),
        ],
      );
    });
  }
}

/// Retry button for failed operations
class RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  final bool isLoading;

  const RetryButton({
    super.key,
    required this.onRetry,
    this.message,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'فشل في تحميل البيانات'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onRetry,
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(isLoading ? 'جاري المحاولة...'.tr : 'إعادة المحاولة'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
