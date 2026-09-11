import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/result/app_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/mood_cta_card.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../discover/data/models/movie.dart';
import '../../discover/presentation/providers.dart';

/// Home tab: Trending + Popular rails with independent section states.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: false,
              pinned: false,
              backgroundColor: AppColors.background,
              expandedHeight: 76,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                title: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/splash/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        semanticLabel: 'Logo FixLens',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FixLens',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Mau nonton apa malam ini?',
                          style: textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!AppConfig.isConfigured)
              const SliverToBoxAdapter(child: DemoBanner()),
            SliverToBoxAdapter(
              child: MoodCtaCard(onTap: () => context.push('/mood')),
            ),
            _SectionSliver(
              title: 'Trending minggu ini',
              subtitle: 'Paling ramai dibicarakan',
              result: ref.watch(trendingProvider),
              onRetry: () => ref.invalidate(trendingProvider),
            ),
            _SectionSliver(
              title: 'Populer',
              subtitle: 'Favorit penonton Indonesia',
              result: ref.watch(popularProvider),
              onRetry: () => ref.invalidate(popularProvider),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SectionSliver extends StatelessWidget {
  final String title;
  final String? subtitle;
  final AsyncValue<AppResult<List<MovieSummary>>> result;
  final VoidCallback onRetry;

  const _SectionSliver({
    required this.title,
    this.subtitle,
    required this.result,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      AsyncData(value: AppOk(data: final movies)) => movies.isEmpty
          ? SliverToBoxAdapter(
              child: AppEmpty(title: title, subtitle: 'Belum ada data.'),
            )
          : SliverToBoxAdapter(
              child: MovieRail(
                title: title,
                subtitle: subtitle,
                movies: movies,
              ),
            ),
      AsyncData(value: AppErr(message: final m)) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            height: 220,
            child: SingleChildScrollView(
              child: AppError(message: m, onRetry: onRetry),
            ),
          ),
        ),
      ),
      AsyncError(:final error) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            height: 220,
            child: SingleChildScrollView(
              child: AppError(
                message: 'Gagal memuat $title: $error',
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      ),
      _ => SliverToBoxAdapter(child: MovieRailSkeleton(title: title)),
    };
  }
}
