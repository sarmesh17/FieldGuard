import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final bool highlighted;

  const SectionCard({
    super.key,
    required this.title,
    required this.items,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.045),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.fromLTRB(
              w * 0.045,
              w * 0.042,
              w * 0.045,
              w * 0.028,
            ),
            child: Row(
              children: [
                if (highlighted) ...[
                  Container(
                    width: w * 0.009,
                    height: w * 0.042,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff6558FF), Color(0xff9B4EFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(w * 0.01),
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                ],
                Text(
                  title,
                  style: TextStyle(
                    fontSize: w * 0.032,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: highlighted
                        ? const Color(0xff635BFF)
                        : const Color(0xff9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xffF3F4F6),
          ),
          // Items with dividers between them
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.045),
                child: Container(height: 1, color: const Color(0xffF3F4F6)),
              ),
          ],
          SizedBox(height: w * 0.01),
        ],
      ),
    );
  }
}
