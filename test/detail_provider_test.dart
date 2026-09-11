import 'package:dio/dio.dart';
import 'package:fixlens_movie_app/src/core/network/tmdb_client.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/detail/presentation/detail_provider.dart';
import 'package:fixlens_movie_app/src/features/discover/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeClient extends TmdbClient {
  DetailFakeClient() : super(dio: Dio());

  @override
  Future<AppResult<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return AppOk({
      'id': 550,
      'title': 'Fight Club',
      'overview': '',
      'release_date': '1999-10-15',
      'vote_average': 8.4,
      'runtime': 139,
      'genres': [],
      'credits': {'cast': []},
      'videos': {
        'results': [
          {'site': 'YouTube', 'type': 'Trailer', 'key': 'k1'},
        ],
      },
      'similar': {'results': []},
    });
  }
}

void main() {
  test('detailProvider emits parsed detail', () async {
    final container = ProviderContainer(
      overrides: [
        tmdbClientProvider.overrideWithValue(DetailFakeClient()),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(detailProvider(550), (_, _) {});
    addTearDown(sub.close);

    final result = await container.read(detailProvider(550).future);
    expect(result, isA<AppOk>());
    final detail = (result as AppOk).data;
    expect(detail.title, 'Fight Club');
    expect(detail.trailerKey, 'k1');
  });
}
