# Plan: FixLens Foundation (Scaffold + Infra)

## Summary

Scaffold aplikasi Flutter greenfield di folder ini (Android-first, package `fixlens_movie_app`, org `com.fixlens`) lengkap dengan state management (Riverpod), navigasi (go_router bottom nav 3 tab + rute detail placeholder), tema dark cinema Material3, config API key (dart-define + .env fallback), inisialisasi Hive CE, shared loading/empty/error widgets, smoke test, dan README clone-to-run. Output: `flutter analyze` 0 issue + app jalan di emulator.

## User Story

As a solo dev pemilik repo portfolio,
I want scaffold Flutter yang langsung bisa di-clone dan `flutter run` tanpa setup manual,
So that Fase 2-3 bisa dibangun di atas fondasi yang sudah benar (routing, theme, config, storage init).

## Problem → Solution

Folder kosong (hanya `.claude/`) → Aplikasi Flutter runnable dengan infra fondasi (router/theme/config/storage-init) + pola kode yang dikunci untuk fase berikutnya.

## Metadata

- **Complexity**: Medium
- **Source PRD**: `.claude/PRPs/prds/fixlens-movie-app.prd.md`
- **PRD Phase**: 1 — Foundation
- **Estimated Files**: ~18 (semua CREATE, greenfield)

---

## UX Design

### Before

```
┌─────────────────────────────┐
│  Folder fixlens-movie-app/  │
│  hanya berisi .claude/      │
│  Tidak ada app.             │
└─────────────────────────────┘
```

### After

```
┌─────────────────────────────┐
│ FixLens AppBar              │
├─────────────────────────────┤
│                             │
│  Placeholder per tab:       │
│  Home / Search / Watchlist  │
│  (+ rute /movie/:id kosong) │
│                             │
├─────────────────────────────┤
│ Home │ Search │ Watchlist   │  <- bottom nav
└─────────────────────────────┘
```

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| App launch | N/A | Splash → Home tab, theme dark | Placeholder text per layar |
| Bottom nav | N/A | 3 tab switch tanpa reload | StatefulShellRoute |
| Missing API key | N/A | Banner kecil "Demo mode — key belum dikonfigurasi" di Home | Non-blocking; detail di Task 6 |

---

## Mandatory Reading

Greenfield — tidak ada file internal untuk dibaca. Yang WAJIB dibaca sebelum implementasi adalah dokumentasi paket berikut (baca README/Changelog pub.dev saat eksekusi, karena API berubah — contoh: `youtube_player_flutter` 10.x rewrite, tapi itu Fase 2):

| Priority | File/Doc | Why |
|---|---|---|
| P0 | `go_router` README — `StatefulShellRoute.indexedStack` | Pola bottom nav yang dipakai |
| P0 | `flutter_riverpod` README — `ProviderScope`, `ConsumerWidget` | Pola state/UI yang dipakai |
| P0 | `hive_ce_flutter` README — `Hive.initFlutter()`, `openBox` | Init storage; JANGAN pakai paket `hive` original |
| P1 | `flutter_dotenv` README + `String.fromEnvironment` docs | Strategi key: dart-define primer, .env fallback |
| P2 | Referensi `github.com/aydozy/popcorn` (struktur `data/domain/presentation` + `get_it`) dan `github.com/MuhammadAhmadRao/ViewVibe` (Riverpod + sqflite + trailer) | Inspirasi struktur folder; kita pakai varian ringan (lihat Patterns) |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| Hive original mati → pakai Hive CE | luci-studio.com blog 2026-06 + pub.dev/packages/hive_ce (v2.19.3) | `hive`/`isar` original = legacy. Pakai `hive_ce` + `hive_ce_flutter`. Import `package:hive_ce/hive_ce.dart`, BUKAN `package:hive/...` |
| youtube_player_flutter 10.x breaking (Mei 2026) | pub.dev changelog 10.0.0/10.0.1 | Rewrite di atas `youtube_player_iframe`; `YoutubePlayerBuilder` dihapus; flags pindah ke controller; min Flutter 3.38 (kita 3.44.6 ✓). Relevan Fase 2 — JANGAN ikut tutorial lama |
| youtube player tanpa API key | pub.dev youtube_player_iframe 6.0.2 | iFrame API resmi, tanpa YouTube key, support Android/iOS/macOS/Web |
| TMDB v3 API | developer.themoviedb.org | Discover (`with_genres`, `vote_average.gte`), `append_to_response=credits,videos,similar` — relevan Fase 2 |

