import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wissal_app/services/connectivity/connectivity_service.dart';
import 'package:wissal_app/services/offline_queue/offline_queue_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();
    final offlineQueueService = Get.find<OfflineQueueService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;
      final pendingCount = offlineQueueService.pendingCount.value;
      final isProcessing = offlineQueueService.isProcessing.value;

      // Show nothing if online and no pending messages
      if (isOnline && pendingCount == 0 && !isProcessing) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOnline
              ? (isProcessing ? Colors.blue : Colors.amber.shade700)
              : Colors.red.shade700,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnline
                    ? (isProcessing ? Icons.sync : Icons.schedule)
                    : Icons.cloud_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getMessage(isOnline, pendingCount, isProcessing),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (isProcessing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _getMessage(bool isOnline, int pendingCount, bool isProcessing) {
    if (!isOnline) {
      if (pendingCount > 0) {
        final key = pendingCount > 1 ? 'no_connection_pending_plural' : 'no_connection_pending';
        return key.tr.replaceAll('@count', pendingCount.toString());
      }
      return 'no_internet'.tr;
    }

    if (isProcessing) {
      return 'sending_pending'.tr;
    }

    if (pendingCount > 0) {
      final key = pendingCount > 1 ? 'messages_waiting_plural' : 'messages_waiting';
      return key.tr.replaceAll('@count', pendingCount.toString());
    }

    return '';
  }
}

/// A smaller indicator for use in app bars or smaller spaces
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      final isOnline = connectivityService.isOnline.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'online'.tr : 'offline'.tr,
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }
}
