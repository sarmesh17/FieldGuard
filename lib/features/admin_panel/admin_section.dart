import 'package:fieldguard/features/admin_panel/admin_panel.dart';
import 'package:flutter/material.dart';

class AdminSection extends StatelessWidget {
  final double width;
  final String title;
  final List<MenuItemData> items;
  final Color accent;

  const AdminSection({
    super.key,
    required this.width,
    required this.title,
    required this.items,
    this.accent = const Color(0xff5B4CFF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * .04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .012,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(width * .04),
                bottomLeft: Radius.circular(width * .04),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * .05,
                    vertical: width * .05,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: width * .05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ...List.generate(items.length, (index) {
                  final item = items[index];

                  return Column(
                    children: [
                      if (index != 0)
                        Divider(
                          height: 0,
                          color: Colors.black.withOpacity(.08),
                        ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * .05,
                          vertical: width * .045,
                        ),
                        child: Row(
                          children: [
                            if (item.icon != null)
                              Padding(
                                padding: EdgeInsets.only(right: width * .03),
                                child: Icon(
                                  item.icon,
                                  size: width * .05,
                                  color:
                                      item.iconColor ?? const Color(0xff0B5A37),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: width * .04,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (item.badge != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * .025,
                                  vertical: width * .012,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xffF3F2EE),
                                  borderRadius: BorderRadius.circular(
                                    width * .03,
                                  ),
                                ),
                                child: Text(
                                  item.badge!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: width * .025,
                                    color: const Color(0xffA29B92),
                                  ),
                                ),
                              ),
                            SizedBox(width: width * .03),
                            Icon(
                              Icons.chevron_right,
                              color: const Color(0xff9E968D),
                              size: width * .06,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
