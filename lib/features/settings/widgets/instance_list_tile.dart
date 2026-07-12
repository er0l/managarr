import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_avatar.dart';
import '../../../core/widgets/status_dot.dart';
import '../../dashboard/providers/health_check_provider.dart';

class InstanceListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ServiceAvatar(type: type, size: 40),
      title: Text(instance.name, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        instance.baseUrl,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (instance.enabled)
            StatusDot(
              healthAsync: ref.watch(healthCheckProvider(instance)),
            )
          else ...[
            const DisabledDot(),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.statusUnknown.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'disabled',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
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
