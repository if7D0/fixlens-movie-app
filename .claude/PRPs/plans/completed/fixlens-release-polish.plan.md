# Plan: FixLens Release Polish (Phase 5)

## Summary

Buat app layak rilis portfolio: ikon launcher + splash generatif, nama
"FixLens", signing release (debug-key APK langsung + jalur upload-keystore
untuk AAB Play), build apk/aab dengan TMDB key ter-bake, screenshot +
draf store listing, dan IAS konfig iOS sejauh mungkin tanpa Mac. Build ipa
tetap manual di Mac (lingkungan ini Windows — dinyatakan eksplisit).

## User Story

As a pemilik portfolio,
I want APK rilis berikon/splash resmi + draf listing yang bisa diunduh orang,
So that repo GitHub terlihat serius dan bisa diinstall tanpa cacat.

## Problem → Solution

Label `fixlens_movie_app` + ikon Flutter default + tanpa artefak rilis →
Identitas FixLens penuh + apk/aab rilis terverifikasi + dokumen listing.

## Metadata

- **Complexity**: Medium
- **Source PRD**: `.claude/PRPs/prds/fixlens-movie-app.prd.md`
- **PRD Phase**: 5 — iOS + polish
- **Estimated Files**: ~10 (3 config, 2 native edit, 2 docs, 2 asset-user, 1 keystore-manual)

---

## UX Design

### Before

Ikon robot Flutter, splash hitam polos, nama `fixlens_movie_app` di launcher.

### After

Ikon 🍿-brand (atau artwork owner), splash dark cinema + logo, nama
"FixLens". Alur dalam app TIDAK berubah (murni polish + artefak).

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| Launcher | Ikon/nama default | Ikon + "FixLens" | Android verified; iOS config-only |
| Cold start | Splash hitam | Splash brand (termasuk API Android 12) | preserve hingga frame pertama |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `pubspec.yaml` | 1-30 | version, description, tempat blok config generator |
| P0 | `android/app/src/main/AndroidManifest.xml` | 1-15 | `android:label` → "FixLens" |
| P1 | `android/app/build.gradle.kts` | all | SigningConfigs release + key.properties guard |
| P1 | `lib/main.dart` | bootstrap | Sisip preserve/remove splash di sekitar init |
| P2 | `ios/Runner/Info.plist` | display name keys | CFBundleDisplayName → FixLens |

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| launcher_icons | pub.dev + README upstream (0.14.x) | `flutter pub add dev:...`; config `flutter_launcher_icons:` (image 1024, adaptive fg/bg, `remove_alpha_ios`); run `dart run flutter_launcher_icons`. Commit hasil generate |
| native_splash | Blog 2026 + upstream | `flutter_native_splash:` (color/image/dark/android_12); `dart run flutter_native_splash:create`; `preserve()`/`remove()` di main; Android 12 butuh logo dalam lingkaran + padding |
| Release signing | developer.android.com | Upload keystore via keytool; `key.properties` gitignored; fallback debug-sign untuk APK portfolio |
| iOS tanpa Mac | Batasan alat | `ios:true` generate xcassets tanpa Xcode ✓; `flutter build ipa` HANYA di Mac → tandai manual |

---

## Patterns to Mirror

### NAMING_CONVENTION

```dart
// SOURCE: repo — assets/ belum ada; buat assets/icon/app_icon.png (1024,
// square, tanpa rounded) + assets/splash/logo.png (transparan, padding lega)
```

### ERROR_HANDLING / LOGGING

Tidak ada logika runtime baru kecuali preserve/remove splash (pola
try/finally agar splash tak nyangkut bila init gagal).

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `assets/icon/app_icon.png` (+fg) | CREATE (owner supply, Task 0) | Master 1024 untuk generator |
| `assets/splash/logo.png` (+android12) | CREATE (owner supply, Task 0) | Splash + API-12 circle-safe |
| `pubspec.yaml` | UPDATE | dev-deps 2 generator + 2 blok config + description + label versi |
| `android/app/src/main/AndroidManifest.xml` | UPDATE | label "FixLens" |
| `ios/Runner/Info.plist` | UPDATE | CFBundleDisplayName "FixLens" |
| `android/app/build.gradle.kts` | UPDATE | signingConfigs release baca key.properties bila ada, else debug |
| `android/key.properties` | CREATE (gitignored!) | Store/key passwords — JANGAN commit; sediakan `.example` |
| `lib/main.dart` | UPDATE | preserve sebelum init, remove setelah runApp scheduled |
| `store-listing.md` | CREATE | Judul + deskripsi ID/EN + fitur + catatan Data safety + atribusi TMDB |
| `README.md` | UPDATE | Bagian Install APK rilis + build command + catatan ipa |

## NOT Building

- Publish Play Store / App Store (butuh akun $25/Apple + review; hanya siapkan artefak + draf)
- Build `ipa` di sini (butuh Mac — didokumentasikan sebagai langkah manual)
- Ganti backend/key strategy (tetap: TMDB dart-define + Firebase demo)
- Fitur baru apa pun; hapus `temuan-*.jpg` (milik user, biarkan)

---

## Step-by-Step Tasks

### Task 0: Aset owner (MANUAL, pemblokir visual)

- **ACTION**: Minta owner taruh 2 file (atau setujui fallback): `assets/icon/app_icon.png` 1024×1024 square (simbol 🍿/film sederhana, tanpa teks kecil, tanpa rounded corner) dan `assets/splash/logo.png` (logo transparan + padding ≥25% tiap sisi untuk lingkaran Android 12). Fallback bila owner menolak: ikon huruf "F"背景深 + splash polos warna seed — catat di laporan sebagai placeholder.
- **VALIDATE**: Kedua file ada + terbaca (buka di viewer).

