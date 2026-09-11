# Plan: FixLens Discovery + Detail (TMDB Data Layer + Screens)

## Summary

Bangun lapisan data TMDB (dio client dengan auth Bearer v4, model, repository mengembalikan `AppResult`) lalu hidupkan tiga layar: Home (rail Trending + Popular), Search (teks debounce + filter multi-genre + rating minimum + load more), dan Detail (backdrop/poster/meta/genre/overview, trailer YouTube embed dengan fallback, cast horizontal, film terkait). Tanpa key, semua layar degrade ke demo-mode yang tidak crash. Output: alur cari→detail→trailer end-to-end live.

## User Story

As a penonton yang bingung mau nonton apa,
I want mencari/filter film dan membuka detail berisi trailer, cast, dan film terkait,
So that saya bisa memutuskan tontonan tanpa scroll tak berujung.

## Problem → Solution

Tiga tab + rute detail masih placeholder statis → Layar berisi data live TMDB dengan loading/empty/error states standar dan mode demo yang aman tanpa key.

## Metadata

- **Complexity**: Large
- **Source PRD**: `.claude/PRPs/prds/fixlens-movie-app.prd.md`
- **PRD Phase**: 2 — Discovery+Detail
- **Estimated Files**: ~20 (8 create data, 5 create presentation, 4 update screens, 2 tests, 1 pubspec)

---

## UX Design

### Before

```
┌─────────────────────────────┐
│ FixLens (Home)              │
│ Demo-mode banner (jika)     │
│ "Home — discovery hadir     │
│  di Fase 2."                │
├─────────────────────────────┤
│ Home │ Search │ Watchlist   │
└─────────────────────────────┘
Search/Detail: teks placeholder.
```

### After

```
┌─────────────────────────────┐
│ FixLens            [search] │
│ Trending minggu ini         │
│ [poster][poster][poster] >  │
│ Populer                     │
│ [poster][poster][poster] >  │
├─────────────────────────────┤
│ Home │ Search │ Watchlist   │
└─────────────────────────────┘
Search: kolom query + chips genre (multi) + slider rating min +
grid hasil + tombol "Muat lagi".
Detail (/movie/:id): backdrop, poster+judul+meta, chips genre,
overview, TRAILER (player / thumbnail-fallback), cast horizontal,
"Film terkait" (rail MovieCard).
```

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| Home | Teks statis | 2 rail live (Trending, Popular), tap poster → detail | Tiap rail punya status sendiri (AppLoading/AppError+retry) |
| Search | Teks statis | Query debounce 400ms + chips multi-genre + slider rating + grid + load more | Filter diterapkan ke `/discover`; query teks ke `/search` |
| Detail | `Detail film {id}` | Data penuh + trailer + cast + terkait | Tanpa trailer → kartu thumbnail + tombol buka YouTube |
| Tanpa key | Banner demo | Banner tetap + tiap section tampil AppEmpty "mode demo" | Tidak ada crash, tidak ada call jaringan |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `lib/src/core/result/app_result.dart` | 1-22 | Repository WAJIB return `AppOk`/`AppErr`; UI dilarang terima throw mentah |
| P0 | `lib/src/core/config/app_config.dart` | 13-22 | Guard `tmdbReadToken`/`isConfigured`; pola demo-mode |
| P0 | `lib/src/core/router/app_router.dart` | 68-74 | Rute `/movie/:id` → `DetailScreen(movieId: String)`; parse int di provider, `int.tryParse` gagal → error state |
| P1 | `lib/src/shared/widgets/app_error.dart` | all | Kontrak `AppError(message:, onRetry:)` untuk semua error section |
| P1 | `lib/src/shared/widgets/app_empty.dart` | all | Kontrak `AppEmpty(title:, subtitle:)` untuk demo/empty |
| P1 | `lib/src/features/home/presentation/home_screen.dart` | all | Banner demo-mode yang dipertahankan + tempat rail dipasang |
| P2 | `lib/src/core/utils/app_log.dart` | 1-8 | `appLog` untuk log error jaringan (debug only) |
| P2 | `test/smoke_test.dart` | all | Pola widget test yang berlaku |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| youtube_player 10.x API | pub.dev youtube_player_flutter 10.0.1 README + Changelog 10.0.0 | Rewrite di atas iframe 6.x; min Flutter 3.38 ✓. README masih contohkan `YoutubePlayerBuilder` tapi changelog 10.0.0 menyatakan DIHAPUS — baca README + example paket TERINSTAL, ikuti API aktual, verifikasi via analyze |
| TMDB auth v4 | developer.themoviedb.org/reference/getting-started | Header `Authorization: Bearer <v4 read token>` ke `https://api.themov
iedb.org/3`; body error `{status_code, status_message}` |
| TMDB discover/search/detail | TMDB docs `/discover/movie`, `/search/movie`, `/movie/{id}` | `with_genres` (koma), `vote_average.gte`, `sort_by=popularity.desc`, `include_adult=false`, `page`; detail pakai `append_to_response=credits,videos,similar` |
| TMDB images | TMDB docs getting-started/images | `https://image.tmdb.org/t/p/{w185,w342,w500,w780,original}{path}`; path null → placeholder |
| Riverpod Notifier | riverpod.dev + pub.dev Notifier docs | `NotifierProvider<XNotifier, XState>(XNotifier.new)` + `class X extends Notifier<S> { build() {...} }`; HINDARI `StateProvider` (deprecated path) |
| cached_network_image | pub.dev README | `CachedNetworkImage(imageUrl:, placeholder:, errorWidget:)` |

