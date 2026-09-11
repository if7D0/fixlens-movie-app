# Plan: FixLens Mood Quiz + Watchlist (MVP Gate)

## Summary

Bangun dua kapabilitas MVP: (1) Quiz "mood finder" 3 pertanyaan (mood 8 tile → teman nonton → durasi) dengan tabel mapping manual mood→genre TMDB + alasan cocok deterministik, menghasilkan 3 rekomendasi via `discover`; (2) Watchlist persisten Hive (JSON maps, tanpa codegen) dengan toggle di Detail, grid + hapus + undo di tab Watchlist, dan badge count di bottom nav. Gate: quiz→3 picks <60 detik + persist 100%.

## User Story

As a penonton lelah yang bingung mau nonton apa,
I want menjawab 3 pertanyaan mood sederhana dan menyimpan hasilnya,
So that saya dapat 3 rekomendasi yang cocok dalam <1 menit tanpa scroll.

## Problem → Solution

Quiz belum ada (hipotesis tak teruji) + tab Watchlist placeholder → Alur Find by Mood end-to-end + watchlist lokal penuh, keduanya bekerja dalam demo-mode tanpa crash.

## Metadata

- **Complexity**: Large
- **Source PRD**: `.claude/PRPs/prds/fixlens-movie-app.prd.md`
- **PRD Phase**: 3 — Mood+Watchlist (MVP gate)
- **Estimated Files**: ~15 (8 create, 6 update, 1 main)

---

## UX Design

### Before

```
Home: banner demo + rail Trending + rail Popular (Fase 2).
Watchlist tab: teks placeholder. Detail: tanpa bookmark.
```

### After

```
Home: [banner demo?] + CARD "Find by Mood 🍿" + rails (tetap).
/mood: "Lagi pengin ngerasain apa?" [8 tiles] → progress 1/3
      "Nonton sama siapa?" [Solo/Pasangan/Keluarga/Teman] → 2/3
      "Punya waktu berapa lama?" [<100/100-140/Bebas] → loading
/mood/result: "3 pilihan buat kamu" + 3 kartu (poster+alasan) → tap = detail
Detail: ikon bookmark di AppBar (isi/kosong + snackbar undo saat hapus).
Watchlist tab: grid + geser hapus + snackbar undo + badge count di nav.
```

### Interaction Changes

| Touchpoint | Before | After | Notes |
|---|---|---|---|
| Home CTA | Tidak ada | Card "Find by Mood" → `/mood` | Di atas rail Trending |
| Quiz | Tidak ada | 3 langkah + back + loading + result | Jawaban Q3 langsung run |
| Result | Tidak ada | 3 picks + alasan deterministik | <3 hasil → 1x relax filter → empty state + ulangi |
| Detail AppBar | Polos | Bookmark toggle + snackbar | Undo hanya saat menghapus |
| Watchlist | Placeholder | Grid + Dismissible + undo + empty state | Persist NPM restart |
| Bottom nav | Label polos | Badge count di Watchlist | Via Consumer di shell builder |

---

## Mandatory Reading

| Priority | File | Lines | Why |
|---|---|---|---|
| P0 | `lib/src/features/discover/presentation/providers.dart` | SearchNotifier/SearchState | Pola Notifier + copyWith + token anti-basi untuk QuizNotifier |
| P0 | `lib/src/features/discover/data/movie_repository.dart` | discover() | Signature di-EXTEND (param baru); reuse untuk quiz |
| P0 | `lib/src/core/router/app_router.dart` | 14-40, 68-74 | Shell builder (badge) + pola rute luar-shell (`/movie/:id`) untuk `/mood*` |
| P0 | `lib/main.dart` | 11-16 | Bootstrap: `openBox('watchlist')` + override provider di sini |
| P1 | `lib/src/features/discover/data/models/movie.dart` | all | Tambah `toJson()` aditif; field untuk alasan + kartu |
| P1 | `lib/src/features/home/presentation/home_screen.dart` | all | Sisip CTA tanpa rusak section AsyncValue |
| P1 | `lib/src/features/detail/presentation/detail_screen.dart` | AppBar + `_Body` | Sisip bookmark toggle |
| P2 | `lib/src/shared/widgets/movie_card.dart` | MovieRail | Reuse untuk rail; kartu result terpisah (butuh alasan) |
| P2 | `test/search_notifier_test.dart` | FakeTmdbClient + container | Pola fake/override untuk quiz test |

## External Documentation

