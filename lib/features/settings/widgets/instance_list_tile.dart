import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';

class InstanceListTile extends StatelessWidget {
  const InstanceListTile({
    super.key,
    required this.instance,
    required this.onTap,
    required this.onDelete,
  });

  final Instance instance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.tealPrimary.withAlpha(20),
        child: Text(
          type.displayName[0],
          style: const TextStyle(
            color: AppColors.tealPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(instance.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        instance.baseUrl,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!instance.enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusUnknown.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'disabled',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.statusOffline,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
