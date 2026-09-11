import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/tmdb_image.dart';
import '../quiz_provider.dart';

/// One recommendation row: poster + title/meta + deterministic reason.
class PickCard extends StatelessWidget {
  final MoodPick pick;

  const PickCard({super.key, required this.pick});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final posterUrl = TmdbImage.poster(pick.movie.posterPath);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/movie/${pick.movie.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: posterUrl == null
                        ? Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: const Icon(Icons.movie_outlined),
                          )
                        : CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pick.movie.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pick.movie.year} • '
                      '${pick.movie.voteAverage.toStringAsFixed(1)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pick.reason,
                      style: textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
