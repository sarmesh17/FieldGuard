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
        borderRadius: BorderRadius.circular(w * .04),
        border: Border.all(
          color: const Color(0xffDDD6CE),
        ),
      ),
      child: Row(
        children: [
          if (highlighted)
            Container(
              width: w * .012,
              decoration: BoxDecoration(
                color: const Color(0xff635BFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(w * .04),
                  bottomLeft: Radius.circular(w * .04),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * .05,
                    vertical: w * .045,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: w * .045,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                        color: highlighted
                            ? const Color(0xff635BFF)
                            : const Color(0xff667085),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...items,
              ],
            ),
          ),
        ],
      ),
    );
  }
}