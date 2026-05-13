import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String? suffix;
  final Color valueColor;
  final Color? sideColor;

  const SummaryCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.valueColor,
    this.suffix,
    this.sideColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: width * .3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
                width * .03),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (sideColor != null)
            Container(
              width: width * .01,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius:
                    BorderRadius.only(
                  topLeft: Radius.circular(
                      width * .03),
                  bottomLeft:
                      Radius.circular(
                          width * .03),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(
                horizontal: width * .035,
                vertical: width * .04,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize:
                          width * .035,
                      letterSpacing: 1,
                      color: const Color(
                          0xff62697A),
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize:
                              width * .06,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color:
                              valueColor,
                        ),
                      ),
                      if (suffix != null)
                        Padding(
                          padding:
                              EdgeInsets.only(
                            bottom:
                                width * .01,
                            left:
                                width * .01,
                          ),
                          child: Text(
                            suffix!,
                            style:
                                TextStyle(
                              fontSize:
                                  width *
                                      .045,
                              color:
                                  const Color(
                                      0xff9A958F),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
