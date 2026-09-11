import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/tmdb_image.dart';
import '../../core/theme/app_theme.dart';
import '../../features/discover/data/models/movie.dart';
import 'section_header.dart';

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
///
/// Layout contract (regression-tested): card content ≈ 216h at ~108w with
/// headroom for 2-line titles and larger font scales. Overlays below live
/// INSIDE the poster bounds so rail (120x252) and grid (0.48) bounds hold.
class MovieCard extends StatelessWidget {
  final MovieSummary movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final posterUrl = TmdbImage.poster(movie.posterPath);
    return Semantics(
      button: true,
      label:
          '${movie.title}, ${movie.year}, rating ${movie.voteAverage.toStringAsFixed(1)}',
      child: InkWell(
        onTap: () => context.push('/movie/${movie.id}'),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: const Color(0xFF2A2A42)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm - 1),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (posterUrl == null)
                        Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainer,
                          child: const Icon(
                            Icons.movie_outlined,
                            size: 40,
                            semanticLabel: 'Tanpa poster',
                          ),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const ShimmerPoster(),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 40,
                              semanticLabel: 'Poster gagal dimuat',
                            ),
                          ),
                        ),
                      // Bottom scrim for badge legibility (inside bounds).
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.cardScrim,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            border: Border.all(
                              color: AppColors.rating.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 11,
                                color: AppColors.rating,
                                semanticLabel: 'Rating',
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie.voteAverage.toStringAsFixed(1),
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFFF1F4F9),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  movie.year,
                  style: textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stable shimmer shown while a poster loads (keeps aspect, no jumping).
class ShimmerPoster extends StatefulWidget {
  const ShimmerPoster({super.key});

  @override
  State<ShimmerPoster> createState() => _ShimmerPosterState();
}

class _ShimmerPosterState extends State<ShimmerPoster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            size: 36,
            color: Color(0xFF4A4A68),
          ),
        ),
      ),
    );
  }
}

/// Horizontal rail of [MovieCard]s with a cinematic section header.
class MovieRail extends StatelessWidget {
  final String title;
  final List<MovieSummary> movies;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const MovieRail({
    super.key,
    required this.title,
    required this.movies,
    this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          count: movies.length,
          actionLabel: onSeeAll != null ? 'Lihat' : null,
          onAction: onSeeAll,
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
