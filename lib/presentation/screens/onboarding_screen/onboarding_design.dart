import 'package:flutter/material.dart';

class OnboardingDesign extends StatelessWidget {
  final String image ;
  final String  title;
  final String  subTitle;

  OnboardingDesign({required this.image,required this.title, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
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
          child: Container(
            height: size.height * 0.32,
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(15),
              child: Image.network(
                image,
                fit: BoxFit.fill,
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
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: size.height * 0.01),

        /// Subtitle
        Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          child:  Text(
            subTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.5, color: Colors.black54),
          ),
        ),
        
      ],
    );
  }
}
