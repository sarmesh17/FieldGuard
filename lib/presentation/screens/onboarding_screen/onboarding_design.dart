import 'package:flutter/material.dart';

class OnboardingDesign extends StatelessWidget {
  final String image;
  final String title;
  final String subTitle;

  const OnboardingDesign({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // 🔹 Responsive sizes with clamp
    double titleSize = (size.width * 0.05).clamp(22, 32);
    double subTitleSize = (size.width * 0.01).clamp(14, 18);
    double imageHeight = (size.height * 0.30).clamp(200, 320);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Image Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(size.width * 0.04),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEEEA),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: imageHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                image,
                fit: BoxFit.cover, // 🔥 better than fill
              ),
            ),
          ),
        ),
    
        SizedBox(height: size.height * 0.02),
    
        /// Title
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
    
        SizedBox(height: size.height * 0.01),
    
        /// Subtitle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          child: Text(
            subTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subTitleSize,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
