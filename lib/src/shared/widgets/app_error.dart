import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Standard error state with retry. Contract for Phase 2-3: do not change
/// signature without updating the plan.
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.error.withValues(alpha: 0.30),
                ),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: scheme.error,
                semanticLabel: 'Gagal memuat',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ups, ada gangguan',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
