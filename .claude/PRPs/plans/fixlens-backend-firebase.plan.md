# Plan: FixLens Backend — Firebase Auth + Sync + Public Reviews (Phase 4)

## Summary

Sambungkan app ke Firebase (project owner): Google Sign-In, sinkronisasi
watchlist Hive ↔ Firestore (last-write-wins), dan rating + ulasan publik per
film dengan ringkasan rata-rata transaksional. Tanpa backend (init gagal /
belum login), app tetap jalan penuh secara lokal — Firebase adalah lapisan
tambahan, bukan fondasi. Prasyarat manual owner (console + flutterfire_cli)
tercantum eksplisit sebagai Task 0.

## User Story

As a penonton yang sudah login,
I want watchlist saya tersinkron dan bisa memberi/membaca ulasan film,
So that data ikut pindah device dan saya dapat sinyal sosial sebelum nonton.

## Problem → Solution

Watchlist hanya lokal + tanpa sinyal sosial → Akun Google opsional, sync
otomatis saat login, dan section ulasan publik di Detail — semuanya degrade
graceful tanpa backend.

## Metadata

- **Complexity**: Large
- **Source PRD**: `.claude/PRPs/prds/fixlens-movie-app.prd.md`
- **PRD Phase**: 4 — Backend-optional (gate MVP lolos ✓ per user)
- **Estimated Files**: ~17 (9 create, 5 update, 2 generated, 1 rules)

---

## UX Design

### Before

Bottom nav 3 tab (Home/Search/Watchlist). Detail tanpa ulasan. Tanpa akun.

### After

Bottom nav 4 tab (+ Profil). Detail + section "Ulasan" (badge rata-rata,
3 preview, tombol tulis). Profil: tombol login / info user + logout +
"Sync sekarang" + ulasan saya. Belum login → CTA login, semua fitur lokal
tetap jalan.

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| Bottom nav | 3 tab | 4 tab (+ Profil) | Badge Watchlist tetap |
| Profil (baru) | Tidak ada | Login Google / info + logout + sync + ulasan saya | Tanpa login: hanya tombol + penjelasan lokal |
| Detail | Trailer/cast/terkait | + Ulasan (avg, list, tulis) | Tulis butuh login → arahkan ke Profil |
| Watchlist toggle | Lokal | Lokal + push Firestore bila login | Pull+merge saat login |
| Tanpa backend | N/A | Semua di atas nonaktif rapi, banner kecil di Profil | Init gagal → `firebaseReady=false` |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `lib/main.dart` | all | Bootstrap: selipkan init Firebase guarded SETELAH Hive, SEBELUM runApp |
| P0 | `lib/src/core/router/app_router.dart` | shell builder + `/movie/:id` | Tambah branch Profil + rute; pola Consumer badge |
| P0 | `lib/src/features/watchlist/presentation/watchlist_provider.dart` | all | Sisip sync-hook di toggle/add/remove (jangan ubah state shape) |
| P1 | `lib/src/features/detail/presentation/detail_screen.dart` | `_Body` | Sisip `ReviewSection(movieId:)` setelah terkait |
| P1 | `lib/src/features/discover/data/models/movie.dart` | toJson/fromJson | Reuse untuk dokumen watchlist Firestore |
| P2 | `test/watchlist_test.dart` | overrides | Pola override provider untuk test merge/sync |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| google_sign_in 7.x + Firebase | firebase.google.com/docs/auth/flutter/federated-auth (Mar 2026) + MIGRATION.md | Singleton; `await GoogleSignIn.instance.initialize()` DULU; `authenticate()` (bukan `signIn()`); `googleAuth.idToken` saja (tanpa accessToken); kredensial `GoogleAuthProvider.credential(idToken:)`. Tutorial lama RUSAK total |
| SHA-1 + enable provider | Firebase docs di atas | Daftarkan SHA-1 debug (+release) di console; aktifkan provider Google. Tanpa ini: `ApiException: 10` |
| google-services.json wajib | flutterfire#9468 + google docs | Build Android GAGAL tanpanya → file demo WAJIB di-commit (aman: bukan secret; proteksi via rules + SHA). Degradasi hanya di level runtime, bukan file hilang |
| Firestore offline | Default Android/iOS cache aktif | Read/write tetap jalan offline, sync otomatis — andalkan, jangan bikin antrean manual |

