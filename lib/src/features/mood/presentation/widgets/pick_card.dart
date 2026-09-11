import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/tmdb_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../quiz_provider.dart';

/// One recommendation row: rank + poster + title/meta + deterministic reason.
class PickCard extends StatelessWidget {
  final MoodPick pick;
  final int rank;

  const PickCard({super.key, required this.pick, this.rank = 0});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final posterUrl = TmdbImage.poster(pick.movie.posterPath);
    return Semantics(
      button: true,
      label: 'Pilihan $rank: ${pick.movie.title}. ${pick.reason}',
      child: Material(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => context.push('/movie/${pick.movie.id}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: const Color(0xFF2A2A42)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: 92,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: posterUrl == null
                              ? Container(
                                  color: scheme.surfaceContainerHigh,
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
                    if (rank > 0)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: AppColors.moodGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$rank',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pick.movie.title,
                        style: textTheme.titleSmall?.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.rating,
                            semanticLabel: 'Rating',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pick.movie.voteAverage.toStringAsFixed(1)} • ${pick.movie.year}',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandViolet.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          pick.reason,
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFD9D4FF),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