Tidak ada riset eksternal — Hive CE key-value = API Hive v2 stabil yang dipakai
minimal (openBox/put/delete/values, tanpa codegen/adapter karena nilai = JSON
maps, keputusan Fase 1). Satu-satunya API baru: `Hive.openBox(name)` di
`main.dart` + `ProviderScope(overrides:)` (pola standar Riverpod).

---

## Patterns to Mirror

### NAMING_CONVENTION

```dart
// SOURCE: Fase 1-2 — features/<domain>/{data/{models,*_repository.dart},
// presentation/{*_provider(s).dart,screens,widgets/}}
// Baru: features/mood/{data/mood_map.dart,presentation/{quiz_provider.dart,
// mood_quiz_screen.dart,mood_result_screen.dart,widgets/pick_card.dart}}
// features/watchlist/{data/watchlist_repository.dart,presentation/watchlist_provider.dart}
```

### ERROR_HANDLING

```dart
// SOURCE: lib/src/core/result/app_result.dart:9-22 + tmdb_client pattern
// Quiz: runQuiz catch SEMUA error repo -> QuizState(status: error, message)
// karena MovieRepository SUDAH map ke AppErr, cukup teruskan pesannya.
// Watchlist I/O Hive: try/catch -> appLog + snackbar 'Gagal menyimpan'.
// Tidak ada throw ke UI.
```

### STATE_PATTERN

```dart
// SOURCE: providers.dart SearchState/SearchNotifier (copyWith, status enum)
// QuizState: step 0-2, moodId?/companyId?/durationId?, QuizStatus
// {answering, loading, result, error}, picks List<MoodPick>, errorMessage?
// WatchlistState: items List<MovieSummary>, ids Set<int> (turunan, untuk O(1)).
class MoodPick {
  final MovieSummary movie;
  final String reason; // deterministik dari jawaban + data film
  const MoodPick({required this.movie, required this.reason});
}
```

### REPOSITORY_PATTERN

```dart
// SOURCE: movie_repository.dart + detail_repository.dart
class WatchlistRepository {
  WatchlistRepository(this._box); // Box dari hive_ce (pure, testable)
  final Box _box;
  List<MovieSummary> items(); // parse defensif, entri korup di-skip
  bool contains(int id);
  Future<void> save(MovieSummary m); // put('m_$id', {...toJson, savedAt})
  Future<void> remove(int id);
}
```

### TEST_STRUCTURE

```dart
// SOURCE: test/search_notifier_test.dart — FakeTmdbClient + ProviderContainer
// overrides + addTearDown(dispose). Ulangi untuk quiz (override
// tmdbClientProvider) dan watchlist (Hive.init(temp) + openBox real).
```

---

## Files to Change

| File | Action | Justification |
|---|---|---|
| `lib/src/features/discover/data/movie_repository.dart` | UPDATE | Tambah param opsional `voteCountGte, runtimeLte, runtimeGte, releaseDateLte` ke `discover()` (default null = tak dikirim) |
| `lib/src/features/discover/data/models/movie.dart` | UPDATE | Tambah `toJson()` aditif untuk persist watchlist |
| `lib/src/features/mood/data/mood_map.dart` | CREATE | Tabel 8 mood + 4 company + 3 durasi + builder alasan (lihat Desain Kunci) |
| `lib/src/features/mood/presentation/quiz_provider.dart` | CREATE | `QuizNotifier` + `QuizState` + `quizProvider`; `runQuiz()` via `MovieRepository.discover` + 1x relax |
| `lib/src/features/mood/presentation/mood_quiz_screen.dart` | CREATE | 3 langkah tiles + progress + back; Q3 → runQuiz → push `/mood/result` |
| `lib/src/features/mood/presentation/mood_result_screen.dart` | CREATE | 3 kartu alasan + tap→detail + "Ulangi kuis" |
| `lib/src/features/mood/presentation/widgets/pick_card.dart` | CREATE | Poster 90px + judul/meta + alasan (bukan MovieCard — butuh baris alasan) |
| `lib/src/features/watchlist/data/watchlist_repository.dart` | CREATE | CRUD box JSON (lihat pattern) |
| `lib/src/features/watchlist/presentation/watchlist_provider.dart` | CREATE | `WatchlistNotifier` + `watchlistBoxProvider` (override di main/test) |
| `lib/src/features/watchlist/presentation/watchlist_screen.dart` | UPDATE (overwrite) | Grid + Dismissible + undo + empty state |
| `lib/src/features/detail/presentation/detail_screen.dart` | UPDATE | Bookmark toggle di AppBar + snackbar (+undo saat hapus) |
| `lib/src/features/home/presentation/home_screen.dart` | UPDATE | Card CTA "Find by Mood" → `push('/mood')` |
| `lib/src/core/router/app_router.dart` | UPDATE | Rute `/mood`, `/mood/result` (luar shell) + Consumer badge di nav |
| `lib/main.dart` | UPDATE | `openBox('watchlist')` + `ProviderScope(overrides:)` |
| `test/mood_map_test.dart` | CREATE | Tabel lengkap + alasan + modifier company |
| `test/watchlist_test.dart` | CREATE | Repo round-trip (box temp) + toggle/add/remove notifier |
| `test/quiz_provider_test.dart` | CREATE | 3 jawaban → 3 picks + alasan non-kosong; error repo → status error |
| `README.md` | UPDATE | Status Fase 3 + 1 baris cara pakai quiz |

