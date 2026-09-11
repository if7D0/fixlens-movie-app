import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/tmdb_image.dart';
import '../../../core/result/app_result.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../reviews/presentation/review_section.dart';
import '../../watchlist/presentation/watchlist_provider.dart';
import '../data/models/movie_detail.dart';
import 'detail_provider.dart';
import 'widgets/trailer_player.dart';

/// Full detail route (`/movie/:id`): header, overview, trailer, cast,
/// similar titles.
class DetailScreen extends ConsumerWidget {
  final String movieId;

  const DetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(movieId);
    if (id == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppError(
          message: 'ID film tidak valid.',
          onRetry: () => context.pop(),
        ),
      );
    }
    final async = ref.watch(detailProvider(id));
    return switch (async) {
      AsyncData(value: AppOk(data: final d)) => Scaffold(
        appBar: AppBar(
          title: Text(d.title),
          actions: [_BookmarkAction(detail: d)],
        ),
        body: _Body(detail: d),
      ),
      AsyncData(value: AppErr(message: final m)) => Scaffold(
        appBar: AppBar(),
        body: AppError(
          message: m,
          onRetry: () => ref.invalidate(detailProvider(id)),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: AppError(
          message: 'Gagal memuat detail: $error',
          onRetry: () => ref.invalidate(detailProvider(id)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const AppLoading(),
      ),
    };
  }
}

class _BookmarkAction extends ConsumerWidget {
  final MovieDetail detail;

  const _BookmarkAction({required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      watchlistProvider.select((s) => s.ids.contains(detail.id)),
    );
    return IconButton(
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
      onPressed: () async {
        final summary = detail.toSummary();
        final nowSaved = await ref
            .read(watchlistProvider.notifier)
            .toggle(summary);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowSaved ? 'Ditambah ke watchlist' : 'Dihapus dari watchlist',
            ),
            action: nowSaved
                ? null
                : SnackBarAction(
                    label: 'Urungkan',
                    onPressed: () => ref
                        .read(watchlistProvider.notifier)
                        .add(summary),
                  ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  final MovieDetail detail;

  const _Body({required this.detail});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final backdropUrl = TmdbImage.backdrop(detail.backdropPath);
    final posterUrl = TmdbImage.poster(detail.posterPath);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (backdropUrl != null)
            CachedNetworkImage(
              imageUrl: backdropUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  const SizedBox(height: 8),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posterUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: posterUrl,
                      width: 110,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.movie_outlined, size: 48),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detail.year} • ${detail.runtimeLabel} • '
                        '${detail.voteAverage.toStringAsFixed(1)}',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final g in detail.genreNames)
                            Chip(
                              label: Text(g),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (detail.overview.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(detail.overview),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Trailer', style: textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TrailerPlayer(
              videoId: detail.trailerKey,
              backdropPath: detail.backdropPath,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Pemeran', style: textTheme.titleMedium),
          ),
          if (detail.cast.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Data pemeran tidak tersedia.'),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: detail.cast.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = detail.cast[i];
                  final avatarUrl = TmdbImage.avatar(c.profilePath);
                  return SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: avatarUrl != null
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person_outline)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.name,
                          style: textTheme.labelSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          c.character,
                          style: textTheme.labelSmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (detail.similar.isNotEmpty)
            MovieRail(title: 'Film terkait', movies: detail.similar)
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppEmpty(
                title: 'Tidak ada yang terkait',
                subtitle: 'Belum ada rekomendasi untuk film ini.',
              ),
            ),
          ReviewSection(movieId: detail.id),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
