import 'package:flutter/material.dart';
import '../../../core/config/spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/artist.dart';

class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist, required this.onTap});

  final LidarrArtist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = artist.posterUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (posterUrl != null)
                    Image.network(posterUrl, fit: BoxFit.cover)
                  else
                    Container(
                      color: AppColors.tealDark,
                      alignment: Alignment.center,
                      child: Text(
                        artist.artistName.isNotEmpty ? artist.artistName[0] : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!artist.monitored)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.visibility_off,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.artistName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (artist.statistics != null) ...[
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: (artist.statistics!.percentOfTracks ?? 0) / 100,
                      backgroundColor: AppColors.textSecondary.withAlpha(25),
                      color: AppColors.tealPrimary,
                      minHeight: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
