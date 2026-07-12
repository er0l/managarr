import 'package:flutter/material.dart';

import '../config/spacing.dart';

/// Bold section title used by dashboard sections and settings groups,
/// with an optional trailing widget (badge, "see all" action, …).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal,
        Spacing.s20,
        Spacing.pageHorizontal,
        Spacing.s12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
