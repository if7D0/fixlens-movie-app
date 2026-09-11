import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../firebase_options.dart';
import '../utils/app_log.dart';

/// Guarded Firebase bootstrap. Returns true when backend features
/// (auth, sync, reviews) are usable; false keeps the app fully local.
/// Never throws.
Future<bool> initFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    appLog('firebase ready');
    return true;
  } catch (e) {
    appLog('firebase unavailable, local-only mode: $e');
    return false;
  }
}

/// Overridden in tests. UI gates backend features on this flag.
final firebaseReadyProvider = Provider<bool>(
  (_) => throw UnimplementedError('Override firebaseReadyProvider'),
);
