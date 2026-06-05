import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fieldguard/core/theme/app_colors.dart';

/// App-wide shimmer skeleton toolkit.
///
/// Use [AppShimmer] to animate a set of [SkeletonBox] placeholders, or grab a
/// ready-made layout: [SkeletonList] / [SkeletonListTile] for list screens and
/// [SkeletonDetail] for detail screens. The card chrome (white background,
/// border) stays OUTSIDE the shimmer so only the grey placeholder blocks
/// animate — never the whole card.
const _baseColor = AppColors.grey4;
const _highlightColor = AppColors.white;

/// Wraps placeholder boxes in the app's standard shimmer animation.
class AppShimmer extends StatelessWidget {
  final Widget child;
  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: _baseColor,
    highlightColor: _highlightColor,
    child: child,
  );
}

/// A single rounded placeholder block. Render inside an [AppShimmer] for the
/// animated sweep (the box colour is replaced by the shimmer gradient).
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
    );
  }
}

/// One placeholder list row (avatar + two text lines) inside a card.
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const AppShimmer(
        child: Row(
          children: [
            SkeletonBox(width: 52, height: 52, radius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 160, height: 13),
                  SizedBox(height: 9),
                  SkeletonBox(width: 90, height: 11),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 22, height: 22, radius: 6),
          ],
        ),
      ),
    );
  }
}

/// A scrollable list of [SkeletonListTile]s — drop-in for a list screen's
/// initial loading state.
class SkeletonList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 7,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 32),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => const SkeletonListTile(),
    );
  }
}

/// Placeholder for a detail screen: a hero band, then a few stacked rows.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Hero band with avatar + name lines.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            color: AppColors.green,
            child: const AppShimmer(
              child: Column(
                children: [
                  SkeletonBox(width: 96, height: 96, shape: BoxShape.circle),
                  SizedBox(height: 16),
                  SkeletonBox(width: 150, height: 18),
                  SizedBox(height: 10),
                  SkeletonBox(width: 90, height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmer(child: SkeletonBox(width: 160, height: 16)),
                SizedBox(height: 14),
                SkeletonListTile(),
                SkeletonListTile(),
                SizedBox(height: 10),
                AppShimmer(child: SkeletonBox(width: 140, height: 16)),
                SizedBox(height: 14),
                SkeletonListTile(),
                SkeletonListTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
