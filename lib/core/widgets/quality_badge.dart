import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dark-pill quality badge matching the v2 design system.
///
/// Shows the quality label (e.g. "4K HDR", "1080p", "FLAC") in a dark pill
/// with a Mono font. HDR / Dolby Vision content gets an orange border glow to
/// signal premium quality at a glance.
///
/// ```dart
/// QualityBadge(quality: '4K HDR')   // orange border
/// QualityBadge(quality: '1080p')    // neutral border
/// QualityBadge(quality: '4K HDR', small: true) // compact variant
/// ```
class QualityBadge extends StatelessWidget {
  const QualityBadge({
    super.key,
    required this.quality,
    this.small = false,
  });

  final String quality;
  final bool small;

  static bool _isHdr(String q) =>
      q.contains('HDR') ||
      q.contains('DV') ||
      q.contains('DolbyVision') ||
      q.contains('2160');

  @override
  Widget build(BuildContext context) {
    if (quality.isEmpty) return const SizedBox.shrink();
    final isHdr = _isHdr(quality);
    final borderColor = isHdr
        ? AppColors.orangeAccent.withAlpha(200)
        : Colors.white.withAlpha(45);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        quality,
        style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'JetBrainsMono',
          letterSpacing: 0.04,
          height: 1.4,
        ),
      ),
    );
  }
}
