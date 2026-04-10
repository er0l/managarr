import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Data for a single external link chip.
class ExternalLink {
  const ExternalLink({
    required this.label,
    required this.url,
    this.color,
  });

  final String label;
  final String url;

  /// Chip accent colour. Defaults to [AppColors.tealPrimary] when null.
  final Color? color;
}

/// Renders a "Links" heading followed by a [Wrap] of branded outline chips.
/// Returns [SizedBox.shrink] when [links] is empty.
class ExternalLinksSection extends StatelessWidget {
  const ExternalLinksSection({super.key, required this.links});

  final List<ExternalLink> links;

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Could not open: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: links
              .map((link) => _LinkChip(
                    link: link,
                    onTap: () => _open(context, link.url),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.link, required this.onTap});

  final ExternalLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = link.color ?? AppColors.tealPrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(180)),
          borderRadius: BorderRadius.circular(20),
          color: color.withAlpha(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              link.label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
