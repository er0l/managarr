import 'package:flutter/material.dart';

import '../api/models/media_request.dart';

class MediaRequestTile extends StatelessWidget {
  const MediaRequestTile({
    super.key,
    required this.request,
    this.onTap,
  });

  final SeerMediaRequest request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = request.posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w92${request.posterPath}'
        : null;

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 42,
          height: 63,
          child: posterUrl != null
              ? Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (e, s, t) => _PosterFallback(request: request),
                )
              : _PosterFallback(request: request),
        ),
      ),
      title: Text(
        request.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requested by ${request.requestedBy}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: request.statusColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: request.statusColor.withAlpha(120)),
                ),
                child: Text(
                  request.statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: request.statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  request.mediaType == 'movie' ? 'Movie' : 'TV',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.request});
  final SeerMediaRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      alignment: Alignment.center,
      child: Icon(
        request.mediaType == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
        color: Colors.white30,
        size: 20,
      ),
    );
  }
}
