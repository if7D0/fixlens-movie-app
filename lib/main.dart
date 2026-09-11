import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'src/app/app.dart';
import 'src/core/utils/app_log.dart';
import 'src/features/watchlist/presentation/watchlist_provider.dart';

/// Bootstrap order is contractual: dotenv -> Hive (+open box) ->
/// ProviderScope (with box override) -> runApp.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await Hive.initFlutter();
  final watchlistBox = await Hive.openBox('watchlist');
  appLog('bootstrap complete');
  runApp(
    ProviderScope(
      overrides: [
        watchlistBoxProvider.overrideWithValue(watchlistBox),
      ],
      child: const FixLensApp(),
    ),
  );
}
