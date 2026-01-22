import 'package:flutter/material.dart';
import 'package:wissal_app/model/message_sync_status.dart';

class MessageStatusIndicator extends StatelessWidget {
  final MessageSyncStatus? status;
  final Color? color;
  final double size;
  final VoidCallback? onRetry;

  const MessageStatusIndicator({
    super.key,
    this.status,
    this.color,
    this.size = 16,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white.withOpacity(0.7);

    switch (status) {
      case MessageSyncStatus.pending:
        return Icon(
          Icons.schedule,
          size: size,
          color: effectiveColor,
        );

      case MessageSyncStatus.uploading:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        );

      case MessageSyncStatus.sent:
        return Icon(
          Icons.done,
          size: size,
          color: effectiveColor,
        );

      case MessageSyncStatus.delivered:
        return Icon(
          Icons.done_all,
          size: size,
          color: effectiveColor,
        );

      case MessageSyncStatus.read:
        return Icon(
          Icons.done_all,
          size: size,
          color: Colors.blue.shade300,
        );

      case MessageSyncStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: size,
              color: Colors.red,
            ),
          ),
        );

      default:
        return Icon(
          Icons.done,
          size: size,
          color: effectiveColor,
        );
    }
  }
}

/// Extended indicator with text description
class MessageStatusIndicatorWithText extends StatelessWidget {
  final MessageSyncStatus? status;
  final VoidCallback? onRetry;

  const MessageStatusIndicatorWithText({
    super.key,
    this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MessageStatusIndicator(
          status: status,
          size: 14,
          onRetry: onRetry,
        ),
        const SizedBox(width: 4),
        Text(
          _getStatusText(status),
          style: TextStyle(
            fontSize: 10,
            color: status == MessageSyncStatus.failed
                ? Colors.red
                : Colors.grey.shade600,
          ),
        ),
        if (status == MessageSyncStatus.failed && onRetry != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText(MessageSyncStatus? status) {
    switch (status) {
      case MessageSyncStatus.pending:
        return 'Sending...';
      case MessageSyncStatus.uploading:
        return 'Uploading...';
      case MessageSyncStatus.sent:
        return 'Sent';
      case MessageSyncStatus.delivered:
        return 'Delivered';
      case MessageSyncStatus.read:
        return 'Read';
      case MessageSyncStatus.failed:
        return 'Failed';
      default:
        return 'Sent';
    }
  }
}
