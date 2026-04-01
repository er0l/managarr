import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, required this.onTap});

  final RadarrMovie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterUrl;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Poster image
            if (posterUrl != null)
              Image.network(
                posterUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _Skeleton();
                },
                errorBuilder: (e, s, t) => _Placeholder(movie: movie),
              )
            else
              _Placeholder(movie: movie),

            // Bottom gradient overlay with title + year
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (movie.year > 0)
                      Text(
                        movie.year.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Monitoring status dot — top-right
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: movie.hasFile
                      ? AppColors.statusOnline
                      : movie.monitored
                          ? AppColors.statusWarning
                          : AppColors.statusUnknown,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            movie.title.isNotEmpty ? movie.title[0] : 'R',
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.surfaceElevated);
  }
}
