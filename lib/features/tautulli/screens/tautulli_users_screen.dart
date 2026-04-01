import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';
import 'tautulli_user_detail_screen.dart';

class TautulliUsersScreen extends ConsumerWidget {
  const TautulliUsersScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tautulliUsersProvider(instance));

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (users) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tautulliUsersProvider(instance)),
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final lastSeenStr = user.lastSeenAt != null
                  ? 'Last seen: ${DateFormat.yMMMd().format(user.lastSeenAt!)}'
                  : 'Never seen';

              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TautulliUserDetailScreen(
                      instance: instance,
                      userId: user.userId,
                      displayName: user.friendlyName ?? user.username,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.orangeAccent.withAlpha(30),
                  child: const Icon(Icons.person_outline, color: AppColors.orangeAccent, size: 20),
                ),
                title: Text(
                  user.friendlyName ?? user.username,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  lastSeenStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
              );
            },
          ),
        );
      },
    );
  }
}
