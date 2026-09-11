import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Detail route placeholder (`/movie/:id`). Full detail lands in Phase 2.
class DetailScreen extends ConsumerWidget {
  final String movieId;

  const DetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(child: Text('Detail film $movieId — hadir di Fase 2.')),
    );
  }
}
