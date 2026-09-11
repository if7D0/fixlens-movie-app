# FixLens Movie App

## Problem Statement

Penonton solo (sekunder: pasangan dengan mood sama), usia 18-30, menghabiskan waktu scroll lama lalu tidak jadi nonton, karena rekomendasi monoton — trending/FOMO yang sama di semua platform. Cost: decision fatigue dan malam tanpa tontonan.

## Evidence

- User quote: "Scroll berlama-lama tapi tidak jadi nonton, rekomendasi juga hal yang sama, serupa, dan monoton."
- User quote: orang "hanya menonton film kalau film itu sedang trending atau mereka terlihat fomo."
- Market evidence: WatchPulse ("No more scrolling half an hour and picking nothing"), Qouch Potato ("watch decision in under a minute"), Moodflix / MoodPick / Cinento / MoodMoviePicker — semuanya memvalidasi pain scroll-fatigue yang sama.
- Assumption - needs validation through uji 5-user: "FOMO adalah driver utama; mood-matching mengurangi scroll time." Metode: ukur time-to-3-picks sebelum/sesudah quiz.

## Proposed Solution

Aplikasi Flutter (Dart), Android-first, berbasis TMDB gratis: quiz "mood finder" 3 pertanyaan dengan mapping manual mood→genre ke endpoint Discover (`with_genres` + `vote_average.gte`) menghasilkan 3 rekomendasi + alasan "kenapa cocok", dilanjutkan detail (cast, trailer YouTube embed, film terkait) dan watchlist lokal persisten. Tanpa AI/LLM, tanpa backend di v1. API demo key ter-bundle dengan override agar clone langsung jalan.

## Key Hypothesis

We believe quiz mood 3 pertanyaan akan mengurangi scroll-fatigue untuk penonton solo.
We'll know we're right when user mendapat 3 rekomendasi <1 menit dari buka app (diukur via uji manual 5 skenario mood).

## What We're NOT Building

- AI LLM / Gemini/Claude recommender - butuh backend, API key, dan biaya; mapping manual cukup per keputusan user
- Info streaming JustWatch per-region - kompleksitas region dan lisensi; di luar kebutuhan portfolio v1
- Windows support - target Android (+iOS later); `youtube_player_flutter`/`sqflite` tidak andal di Web/Windows
- Login/backend, review sosial ala Letterboxd, iOS support - deferred ke Fase 4-5, bukan dibatalkan (lindungi MVP solo-dev + clone-to-run)

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| Time-to-3-picks via quiz | <60 detik | Uji manual stopwatch, 5 skenario mood |
| Clone-to-run tanpa error di Android | 100% pada mesin teruji | `flutter pub get` + `flutter run` di 1 device fisik + 1 emulator |
| Watchlist persist across restart | 100% | Kill + relaunch, cek Hive/sqflite |
| Crash-free quiz→detail flow + analyze bersih | 0 crash, 0 analyze issue | Uji manual + `flutter analyze` |

## Open Questions

- [x] Mapping mood→genre manual — disetujui, tabel final divalidasi 5 user saat implementasi
- [x] API key demo (v4 read-token default + `--dart-define` override, rotate oleh owner repo) — disetujui
- [x] `flutter doctor --android-licenses` harus di-run sebelum build pertama — disetujui
- [x] Komparasi side-by-side = Could, bukan Must — disetujui
- [x] Tambahan non-AI (alasan cocok per kartu, filter durasi max, mode pasangan sebagai Could) — disetujui, tanpa AI

---

## Users & Context

**Primary User**
- **Who**: Penonton 18-30, nonton solo di HP Android malam hari; sekunder: pasangan dengan mood yang sama.
- **Current behavior**: Scroll Netflix/TikTok/IMDb, ikut yang trending/FOMO, sering batal nonton.
- **Trigger**: Momen "Malam ini nonton apa?" dalam kondisi lelah/galau/santai.
- **Success state**: Pilih 1 film <1 menit, masuk watchlist atau langsung tonton trailer.

**Job to Be Done**
When malam ini mau nonton sendiri dan lagi badmood/lelah, I want jawab 3 pertanyaan mood sederhana, so I can dapat 3 rekomendasi yang cocok dalam <1 menit tanpa scroll.
(DRAFT — asumsi berbasis jawaban user, perlu validasi uji 5-user.)

**Non-Users**
Cinephile hardcore yang sudah settled di Letterboxd dan butuh review sosial mendalam; anak (butuh parental control); pencari info streaming per-region. Mereka diabaikan di v1 agar fokus pada decision-maker ringan.

---

## Solution Detail

### Core Capabilities (MoSCoW)

