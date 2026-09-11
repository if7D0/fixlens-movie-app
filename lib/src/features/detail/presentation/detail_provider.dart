import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/app_result.dart';
import '../../discover/presentation/providers.dart';
import '../data/detail_repository.dart';
import '../data/models/movie_detail.dart';

final detailRepositoryProvider = Provider<DetailRepository>(
  (ref) => DetailRepository(ref.watch(tmdbClientProvider)),
);

final detailProvider =
    FutureProvider.autoDispose
        .family<AppResult<MovieDetail>, int>((ref, id) {
          return ref.watch(detailRepositoryProvider).detail(id);
        });
