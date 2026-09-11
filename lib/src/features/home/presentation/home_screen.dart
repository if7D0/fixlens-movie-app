import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

/// Home tab placeholder. Full discovery UI lands in Phase 2-3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixLens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!AppConfig.isConfigured)
            Card(
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Demo mode — TMDB key belum dikonfigurasi. '
                  'Lihat README untuk cara menambahkannya.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text('Home — discovery hadir di Fase 2.'),
        ],
      ),
    );
  }
}