---

## Patterns to Mirror

Greenfield: pola di bawah ini DITETAPKAN oleh plan ini dan wajib diikuti fase-fase berikutnya. (SOURCE: ditetapkan plan ini — bukan contoh codebase.)

### NAMING_CONVENTION

```dart
// files: snake_case (home_screen.dart); classes: PascalCase (HomeScreen)
// providers: camelCase + 'Provider' suffix (tmdbClientProvider)
// routes: '/home', '/search', '/watchlist', '/movie/:id'
```

### ERROR_HANDLING

```dart
// SOURCE: ditetapkan plan ini — pakai sealed result untuk semua call data (Fase 2+)
sealed class AppResult<T> {
  const AppResult();
}
final class AppOk<T> extends AppResult<T> {
  final T data; const AppOk(this.data);
}
final class AppErr<T> extends AppResult<T> {
  final String message; const AppErr(this.message);
}
// UI: AppErr -> AppError widget (Task 9). Tidak ada throw mentah ke UI.
```

### LOGGING_PATTERN

```dart
// SOURCE: ditetapkan plan ini — hanya debugPrint terkondisi, tanpa paket logger di Fase 1
import 'package:flutter/foundation.dart';
void appLog(String msg) {
  if (kDebugMode) debugPrint('[FixLens] $msg');
}
```

### REPOSITORY_PATTERN (disiapkan untuk Fase 2, tidak diimplementasi penuh di sini)

```dart
// SOURCE: ditetapkan plan ini — UI -> Riverpod provider -> Repository -> dio client
// lib/src/features/<fitur>/data/<fitur>_repository.dart
// Repository mengembalikan AppResult<T>. Tidak ada dio di widget.
```

### STATE_PATTERN

```dart
// SOURCE: ditetapkan plan ini
// - Global/app-wide: Riverpod Provider/StateNotifierProvider
// - Lokal layar: StatefulWidget biasa. Jangan angkat state lokal ke provider.
import 'package:flutter_riverpod/flutter_riverpod.dart';
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const Placeholder();
}
```

### TEST_STRUCTURE