## NOT Building

- Mode pasangan sebagai resolver gabungan 2 profil (Could PRD — di luar fase ini; Q2 "Pasangan" hanya modifier mapping)
- Komparasi side-by-side (Could — fase lain bila jadi)
- Sinkronisasi cloud/backup (Fase 4)
- Notifikasi "film watchlist sudah rilis" (di luar PRD)
- Codegen Hive/adapters (keputusan: JSON maps)
- Bahasa API `id-ID` (tetap `en-US`)

---

## Desain Kunci (diputuskan di plan, delegasi user)

### Tabel mood → genre (TMDB ids) + tone alasan

| moodId | Label | Genres | Tone |
|---|---|---|---|
| santai | Santai | 35, 16, 10751 | ringan dan menenangkan |
| tertawa | Tertawa | 35 | lucu dan menghibur |
| tegang | Tegang | 53, 80, 9648 | penuh ketegangan |
| sedih | Sedih | 18 | menyentuh dan emosional |
| romantis | Romantis | 10749, 18 | hangat dan romantis |
| nostalgia | Nostalgia | 12, 18 (+releaseDateLte 2010-12-31) | klasik penuh kenangan |
| penasaran | Penasaran | 9648, 878, 99 | misterius dan bikin mikir |
| semangat | Semangat | 28, 12 | penuh aksi dan energi |

### Modifier company (Q2)

| companyId | Label | Efek |
|---|---|---|
| solo | Sendiri | tidak ada |
| pasangan | Pasangan | +10749 ke genre (bila belum ada), minVotes 100 |
| keluarga | Keluarga | exclude genre 27 (horror), minVotes 200 |
| teman | Teman | +[35, 28] ke genre, minVotes 100 |

### Durasi (Q3) + default kualitas

- cepat: `runtimeLte=100`, label '< 100 menit'
- standar: `runtimeGte=80, runtimeLte=150`, label 'sekitar 2 jam'
- bebas: tanpa filter, label 'durasi bebas'
- Selalu: `minRating=6.5`, `voteCountGte` per company, `sort_by=popularity.desc`

### Template alasan (deterministik)

`'{Tone} buat {companyLabel} • {durationLabel} • rating {vote}'`
Contoh: 'Komedi ringan buat ketawa sendirian • < 100 menit • rating 7.8'.
`companyLabel`: sendirian / berdua / bareng keluarga / bareng teman.

### Aturan hasil

Ambil top-3 `discover`. Bila <3: 1x relax (hapus runtime filter, ulang call).
Masih <3 → empty state + 'Ubah jawaban'. Error repo → error state + retry
(`ref.invalidate(quizProvider)` lalu jawab ulang otomatis? Tidak — tombol
'Coba lagi' memanggil `runQuiz()` ulang).

---

## Step-by-Step Tasks

### Task 1: Extend discover + MovieSummary.toJson + unit test

- **ACTION**: Tambah 4 param opsional ke `discover()` dan kirim hanya bila bermakna (`vote_count.gte`, `with_runtime.lte/gte`, `primary_release_date.lte`). Tambah `toJson()` ke MovieSummary (8 field + abaikan turunan). Extend `movie_model_test.dart` (via file baru `test/movie_json_test.dart` agar tak ubah test lama): round-trip fromJson→toJson→fromJson stabil.
- **MIRROR**: Pola "param hanya dikirim bila bermakna" (Fase 2 discover), TEST_STRUCTURE.
- **GOTCHA**: `with_genres` kosong → jangan kirim (aturan lama dipertahankan).
- **VALIDATE**: `flutter analyze` + `flutter test` hijau.

### Task 2: mood_map + unit test