| Priority | Capability | Rationale |
|----------|------------|-----------|
| Must | Quiz mood 3 pertanyaan → 3 rekomendasi + alasan cocok | Core differentiator, menguji hipotesis |
| Must | Detail: cast, trailer YouTube embed, film terkait | Tindakan atas rekomendasi; ekspektasi dasar pengguna |
| Must | Watchlist persisten (Hive/sqflite) + badge/undo | Sinyal sukses #2; retensi tanpa backend |
| Should | Search + filter multi-genre & rating minimum | Fallback saat quiz kurang; satu endpoint Discover yang sama |
| Should | Filter durasi max (time-boxed) | Pola Moodflix terbukti; effort rendah |
| Could | Komparasi 2 film side-by-side (rating/popularitas) | Differentiator lemah; effort rendah |
| Could | Mode pasangan (irisan 2 mood) | Scope sekunder yang diminta user |
| Won't (v1) | AI LLM, JustWatch per-region, Windows, login/backend, review sosial, iOS | Lihat "What We're NOT Building"; login/review/iOS → Fase 4-5 |

### MVP Scope

Quiz (3 pertanyaan, 8-10 mood tiles) + mapping manual mood→genre + Home/Detail/Watchlist/Search-dasar + trailer embed + `.env.example` + demo key default + README clone-to-run + `flutter analyze` bersih. Tanpa auth, tanpa backend, tanpa iOS. Inilah versi minimum yang bisa menguji hipotesis <1 menit.

### User Flow

Buka app → (onboarding 1x) → pilih "Find by Mood" → jawab 3 pertanyaan (~20 detik) → lihat 3 kartu + alasan cocok → tap kartu → Detail (trailer/cast/terkait) → save ke Watchlist → selesai (<60 detik). Jalur fallback: Search → filter genre/rating → Detail → Watchlist.

---

## Technical Approach

**Feasibility**: HIGH

**Architecture Notes**
- Flutter 3.44.6 stable / Dart 3.12.2 (terdeteksi di mesin user), Android SDK 37, target Android-first; struktur folder siap iOS (fase later), Web/Windows eksplisit tidak didukung.
- Networking: `dio` atau `http` + interceptor bearer; state: kunci 1 pilihan (`flutter_bloc` ATAU `riverpod`) saat planning Fase 1; navigasi `go_router`; gambar `cached_network_image`; video `youtube_player_flutter` (iFrame, tanpa YouTube API key, butuh minSdk 20 — aman dengan default Flutter baru).
- Data TMDB: `GET /discover/movie?with_genres=A,B&vote_average.gte=X` untuk quiz/search; `GET /movie/{id}?append_to_response=credits,videos,similar` untuk detail; `cached` genre backdrop bila perlu.
- Persistensi: Hive (ringan) atau sqflite untuk watchlist + flag onboarding; `flutter_dotenv` + `--dart-define` untuk key.
- Key strategy (disetujui user): bundle demo v4 read-token sebagai default agar clone langsung jalan + override via `--dart-define`/`.env`; jangan commit `.env` asli; tampilkan error state jelas saat 401/kuota; owner repo bertanggung jawab rotate jika di-revoke.
- Referensi terbukti: `aydozy/popcorn` (Bloc+Hive), `MuhammadAhmadRao/ViewVibe` (Riverpod+sqflite+`youtube_player_flutter`), `suleohis/flicknova` (Riverpod+Isar).

**Technical Risks**

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Demo key terekspos/di-revoke | M | Token read-only, dokumentasi rotate 5 menit, override via dart-define |
| Android licenses belum accepted | H | Run `flutter doctor --android-licenses` sebelum build pertama |
| Trailer gagal (no network/WebView) | M | Thumbnail fallback + buka app YouTube via intent + offline state |
| Scope creep (backend/iOS dini) | M | Kunci Fase 1-3 tanpa backend; gate review sebelum Fase 4 |

---

## Implementation Phases

<!--
  STATUS: pending | in-progress | complete
  PARALLEL: phases that can run concurrently (e.g., "with 3" or "-")
  DEPENDS: phases that must complete first (e.g., "1, 2" or "-")
  PRP: link to generated plan file once created
-->

