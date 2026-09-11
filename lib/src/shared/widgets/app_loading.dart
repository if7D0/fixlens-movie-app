import 'package:flutter/material.dart';

/// Standard loading state. Contract for Phase 2-3: do not change signature
/// without updating the plan.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
