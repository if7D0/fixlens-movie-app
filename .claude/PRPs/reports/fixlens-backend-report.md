# Implementation Report: FixLens Backend — Firebase (Phase 4)

## Summary

Firebase Auth (Google Sign-In 7.x), sinkronisasi watchlist Hive ↔ Firestore
(last-write-wins), dan rating + ulasan publik per film dengan ringkasan
transaksional. Tab Profil ke-4, section ulasan di Detail, auto-sync saat
login + tombol manual. Tanpa backend: 100% lokal tanpa crash. Terverifikasi:
analyze 0, 43 test hijau, keyed run `[FixLens] firebase ready` + bootstrap
tanpa error. Gate manusia (tap login, tulis ulasan, restore sync): user
acceptance di bawah.

## Assessment vs Reality

| Metric | Predicted (Plan) | Actual |
|---|---|---|
| Complexity | Large | Large |
| Confidence | 7/10 | 8/10 (Task 0 tuntas penuh; API 7.x terverifikasi dari source) |
| Files Changed | ~17 | 13 created, 7 updated |

## Tasks Completed

| # | Task | Status | Notes |
|---|---|---|---|
| 0 | Prasyarat manual | done | Project + Firestore Jakarta + Google provider + app/SHA-1 (console); flutterfire non-interaktif; rules deployed; build PASS |
| 1 | Deps + bootstrap | done | firebase_core 4.14.0, auth 6.6.1, firestore 6.9.0, google_sign_in 7.2.0; guarded init + flag provider |
| 2 | Auth repo + provider | done | API 7.x terverifikasi source (initialize/authenticate/idToken, canceled mapping); pesan ApiException-10 |
| 3 | Sync pure + service | done | mergeWatchlists + service pull/push; `updatedAtMs()` repo; hook toggle/remove; no-cycle via uid param + UI-owned login trigger |
| 4 | Review model + repo | done | Validasi rating/teks, math summary, transaksi upsert/delete, list, myReviews collectionGroup (field uid diduplikasi) |
| 5 | UI + wiring | done | Profil, ReviewSection/Sheet, tab ke-4 + badge tetap, ReviewSection di Detail |
| 6 | Rules + README | done | Rules sudah live sejak Task 0 (cocok dgn implementasi); README 8 langkah + keterbatasan |
| 7 | Tests + gate | done | 8 test pure baru; device keyed OK; gate manusia pending di bawah |

## Validation Results

| Level | Status | Notes |
|---|---|---|
| Static Analysis | done Pass | No issues found! (termasuk fix `valueOrNull` hilang di Riverpod 3 + import tak perlu) |
| Unit Tests | done Pass | 43/43 (review 5, sync-merge 3) |
| Build | done Pass | assembleDebug + launch keyed, firebase ready, nol error |
| Integration (live) | partial | Init + rails OK; login/ulasan/sync butuh tap manusia |
| Edge Cases | done Pass (code) | Demo-mode, batal login, guard tombol, prefill aman |

## Files Changed

| File | Action |
|---|---|
| `lib/src/core/backend/firebase_bootstrap.dart` | CREATED |
| `lib/src/features/account/data/auth_repository.dart` | CREATED |
| `lib/src/features/account/presentation/account_provider.dart` | CREATED |
| `lib/src/features/account/presentation/profile_screen.dart` | CREATED |
| `lib/src/features/watchlist/data/watchlist_sync.dart` | CREATED |
| `lib/src/features/reviews/data/models/review.dart` | CREATED |
| `lib/src/features/reviews/data/review_repository.dart` | CREATED |
| `lib/src/features/reviews/presentation/reviews_provider.dart` | CREATED |
| `lib/src/features/reviews/presentation/review_section.dart` | CREATED |
| `lib/src/features/reviews/presentation/review_sheet.dart` | CREATED |
| `test/review_test.dart`, `test/sync_merge_test.dart` | CREATED |
| `lib/main.dart` (firebase overrides), `app_router.dart` (tab Profil), `detail_screen.dart` (section), `watchlist_provider.dart` (hook+sync), `watchlist_repository.dart` (+timestamps), `README.md` | UPDATED |
| `firestore.rules`, `firebase.json`, `firebase_options.dart`, `google-services.json` (Task 0) | CREATED earlier |

## Deviations from Plan

1. **WHAT**: `uid` diduplikasi ke dokumen review.
   **WHY**: collectionGroup `where('uid')` butuh field (doc ID tak bisa di-query).
2. **WHAT**: Trigger auto-sync di ProfileScreen via `ref.listen`, bukan di `signIn()`.
   **WHY**: Hindari siklus import account↔watchlist; UI memiliki trigger.
3. **WHAT**: Review prefill via `ref.listen` + post-set, bukan baca-saat-build.
   **WHY**: Data tiba setelah build pertama; pola aman Riverpod.
4. **WHAT**: `valueOrNull` diganti switch-expression.
   **WHY**: Hilang di Riverpod 3.4 (temuan analyze).

## Issues Encountered

- `firstOrNull` tidak ada di dart:core (pelajaran Fase 3) — dihindari sejak awal via loop manual.
- google_sign_in 7.x: tutorial lama (signIn/accessToken) 100% rusak — dipakai snippet resmi Firebase Mar 2026, terverifikasi di source terinstal.
- Watch: warning build "plugins that apply KGP will fail in future Flutter" (firebase_auth/core) — non-blokir hari ini, catat untuk upgrade plugin di Fase 5.
- Token live hanya via `--dart-define`/header; tidak tertulis di repo.

## Tests Written

| Test File | Tests | Coverage |
|---|---|---|
| `test/review_test.dart` | 5 | Avg tambah/ubah/hapus, sanitasi, round-trip |
| `test/sync_merge_test.dart` | 3 | Menang-baru, union, sisi kosong |

## User Acceptance (di HP, butuh tap manusia)

- [ ] Tab Profil → Login dengan Google → nama/avatar muncul
- [ ] Toggle bookmark → cek dokumen di console Firestore
- [ ] Detail → tulis ulasan (rating+teks) → badge avg berubah; ubah; hapus
- [ ] Reinstall → login → watchlist pulih (sync)
- [ ] Logout → fitur lokal tetap jalan; Profil mode signed-out

## Next Steps

- [ ] User acceptance di atas
- [ ] Commit + push `main`
- [ ] `/flutter-review` opsional
- [ ] `/prp-plan` Fase 5 (iOS + polish) bila Fase 4 diterima
