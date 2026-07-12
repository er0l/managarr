import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Icon + tiny label button for module BottomAppBars (Tautulli-style),
/// so every bottom action is self-explanatory.
class BottomBarButton extends StatelessWidget {
  const BottomBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Highlights the button (active filter/sort, selected media type…).
  final bool active;

  static const _muted = Color(0xA0FFFFFF);

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.tealPrimary : _muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