- **ACTION**: Tulis tabel (8 mood, 4 company, 3 durasi) sebagai const maps + `buildRequest(answers) → QuizRequest(genres, excludeGenres, minRating, minVotes, runtimeLte/Gte, releaseDateLte, tone, companyLabel, durationLabel)` + `buildReason(answer, movie)`.
- **MIRROR**: NAMING_CONVENTION (features/mood/data).
- **GOTCHA**: Jangan hardcode string label di provider/screen — semua label dari map ini (sumber tunggal).
- **VALIDATE**: `test/mood_map_test.dart`: tiap mood genre non-kosong; keluarga exclude 27; reason memuat tone+company+durasi+rating.

### Task 3: QuizNotifier + provider + unit test

- **ACTION**: `QuizState/QuizStatus/quizProvider` per STATE_PATTERN. `answer(step, id)` maju step (Q3 → `runQuiz()`); `back()`; `restart()`. `runQuiz()`: guard jawaban lengkap → status loading → `repo.discover(...)` dari buildRequest → top-3 + reason per film → status result; <3 → 1x relax tanpa runtime; error → status error + message repo.
- **MIRROR**: SearchNotifier (copyWith, token anti-basi bila perlu — quiz single-shot, token opsional tapi disarankan; FakeTmdbClient test).
- **IMPORTS**: `flutter_riverpod`, repo, mood_map, models.
- **GOTCHA**: `runQuiz` async gap → cek `ref.mounted` sebelum set state akhir.
- **VALIDATE**: `test/quiz_provider_test.dart` (3 jawaban → 3 picks + alasan; repo error → status error). analyze+test hijau.

### Task 4: Layar quiz + result + rute

- **ACTION**: `mood_quiz_screen.dart`: AppBar 'Find by Mood', indikator 'Langkah x dari 3', grid 2 kolom tiles (label + emoji; emoji di map sebagai field display), back (AppBar + sistem via `pop` default — QuizNotifier tetap simpan step bila kembali dari result? restart saat masuk /mood: panggil `restart()` di `initState` via ConsumerStatefulWidget — SATU-SATUNYA StatefulWidget baru yang dibenarkan, alasannya one-shot init). Q3 onTap → `answer()` lalu `push('/mood/result')` (result watch provider → loading→result otomatis). `mood_result_screen.dart`: judul + 3 `PickCard` + tombol 'Ulangi kuis' (restart + pop). `pick_card.dart` mandiri. Router: tambah 2 GoRoute luar shell.
- **MIRROR**: ConsumerWidget di mana-mana kecuali init sekali di atas; kontrak AppLoading/AppError/AppEmpty.
- **IMPORTS**: `go_router` (push/pop), providers.
- **GOTCHA**: Jangan fetch di `build()` — fetch dipicu jawaban Q3 (event), bukan build.
- **VALIDATE**: analyze bersih.

### Task 5: Watchlist repo + provider + bootstrap + unit test

- **ACTION**: `watchlist_repository.dart` per REPOSITORY_PATTERN (Box hive_ce; skip entri korup diam-diam + appLog). `watchlist_provider.dart`: `watchlistBoxProvider = Provider<Box>((_) => throw UnimplementedError('override di main'))`, `WatchlistNotifier extends Notifier<WatchlistState>` (build → load sinkron dari box), `toggle(movie) → Future<bool> wasAdded`, `add/remove`. main.dart: openBox + overrides (lihat Mandatory). 
- **MIRROR**: ERROR_HANDLING (I/O gagal → AppErr-like message via state? Sederhana: try/catch + appLog + return false + UI snackbar 'Gagal menyimpan').
- **GOTCHA**: Box read sinkron — JANGAN await di build(); load sinkron langsung. `toggle` async hanya untuk write.
- **VALIDATE**: `test/watchlist_test.dart`: `Hive.init(temp)` + openBox real → save/contains/remove round-trip; notifier toggle dua arah. analyze+test hijau.

### Task 6: UI watchlist + bookmark detail + badge + CTA home

- **ACTION**: watchlist_screen overwrite: `watch(list)` → loading tak ada (sinkron; langsung grid/empty); Dismissible per sel (key id, background merah) → remove + SnackBar Undo (add kembali); badge: app_router shell builder bungkus `bottomNavigationBar` dengan Consumer → `Badge.count(count: ids.length, child: icon)` hanya bila count>0. detail_screen: AppBar action bookmark (watch select contains) → toggle + snackbar ('Ditambah ke watchlist' / 'Dihapus…' + Undo). home_screen: CTA card atas (icon mood + teks + chevron) → push('/mood').
- **MIRROR**: Kontrak AppEmpty; `ref.invalidate` tak perlu (state reaktif).
- **GOTCHA**: `context` snackbar setelah await toggle → cek `context.mounted`. Badge rebuild nav SAJA (jangan watch di seluruh shell).
- **VALIDATE**: analyze bersih.

