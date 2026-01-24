// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatTile extends StatelessWidget {
  final String imgUrl;
  final String name;
  final String lastChat;
  final String lastTime;
  final bool isPinned;
  final bool isArchived;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const ChatTile({
    Key? key,
    required this.imgUrl,
    required this.name,
    required this.lastChat,
    required this.lastTime,
    this.isPinned = false,
    this.isArchived = false,
    this.onPin,
    this.onUnpin,
    this.onDelete,
    this.onArchive,
    this.onUnarchive,
  }) : super(key: key);

  void _showOptionsMenu(BuildContext context) {
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
            // Pin/Unpin option
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: isPinned ? Colors.grey : Colors.amber,
              ),
              title: Text(isPinned ? 'unpin_message'.tr : 'pin_message'.tr),
              onTap: () {
                Navigator.pop(context);
                if (isPinned) {
                  onUnpin?.call();
                } else {
                  onPin?.call();
                }
              },
            ),
            // Archive option
            ListTile(
              leading: Icon(
                isArchived ? Icons.unarchive : Icons.archive,
                color: Colors.blue,
              ),
              title: Text(isArchived ? 'unarchive'.tr : 'archive'.tr),
              onTap: () {
                Navigator.pop(context);
                if (isArchived) {
                  onUnarchive?.call();
                } else {
                  onArchive?.call();
                }
              },
            ),
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('delete_chat'.tr, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_chat'.tr),
        content: Text('delete_chat_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showOptionsMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: isPinned
                ? Border.all(color: Colors.amber.shade300, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imgUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  lastChat,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastTime,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (isPinned) ...[
                      const SizedBox(height: 4),
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