---

## Patterns to Mirror

### NAMING_CONVENTION

```dart
// SOURCE: Fase 1-3 — features/<domain>/{data/{models,*_repository.dart},
// presentation/{*_provider.dart,screens,widgets/}}
// Baru: features/account/{data/auth_repository.dart,presentation/{account_provider.dart,profile_screen.dart}}
// features/reviews/{data/{models/review.dart,review_repository.dart},
// presentation/{reviews_provider.dart,review_section.dart,review_sheet.dart}}
// features/watchlist/data/watchlist_sync.dart (pure merge fn)
```

### ERROR_HANDLING

```dart
// SOURCE: AppResult + try/catch-appLog (tmdb_client, watchlist_provider)
// Auth: signIn lemah -> AppErr('Login dibatalkan' / 'Login gagal: ...').
// ApiException 10 -> 'SHA-1 belum terdaftar (lihat README)'.
// Review write gagal (rules/offline-permanen) -> snackbar + AppErr.
// Sync gagal -> appLog + badge/dot 'belum sync' di Profil (jangan blokir UI).
```

### STATE_PATTERN

```dart
// SOURCE: SearchNotifier/QuizNotifier/WatchlistNotifier (copyWith, status)
// AccountState: {status: signedOut/signingIn/signedIn, user: AppUser?, errorMessage?}
// AppUser {uid, displayName, photoUrl, email} dari Firebase User (jangan
// expose Firebase User ke UI).
// ReviewsState per movieId via FutureProvider.family (list) + ringkasan.
```

### REPOSITORY_PATTERN

```dart
// SOURCE: movie/detail/watchlist repositories (konstruktor-inject, AppResult)
// AuthRepository(FirebaseAuth, GoogleSignIn): Stream<AppUser?> authChanges(),
// Future<AppResult<AppUser>> signInWithGoogle(), signOut().
// ReviewRepository(FirebaseFirestore): upsertReview (TRANSAKSI summary),
// Future listRecent(movieId), Future myReview(movieId).
```

### TEST_STRUCTURE