### Task 7: README + validasi MVP gate di device

- **ACTION**: README: Fase 3 complete + cara pakai quiz 2 baris. Device keyed: (a) stopwatch 5 skenario mood (target tiap <60 dtk dari tap CTA ke 3 picks tampil); (b) tambah 3 watchlist → force-stop → relaunch → 3 tetap ada; hapus 1 + undo; (c) demo-mode tanpa key: quiz tampil error ramah (repo guard), watchlist lokal tetap jalan penuh (tanpa jaringan!).
- **VALIDATE**: Gate PRD: 5/5 <60s + persist 100%. Catat waktu tiap skenario di laporan.

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
|---|---|---|---|
| mood table lengkap | semua moodId | genre non-kosong, tone non-kosong | Tidak |
| keluarga modifier | company=keluarga | exclude={27}, minVotes=200 | Ya |
| reason builder | jawaban + film 7.8 | memuat tone, company, durasi, '7.8' | Tidak |
| toJson round-trip | fixture penuh | fromJson(toJson) stabil | Ya — field null |
| watchlist repo | save→contains→remove | true→false, items konsisten | Ya — entri korup di-skip |
| quiz happy path | 3 jawaban (fake repo) | 3 picks + alasan | Tidak |
| quiz repo error | fake AppErr | status error + message | Ya |
| quiz relax | fake 1 hasil ber-runtime | retry tanpa runtime → ≥1 | Ya |

### Edge Cases Checklist

- [ ] Tanpa key: quiz error ramah; watchlist 100% lokal jalan
- [ ] Jawaban tak lengkap (deep-link /mood/result): redirect tampilan ke 'mulai kuis' (guard status answering → empty CTA)
- [ ] discover 0 hasil: 1x relax lalu empty + ubah jawaban
- [ ] Dismissible + undo cepat ganda
- [ ] Kill app mid-quiz: state hilang (wajar) — watchlist tidak
- [ ] poster null di PickCard/grid (placeholder — pola lama)

---

## Validation Commands

```powershell
flutter analyze
```

EXPECT: No issues found!

```powershell
flutter test
```

EXPECT: All pass (16 lama + ~10 baru).

### Manual Validation (device keyed + demo)

- [ ] 5 skenario quiz <60 dtk (catat waktu)
- [ ] Watchlist persist kill+relaunch 100%
- [ ] Undo hapus (grid + detail) bekerja
- [ ] Badge count sinkron tambah/hapus
- [ ] Demo-mode: quiz error ramah, watchlist normal
- [ ] Trailer/detail Fase 2 tidak regresi (smoke cepat)

---

## Acceptance Criteria

- [ ] Semua 7 task selesai
- [ ] analyze nol issue, test pass
- [ ] Gate MVP: 5/5 skenario <60s + persist 100% tercatat di laporan
- [ ] Tanpa dio di widget; tanpa throw ke UI; controller/d,user disposed (tak ada controller baru fase ini)
- [ ] Tanpa secret; box hanya JSON maps

## Completion Checklist

- [ ] Label quiz dari mood_map (sumber tunggal, siap l10n)
- [ ] `with_genres`/`gte`/`lte` hanya bila bermakna (aturan dipertahankan)
- [ ] SnackBar guarded `context.mounted`
- [ ] Versi paket (tanpa dep baru — Hive/Riverpod existing) dicatat
- [ ] README status diperbarui
- [ ] Self-contained

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Tabel mapping terasa asal (belum validasi user) | H | Sedang | Tandai v1 di kode + README; uji 5-user pasca-merge (PRD mengakui) |
| discover top-3 kurang relevan | M | Sedang | Floor rating 6.5 + votes + popularity; relax-chain documented |
| Box corrupt upgrade skema | L | Rendah | Parse defensif + skip + appLog; version key `v` di value bila perlu |
| Quiz terasa lambat di HP lama | L | Rendah | 1 call + gambar cached; stopwatch buktikan <60s |

## Notes

- Tanpa dependensi baru (sengaja): Hive CE + Riverpod + go_router existing.
- Mode pasangan penuh (Could) eksplisit OUT; Q2 pasangan = modifier.
- `restart()` di entering /mood via ConsumerStatefulWidget initState — satu-satunya state lokal beralasan (one-shot init, bukan data).
