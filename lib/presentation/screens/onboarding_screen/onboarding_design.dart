import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';

/// Displays a single onboarding page — image, title, and subtitle.
class OnboardingDesign extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subTitle;

  const OnboardingDesign({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = switch (SizeConfig.screenType) {
      ScreenType.small => SizeConfig.heightPercent(28),
      ScreenType.medium => SizeConfig.heightPercent(32),
      ScreenType.large => SizeConfig.heightPercent(35),
    };

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Image card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(SizeConfig.scale(16)),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEEEA),
              borderRadius: BorderRadius.circular(SizeConfig.scale(28)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x0D000000),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SizedBox(
              height: imageHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(SizeConfig.scale(15)),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: SizeConfig.scale(48),
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(2)),

          /// Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(24),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(height: SizeConfig.heightPercent(1)),

          /// Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              subTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: SizeConfig.scaledFontSize(14),
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
