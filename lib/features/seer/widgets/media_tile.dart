import 'package:flutter/material.dart';

import '../../../core/config/spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/search_result.dart';

class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  final SeerSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = result.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, s) => Container(
                    color: AppColors.tealDark,
                    alignment: Alignment.center,
                    child: Icon(
                      result.mediaType == 'movie'
                          ? Icons.movie_outlined
                          : Icons.tv_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Icon(
                    result.mediaType == 'movie'
                        ? Icons.movie_outlined
                        : Icons.tv_outlined,
                    color: Colors.white24,
                    size: 24,
                  ),
                ),
        ),
      ),
      title: Text(
        result.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (result.year.isNotEmpty) result.year,
          result.mediaType == 'movie' ? 'Movie' : 'TV Show',
        ].join(' · '),
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