```dart
// SOURCE: test/*_test.dart — fake + ProviderContainer overrides + temp box
// Baru (pure, tanpa emulator): test/review_test.dart (avg math, model),
// test/sync_merge_test.dart (last-write-wins dua arah).
// Rules + alur login ASLI: manual via console/Firebase playground (dicatat).
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `pubspec.yaml` | UPDATE (`flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in`) | Deps Fase 4; catat versi |
| `lib/firebase_options.dart` | CREATE (generated `flutterfire configure`) | Config project demo; di-commit (bukan secret) |
| `android/app/google-services.json` | CREATE (generated) | WAJIB ada agar build jalan; di-commit |
| `android/settings.gradle.kts` + `android/app/build.gradle.kts` | UPDATE (biasanya otomatis via CLI) | Verifikasi plugin google-services terpasang |
| `firestore.rules` | CREATE | Rules salin-tempel + `firebase deploy --only firestore:rules` |
| `lib/src/core/backend/firebase_bootstrap.dart` | CREATE | `Future<bool> initFirebase()` guarded → `firebaseReadyProvider` |
| `lib/src/features/account/data/auth_repository.dart` | CREATE | Google flow API 7.x + mapping AppUser + ApiException-10 message |
| `lib/src/features/account/presentation/account_provider.dart` | CREATE | AccountNotifier + `accountProvider` + listened authChanges |
| `lib/src/features/account/presentation/profile_screen.dart` | CREATE | Tab ke-4: login/logout, sync, ulasan saya |
| `lib/src/features/watchlist/data/watchlist_sync.dart` | CREATE | Pure `mergeWatchlists(local, remote)` last-write-wins + `WatchlistSyncService` (pull/push) |
| `lib/src/features/reviews/data/models/review.dart` | CREATE | Review{uid,displayName,rating 1-10,text,updatedAt} from/toJson + `ReviewSummary{avg,count}` + `applyRating()` pure math |
| `lib/src/features/reviews/data/review_repository.dart` | CREATE | Transaksi summary + CRUD + list |
| `lib/src/features/reviews/presentation/reviews_provider.dart` | CREATE | `reviewsProvider(movieId)` + `summaryProvider(movieId)` + `myReviewProvider(movieId)` |
| `lib/src/features/reviews/presentation/review_section.dart` | CREATE | Badge avg + 3 preview + tombol tulis (guard login) |
| `lib/src/features/reviews/presentation/review_sheet.dart` | CREATE | Bottom sheet slider 1-10 + text ≤500 + submit |
| `lib/src/features/detail/presentation/detail_screen.dart` | UPDATE | Sisip ReviewSection setelah terkait |
| `lib/src/features/watchlist/presentation/watchlist_provider.dart` | UPDATE | Hook sync di toggle/add/remove (bila login; gagal → log saja) |
| `lib/src/core/router/app_router.dart` | UPDATE | Branch `/profile` + tab ke-4 |
| `lib/main.dart` | UPDATE | Init Firebase guarded + override provider kesiapan |
| `test/review_test.dart`, `test/sync_merge_test.dart` | CREATE | Unit pure (lihat strategi) |
| `README.md` | UPDATE | Setup console 10 langkah + mode tanpa-backend + atribusi |

## NOT Building

- Cloud Functions / agregasi server-side (summary via transaksi klien)
- Email/password, Apple/Facebook login (hanya Google)
- Komentar berbalas/like/dislike ulasan (rating+teks saja)
- App Check / rate-limit lanjutan (rules + SHA cukup untuk portfolio)
- Migrasi akun anonim→permanen (tanpa mode anonim)
- iOS push/GoogleService plist (Fase 5 bila iOS; Android dulu)

---

## Step-by-Step Tasks

### Task 0: Prasyarat MANUAL owner (di luar kode, wajib dulu)

- **ACTION**: (1) Buat project Firebase → aktifkan Authentication/Google provider. (2) `keytool -list -v -keystore ~/.android/debug.keystore` (alias androiddebugkey, pass android) ambil SHA-1 → daftarkan di console (+ SHA-1 release bila ada). (3) `dart pub global activate flutterfire_cli` → `flutterfire configure` (pilih Android, package `com.fixlens.fixlens_movie_app`). (4) Buat Firestore Database (production mode) → deploy `firestore.rules` (dibuat Task 6) → `firebase deploy --only firestore:rules`.
- **VALIDATE**: File `lib/firebase_options.dart` + `android/app/google-services.json` ada; build debug jalan. Tanpa ini Task 1-8 TAK BISA full-validasi (dicatat di laporan).

### Task 1: Deps + bootstrap guarded

- **ACTION**: `flutter pub add ...` (4 paket); tulis `firebase_bootstrap.dart`: `initFirebase()` try/catch → bool; `firebaseReadyProvider = Provider<bool>` (override false di test); selipkan di main SETELAH Hive (catch → lanjut lokal).
- **MIRROR**: ERROR_HANDLING (catch+appLog, tak ada throw ke UI).
- **GOTCHA**: Jangan init SEBELUM `ensureInitialized`. Provider kesiapan di-watch Profil/Detail untuk sembunyikan fitur backend.
- **VALIDATE**: analyze bersih; tanpa config (simulasikan dengan rename sementara — JANGAN commit) app tetap launch lokal.

### Task 2: Auth repository + provider + test pola

- **ACTION**: `AuthRepository` persis snippet Firebase 7.x: `initialize()` sekali (panggil di signIn bila belum), `authenticate()`, `idToken` → `signInWithCredential`. Tangani null (user batal → AppErr ramah) + ApiException-10. `AccountNotifier`: listen `authChanges()` (cancel di `ref.onDispose`), expose AccountState.
- **MIRROR**: REPOSITORY_PATTERN, STATE_PATTERN.
- **IMPORTS**: `firebase_auth`, `google_sign_in`, AppResult.
- **GOTCHA**: JANGAN pakai `signIn()`/`accessToken` (hilang di 7.x). `initialize()` wajib sebelum `authenticate()`.
- **VALIDATE**: analyze; login ASLI hanya manual (Task 8).

### Task 3: Watchlist sync (pure + service)

- **ACTION**: `mergeWatchlists(local: Map<id,Entry>, remote)`: per id pilih `updatedAt` terbaru; entry = {movieJson, updatedAtMs}. `WatchlistSyncService(repo Hive, firestore, uid)`: `syncOnLogin()` (pull users/{uid}/watchlist → merge → tulis balik keduanya), `pushToggle(movie, saved)` (set/delete doc). Model dokumen: `{...movie.toJson(), updatedAt: ms}`.
- **MIRROR**: REPOSITORY_PATTERN; TEST_STRUCTURE.
- **GOTCHA**: Field Firestore `updatedAt` int-ms (bukan Timestamp campur) agar merge deterministik. Offline write antre otomatis oleh SDK — jangan bikin antrean sendiri.
- **VALIDATE**: `test/sync_merge_test.dart`: lokal-menang, remote-menang, disjoint-union, hapus-vs-tua.

### Task 4: Review model + repository transaksi

- **ACTION**: `review.dart`: validasi rating 1-10, text trim ≤500 (potong, jangan tolak). `applyRatingSummary(old, myOld, myNew) → baru` pure. Repo: `upsertReview(movieId, uid, displayName, rating, text)` dalam `runTransaction`: baca summary + review lama → hitung → set keduanya. `listRecent` (orderBy updatedAt desc, limit 20), `deleteMyReview` (transaksi balik).
- **MIRROR**: ERROR_HANDLING (permission-denied → 'Tidak punya akses, coba login ulang').
- **GOTCHA**: Struktur: `movie_reviews/{movieId}` (summary) + `movie_reviews/{movieId}/reviews/{uid}`. Rules andalkan `request.auth.uid == uid` (lihat Task 6).
- **VALIDATE**: `test/review_test.dart`: math tambah/ubah/hapus, potong teks, tolak rating di repo (bukan model).

### Task 5: UI Profil + Review + wiring

- **ACTION**: ProfileScreen (Consumer): belum login → CTA + catatan lokal; login → avatar/nama/email, tombol Sync + status terakhir, list ulasan saya (Future, hapus per item), Logout. ReviewSection(movieId): watch summary (badge '★ 7.8 (12)') + 3 preview + tombol (login? sheet : arahkan /profile). ReviewSheet: slider + field + submit → invalidate providers. Router: branch `/profile` tab ke-4 (ikon person). Detail: sisip section. Watchlist provider: hook `sync.pushToggle` bila `account signedIn` (fire-and-forget + catch-log).
- **MIRROR**: Kontrak AppLoading/Error/Empty; Consumer sempit untuk badge; `context.mounted` pasca-await.
- **GOTCHA**: Jangan watch account di seluruh shell (cukup di Profil + tombol tulis).
- **VALIDATE**: analyze; demo-mode (firebaseReady=false): tab Profil tampil info lokal, tombol login disabled-beralasan.

### Task 6: firestore.rules + README setup

- **ACTION**: `firestore.rules`: users/{uid} + watchlist: owner-only RW; movie_reviews: read publik, tulis hanya `reviews/{request.auth.uid}` + validasi rating int 1-10 + text ≤500 + summary hanya via... (summary ditulis klien dalam transaksi SAMA — izinkan write summary bila uid login; catat keterbatasan di README). README: 10 langkah console + deploy rules + 'pakai project sendiri' (flutterfire configure ulang).
- **VALIDATE**: Rules lolos simulator console untuk 4 kasus (baca publik, tulis milikku, tulis milik orang→tolak, anon tulis→tolak).

### Task 7: Provider tests + gate akhir

- **ACTION**: Tulis 2 file test pure; `flutter analyze` + `flutter test` hijau.
- **VALIDATE**: Manual device keyed (butuh Task 0): login→avatar; toggle→muncul di console Firestore; tulis ulasan→avg berubah; logout→fitur lokal tetap; reinstall→login→watchlist kembali (sync). Catat di laporan.

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| avg tambah | {3.0,2}+8 | avg 4.67 count 3 | Tidak |
| avg ubah | {sum 14,count 3}, lama 8 → baru 10 | sum 16 | Ya |
| avg hapus | {sum 16,count 3} hapus 10 | sum 6 count 2; count 0 → avg 0 | Ya |
| teks >500 | 600 char | dipotong 500 | Ya |
| merge lokal-menang | local ts>remote | versi lokal | Ya |
| merge disjoint | A vs B | union | Tidak |
| hapus-vs-tua | delete tombstone? | Lihat gotcha | Ya — v1: hapus lokal tak push tombstone (dok RFB: hapus saat offline lalu login bisa muncul lagi; mitigasi: push delete saat online saja) |

### Edge Cases Checklist

- [ ] Tanpa config/backend: semua lokal, tanpa crash
- [ ] Login dibatalkan user → pesan ramah, tetap signedOut
- [ ] ApiException 10 → pesan SHA-1
- [ ] Tulis ulasan tanpa login → diarahkan Profil
- [ ] Offline: tulis antre SDK, terkirim saat online
- [ ] Hapus offline lalu login → bisa muncul lagi (keterbatasan terdokumentasi)

---

## Validation Commands

```powershell
flutter analyze
```

EXPECT: No issues found!

```powershell
flutter test
```

EXPECT: All pass (35 lama + ~8 baru).

### Manual Validation (butuh Task 0 + device)

- [ ] Login Google → nama/avatar di Profil
- [ ] Toggle watchlist → dokumen di console
- [ ] Tulis/ubah/hapus ulasan → avg + count benar
- [ ] Reinstall → login → watchlist pulih
- [ ] Rules simulator 4 kasus hijau

---

## Acceptance Criteria

- [ ] Task 0 selesai (file config ada) + Task 1-7 selesai
- [ ] analyze nol issue, test pass
- [ ] Login→sync→review terverifikasi di device + console
- [ ] Demo-mode tanpa backend tetap 100% lokal tanpa crash
- [ ] Tanpa secret di repo (service key HANYA di console, tak ada file)

## Completion Checklist

- [ ] API google_sign_in 7.x (initialize/authenticate/idToken) — tanpa API lama
- [ ] Transaksi summary benar untuk tambah/ubah/hapus
- [ ] SnackBar guarded mounted; Consumer sempit
- [ ] Rules ter-deploy dari `firestore.rules` repo
- [ ] README setup 10 langkah + mode lokal
- [ ] Self-contained

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Task 0 (console/SHA/flutterfire) belum dikerjakan | H | Total (blokir validasi) | Plan eksplisit sekuens; kode tetap compile (config hadir via CLI) |
| Kuota abuse project demo publik | M | Sedang | Rules ketat + SHA/package; rotasi project bila perlu (dok di README) |
| Transaksi summary race 2 device | L | Rendah | Transaksi Firestore menangani retry; last-writer konsisten |
| google_sign_in breaking lagi | L | Sedang | Kunci versi ter-resolve di laporan |

## Notes

- Tanpa Cloud Functions (transaksi klien cukup untuk skala portfolio).
- Struktur Firestore: `users/{uid}`, `users/{uid}/watchlist/{movieId}`, `movie_reviews/{movieId}` + `reviews/{uid}`.
- Keterbatasan hapus-offline didokumentasikan jujur (tanpa tombstone di v1).
