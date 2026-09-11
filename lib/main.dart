import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'src/app/app.dart';
import 'src/core/utils/app_log.dart';

/// Bootstrap order is contractual: dotenv -> Hive -> ProviderScope -> runApp.
/// Boxes are opened in Phase 3; Phase 1 only initializes Hive.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  await Hive.initFlutter();
  appLog('bootstrap complete');
  runApp(const ProviderScope(child: FixLensApp()));
}
