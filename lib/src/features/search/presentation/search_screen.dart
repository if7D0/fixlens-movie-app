import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../discover/data/models/genre.dart';
import '../../discover/presentation/providers.dart';

/// Search tab: debounced text query, multi-genre chips, minimum rating,
/// grid results with "load more".
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final genresAsync = ref.watch(genresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              hintText: 'Cari judul film…',
              leading: const Icon(Icons.search),
              onChanged: notifier.setQuery,
            ),
          ),
          _GenreChips(genresAsync: genresAsync, selected: search.genres),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Rating min'),
                Expanded(
                  child: Slider(
                    value: search.minRating,
                    max: 10,
                    divisions: 20,
                    label: search.minRating.toStringAsFixed(1),
                    onChanged: notifier.setMinRating,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(search.minRating.toStringAsFixed(1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _Results(search: search)),
        ],
      ),
    );
  }
}

class _GenreChips extends ConsumerWidget {
  final AsyncValue<AppResult<List<Genre>>> genresAsync;
  final Set<int> selected;

  const _GenreChips({required this.genresAsync, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);
    return switch (genresAsync) {
      AsyncData(value: AppOk(data: final genres)) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (final g in genres)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(g.name),
                  selected: selected.contains(g.id),
                  onSelected: (_) => notifier.toggleGenre(g.id),
                ),
              ),
          ],
        ),
      ),
      AsyncData(value: AppErr(message: final m)) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          m,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ),
      _ => const SizedBox(height: 8),
    };
  }
}

class _Results extends ConsumerWidget {
  final SearchState search;

  const _Results({required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);
    switch (search.status) {
      case SearchStatus.initial:
        return const AppEmpty(
          title: 'Cari film',
          subtitle: 'Ketik judul atau pilih genre dan rating di atas.',
        );
      case SearchStatus.loading:
        return const AppLoading();
      case SearchStatus.error:
        return AppError(
          message: search.errorMessage ?? 'Gagal memuat.',
          onRetry: notifier.refresh,
        );
      case SearchStatus.empty:
        return const AppEmpty(
          title: 'Tidak ketemu',
          subtitle: 'Coba kata kunci atau filter lain.',
        );
      case SearchStatus.data:
      case SearchStatus.loadingMore:
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: movieGridDelegate,
                itemCount: search.results.length,
                itemBuilder: (context, i) =>
                    MovieCard(movie: search.results[i]),
              ),
            ),
            if (search.hasMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: search.status == SearchStatus.loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : OutlinedButton(
                        onPressed: notifier.loadMore,
                        child: const Text('Muat lagi'),
                      ),
              ),
          ],
        );
    }
  }
}