```dart
// SOURCE: ditetapkan plan ini — test/smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fixlens_movie_app/main.dart' as app; // sesuaikan dengan bootstrap
void main() {
  testWidgets('app launches with bottom nav', (tester) async {
    await tester.pumpWidget(const app.FixLensApp());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
  });
}
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `pubspec.yaml` | UPDATE (via `flutter pub add`) | Tambah deps Fase 1 |
| `lib/main.dart` | CREATE (overwrite hasil scaffold) | Bootstrap: dotenv → Hive → ProviderScope → runApp |
| `lib/src/app/app.dart` | CREATE | FixLensApp (MaterialApp.router + theme) |
| `lib/src/core/config/app_config.dart` | CREATE | Baca TMDB token (dart-define primer, .env fallback) + flag isConfigured |
| `lib/src/core/theme/app_theme.dart` | CREATE | Dark cinema theme Material3 |
| `lib/src/core/router/app_router.dart` | CREATE | go_router + StatefulShellRoute 3 tab + `/movie/:id` placeholder |
| `lib/src/core/utils/app_log.dart` | CREATE | Logger terkondisi (Logging pattern) |
| `lib/src/core/result/app_result.dart` | CREATE | Sealed AppResult (siapkan Fase 2) |
| `lib/src/shared/widgets/app_loading.dart` | CREATE | Loading state standar |
| `lib/src/shared/widgets/app_empty.dart` | CREATE | Empty state standar |
| `lib/src/shared/widgets/app_error.dart` | CREATE | Error + tombol retry standar |
| `lib/src/features/home/presentation/home_screen.dart` | CREATE | Tab Home placeholder (+ banner demo-mode) |
| `lib/src/features/search/presentation/search_screen.dart` | CREATE | Tab Search placeholder |
| `lib/src/features/watchlist/presentation/watchlist_screen.dart` | CREATE | Tab Watchlist placeholder |
| `lib/src/features/detail/presentation/detail_screen.dart` | CREATE | Rute `/movie/:id` placeholder (isi penuh Fase 2) |
| `test/smoke_test.dart` | CREATE | App launch + bottom nav ada |
| `.env.example` | CREATE | Template key tanpa secret |
| `.gitignore` | UPDATE | Pastikan `.env` ter-ignore |
| `README.md` | CREATE (overwrite hasil scaffold) | Clone-to-run + key strategy + atribusi TMDB |

## NOT Building

- Pemanggilan API TMDB apa pun (Fase 2)
- Quiz mood, mapping genre, watchlist logic (Fase 3)
- Trailer YouTube / `youtube_player_flutter` (Fase 2)
- Login/backend/review sosial/iOS (Fase 4-5)
- Launcher icon custom, splash native, flavor prod/dev (Fase 5)
- `cached_network_image`, `dio` (ditunda ke Fase 2 agar pubspec Fase 1 ramping)

---

## Step-by-Step Tasks

### Task 1: Prereq lisensi Android (manual, sekali saja)

- **ACTION**: Jalankan `flutter doctor --android-licenses` dan terima semua lisensi.
- **IMPLEMENT**: Perintah di atas; verifikasi dengan `flutter doctor` (kategori Android toolchain tanpa error lisensi).
- **GOTCHA**: Tanpa ini `flutter run`/`build` gagal walau kode benar. Ini blocker yang sudah terdeteksi di PRD.
- **VALIDATE**: `flutter doctor` → tidak ada baris "Android license status unknown".

### Task 2: Scaffold Flutter di folder ini

- **ACTION**: Generate proyek Flutter in-place dengan org dan nama paket yang benar.
- **IMPLEMENT**: Dari folder ini jalankan:
  ```powershell
  flutter create --org com.fixlens --project-name fixlens_movie_app --platforms android,ios .
  ```
- **GOTCHA**: Folder berisi `.claude/` (hidden). Jika `flutter create` menolak karena direktori tidak kosong: pindahkan `.claude/` sementara ke luar folder, run create, kembalikan `.claude/`. Jangan hapus `.claude/`.
- **GOTCHA**: Nama folder ber-hyphen (`fixlens-movie-app`) tidak valid sebagai package — itu sebabnya `--project-name fixlens_movie_app` (underscore) wajib.
- **VALIDATE**: `pubspec.yaml` ada dengan `name: fixlens_movie_app`; `android/` dan `ios/` ter-generate; `flutter --version` tetap 3.44.x.

### Task 3: Tambah dependensi Fase 1

- **ACTION**: Tambah deps via `flutter pub add` (resolve versi terbaru yang kompatibel — jangan hardcode versi di plan).
- **IMPLEMENT**:
  ```powershell
  flutter pub add flutter_riverpod go_router flutter_dotenv hive_ce hive_ce_flutter
  ```
- **MIRROR**: STATE_PATTERN (Riverpod), router via go_router (Mandatory Reading P0).
- **GOTCHA**: JANGAN tambah paket `hive` (original, legacy) atau `isar`. JANGAN tambah `webview_flutter` manual (nanti diekspor otomatis oleh youtube player di Fase 2).
- **IMPORTS**: (dipakai di task berikutnya) `flutter_riverpod`, `go_router`, `flutter_dotenv`, `hive_ce_flutter`.
- **VALIDATE**: `flutter pub get` sukses; `pubspec.yaml` berisi kelima paket; catat versi ter-resolve untuk laporan.

### Task 4: Struktur folder + fondasi core

- **ACTION**: Buat struktur folder dan file core.
- **IMPLEMENT**: Buat tree:
  ```
  lib/src/app/  lib/src/core/{config,theme,router,utils,result}/
  lib/src/shared/widgets/  lib/src/features/{home,search,watchlist,detail}/presentation/
  ```
  Lalu tulis `app_result.dart` (sealed AppResult — snippet di Patterns) dan `app_log.dart` (`appLog` — snippet di Patterns).
- **MIRROR**: ERROR_HANDLING, LOGGING_PATTERN, NAMING_CONVENTION.
- **GOTCHA**: Tanpa barrel file (`export`) di Fase 1 — import langsung per file untuk hindari churn export.
- **VALIDATE**: `flutter analyze` tanpa error (warning unused import = perbaiki).

### Task 5: Tema + shared widgets

- **ACTION**: Tulis `app_theme.dart` (dark cinema, Material3, `ColorScheme.fromSeed` seed deep-purple/charcoal + `useMaterial3: true`) dan tiga widget: `AppLoading` (Center + CircularProgressIndicator), `AppEmpty` (icon + title + subtitle), `AppError` (icon + message + ElevatedButton retry dengan `VoidCallback onRetry`).
- **MIRROR**: NAMING_CONVENTION. Ketiga widget adalah kontrak UI untuk Fase 2-3 — jangan ubah signature tanpa update plan.
- **VALIDATE**: `flutter analyze` bersih.

### Task 6: Konfigurasi API key

- **ACTION**: Tulis `AppConfig` + `.env.example` + update `.gitignore`.
- **IMPLEMENT**: `app_config.dart`:
  ```dart
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  abstract final class AppConfig {
    static const _dartDefineKey = 'TMDB_READ_TOKEN';
    static const String _demoToken = 'DEMO_TOKEN_REPLACE_ME';
    static String get tmdbReadToken {
      const fromDefine = String.fromEnvironment(_dartDefineKey);
      if (fromDefine.isNotEmpty) return fromDefine;
      return dotenv.env['TMDB_READ_TOKEN'] ?? _demoToken;
    }
    static bool get isConfigured => tmdbReadToken != _demoToken;
  }
  ```
  `.env.example` berisi `TMDB_READ_TOKEN=isi_dengan_token_baca_TMDB_v4_anda`. `.gitignore` tambah baris `.env`.
- **MIRROR**: Keputusan PRD "demo key bundle + override".
- **GOTCHA**: Jangan commit file `.env` asli. Token demo default (`DEMO_TOKEN_REPLACE_ME`) membuat app jalan dalam "demo mode" (banner) sampai owner menaruh token real via `--dart-define` atau `.env` lokal.
- **VALIDATE**: `isConfigured == false` secara default; dengan `--dart-define=TMDB_READ_TOKEN=x` (saat run) menjadi true.

### Task 7: Router + layar placeholder

- **ACTION**: Tulis `app_router.dart` (GoRouter + `StatefulShellRoute.indexedStack`, 3 branch: `/home`, `/search`, `/watchlist`) + rute `/movie/:id` (detail placeholder terima `id` via `state.pathParameters`) + 4 screen placeholder (Scaffold + AppBar + teks judul). Home menampilkan banner demo-mode bila `!AppConfig.isConfigured`.
- **MIRROR**: STATE_PATTERN (`ConsumerWidget`), NAMING_CONVENTION (path route).
- **IMPORTS**: `package:go_router/go_router.dart`, `package:flutter_riverpod/flutter_riverpod.dart`.
- **GOTCHA**: Ikuti README go_router versi terinstal (API `StatefulShellRoute` stabil, tapi cek nama konstruktor bila versi mayor berubah).
- **VALIDATE**: Navigasi tab tidak me-reset state tab lain (indexedStack); deep route `/movie/550` render tanpa crash.

### Task 8: Bootstrap main.dart

- **ACTION**: Overwrite `lib/main.dart` + `lib/src/app/app.dart`.
- **IMPLEMENT**: Urutan bootstrap WAJIB: `WidgetsFlutterBinding.ensureInitialized()` → `await dotenv.load(isOptional: true)` → `await Hive.initFlutter()` → `runApp(ProviderScope(child: FixLensApp()))`. `FixLensApp extends ConsumerWidget`, `MaterialApp.router(routerConfig: appRouter, theme: AppTheme.dark, ...)`.
- **IMPORTS**: `flutter_dotenv`, `hive_ce_flutter`, `flutter_riverpod`.
- **GOTCHA**: `dotenv.load` harus `isOptional: true` agar app tetap jalan tanpa file `.env` (demo mode). `Hive.initFlutter()` tanpa openBox di Fase 1 (box dibuka Fase 3).
- **VALIDATE**: App launch tanpa exception; matikan-relock tidak relevan (belum ada data).

### Task 9: Smoke test

- **ACTION**: Tulis `test/smoke_test.dart` sesuai snippet TEST_STRUCTURE (sesuaikan nama class app hasil implementasi).
- **MIRROR**: TEST_STRUCTURE.
- **VALIDATE**: `flutter test` semua pass.

### Task 10: README clone-to-run

- **ACTION**: Overwrite `README.md`: deskripsi 3 baris + atribusi "This product uses the TMDB API but is not endorsed or certified by TMDB." + langkah: prereq (Flutter 3.44+, accept licenses), `git clone`, `flutter pub get`, cara jalan (`flutter run`, opsi `--dart-define=TMDB_READ_TOKEN=...` atau copy `.env.example`→`.env`), cara dapat token TMDB gratis, tabel status fase, bagian troubleshooting (lisensi, Java/Gradle, minSdk).
- **GOTCHA**: Sebutkan batasan: Android (dan iOS menyusul Fase 5); Web/Windows tidak didukung.
- **VALIDATE**: Orang baru bisa run hanya dengan ikut README (validasi mental per langkah).

### Task 11: Validasi akhir Fase 1

- **ACTION**: Jalankan berurutan: `flutter analyze`, `flutter test`, `flutter run` di emulator/device Android.
- **IMPLEMENT**: Perbaiki semua analyze issue (target NOL). Verifikasi `android/app/build.gradle.kts` (atau `.gradle`) `minSdk >= 20` (syarat future youtube player); naikkan bila di bawah itu.
- **GOTCHA**: Jika build Gradle gagal dengan error versi Java ("Unsupported class file major version") — Java mesin adalah 20 sedangkan AGP butuh 17: set `org.gradle.java.home` ke JDK 17 di `android/gradle.properties` atau via JAVA_HOME saat build. Catat solusi yang dipakai di Notes plan/implementasi.
- **VALIDATE**: analyze 0 issue, test pass, app tampil 3 tab di emulator. Gate PRD Fase 1 terpenuhi.

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| AppConfig default | tanpa dart-define/.env | `isConfigured == false` | Ya — demo mode |
| AppConfig override | dart-define terisi | `isConfigured == true` | Tidak |

### Widget Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| Smoke launch | pump FixLensApp | Bottom nav 3 tab tampil | Tidak |
| Demo banner | `isConfigured == false` | Banner tampil di Home | Ya |

### Edge Cases Checklist

- [ ] Tanpa `.env` (dotenv optional) — app tetap jalan
- [ ] Tanpa token — banner demo, bukan crash
- [x] N/A Fase 1: empty network, invalid types, concurrent (relevan Fase 2-3)

---

## Validation Commands

### Static Analysis

```powershell
flutter analyze
```

EXPECT: No issues found (nol).

### Unit Tests

```powershell
flutter test
```

EXPECT: All tests pass.

### Manual Validation

- [ ] `flutter run` di emulator Android: 3 tab tampil, theme dark
- [ ] Pindah tab Home→Search→Watchlist: state tab tidak reset
- [ ] Buka route `/movie/550` (via temp button atau deep link): placeholder tampil tanpa crash
- [ ] Tanpa `.env`: banner demo-mode tampil, app tidak crash
- [ ] `minSdk >= 20` terverifikasi di config Android

---

## Acceptance Criteria

- [ ] Semua 11 task selesai
- [ ] `flutter analyze` nol issue
- [ ] `flutter test` pass
- [ ] App run di emulator Android dengan 3 tab + rute detail placeholder
- [ ] `.env` ter-ignore; `.env.example` ada; README clone-to-run lengkap
- [ ] Tidak ada dependensi Fase 2/3 yang bocor ke pubspec (dio, youtube player, dsb.)

## Completion Checklist

- [ ] Import `hive_ce`, bukan `hive`
- [ ] `dotenv.load(isOptional: true)`
- [ ] Tidak ada secret ter-commit
- [ ] Pola (AppResult/appLog/shared widgets/route paths) sesuai plan untuk dipakai Fase 2-3
- [ ] Versi paket ter-resolve dicatat di laporan implementasi
- [ ] Self-contained — implementasi tanpa riset tambahan

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `flutter create` menolak dir non-kosong (akibat `.claude/`) | M | Rendah | Pindahkan `.claude/` sementara, kembalikan setelahnya (Task 2) |
| Java 20 vs Gradle/AGP butuh JDK 17 | M | Sedang (build gagal) | Set `org.gradle.java.home` ke JDK 17; catat solusi (Task 11) |
| API go_router versi baru berubah | L | Rendah | Baca README versi terinstal saat eksekusi (Task 7) |
| Hive CE maintenance komunitas | L (untuk Fase 1, hanya init) | Rendah | Pemakaian Fase 1 minimal (init saja); evaluasi ulang bila bermasalah di Fase 3 |

## Notes

- Keputusan terkunci (delegasi user): Riverpod (bukan Bloc — boilerplate lebih ringan untuk solo dev), `go_router`, `dio`+`cached_network_image`+`youtube_player_flutter` ditunda Fase 2, Hive CE JSON-maps tanpa codegen (hindari `build_runner` di Fase 1).
- Struktur folder mengacu varian ringan ViewVibe (`features/.../presentation|data`, `core/`, `shared/`), bukan full Clean Architecture popcorn (overkill untuk MVP solo).
- Setelah Fase 1 complete: update status Fase 1 di PRD menjadi `complete` sebelum plan Fase 2.
