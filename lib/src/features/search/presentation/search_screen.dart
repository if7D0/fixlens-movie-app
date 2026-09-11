import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_empty.dart';
import '../../../shared/widgets/app_error.dart';
import '../../../shared/widgets/app_loading.dart';
import '../../../shared/widgets/movie_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../discover/data/models/genre.dart';
import '../../discover/presentation/providers.dart';

/// Search tab: debounced text query, multi-genre chips, minimum rating,
/// grid results with "load more".
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final genresAsync = ref.watch(genresProvider);
    // One-way sync for external resets (clear button). Typing flows
    // controller -> provider with the same value echoed back (no-op).
    if (_controller.text != search.query) {
      _controller.value = TextEditingValue(
        text: search.query,
        selection: TextSelection.collapsed(offset: search.query.length),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'Search',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SearchBar(
                controller: _controller,
                hintText: 'Cari judul film…',
                leading: const Icon(Icons.search),
                trailing: search.query.isNotEmpty
                    ? [
                        IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _controller.clear();
                            notifier.setQuery('');
                          },
                        ),
                      ]
                    : null,
                onChanged: notifier.setQuery,
              ),
            ),
            _GenreChips(genresAsync: genresAsync, selected: search.genres),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFF2A2A42)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 18,
                    color: AppColors.rating,
                    semanticLabel: 'Rating minimal',
                  ),
                  const SizedBox(width: 8),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.rating.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      search.minRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.rating,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Divider(height: 1),
            ),
            Expanded(child: _Results(search: search)),
          ],
        ),
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
          icon: Icons.search_outlined,
        );
      case SearchStatus.loading:
        return const MovieGridSkeleton();
      case SearchStatus.error:
        return AppError(
          message: search.errorMessage ?? 'Gagal memuat.',
          onRetry: notifier.refresh,
        );
      case SearchStatus.empty:
        return const AppEmpty(
          title: 'Tidak ketemu',
          subtitle: 'Coba kata kunci atau filter lain.',
          icon: Icons.sentiment_dissatisfied_outlined,
        );
      case SearchStatus.data:
      case SearchStatus.loadingMore:
        return Column(
          children: [
            SectionHeader(
              title: 'Hasil',
              subtitle:
                  '${search.results.length} film${search.hasMore ? ' • masih ada lagi' : ''}',
              count: search.results.length,
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: movieGridDelegate,
                itemCount: search.results.length,
                itemBuilder: (context, i) =>
                    MovieCard(movie: search.results[i]),
              ),
            ),
            if (search.hasMore)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: search.status == SearchStatus.loadingMore
                    ? const SizedBox(
                        height: 48,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: notifier.loadMore,
                          icon: const Icon(Icons.expand_more, size: 20),
                          label: const Text('Muat lagi'),
                        ),
                      ),
              ),
          ],
        );
    }
  }
}