| # | Phase | Description | Status | Parallel | Depends | PRP Plan |
|---|-------|-------------|--------|----------|---------|----------|
| 1 | Foundation | Scaffold Flutter, DI, router, theme, dotenv, analyze bersih, README skeleton | complete | - | - | plan: `.claude/PRPs/plans/completed/fixlens-foundation.plan.md`; report: `.claude/PRPs/reports/fixlens-foundation-report.md` |
| 2 | Discovery+Detail | TMDB discover/search/detail/credits/videos/similar + trailer embed | complete | - | 1 | plan: `.claude/PRPs/plans/completed/fixlens-discovery-detail.plan.md`; report: `.claude/PRPs/reports/fixlens-discovery-detail-report.md` |
| 3 | Mood+Watchlist (MVP gate) | Quiz 3Q + mapping + alasan + filter durasi + watchlist Hive + time-to-pick <60s | complete | - | 2 | plan: `.claude/PRPs/plans/completed/fixlens-mood-watchlist.plan.md`; report: `.claude/PRPs/reports/fixlens-mood-watchlist-report.md` |
| 4 | Backend-optional | Login + sync + review sosial (hanya jika MVP valid) | pending | with 5 | 3 | - |
| 5 | iOS + polish | iOS build, icon/splash, release apk/aab, store listing | pending | with 4 | 3 | - |

### Phase Details

**Phase 1: Foundation**
- **Goal**: Repo bisa di-clone dan `flutter run` jalan di Android tanpa setup manual.
- **Scope**: Template app, config key (default+override), error/empty/loading states, README clone-to-run.
- **Success signal**: `flutter analyze` 0 issue + run di emulator.

**Phase 2: Discovery+Detail**
- **Goal**: Alur cari→detail→trailer end-to-end live TMDB.
- **Scope**: Discover/search/detail/credits/videos/similar, `cached_network_image`, `youtube_player_flutter` + fallback.
- **Success signal**: Search filter + detail + trailer jalan dengan offline-degraded.

**Phase 3: Mood+Watchlist (MVP gate)**
- **Goal**: Hipotesis teruji.
- **Scope**: Quiz 3Q (8-10 mood), tabel mapping mood→genre, alasan cocok, filter durasi, watchlist persist + badge/undo.
- **Success signal**: 5 skenario <60 detik + persist 100%.

**Phase 4: Backend-optional**
- **Goal**: Sync multi-device + sosial ringan (hanya jika gate Phase 3 lolos).
- **Scope**: Login, sync watchlist, review/komentar dasar.
- **Success signal**: Login + sync jalan tanpa merusak mode offline/lokal.

**Phase 5: iOS + polish**
- **Goal**: Siap portfolio/release.
- **Scope**: iOS build, launcher icon/splash, apk/aab release, screenshot, lisensi/atribusi TMDB.
- **Success signal**: Release build Android (+iOS bila tersedia Mac) terpasang bersih.

### Parallelism Notes

Fase 1→2→3 serial karena fondasi API dan dependensi layar. Fase 4 dan 5 bisa paralel setelah gate Fase 3 lolos karena domain terpisah (backend vs packaging) — keduanya depend on 3.

---

## Decisions Log

| Decision | Choice | Alternatives | Rationale |
|----------|--------|--------------|-----------|
| Platform | Flutter/Dart, Android-first | Kotlin native | Keputusan user (Dart wajib) + 1 codebase untuk iOS later |
| Rekomendasi | Rule-based mood→genre manual | AI LLM | Keputusan user + tanpa backend/biaya; pola tile tervalidasi pasar |
| API setup | Demo key bundle + override | Wajib isi manual | Keputusan user: tinggal pakai; mitigasi revoke didokumentasikan |
| Komparasi | Could, bukan Must | Hapus total | Effort rendah tapi tidak menguji hipotesis |
| Backend/review/iOS | Fase 4-5 | Masuk v1 | Lindungi MVP solo-dev + clone-to-run |
| Tambahan non-AI | Alasan cocok + filter durasi (Should), mode pasangan (Could) | Tidak tambah | Diizinkan user; pola pasar terbukti; tanpa AI |

---

## Research Summary

**Market Context**
Enam kompetitor mood-based (WatchPulse, Qouch Potato, Moodflix, MoodPick, Cinento, MoodMoviePicker) memvalidasi pain scroll-fatigue dan klaim keputusan <1 menit. Pola umum: 8-12 mood tiles, quiz onboarding, alasan cocok per kartu, filter durasi/time-boxed, info streaming. Gap: mereka berat (AI backend, akun, region streaming kompleks) — ruang untuk versi Flutter ringan offline-first dengan mapping manual.

**Technical Context**
TMDB v3 gratis mencakup semua kebutuhan (discover filter multi-genre + rating, credits, images, videos YouTube, similar/recommendations, trending). Stack Flutter matang (Bloc/Riverpod, Hive/sqflite/Isar, `youtube_player_flutter`, `cached_network_image`, `go_router`, `flutter_dotenv`). Folder lokal masih kosong (greenfield). Mesin user: Flutter 3.44.6 / Dart 3.12.2 / Android SDK 37, 4 device; satu-satunya blocker build adalah `android-licenses` yang belum accepted.

---

*Generated: 2026-09-11*
*Status: DRAFT - needs validation*
