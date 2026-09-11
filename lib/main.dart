import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'src/app/app.dart';
import 'src/core/backend/firebase_bootstrap.dart';
import 'src/core/utils/app_log.dart';
import 'src/features/account/data/auth_repository.dart';
import 'src/features/account/presentation/account_provider.dart';
import 'src/features/watchlist/data/watchlist_sync.dart';
import 'src/features/watchlist/presentation/watchlist_provider.dart';

/// Bootstrap order is contractual: dotenv -> Hive (+open box) -> Firebase
/// (guarded) -> ProviderScope (with overrides) -> runApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await Hive.initFlutter();
  final watchlistBox = await _openWatchlistBox();
  final firebaseReady = await initFirebase();
  appLog('bootstrap complete');
  runApp(
    ProviderScope(
      overrides: [
        watchlistBoxProvider.overrideWithValue(watchlistBox),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        authRepositoryProvider.overrideWithValue(FirebaseAuthRepository()),
        if (firebaseReady)
          firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
      ],
      child: const FixLensApp(),
    ),
  );
}

/// Opens the watchlist box, resetting it if corrupt so the app can always
/// launch (local data loss beats a dead-on-arrival install).
Future<Box> _openWatchlistBox() async {
  try {
    return await Hive.openBox('watchlist');
  } catch (e) {
    appLog('watchlist box corrupt, resetting: $e');
    try {
      await Hive.deleteBoxFromDisk('watchlist');
    } catch (_) {
      // Best effort: reopen below will surface a fresh error if any.
    }
    return Hive.openBox('watchlist');
  }
}
