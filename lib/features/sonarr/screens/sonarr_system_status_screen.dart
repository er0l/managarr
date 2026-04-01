import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/sonarr_providers.dart';

class SonarrSystemStatusScreen extends ConsumerWidget {
  const SonarrSystemStatusScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('System Status',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      body: ListView(
        children: [
          _HealthSection(instance: instance),
          const Divider(height: 1),
          _DiskSpaceSection(instance: instance),
          const Divider(height: 1),
          _AboutSection(instance: instance),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Health Checks ─────────────────────────────────────────────────────────────

class _HealthSection extends ConsumerWidget {
  const _HealthSection({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(sonarrHealthProvider(instance));
    return _Section(
      title: 'Health Checks',
      trailing: IconButton(
        icon: const Icon(Icons.refresh, size: 20),
        onPressed: () => ref.invalidate(sonarrHealthProvider(instance)),
      ),
      child: healthAsync.when(
        loading: () => const _Loading(),
        error: (e, _) => _ErrorTile(message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const ListTile(
              leading: Icon(Icons.check_circle_outline,
                  color: AppColors.statusOnline),
              title: Text('No issues found'),
            );
          }
          return Column(
            children: items.map((item) => _HealthTile(item: item)).toList(),
          );
        },
      ),
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] as String? ?? 'ok').toLowerCase();
    final message = item['message'] as String? ?? '';
    final source = item['source'] as String? ?? '';

    final Color color;
    final IconData icon;
    switch (type) {
      case 'error':
        color = AppColors.statusOffline;
        icon = Icons.error_outline;
      case 'warning':
        color = AppColors.statusWarning;
        icon = Icons.warning_amber_outlined;
      case 'notice':
        color = AppColors.blueAccent;
        icon = Icons.info_outline;
      default:
        color = AppColors.statusOnline;
        icon = Icons.check_circle_outline;
    }

    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(message, style: const TextStyle(fontSize: 13)),
      subtitle: source.isNotEmpty
          ? Text(source,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary))
          : null,
      dense: true,
    );
  }
}

// ── Disk Space ────────────────────────────────────────────────────────────────

class _DiskSpaceSection extends ConsumerWidget {
  const _DiskSpaceSection({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diskAsync = ref.watch(sonarrDiskSpaceProvider(instance));
    return _Section(
      title: 'Disk Space',
      child: diskAsync.when(
        loading: () => const _Loading(),
        error: (e, _) => _ErrorTile(message: '$e'),
        data: (items) {
          if (items.isEmpty) {
            return const ListTile(title: Text('No disk info available'));
          }
          return Column(
            children: items.map((d) => _DiskTile(disk: d)).toList(),
          );
        },
      ),
    );
  }
}

class _DiskTile extends StatelessWidget {
  const _DiskTile({required this.disk});
  final Map<String, dynamic> disk;

  String _fmt(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double val = bytes.toDouble();
    while (val >= 1024 && i < units.length - 1) {
      val /= 1024;
      i++;
    }
    return '${val.toStringAsFixed(1)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final path = disk['path'] as String? ?? '';
    final freeSpace = disk['freeSpace'] as int? ?? 0;
    final totalSpace = disk['totalSpace'] as int? ?? 0;
    final usedSpace = totalSpace - freeSpace;
    final pct = totalSpace > 0 ? usedSpace / totalSpace : 0.0;

    Color barColor = AppColors.statusOnline;
    if (pct > 0.9) {
      barColor = AppColors.statusOffline;
    } else if (pct > 0.75) {
      barColor = AppColors.statusWarning;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(path,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${_fmt(freeSpace)} free',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: barColor.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(usedSpace)} of ${_fmt(totalSpace)} used',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _AboutSection extends ConsumerWidget {
  const _AboutSection({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(sonarrSystemStatusProvider(instance));
    return _Section(
      title: 'About',
      child: statusAsync.when(
        loading: () => const _Loading(),
        error: (e, _) => _ErrorTile(message: '$e'),
        data: (status) => Column(
          children: [
            _InfoRow(label: 'Version', value: status.version),
            if (status.osVersion != null)
              _InfoRow(label: 'OS Version', value: status.osVersion!),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            color: AppColors.tealDark,
                            fontWeight: FontWeight.bold)),
              ),
              ?trailing,
            ],
          ),
        ),
        child,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      ListTile(
        leading: const Icon(Icons.error_outline, color: AppColors.statusOffline),
        title: Text(message,
            style: const TextStyle(color: AppColors.statusOffline, fontSize: 13)),
      );
}
