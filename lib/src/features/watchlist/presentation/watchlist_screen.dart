import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watchlist tab placeholder. Persistent watchlist lands in Phase 3.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: const Center(
        child: Text('Watchlist — penyimpanan lokal hadir di Fase 3.'),
      ),
    );
  }
}
