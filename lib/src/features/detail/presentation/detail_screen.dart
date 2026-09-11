import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/tmdb_image.dart';
import '../../../core/result/app_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const SizedBox.shrink(),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: _BookmarkAction(detail: d),
            ),
          ],
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
      tooltip: saved ? 'Hapus dari watchlist' : 'Simpan ke watchlist',
      icon: Icon(
        saved ? Icons.bookmark : Icons.bookmark_outline,
        semanticLabel: saved ? 'Tersimpan di watchlist' : 'Simpan',
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final backdropUrl = TmdbImage.backdrop(detail.backdropPath);
    final posterUrl = TmdbImage.poster(detail.posterPath);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cinematic header: backdrop + scrim, poster overlaps content.
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: backdropUrl != null
                    ? CachedNetworkImage(
                        imageUrl: backdropUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: scheme.surfaceContainerHigh,
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.moodGradient,
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.moodGradient,
                        ),
                      ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.heroScrim),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: -56,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md - 1),
                        child: posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: posterUrl,
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    Container(
                                      width: 110,
                                      height: 165,
                                      color: scheme.surfaceContainer,
                                      child: const Icon(
                                        Icons.movie_outlined,
                                        size: 48,
                                      ),
                                    ),
                              )
                            : Container(
                                width: 110,
                                height: 165,
                                color: scheme.surfaceContainer,
                                child: const Icon(
                                  Icons.movie_outlined,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.rating.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                                border: Border.all(
                                  color: AppColors.rating.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.rating,
                                    semanticLabel: 'Rating',
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    detail.voteAverage.toStringAsFixed(1),
                                    style: textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${detail.year} • ${detail.runtimeLabel}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 68),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(detail.title, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: 10),
          if (detail.genreNames.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (var i = 0; i < detail.genreNames.length; i++) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(color: const Color(0xFF34344E)),
                      ),
                      child: Text(
                        detail.genreNames[i],
                        style: textTheme.labelLarge?.copyWith(fontSize: 12),
                      ),
                    ),
                    if (i != detail.genreNames.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          if (detail.overview.isNotEmpty) ...[
            const SectionHeader(title: 'Sinopsis'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                detail.overview,
                style: textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
          ],
          const SectionHeader(
            title: 'Trailer',
            subtitle: 'Cuplikan resmi film',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFF2A2A42)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.lg - 1),
                child: TrailerPlayer(
                  videoId: detail.trailerKey,
                  backdropPath: detail.backdropPath,
                ),
              ),
            ),
          ),
          const SectionHeader(title: 'Pemeran', subtitle: 'Para pemain utama'),
          if (detail.cast.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Data pemeran tidak tersedia.'),
            )
          else
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: detail.cast.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final c = detail.cast[i];
                  final avatarUrl = TmdbImage.avatar(c.profilePath);
                  return SizedBox(
                    width: 84,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.moodGradient,
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: scheme.surfaceContainer,
                            backgroundImage: avatarUrl != null
                                ? CachedNetworkImageProvider(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.name,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          c.character,
                          style: textTheme.labelSmall?.copyWith(fontSize: 11),
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
            MovieRail(
              title: 'Film terkait',
              subtitle: 'Mungkin kamu juga suka',
              movies: detail.similar,
            )
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
