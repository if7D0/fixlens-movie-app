import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../result/app_result.dart';
import '../utils/app_log.dart';

/// HTTP client for TMDB v3 with v4 Bearer auth (locked Phase 2).
///
/// Every call returns [AppResult] — raw [DioException]s never escape.
/// Without a configured key all calls short-circuit to a demo-mode [AppErr]
/// so no network traffic happens and UI can degrade gracefully.
class TmdbClient {
  TmdbClient({Dio? dio}) : _dio = dio ?? Dio(_baseOptions) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] =
              'Bearer ${AppConfig.tmdbReadToken}';
          options.queryParameters.putIfAbsent(
            'language',
            () => tmdbLanguage,
          );
          options.queryParameters.putIfAbsent('include_adult', () => 'false');
          handler.next(options);
        },
      ),
    );
  }

  static const String tmdbLanguage = 'en-US';

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: 'https://api.themoviedb.org/3',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  );

  final Dio _dio;

  Future<AppResult<Map<String, dynamic>>> getJson(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (!AppConfig.isConfigured) {
      return const AppErr(
        'Mode demo — tambahkan TMDB key (lihat README).',
      );
    }
    try {
      final res = await _dio.get(path, queryParameters: query);
      final data = res.data;
      if (data is Map<String, dynamic>) return AppOk(data);
      const msg = 'Respons tak terduga dari server.';
      appLog('TMDB $path -> $msg');
      return const AppErr(msg);
    } on DioException catch (e) {
      final msg = _messageFor(e);
      appLog('TMDB $path -> $msg');
      return AppErr(msg);
    }
  }

  String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi lambat — coba lagi.';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Tidak ada koneksi — periksa internet lalu coba lagi.';
      case DioExceptionType.badResponse:
        return _messageForStatus(e);
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Koneksi tidak aman — coba lagi nanti.';
    }
  }

  String _messageForStatus(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) {
      return 'Kunci API ditolak (401) — periksa TMDB key.';
    }
    if (code == 404) return 'Data tidak ditemukan.';
    final data = e.response?.data;
    if (data is Map && data['status_message'] is String) {
      return 'TMDB: ${data['status_message']}';
    }
    return 'Kesalahan server (${code ?? 'tanpa kode'}).';
  }
}
