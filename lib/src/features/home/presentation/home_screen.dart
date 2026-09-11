import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/result/app_result.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../discover/data/models/movie.dart';
import '../../discover/presentation/providers.dart';

/// Home tab: Trending + Popular rails with independent section states.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixLens')),
      body: ListView(
        children: [
          if (!AppConfig.isConfigured)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Demo mode — TMDB key belum dikonfigurasi. '
                    'Lihat README untuk cara menambahkannya.',
                  ),
                ),
              ),
            ),
          _Section(
            title: 'Trending minggu ini',
            result: ref.watch(trendingProvider),
            onRetry: () => ref.invalidate(trendingProvider),
          ),
          _Section(
            title: 'Populer',
            result: ref.watch(popularProvider),
            onRetry: () => ref.invalidate(popularProvider),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final AsyncValue<AppResult<List<MovieSummary>>> result;
  final VoidCallback onRetry;

  const _Section({
    required this.title,
    required this.result,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      AsyncData(value: AppOk(data: final movies)) => movies.isEmpty
          ? AppEmpty(title: title, subtitle: 'Belum ada data.')
          : MovieRail(title: title, movies: movies),
      AsyncData(value: AppErr(message: final m)) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: SizedBox(
          height: 220,
          child: SingleChildScrollView(
            child: AppError(message: m, onRetry: onRetry),
          ),
        ),
      ),
      AsyncError(:final error) => Padding(
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
      _ => const SizedBox(height: 200, child: AppLoading()),
    };
  }
}
