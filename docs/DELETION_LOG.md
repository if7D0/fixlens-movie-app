# Code Deletion Log

## [2026-09-11] Refactor Session — fixlens-movie-app (Flutter, not npm)

> Adapted detection for Dart/Flutter: `flutter analyze` replaces
> knip/depcheck/ts-prune/eslint (all npm-only, N/A here). Manual grep
> reference checks replace ts-prune. Full file inventory (44 lib files)
> verified — every file has an importer.

### Unused Dependencies Removed
- cupertino_icons@^1.0.8 — Last used: never (zero hits for
  `CupertinoIcons|cupertino_icons` in `lib/` + `test/`, verified via
  `Select-String`). All UI uses Material `Icons.*`. Removed from
  `pubspec.yaml`; `flutter pub get` confirms
  `These packages are no longer being depended on: cupertino_icons 1.0.9`.
  `pubspec.lock` updated accordingly.

### Unused Files Deleted
- None. All 44 `lib/**/*.dart` files have at least one importer
  (router, provider, widget tree, or repository). No orphans found.

### Duplicate Code Consolidated
- `lib/src/features/search/presentation/search_screen.dart` (L139-145) +
  `lib/src/features/watchlist/presentation/watchlist_screen.dart` (L31-35)
  -> `lib/src/shared/widgets/movie_card.dart` (`movieGridDelegate`)
- Reason: Both `SliverGridDelegateWithFixedCrossAxisCount` literals were
  byte-identical (`crossAxisCount: 3, spacing: 12, childAspectRatio: 0.48`).
  Single `const` source next to `MovieCard` (already shared by both grids)
  so card sizing can't drift. Both screens now use `movieGridDelegate`.
- Considered but KEPT separate: `MovieCard` poster fallback (column layout)
  vs `PickCard` poster fallback (row layout) — similar 6-line blocks but
  different parents/constraints; merging would hurt readability for ~0 gain.

### Unused Exports Removed
- None (conservative — candidates below were verified IN USE and kept).

### Reviewed and Kept (DO NOT REMOVE)
- `TmdbImage.still()` (`lib/src/core/network/tmdb_image.dart:8`) — zero
  callers in `lib/`, but covered by `test/tmdb_image_test.dart:19-24`
  (`still uses w500`). Public image-size utility, 1 line, tested. Keep.
- `WatchlistRepository.contains()` — zero callers in `lib/` (providers use
  the `ids` set), but covered by `test/watchlist_test.dart:41-46`
  (`repository round-trip save/contains/remove`). Repository public API.
  Keep; removing breaks tests.
- `MovieSummary.backdropPath` / `overview` — unread in current widgets, but
  required for Hive/Firestore JSON round-trip (`toJson`/`fromJson`) and TMDB
  payloads. Data-model fields, not dead code. Keep.
- All other pubspec deps (`flutter_riverpod`, `go_router`,
  `flutter_dotenv`, `hive_ce`, `hive_ce_flutter`, `dio`,
  `cached_network_image`, `youtube_player_flutter`, `firebase_core`,
  `firebase_auth`, `cloud_firestore`, `google_sign_in`) — each has ≥1 import
  in `lib/`. Keep.
- No commented-out code, no `if (false)` branches, no `TODO/FIXME/HACK`
  markers found in `lib/` (grep clean, 1 benign `ignore_for_file` in
  generated `firebase_options.dart` only).

### Impact
- Files deleted: 0
- Dependencies removed: 1 (cupertino_icons)
- Duplicates consolidated: 1 (2 call sites -> 1 const, net -12 lines)
- Lines of code removed: ~3 (pubspec) + ~12 (duplicate literals) ≈ 15
- Bundle size reduction: ~font asset (CupertinoIcons font no longer bundled)

### Testing
- `flutter analyze` — No issues found!
- `flutter pub get` — resolves clean, drops cupertino_icons 1.0.9
- `flutter test` — All 57 tests passed (verbose widget-binding stack in
  `smoke_test.dart` output is pre-existing log noise, not a failure)
- Manual smoke check: Search grid + Watchlist grid render via shared
  `movieGridDelegate`; no API/behavior change (pure const extraction)

### Safety Checklist
- [x] Ran detection tools (`flutter analyze`, grep reference searches)
- [x] Grepped for all references (including tests)
- [x] Checked dynamic imports (none — Dart static imports only)
- [x] Reviewed git history (`main`, HEAD `b8efbc1`, clean `git diff --stat`)
- [x] Checked public API impact (kept tested `still`/`contains`)
- [x] Ran all tests (57 passed)
- [x] No commit pushed (left uncommitted for review per repo policy)
- [x] Documented here in `docs/DELETION_LOG.md`
