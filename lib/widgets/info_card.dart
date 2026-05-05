import 'package:flutter/material.dart';
import '../core/responsive/responsive.dart';

/// A reusable, responsive information card.
///
/// Uses [Flexible] text handling and scalable spacing to prevent overflow
/// on any screen size.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.scale(12)),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(colorScheme),
            SizedBox(width: AppSpacing.md),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(SizeConfig.scale(8)),
      ),
      child: Icon(
        icon,
        size: SizeConfig.scale(24),
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: AppTextStyles.bodyMedium,
          // Allow text to wrap naturally — no fixed height.
        ),
      ],
    );
  }
}
