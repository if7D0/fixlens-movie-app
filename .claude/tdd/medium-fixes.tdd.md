# TDD Evidence: review-MEDIUM fixes (auth abstraction + sync trigger)

## Source plan

No `*.plan.md` — journeys derived from `/flutter-review` findings on commit
`e355343` (2 actionable MEDIUMs; l10n deferred by standing decision).

## User journeys

1. As a user, I want sign-in to flip account state (and failures to show
   friendly errors), so that login is predictable and testable.
2. As a user, I want watchlist auto-sync to trigger on login even if I leave
   the Profile tab, so that reinstall-restore never silently skips.

## Task report

| Task | Summary | Validation | Evidence |
|---|---|---|---|
| RED tests | `test/account_test.dart` (3) + `test/sync_trigger_test.dart` (2) referencing missing `AuthRepository`/`WatchlistSync` abstractions | `flutter test test/account_test.dart test/sync_trigger_test.dart` | RED (compile): `Type 'WatchlistSync' not found`, override type mismatch. Commit `8dfe830` on `main` |
| GREEN refactor | `abstract AuthRepository` + `FirebaseAuthRepository`; `abstract WatchlistSync` + `FirestoreWatchlistSync`; trigger moved `ProfileScreen` → `WatchlistNotifier.build` via `ref.listen` (no import cycle, survives tab switches) | `flutter analyze` + `flutter test` | GREEN: 5/5 new tests pass; full suite 55/55 |
| Coverage lift | +`detail_model_test` (6), +`detail_provider_test` (1) | `flutter test --coverage` | 42.6% → 47.7% (725/1520 lines) |

## Test specification

| # | Guarantee | Test file | Type | Result |
|---|---|---|---|---|
| 1 | Sign-in success flips to signedIn with uid | `account_test.dart` | unit | PASS |
| 2 | Sign-in error stays signedOut with message | `account_test.dart` | unit | PASS |
| 3 | Sign-out clears user | `account_test.dart` | unit | PASS |
| 4 | Login transition triggers cloud sync off-profile | `sync_trigger_test.dart` | unit | PASS |
| 5 | Toggle pushes to cloud when signed in | `sync_trigger_test.dart` | unit | PASS |
| 6 | Trailer prefers official YT, fallbacks, null-safety | `detail_model_test.dart` | unit | PASS |
| 7 | Detail provider emits parsed detail | `detail_provider_test.dart` | unit | PASS |

## Coverage and known gaps

Overall 47.7%. New/changed logic ~90%+ (account 93.5%, quiz 95%, sync merge 100%,
review model 97%). Remaining 0%-files and why they stay:

- UI screens (detail, profile, review section/sheet, search): need widget tests
  with Firebase overrides; follow-up task, not this cycle.
- Firebase SDK glue (`review_repository`, `FirestoreWatchlistSync`,
  `FirebaseAuthRepository` bodies): require emulator or fakes of platform
  classes; covered by manual device acceptance instead.
- `firebase_options.dart` (generated), `tmdb_client` error mapping (needs a
  keyed `--dart-define` run — verified live on device instead).

## Merge evidence

- RED: commit `8dfe830` — `test: add reproducer for account transitions and
  sync trigger` (compile failure = intended signal).
- GREEN: this cycle's fix commit (55/55 + analyze clean + coverage 47.7%).
- Debug detour (not production-relevant): `testWidgets` runs in a fake-async
  zone where real Hive disk IO hangs the runner forever. Widget tests must not
  open Hive boxes; the app's graceful empty-watchlist degradation covers it.
  Scratch debug files were removed, lesson kept in `quiz_flow_test.dart` note.
