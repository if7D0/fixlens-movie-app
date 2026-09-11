# FixLens Movie App

Rekomendasi film berbasis mood — bukan sekadar trending. Jawab 3 pertanyaan
singkat, dapat 3 rekomendasi yang cocok dalam <1 menit.

> This product uses the TMDB API but is not endorsed or certified by TMDB.

## Status fase

| #   | Fase                 | Status   |
| --- | -------------------- | -------- |
| 1   | Foundation           | complete |
| 2   | Discovery + Detail   | complete |
| 3   | Mood + Watchlist MVP | complete |

## Cara pakai quiz

Tap kartu "Find by Mood" di Home → jawab 3 pertanyaan (mood, teman nonton,
durasi) → 3 rekomendasi tampil beserta alasan. Tap film untuk detail, ikon
bookmark untuk simpan ke watchlist.
| 4   | Backend (opsional)   | pending  |
| 5   | iOS + polish         | pending  |

## Mode demo

Tanpa TMDB key aplikasi tetap jalan: banner "Demo mode" tampil di Home dan
setiap section data menampilkan pesan yang sama. Tidak ada request jaringan
yang dikirim dan tidak ada crash — tambah key sesuai langkah di bawah untuk
data live (rail Trending/Populer, search + filter, detail + trailer).

## Prasyarat

- Flutter 3.44+ (`flutter --version`)
- Android SDK + terima lisensi sekali: `flutter doctor --android-licenses`
- Satu device Android (fisik atau emulator)

## Clone lalu jalan (tanpa setup manual)

```powershell
git clone <url-repo-anda>
cd fixlens-movie-app
flutter pub get
flutter run
```

Aplikasi jalan dalam **demo mode** (banner di Home) sampai token TMDB
dikonfigurasi. Tidak ada langkah wajib lain.

## Menambah TMDB key (gratis)

1. Daftar dan ambil **v4 read access token** di
   <https://www.themoviedb.org/settings/api> (gratis).
2. Pilih salah satu cara (urutan prioritas):
   - `flutter run --dart-define=TMDB_READ_TOKEN=token_anda` (direkomendasikan),
   - atau salin `.env.example` menjadi `.env` lalu isi `TMDB_READ_TOKEN`.
3. Jangan pernah commit file `.env` (sudah ada di `.gitignore`).

## Perintah validasi

```powershell
flutter analyze   # harus: No issues found!
flutter test      # harus: All tests passed!
```

## Batasan saat ini

- Target: **Android** (iOS menyusul Fase 5). Web/Windows **tidak didukung**
  (`youtube_player_flutter`/`sqflite` tidak andal di sana).
- Fase 1 = scaffold + infra saja: data TMDB, quiz, dan watchlist hadir di
  Fase 2-3.

## Troubleshooting

| Gejala                                            | Solusi                                                                 |
| ------------------------------------------------- | ---------------------------------------------------------------------- |
| `Android license status unknown`                  | `flutter doctor --android-licenses`, terima semua                      |
| Build Gradle gagal `Unsupported class file major` | AGP butuh JDK 17: set `org.gradle.java.home` ke JDK 17                |
| Banner "Demo mode"                                | Normal tanpa token — tambah key sesuai langkah di atas                 |
| `flutter create` menolak dir non-kosong           | Pindahkan `.claude/` sementara, run create, kembalikan                 |
