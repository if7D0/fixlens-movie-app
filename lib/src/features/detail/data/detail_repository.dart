import '../../../core/network/tmdb_client.dart';
import '../../../core/result/app_result.dart';
import 'models/movie_detail.dart';

/// Read-only TMDB movie detail with credits, videos, and similar titles.
class DetailRepository {
  DetailRepository(this._client);

  final TmdbClient _client;

  Future<AppResult<MovieDetail>> detail(int id) async {
    final res = await _client.getJson(
      '/movie/$id',
      query: {'append_to_response': 'credits,videos,similar'},
    );
    return switch (res) {
      AppOk(data: final data) => AppOk(MovieDetail.fromJson(data)),
      AppErr(message: final m) => AppErr(m),
    };
  }
}