---

## Patterns to Mirror

### NAMING_CONVENTION

```dart
// SOURCE: Fase 1 (app.dart:8-9, router:44-47) — snake_case files, PascalCase
// classes, ConsumerWidget untuk layar, path '/home','/search','/movie/:id'
// Baru: lib/src/features/<fitur>/{data/{models,repositories},presentation/{providers,widgets}}
```

### ERROR_HANDLING

```dart
// SOURCE: lib/src/core/result/app_result.dart:9-22
sealed class AppResult<T> { const AppResult(); }
final class AppOk<T> extends AppResult<T> {
  final T data; const AppOk(this.data);
}
final class AppErr<T> extends AppResult<T> {
  final String message; const AppErr(this.message);
}
// Aturan: DioException/timeout/401/no-key SEMUA dipetakan ke AppErr dengan
// pesan ramah ("Demo mode…", "Kunci API ditolak (401)…", "Tidak ada koneksi…").
// UI: switch AppOk -> konten; AppErr -> AppError(message:, onRetry:).
```

### LOGGING_PATTERN

```dart
// SOURCE: lib/src/core/utils/app_log.dart:4-8
void appLog(String message) {
  if (kDebugMode) {
    debugPrint('[FixLens] $message');
  }
}
// Log setiap AppErr jaringan: appLog('TMDB $endpoint -> $message');
```

### REPOSITORY_PATTERN

```dart
// SOURCE: ditetapkan Fase 1, diwujudkan di sini — UI -> Notifier/FutureProvider
// -> Repository -> TmdbClient(dio). Tidak ada dio di widget/provider.
class MovieRepository {
  MovieRepository(this._client);
  final TmdbClient _client;
  Future<AppResult<List<MovieSummary>>> trending() async { ... }
}
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepository(ref.watch(tmdbClientProvider));
});
```

### STATE_PATTERN

```dart
// SOURCE: Fase 1 (ConsumerWidget) + pola "satu state, status per section"
// Search state immutable dengan status enum:
enum SectionStatus { initial, loading, data, empty, error }
class SearchState {
  final String query; final Set<int> genres; final double minRating;
  final List<MovieSummary> results; final int page; final bool hasMore;
  final SectionStatus status; final String? errorMessage;
  const SearchState({...}); SearchState copyWith({...}) {...}
}
class SearchNotifier extends Notifier<SearchState> {
  @override SearchState build() => const SearchState(...initial...);
}
final searchProvider = NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
// Detail: FutureProvider.family<AppResult<MovieDetail>, int>
// Genres+Home sections: FutureProvider<AppResult<...>>
```

### TEST_STRUCTURE

