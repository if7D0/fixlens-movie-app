import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Standard loading state. Contract for Phase 2-3: do not change signature
/// without updating the plan.
///
/// UX guidance (verified): stable skeleton, no flicker, reserve layout
/// space, expose busy status. [AppLoading] stays a spinner for inline
/// spots; use [MovieRailSkeleton]/[MovieGridSkeleton] for poster lists.
class AppLoading extends StatelessWidget {
  final String? message;

  const AppLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message ?? 'Memuat…',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder block with stable bounds (no content jumping).
class ShimmerBlock extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadii.sm,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Horizontal rail skeleton matching [MovieRail] bounds (120w x 252h).
class MovieRailSkeleton extends StatelessWidget {
  final String title;

  const MovieRailSkeleton({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SizedBox(
          height: 252,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, _) => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 120, height: 180),
                SizedBox(height: 8),
                ShimmerBlock(width: 110, height: 12, borderRadius: 6),
                SizedBox(height: 6),
                ShimmerBlock(width: 70, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Grid skeleton matching the 3-column poster grid bounds.
class MovieGridSkeleton extends StatelessWidget {
  const MovieGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.48,
      ),
      itemCount: 9,
      itemBuilder: (context, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ShimmerBlock(width: double.infinity, height: 120)),
          SizedBox(height: 8),
          ShimmerBlock(width: double.infinity, height: 12, borderRadius: 6),
          SizedBox(height: 6),
          ShimmerBlock(width: 60, height: 10, borderRadius: 6),
        ],
      ),
    );
  }
}