### Task 1: Ikon + splash generatif

- **ACTION**: `flutter pub add dev:flutter_launcher_icons dev:flutter_native_splash`; blok config di pubspec (android `launcher_icon` + adaptive fg/bg `#0E0E14`; ios true + remove_alpha_ios; splash color `#0E0E14`, image logo, dark sama, android_12 image+bg). Run generator; commit SEMUA file native hasil generate.
- **GOTCHA**: Adaptive fg harus glyph tengah 70-80% kanvas; Android 12 memotong lingkaran — padding lega wajib. iOS tolak alpha di ikon marketing.
- **VALIDATE**: `flutter analyze` bersih; ikon tampil di emulator launcher (atau `mipmap-*` + `AppIcon.appiconset` terisi).

### Task 2: Nama + splash lifecycle + versi

- **ACTION**: Manifest label → `FixLens`; Info.plist display name → `FixLens`; pubspec description → deskripsi portfolio 1 baris (tetap 1.0.0+1 untuk rilis pertama). main: `preserve()` setelah `ensureInitialized`, `remove()` pasca `runApp` via post-frame/finally (pola: preserve → try init → runApp → remove di addPostFrameCallback; catch → remove juga).
- **GOTCHA**: Tanpa remove, splash nyangkut bila init throw. Tanpa preserve, flicker hitam.
- **VALIDATE**: Cold start: splash brand → app, tanpa layar hitam/crash; analyze bersih.

### Task 3: Signing + build rilis

- **ACTION**: `android/key.properties` (gitignore!) + template `.example`; edit build.gradle.kts: bila file ada pakai upload-key, else fallback debug signing (dengan appLog/warning build). Buat upload keystore HANYA bila owner setuju (command keytool disediakan; password milik owner, tak dicatat): bila tidak, rilis = debug-signed (cukup untuk GitHub, TIDAK untuk Play).
- **GOTCHA**: Keystore hilang = tak bisa update app Play selamanya — backup di luar repo.
- **VALIDATE**: `flutter build apk --release --dart-define=TMDB_READ_TOKEN=...` sukses.

### Task 4: Artefak rilis + smoke device

- **ACTION**: Build `apk --release` (+`--split-per-abi` bila ukuran penting) DAN `appbundle --release`, keduanya dengan dart-define key (GOTCHA UTAMA: tanpa ini rilis jalan demo-mode!). Install APK rilis di device: cold start, quiz 1x, trailer 1x, watchlist toggle, login.
- **VALIDATE**: Semua smoke lolos di build rilis; catat ukuran file + sha (opsional) di laporan.

### Task 5: Listing + README + iOS handoff

- **ACTION**: `store-listing.md`: judul (≤30 char), short desc (≤80), full desc ID+EN, 2-8 screenshot placeholder (cara ambil: `flutter screenshot` / tombol HP), feature graphic 1024×500 (flag: butuh desain owner), Data safety: lokasi tidak dikumpulkan; Auth (nama/email/foto) + ulasan + watchlist tersimpan; TMDB atribusi. README: seksi unduh APK + build command + "ipa: butuh Mac (`flutter build ipa`)". iOS: pastikan `ios:true` ikon ter-generate + bundle id `com.fixlens.fixlens_movie_app` konsisten.
- **VALIDATE**: README render benar; aab ada; checklist iOS terdokumentasi jujur (untested tanpa Mac).

---

## Testing Strategy

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| Suite lama | `flutter test` | 57+ hijau (tanpa widget splash) | Regresi config |
| Cold start | install rilis | splash → home, tanpa stuck | Ya — init gagal (matikan wifi + hapus data?) |
| Demo rilis | build tanpa dart-define | banner demo (bukan crash) | Ya — gotcha key |

### Edge Cases Checklist
- [ ] Splash hilang normal saat init lambat/gagal
- [ ] Ikon adaptif tampil benar (bulat/jongkok launcher)
- [ ] Release tanpa key = demo, bukan crash
- [ ] iOS: hanya klaim config, bukan tested

---

## Validation Commands

```powershell
flutter analyze
```

EXPECT: No issues found!

```powershell
flutter build apk --release --dart-define=TMDB_READ_TOKEN=<key>
flutter build appbundle --release --dart-define=TMDB_READ_TOKEN=<key>
```

EXPECT: Kedua artefak sukses; smoke device lolos.

---

## Acceptance Criteria
- [ ] Task 0 aset ada (atau fallback tercatat)
- [ ] Ikon + splash tampil di device
- [ ] Nama FixLens di launcher + versi benar
- [ ] apk + aab rilis terbangun + smoke lolos
- [ ] store-listing.md + README lengkap dan jujur soal iOS

## Completion Checklist
- [ ] File generate ter-commit; secret (key.properties, .env) tidak
- [ ] Tanpa perubahan perilaku app
- [ ] Self-contained

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Owner tak sediakan artwork | M | Sedang (tampil generik) | Fallback huruf + catat |
| Keystore handling salah | M | Tinggi (Play update mati) | Default debug-sign; upload-key hanya bila diminta + backup |
| ipa tak teruji (tanpa Mac) | Pasti | Rendah (portfolio Android) | Dokumentasi jujur, config disiapkan |
| Lupa dart-define di rilis | M | Sedang (demo-mode) | Checklist + validasi banner di smoke |

## Notes
- Tanpa dep runtime baru (keduanya dev-only).
- Setelah Fase 5: seluruh PRD complete → rilis GitHub (tag v1.0.0 + upload APK disarankan).
