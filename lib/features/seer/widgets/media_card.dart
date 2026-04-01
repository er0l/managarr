import 'package:flutter/material.dart';

import '../api/models/search_result.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
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

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (posterUrl != null)
              Image.network(
                posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (e, s, t) => _Placeholder(result: result),
              )
            else
              _Placeholder(result: result),
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
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.year.isNotEmpty)
                      Text(
                        result.year,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.mediaType == 'movie' ? 'Movie' : 'TV',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
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
  const _Placeholder({required this.result});
  final SeerSearchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: Icon(
        result.mediaType == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
        color: Colors.white24,
        size: 40,
      ),
    );
  }
}
