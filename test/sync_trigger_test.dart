import 'dart:io';

import 'package:fixlens_movie_app/src/core/backend/firebase_bootstrap.dart';
import 'package:fixlens_movie_app/src/core/result/app_result.dart';
import 'package:fixlens_movie_app/src/features/account/data/auth_repository.dart';
import 'package:fixlens_movie_app/src/features/account/presentation/account_provider.dart';
import 'package:fixlens_movie_app/src/features/discover/data/models/movie.dart';
import 'package:fixlens_movie_app/src/features/watchlist/data/watchlist_sync.dart';
import 'package:fixlens_movie_app/src/features/watchlist/presentation/watchlist_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'account_test.dart' show FakeAuthRepository;

const _user = AppUser(
  uid: 'u9',
  displayName: 'Sync',
  email: null,
  photoUrl: null,
);

const _movie = MovieSummary(
  id: 7,
  title: 'Sync Film',
  posterPath: null,
  backdropPath: null,
  overview: '',
  releaseDate: '2024-01-01',
  voteAverage: 8.0,
  genreIds: [28],
);

/// Recorder fake (no Firestore). Requires WatchlistSync to be abstract.
class FakeWatchlistSync implements WatchlistSync {
  final List<String> syncLogins = [];
  final List<({int id, bool saved})> pushes = [];

  @override
  Future<AppResult<List<MovieSummary>>> syncOnLogin(
    String uid,
    List<MovieSummary> localItems,
    Map<int, int> localUpdatedAtMs,
  ) async {
    syncLogins.add(uid);
    return AppOk(localItems);
  }

  @override
  Future<void> pushToggle(
    String uid,
    MovieSummary movie,
    bool saved,
  ) async {
    pushes.add((id: movie.id, saved: saved));
  }
}

void main() {
  late Directory temp;

  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('fixlens_trigger_');
    Hive.init(temp.path);
  });

  tearDownAll(() => temp.delete(recursive: true));

  Future<(ProviderContainer, FakeAuthRepository, FakeWatchlistSync)>
  makeContainer() async {
    final auth = FakeAuthRepository();
    final sync = FakeWatchlistSync();
    final box = await Hive.openBox(
      'trig_${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() => box.deleteFromDisk());
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        watchlistSyncProvider.overrideWithValue(sync),
        watchlistBoxProvider.overrideWithValue(box),
        firebaseReadyProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);
    // Attach watchlist listener before login happens.
    container.read(watchlistProvider);
    return (container, auth, sync);
  }

  test('login transition triggers cloud sync even off-profile', () async {
    final (container, auth, sync) = await makeContainer();
    auth.nextSignIn = const AppOk<AppUser>(_user);

    await container.read(accountProvider.notifier).signIn();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(sync.syncLogins, ['u9']);
  });

  test('toggle pushes to cloud when signed in', () async {
    final (container, auth, sync) = await makeContainer();
    auth.emit(_user);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await container.read(watchlistProvider.notifier).toggle(_movie);

    expect(sync.pushes, [(id: 7, saved: true)]);
  });
}
