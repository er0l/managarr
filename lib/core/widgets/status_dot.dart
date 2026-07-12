import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/models/health_result.dart';
import '../theme/app_colors.dart';

/// Glowing status dot bound to a health-check result.
/// Shared by the dashboard status strip, drawer, and settings tiles.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.healthAsync, this.size = 8});

  final AsyncValue<HealthResult> healthAsync;
  final double size;

  @override
  Widget build(BuildContext context) {
    return healthAsync.when(
      loading: () => SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.statusUnknown,
        ),
      ),
      error: (e, st) =>
          _dot(AppColors.statusOffline, AppColors.statusOfflineGlow),
      data: (r) => _dot(
        r.online ? AppColors.statusOnline : AppColors.statusOffline,
        r.online ? AppColors.statusOnlineGlow : AppColors.statusOfflineGlow,
      ),
    );
  }

  Widget _dot(Color color, Color glow) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: glow, blurRadius: 6, spreadRadius: 1)],
        ),
      );
}

/// Plain grey dot for instances that are disabled (no health check runs).
class DisabledDot extends StatelessWidget {
  const DisabledDot({super.key, this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.statusUnknown,
        ),
      );
}
