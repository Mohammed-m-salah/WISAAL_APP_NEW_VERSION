import 'package:flutter/material.dart';

class NewContactTile extends StatelessWidget {
  final String btnname;
  final IconData icon;
  final VoidCallback ontap;
  const NewContactTile({
    Key? key,
    required this.btnname,
    required this.icon,
    required this.ontap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [],
        ),
        child: InkWell(
          onTap: ontap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                btnname,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
