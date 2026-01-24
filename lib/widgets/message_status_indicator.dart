import 'package:flutter/material.dart';
import 'package:wissal_app/model/message_sync_status.dart';

// الألوان الثابتة لحالات الرسالة
const Color _silverColor = Color(0xFFB0B0B0); // فضي للـ sent و delivered
const Color _readColor = Color(0xFF1565C0); // أزرق غامق للقراءة

class MessageStatusIndicator extends StatelessWidget {
  final MessageSyncStatus? status;
  final String? readStatus; // لدعم النص القديم "Read" / "Delivered"
  final Color? color;
  final double size;
  final VoidCallback? onRetry;

  const MessageStatusIndicator({
    super.key,
    this.status,
    this.readStatus,
    this.color,
    this.size = 16,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد الحالة النهائية
    MessageSyncStatus? effectiveStatus = status;

    // إذا لم يكن هناك syncStatus، نستخدم readStatus
    if (effectiveStatus == null || effectiveStatus == MessageSyncStatus.sent) {
      if (readStatus == 'Read') {
        effectiveStatus = MessageSyncStatus.read;
      } else if (readStatus == 'Delivered') {
        effectiveStatus = MessageSyncStatus.delivered;
      }
    }

    final defaultColor = color ?? _silverColor;

    switch (effectiveStatus) {
      case MessageSyncStatus.pending:
        // ساعة رمادية - قيد الإرسال (بدون نت)
        return Icon(
          Icons.schedule_rounded,
          size: size,
          color: defaultColor,
        );

      case MessageSyncStatus.uploading:
        // دائرة تحميل - جاري رفع الوسائط
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(defaultColor),
          ),
        );

      case MessageSyncStatus.sent:
        // ✓ صح واحد فضي - تم الإرسال للسيرفر
        return Icon(
          Icons.done_rounded,
          size: size,
          color: _silverColor,
        );

      case MessageSyncStatus.delivered:
        // ✓✓ صحين فضي - تم التوصيل للمستلم
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: _silverColor,
        );

      case MessageSyncStatus.read:
        // ✓✓ صحين أزرق غامق - تمت القراءة
        return Icon(
          Icons.done_all_rounded,
          size: size,
          color: _readColor,
        );

      case MessageSyncStatus.failed:
        // أيقونة خطأ حمراء - فشل الإرسال
        return GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: size,
              color: Colors.red,
            ),
          ),
        );

      default:
        return Icon(
          Icons.done_rounded,
          size: size,
          color: _silverColor,
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
