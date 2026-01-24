import 'package:flutter/material.dart';
import 'package:wissal_app/controller/reactions_controller/reactions_controller.dart';

/// شريط اختيار التفاعلات
class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final String? currentReaction;
  final VoidCallback? onRemoveReaction;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.currentReaction,
    this.onRemoveReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...ReactionEmoji.all.map((emoji) => _buildReactionButton(
                context,
                emoji,
                isSelected: currentReaction == emoji,
              )),
          if (currentReaction != null && onRemoveReaction != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(width: 4),
            _buildRemoveButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, String emoji, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () => onReactionSelected(emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: isSelected ? 28 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return GestureDetector(
      onTap: onRemoveReaction,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.close,
          size: 20,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

/// عرض التفاعلات تحت الرسالة
class ReactionsDisplay extends StatelessWidget {
  final List<String>? reactions;
  final VoidCallback? onTap;
  final bool isMe;

  const ReactionsDisplay({
    super.key,
    this.reactions,
    this.onTap,
    this.isMe = true,
  });

  @override
  Widget build(BuildContext context) {
    final reactionCounts = ReactionsController.parseReactions(reactions);
    if (reactionCounts.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reactionCounts.entries.take(3).map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 14),
                    ),
                  )),
              if (reactions!.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    '${reactions!.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نافذة تفاصيل التفاعلات
class ReactionsDetailSheet extends StatelessWidget {
  final List<String>? reactions;
  final Map<String, String> userNames; // userId -> userName

  const ReactionsDetailSheet({
    super.key,
    this.reactions,
    this.userNames = const {},
  });

  @override
  Widget build(BuildContext context) {
    final reactionCounts = ReactionsController.parseReactions(reactions);
    if (reactionCounts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'reactions'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // إجمالي التفاعلات
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: reactionCounts.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // قائمة المستخدمين
          if (reactions != null)
            ...reactions!.map((reaction) {
              final parts = reaction.split(':');
              final emoji = parts.isNotEmpty ? parts[0] : '';
              final odId = parts.length > 1 ? parts[1] : '';
              final userName = userNames[odId] ?? 'User';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U'),
                ),
                title: Text(userName),
                trailing: Text(emoji, style: const TextStyle(fontSize: 24)),
              );
            }),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String get tr => this; // Placeholder for GetX translation
}
