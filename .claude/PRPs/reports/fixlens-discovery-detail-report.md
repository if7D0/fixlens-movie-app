# Implementation Report: FixLens Discovery + Detail

## Summary

Lapisan data TMDB live (dio + Bearer v4, model null-safe, repository
mengembalikan `AppResult`) plus tiga layar fungsional: Home (rail Trending +
Popular), Search (debounce 400ms + chips multi-genre + slider rating +
load more), Detail (header, overview, trailer YouTube embed + fallback,
cast, film terkait). Demo-mode tanpa key terverifikasi di device (no crash,
tanpa traffic). Kontrak live terverifikasi: key valid, trending 20 hasil,
detail Fight Club (cast 76, 5 video, trailer official, 20 similar), nol
error di log aplikasi.

## Assessment vs Reality

| Metric     | Predicted (Plan) | Actual                                    |
| ---------- | ---------------- | ----------------------------------------- |
| Complexity | Large            | Large                                     |
| Confidence | 8/10             | 8/10 (youtube API sesuai taktik plan: baca kode terinstal) |
| Files Changed | ~20           | 15 created, 4 updated (pubspec, pubspec.lock, 3 screens, README) |

## Tasks Completed

| # | Task | Status | Notes |
|---|---|---|---|
| 1 | Deps + kunci API youtube | done | dio 5.11.1, cached_network_image 4.0.0, youtube_player_flutter 10.0.1 (iframe 6.0.2). API dikunci dari source terinstal: `fromVideoId` + `close()`, tanpa Builder |
| 2 | TmdbClient + TmdbImage + test | done | Bearer v4, timeout 15s, map error lengkap, guard demo-mode. Deviated — tambah case `transformTimeout` (temuan analyze) |
| 3 | Model discover + test | done | `whereType<num>()` ganti cast langsung (temuan test) |
| 4 | Repository + providers | done | Deviated — perbaiki cast `AppErr` ilegal jadi switch; perbaiki level import relatif |
| 5 | MovieCard + Home live | done | Deviated — tangani `AsyncValue` (bukan AppResult langsung); perbaiki import movie_card |
| 6 | Search live | done | Complete (debounce, token anti-basi, filter client-side utk /search) |
| 7 | Detail data + trailer | done | trailerKey official-first; controller dispose via `close()` |
| 8 | Detail screen + live | done | Live contract verified (lihat Validation). Render visual = user acceptance |
| 9 | README + gate | done | Status Fase 1-2 complete + seksi Mode demo |

## Validation Results

| Level | Status | Notes |
|---|---|---|
| Static Analysis | done Pass | `flutter analyze` → No issues found! |
| Unit Tests | done Pass | 9 tests (smoke + tmdb_image 5 + movie_model 3) |
| Build | done Pass | assembleDebug + install + launch di Infinix API 35, dua mode |
| Integration (live) | done Pass (contract) | Direct API: trending=20, detail OK, trailer official key ada; app log nol error TMDB |
| Edge Cases | done Pass (code) | Demo, 401-pesan, null poster/trailer, ID invalid, ketik-cepat, loadMore guard |

## Files Changed

| File | Action |
|---|---|
| `lib/src/core/network/tmdb_client.dart` | CREATED |
| `lib/src/core/network/tmdb_image.dart` | CREATED |
| `lib/src/features/discover/data/models/movie.dart` | CREATED |
| `lib/src/features/discover/data/models/genre.dart` | CREATED |
| `lib/src/features/discover/data/movie_repository.dart` | CREATED |
| `lib/src/features/discover/presentation/providers.dart` | CREATED |
| `lib/src/features/detail/data/models/movie_detail.dart` | CREATED |
| `lib/src/features/detail/data/models/cast_member.dart` | CREATED |
| `lib/src/features/detail/data/detail_repository.dart` | CREATED |
| `lib/src/features/detail/presentation/detail_provider.dart` | CREATED |
| `lib/src/features/detail/presentation/widgets/trailer_player.dart` | CREATED |
| `lib/src/shared/widgets/movie_card.dart` | CREATED |
| `test/tmdb_image_test.dart`, `test/movie_model_test.dart` | CREATED |
| `lib/src/features/{home,search,detail}/presentation/*_screen.dart` | UPDATED |
| `pubspec.yaml`, `pubspec.lock`, `README.md` | UPDATED |

## Deviations from Plan

1. **WHAT**: Tambah `DioExceptionType.transformTimeout` ke pesan lambat.
   **WHY**: Analyze non-exhaustive switch (dio 5.11).
2. **WHAT**: `whereType<num>()` untuk `genre_ids`.
   **WHY**: Cast `as num?` melempar untuk string (temuan unit test).
3. **WHAT**: Ganti cast `res as AppErr<...>` dengan switch-expression.
   **WHY**: Cast generik ilegal — throw saat runtime.
4. **WHAT**: Section Home tangani `AsyncValue` (Data/Error/loading).
   **WHY**: `watch(FutureProvider)` kembalikan AsyncValue, bukan AppResult.
5. **WHAT**: Bungkus AppError section dalam `SingleChildScrollView` (h 220).
   **WHY**: Overflow 56px pada box 140 (temuan smoke test, bug real di demo-mode).
6. **WHAT**: Tanpa `url_launcher` (sesuai plan) — tombol buka-YouTube diganti fallback statis.
   **WHY**: Hindari dep baru; buka-link Fase 5.

## Issues Encountered

- Import relatif salah level (3 file) — pola: dari `*/data/` atau `shared/widgets/` butuh `../../../` atau `../../` yang berbeda; tertangkap analyze, diperbaiki langsung.
- Smoke overflow (di atas) — satu-satunya bug runtime, sudah fix + test hijau.
- Token live dipakai HANYA via `--dart-define` di command run; tidak tertulis di file/repo mana pun (terverifikasi `git status`: hanya file kerja).

## Tests Written

| Test File | Tests | Coverage |
|---|---|---|
| `test/tmdb_image_test.dart` | 5 | 4 ukuran + null/empty |
| `test/movie_model_test.dart` | 3 | Penuh, minim, genre non-numerik |
| `test/smoke_test.dart` | 1 | Launch + nav (existing, tetap hijau) |

## User Acceptance (belum terverifikasi headless)

- [ ] Poster ter-render di rail/grid di device dengan key
- [ ] Trailer terputar dengan suara di Detail
- [ ] Navigasi tap poster → detail → back
- [ ] Ketik cepat di Search tidak menampilkan hasil basi

## Next Steps

- [ ] Review via `/flutter-review` (opsional)
- [ ] Commit + PR branch `feat/fixlens-discovery-detail` via `/prp-pr`
- [ ] `/prp-plan .claude/PRPs/prds/fixlens-movie-app.prd.md` untuk Fase 3