```dart
// SOURCE: test/smoke_test.dart — flutter_test, pump, expect findsWidgets
// Baru (unit, tanpa pump): test/tmdb_image_test.dart, test/movie_model_test.dart
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('poster url uses w342', () {
    expect(TmdbImage.poster('/abc.jpg'), 'https://image.tmdb.org/t/p/w342/abc.jpg');
  });
}
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `pubspec.yaml` | UPDATE (`flutter pub add dio cached_network_image youtube_player_flutter`) | Deps Fase 2; catat versi ter-resolve |
| `lib/src/core/network/tmdb_client.dart` | CREATE | dio + Bearer + `language=en-US` + timeout 15s + map error → AppErr; guard `!isConfigured` → AppErr demo |
| `lib/src/core/network/tmdb_image.dart` | CREATE | Builder URL poster/backdrop/still/cast; null/empty → null (UI pakai placeholder) |
| `lib/src/features/discover/data/models/movie.dart` | CREATE | `MovieSummary.fromJson` (id,title,posterPath,backdropPath,overview,releaseDate,voteAverage,genreIds) + `year` getter |
| `lib/src/features/discover/data/models/genre.dart` | CREATE | `Genre.fromJson` (id,name) |
| `lib/src/features/discover/data/movie_repository.dart` | CREATE | `genres()`, `trending()`, `popular()`, `discover({genres,minRating,page})`, `search({query,page})` → AppResult; parse envelope `{results,page,total_pages}` |
| `lib/src/features/discover/presentation/providers.dart` | CREATE | `tmdbClientProvider`, `movieRepositoryProvider`, `genresProvider`, `trendingProvider`, `popularProvider`, `searchProvider`+`SearchNotifier` (debounce Timer 400ms, `ref.onDispose` cancel) |
| `lib/src/features/detail/data/models/movie_detail.dart` | CREATE | `MovieDetail.fromJson` + nested credits/videos/similar (reuse MovieSummary/CastMember); `trailerKey` getter (YouTube+Trailer, official dulu) |
| `lib/src/features/detail/data/models/cast_member.dart` | CREATE | `CastMember.fromJson` (name,character,profilePath) |
| `lib/src/features/detail/data/detail_repository.dart` | CREATE | `detail(id)` → `AppResult<MovieDetail>` via append_to_response |
| `lib/src/features/detail/presentation/detail_provider.dart` | CREATE | `FutureProvider.family<AppResult<MovieDetail>, int>`; `int.tryParse` gagal → `AppErr('ID film tidak valid')` di screen |
| `lib/src/features/detail/presentation/widgets/trailer_player.dart` | CREATE | StatefulWidget: init controller dari videoId, dispose; tanpa videoId → thumbnail backdrop + tombol "Buka di YouTube" (url_launcher TIDAK dipakai — cukup tombol non-aktif + teks, hindari dep baru; buka-link ditunda Fase 5) |
| `lib/src/shared/widgets/movie_card.dart` | CREATE | Poster w342 + judul + tahun + rating; tap → `context.push('/movie/$id')`; lebar tetap 120 untuk rail, adaptif di grid via parent |
| `lib/src/features/home/presentation/home_screen.dart` | UPDATE | Banner demo dipertahankan; tambah 2 section (Trending, Popular) horizontal rail MovieCard, tiap section status sendiri |
| `lib/src/features/search/presentation/search_screen.dart` | UPDATE | SearchBar + chips genre multi + slider rating 0-10 + grid + "Muat lagi" (hasMore) |
| `lib/src/features/detail/presentation/detail_screen.dart` | UPDATE | Full detail: backdrop w780, poster, meta, chips, overview, trailer, cast rail, terkait rail |
| `test/tmdb_image_test.dart` | CREATE | Builder URL + null handling |
| `test/movie_model_test.dart` | CREATE | fromJson lengkap + field hilang (robustness) + envelope page |
| `README.md` | UPDATE | Baris status Fase 2 → in-progress/complete + tambah bagian "Mode demo" |

## NOT Building

- Quiz mood, mapping genre→mood, watchlist logic (Fase 3)
- Infinite scroll pagination (cukup tombol "Muat lagi"; scroll infinit ditunda)
- `share_plus`, `url_launcher`, buka-link eksternal (ditunda Fase 5)
- Bahasa Indonesia API (`language` dikunci `en-US`, konstanta `tmdbLanguage` siap diubah)
- TV shows / person detail (di luar scope PRD v1)
- Cache offline hasil API (cukup CachedNetworkImage disk cache; Hive cache ditunda)

---

## Step-by-Step Tasks

### Task 1: Dependensi + kunci API youtube player

- **ACTION**: `flutter pub add dio cached_network_image youtube_player_flutter`; catat versi. Lalu baca README + example paket youtube TERINSTAL (`~/.pub-cache` atau pub.dev) dan kunci pilihan API.
- **IMPLEMENT**: Jika `YoutubePlayerBuilder` tidak ada (sesuai changelog 10.0.0): pakai `YoutubePlayer(controller:)` langsung. Bentuk controller ikut contoh terinstal (`YoutubePlayerController(...)` atau `fromVideoId`). Jangan tambah `webview_flutter` manual.
- **GOTCHA**: README pub.dev 10.0.1 masih contohkan Builder yang sudah dihapus — sumber kebenaran = kode terinstal + `flutter analyze`.
- **VALIDATE**: `flutter pub get` sukses; `flutter analyze` tetap bersih (belum ada pemakaian).

### Task 2: TmdbClient + TmdbImage + unit test

- **ACTION**: Buat `tmdb_client.dart`: dio `BaseOptions(baseUrl: https://api.themoviedb.org/3, connectTimeout=15s, receiveTimeout=15s)`, interceptor sisipkan `Authorization: Bearer ${AppConfig.tmdbReadToken}` + query default `language=en-US` + `include_adult=false`. Method generik `getJson(path, {query}) → AppResult<Map<String,dynamic>>`.
- **IMPLEMENT**: Guard awal: jika `!AppConfig.isConfigured` return `AppErr('Mode demo — tambahkan TMDB key (lihat README)')`. Map `DioException`: 401 → 'Kunci API ditolak (401)…', timeout/connection → 'Tidak ada koneksi…', else `status_message` TMDB bila ada. Tiap error juga `appLog('TMDB $path -> $message')`. `tmdb_image.dart`: `poster(path)->w342`, `backdrop->w780`, `still->w500`, `avatar->w185`; null/empty → null.
- **MIRROR**: ERROR_HANDLING, LOGGING_PATTERN.
- **IMPORTS**: `package:dio/dio.dart`, `AppConfig`, `AppResult`, `appLog`.
- **GOTCHA**: JANGAN pakai query `api_key` (itu auth v3). Token demo placeholder HARUS menghasilkan AppErr ramah, bukan call 401.
- **VALIDATE**: Tulis `test/tmdb_image_test.dart` (4 ukuran + null) → `flutter test` pass; `flutter analyze` bersih.

### Task 3: Model discover + unit test

- **ACTION**: `movie.dart` (`MovieSummary.fromJson` defensif: semua field nullable-safe, `voteAverage` via `(json['vote_average'] as num?)?.toDouble() ?? 0.0`, `genreIds` List<int> aman) + `year` getter (4 digit pertama releaseDate, '-' bila kosong). `genre.dart` sederhana.
- **MIRROR**: TEST_STRUCTURE.
- **GOTCHA**: `poster_path` sering null → field nullable, UI yang fallback. Jangan `as String` langsung.
- **VALIDATE**: `test/movie_model_test.dart`: fromJson penuh, field hilang, envelope `{results,page,total_pages}` → `flutter test` pass.

### Task 4: MovieRepository + providers

- **ACTION**: `movie_repository.dart` 5 method (genres, trending `/trending/movie/week`, popular `/movie/popular`, discover, search) kembalikan AppResult; parse envelope sekali di helper privat. `providers.dart`: client+repo Provider, genres/trending/popular FutureProvider autoDispose, SearchNotifier+state (Task 5 pakai).
- **MIRROR**: REPOSITORY_PATTERN, STATE_PATTERN.
- **IMPORTS**: `flutter_riverpod`, repo, models, client.
- **GOTCHA**: `discover` dengan `genres` kosong → JANGAN kirim `with_genres` (tanpa param = semua genre). `minRating` 0 → jangan kirim `vote_average.gte`.
- **VALIDATE**: `flutter analyze` bersih (live call di Task 8).

### Task 5: MovieCard + Home live

- **ACTION**: `movie_card.dart` (lebar 120, CachedNetworkImage poster + placeholder AppLoading mini + errorWidget icon, judul max 2 baris, tahun • rating, `InkWell` → `push('/movie/$id')`). Update `home_screen.dart`: banner demo tetap; dua section rail horizontal (Trending, Popular) masing-masing `ref.watch` + switch status (loading→AppLoading, error→AppError+retry via `ref.invalidate`, empty→AppEmpty).
- **MIRROR**: STATE_PATTERN (ConsumerWidget), kontrak AppLoading/AppError/AppEmpty.
- **IMPORTS**: `cached_network_image`, `go_router` (push), providers.
- **GOTCHA**: `ref.invalidate(trendingProvider)` untuk retry. Tanpa key: provider kembalikan AppErr demo → section tampil AppEmpty "mode demo", banner tetap.
- **VALIDATE**: analyze bersih.

### Task 6: Search live (debounce + filter)

- **ACTION**: `SearchNotifier`: `setQuery` (Timer debounce 400ms, cancel di `ref.onDispose`), `toggleGenre(id)`, `setMinRating(v)`, `loadMore()` (page+1 append bila hasMore), `_fetch({reset})`: query kosong → `discover(genres,minRating)`; query isi → `search(query)` (filter genre/rating diterapkan client-side pada hasil search karena endpoint search tak dukung keduanya). Update `search_screen.dart`: SearchBar, `Wrap` chips dari genresProvider, Slider 0-10 divisi 20 + label, GridView 3 kolom MovieCard, tombol "Muat lagi" bila hasMore, status via AppLoading/AppError/AppEmpty.
- **MIRROR**: STATE_PATTERN (SearchState copyWith), ERROR_HANDLING.
- **GOTCHA**: Race condition ketikan cepat → token request monoton naik, hasil basi dibuang (`if (token != _latest) return`). `loadMore` guard `status==data && hasMore && !loadingMore` (tambah flag di state bila perlu, tanpa ubah pola).
- **VALIDATE**: analyze bersih; test manual ketik cepat di Task 8.

### Task 7: Detail data + trailer player

- **ACTION**: `cast_member.dart`, `movie_detail.dart` (parse `credits.cast` max 15, `videos.results` → `trailerKey`: site YouTube + type Trailer, official dulu lalu terbaru; `similar.results` → List<MovieSummary max 10). `detail_repository.dart`. `detail_provider.dart` FutureProvider.family int. `trailer_player.dart` StatefulWidget: `initState` buat controller (API per Task 1), `dispose` controller, `didUpdateWidget` rebuild bila videoId berubah; tanpa key → AspectRatio 16/9 berisi CachedNetworkImage backdrop + icon play + teks 'Trailer tidak tersedia'.
- **MIRROR**: REPOSITORY_PATTERN, ERROR_HANDLING.
- **GOTCHA**: Controller YouTube WAJIB dispose (review HIGH bila lupa). Jangan buat controller di `build()`.
- **VALIDATE**: analyze bersih.

### Task 8: Detail screen full + validasi live

- **ACTION**: Update `detail_screen.dart`: `int.tryParse(movieId)` gagal → AppError statis. `ref.watch(detailProvider(id))` switch: loading AppLoading; error AppError+retry (`ref.invalidate`); data → SingleChildScrollView: backdrop, header poster+judul+tahun•durasi•rating, chips genre, overview, TrailerPlayer, cast rail (avatar w185 + nama + karakter), terkait rail (MovieCard).
- **MIRROR**: Kontrak shared widgets; MovieCard reuse.
- **VALIDATE**: `flutter analyze` 0 issue; `flutter test` pass; `flutter run -d <device>`: (a) tanpa key → banner + empty demo, tak ada crash; (b) DENGAN key (`--dart-define=TMDB_READ_TOKEN=...`) → Home rail isi, search+filter hasil benar, detail trailer/cast/terkait tampil, ketik cepat tak ada hasil basi. Catat hasil (b) di laporan (tanpa menulis key ke mana pun).

### Task 9: README + final gate

- **ACTION**: Update tabel status README (Fase 2 complete) + seksi "Mode demo" 3 baris. Jalankan `flutter analyze`, `flutter test` final.
- **VALIDATE**: Gate PRD Fase 2: search filter + detail + trailer jalan dengan offline-degraded (demo path) terpenuhi.

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| tmdb_image poster/backdrop/still/avatar | '/a.jpg' | URL ukuran benar | Ya — null/'' → null |
| movie fromJson penuh | fixture TMDB | Field terparse, year benar | Tidak |
| movie fromJson minim (`{id,title}`) | field hilang | Default aman, tanpa throw | Ya |
| envelope results | `{results:[...],page,total_pages}` | List + hasMore benar | Ya — results kosong → empty |

### Edge Cases Checklist

- [ ] Tanpa key (demo) — banner + empty, tanpa call jaringan
- [ ] 401 (key salah) — pesan ramah + retry
- [ ] Timeout / offline — pesan koneksi + retry
- [ ] Film tanpa trailer — fallback thumbnail, tanpa crash
- [ ] `poster_path` null — placeholder icon
- [ ] Query kosong + filter kosong — discover populer default
- [ ] Ketik cepat — hasil basi dibuang
- [ ] `/movie/abc` — error ID tidak valid

---

## Validation Commands

### Static Analysis

```powershell
flutter analyze
```

EXPECT: No issues found!

### Unit Tests

```powershell
flutter test
```

EXPECT: All tests pass (smoke + 2 file baru).

### Manual Validation (device, dua mode)

- [ ] Tanpa key: banner demo + tiap section empty, navigasi lancar
- [ ] Dengan `--dart-define` key real: rail Home isi + poster tampil
- [ ] Search "dune" + genre Sci-Fi + rating ≥7 → hasil relevan; Muat lagi menambah
- [ ] Detail Dune: trailer putar + suara, cast tampil, terkait bisa diklik
- [ ] Airplane mode: pesan koneksi + retry berfungsi

---

## Acceptance Criteria

- [ ] Semua 9 task selesai
- [ ] `flutter analyze` nol issue, `flutter test` pass
- [ ] Alur search→detail→trailer live terverifikasi di device (atau tercatat bila tanpa key)
- [ ] Demo path tanpa crash di semua layar baru
- [ ] Controller YouTube di-dispose; tanpa dio di widget
- [ ] Tidak ada secret/key tertulis di repo

## Completion Checklist

- [ ] Repository return AppResult; UI switch lengkap (loading/data/empty/error)
- [ ] `with_genres`/`vote_average.gte` hanya dikirim bila bermakna
- [ ] `poster_path` null-safe di semua titik
- [ ] Versi paket ter-resolve dicatat di laporan
- [ ] README status fase diperbarui
- [ ] Self-contained — tanpa riset tambahan

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| API youtube 10.x aktual ≠ README pub.dev | H | Sedang | Task 1 kunci dari kode terinstal + analyze sebagai arbiter |
| Rate limit TMDB demo key bersama | M | Rendah | Debounce + pesan error ramah; key pribadi via dart-define |
| Overview/poster null di banyak judul | H | Rendah | Fallback di semua titik (sudah di plan) |
| `language=en-US` vs user Indonesia | Pasti | Rendah | Konstanta `tmdbLanguage`; toggle id-ID Fase 5 |

## Notes

- Keputusan terkunci: auth Bearer v4 (bukan `api_key` v3); `language=en-US`; tombol "Muat lagi" ganti infinite scroll; tanpa `url_launcher`/`share_plus` (Fase 5); TV/person di luar scope.
- Struktur baru `features/discover/` menampung search+home (satu domain TMDB movie); quiz Fase 3 boleh reuse `MovieRepository.discover` + `MovieCard`.
