# Implementation Report: FixLens Mood Quiz + Watchlist (MVP Gate)

## Summary

Quiz "mood finder" 3 pertanyaan (8 mood → company → durasi) dengan tabel
mapping manual + alasan deterministik menghasilkan top-3 via `discover`
(+1x relax tanpa runtime). Watchlist Hive persisten (JSON maps, tanpa
codegen): toggle di Detail + snackbar undo, grid + geser-hapus + undo di tab,
badge count di nav. Demo-mode: quiz error ramah, watchlist 100% lokal.
Terverifikasi: analyze 0, 33 test hijau, keyed run nol error, kontrak param
baru valid di API langsung (20 hasil, top-3 berrating).

## Assessment vs Reality

| Metric | Predicted (Plan) | Actual |
|---|---|---|
| Complexity | Large | Large |
| Confidence | 8/10 | 8/10 |
| Files Changed | ~15 | 13 created, 7 updated |

## Tasks Completed

| # | Task | Status | Notes |
|---|---|---|---|
| 1 | Extend discover + toJson + test | done | 4 param baru, kirim-hanya-bermakna; round-trip test |
| 2 | mood_map + test | done | 8 mood/4 company/3 durasi; `firstOrNull` dihindari (tanpa dep collection); lint dangling-doc + dead class dibersihkan |
| 3 | QuizNotifier + test | done | answer/back/restart/runQuiz + relax; 5 test (happy, error, relax, incomplete, restart) |
| 4 | Quiz/result screens + routes | done | `/mood`, `/mood/result`; restart-on-entry via ConsumerStatefulWidget; guard deep-link; AppEmpty+CTA (kontrak AppEmpty tak diubah) |
| 5 | Watchlist repo/provider/bootstrap/test | done | Box override di main; repo skip-korup; 3 test box-temp |
| 6 | UI watchlist/bookmark/badge/CTA | done | Dismissible+undo, bookmark+undo, Badge.count nav, CTA home |
| 7 | README + gate | done | Partial — gate waktu & persist = user acceptance (di bawah) |

## Validation Results

| Level | Status | Notes |
|---|---|---|
| Static Analysis | done Pass | No issues found! |
| Unit Tests | done Pass | 33/33 (17 baru: json 2, mood 7, quiz 5, watchlist 3... +2 kartu lama) |
| Build | done Pass | assembleDebug + launch 2 mode di Infinix API 35 |
| Live contract | done Pass | discover param baru OK (20 hasil, nostalgia OK); log app nol error TMDB |
| MVP gate (waktu/persist) | pending user | Butuh tap manusia — skrip di bawah |

## Files Changed

| File | Action |
|---|---|
| `lib/src/features/mood/data/mood_map.dart` | CREATED |
| `lib/src/features/mood/presentation/quiz_provider.dart` | CREATED |
| `lib/src/features/mood/presentation/mood_quiz_screen.dart` | CREATED |
| `lib/src/features/mood/presentation/mood_result_screen.dart` | CREATED |
| `lib/src/features/mood/presentation/widgets/pick_card.dart` | CREATED |
| `lib/src/features/watchlist/data/watchlist_repository.dart` | CREATED |
| `lib/src/features/watchlist/presentation/watchlist_provider.dart` | CREATED |
| `test/mood_map_test.dart`, `quiz_provider_test.dart`, `watchlist_test.dart`, `movie_json_test.dart` | CREATED |
| `movie_repository.dart` (+4 param), `movie.dart` (+toJson), `movie_detail.dart` (+toSummary) | UPDATED |
| `home_screen.dart` (CTA), `detail_screen.dart` (bookmark), `watchlist_screen.dart` (overwrite), `app_router.dart` (rute+badge), `main.dart` (box), `README.md` | UPDATED |

## Deviations from Plan

1. **WHAT**: Tanpa `firstOrNull` (helper `_find*` manual).
   **WHY**: Butuh `package:collection`; helper 5 baris lebih murah dari dep baru.
2. **WHAT**: `setMinRating` tidak diubah (sudah debounce dari review Fase 2).
   **WHY**: Plan Task 3 Fase 2 fix sudah mencakup; tidak ada duplikasi logika.
3. **WHAT**: Guard deep-link via if-branch + AppEmpty, bukan guard-case di switch.
   **WHY**: Lebih terbaca; exhaustiveness switch tetap penuh.
4. **WHAT**: Hnaya `Badge` (bukan `Badge.count`).
   **WHY**: `Badge(label:)` cukup; `count` butuh properti persis yang sama.

## Issues Encountered

- `firstOrNull` tidak ada di dart:core (3.12) — diganti helper (lihat deviations).
- Lint `dangling_library_doc_comments` di header mood_map — header jadi komentar biasa.
- `QuizOption` mati (desain menyimpang ke 3 tipe) — dihapus sebelum merge.
- Smoke test + Consumer badge tanpa override: aman by-design (catch → empty + log) — terverifikasi di log test.
- Token live dipakai HANYA via `--dart-define`/header API check; tidak tertulis di repo (`git status` bersih dari secret).

## Tests Written

| Test File | Tests | Coverage |
|---|---|---|
| `test/mood_map_test.dart` | 7 | Tabel, modifier, reason, fallback |
| `test/quiz_provider_test.dart` | 5 | Happy, error, relax, incomplete, restart |
| `test/watchlist_test.dart` | 3 | Round-trip, korup, toggle |
| `test/movie_json_test.dart` | 2 | Round-trip, null paths |

## User Acceptance (wajib sebelum klaim MVP lolos)

- [ ] 5 skenario quiz <60 dtk (tap CTA → 3 picks): catat waktu tiap skenario
- [ ] Simpan 3 film → force-stop → relaunch → 3 tetap ada (persist 100%)
- [ ] Hapus via grid + via detail → undo keduanya bekerja; badge sinkron
- [ ] Poster/trailer/detail Fase 2 tidak regresi (navigasi result → detail)

## Next Steps

- [ ] User acceptance di atas (lalu update status gate PRD bila perlu)
- [ ] Commit + push `main` (satu-branch workflow)
- [ ] Uji 5-user tabel mapping (PRD mengakui v1 belum tervalidasi)
- [ ] `/prp-plan` Fase 4/5 bila gate lolos
