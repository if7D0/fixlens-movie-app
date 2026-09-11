import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/tmdb_image.dart';
import '../../features/discover/data/models/movie.dart';

/// Shared 3-column poster grid delegate for Search and Watchlist grids.
///
/// Single source so card sizing stays in sync: card content ≈ 216h at
/// ~108w, with headroom for 2-line titles and larger font scales.
const movieGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  // Card content ≈ 216h at ~108w: keep headroom for
  // 2-line titles and larger font scales.
  childAspectRatio: 0.48,
);

/// Poster card shared by Home rails, Search grid, and Detail similar rail.
/// Parent controls width: fixed 120 in rails, expanded in grids.
class MovieCard extends StatelessWidget {
  final MovieSummary movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final posterUrl = TmdbImage.poster(movie.posterPath);
    return InkWell(
      onTap: () => context.push('/movie/${movie.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: posterUrl == null
                  ? Container(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: const Icon(Icons.movie_outlined, size: 40),
                    )
                  : CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            style: textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${movie.year} • ${movie.voteAverage.toStringAsFixed(1)}',
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal rail of [MovieCard]s with a section header.
class MovieRail extends StatelessWidget {
  final String title;
  final List<MovieSummary> movies;

  const MovieRail({super.key, required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          // 120w poster (180h) + 6 gap + 2-line title + meta ≈ 234:
          // keep headroom for larger font scales (regression-tested).
          height: 252,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                SizedBox(width: 120, child: MovieCard(movie: movies[i])),
          ),
        ),
      ],
    );
  }
}
