import 'package:flutter/material.dart';

class ShopCard extends StatelessWidget {
  final double width;
  final String title;
  final String owner;
  final String address;
  final String amount;
  final String status;
  final Color amountColor;
  final Color statusColor;
  final Color statusBg;
  final Color sideColor;

  const ShopCard({
    super.key,
    required this.width,
    required this.title,
    required this.owner,
    required this.address,
    required this.amount,
    required this.status,
    required this.amountColor,
    required this.statusColor,
    required this.statusBg,
    required this.sideColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(width * .035),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: width * .01,
            height: width * .29,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: BorderRadius.only(
                topLeft:
                    Radius.circular(width * .035),
                bottomLeft:
                    Radius.circular(width * .035),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(width * .04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight:
                      Radius.circular(width * .035),
                  bottomRight:
                      Radius.circular(width * .035),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: width * .12,
                    height: width * .12,
                    decoration: BoxDecoration(
                      color: const Color(0xffF2F2F2),
                      borderRadius:
                          BorderRadius.circular(
                        width * .025,
                      ),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: width * .055,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  SizedBox(width: width * .035),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      width * .045,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: width * .02),
                            Container(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal:
                                    width * .022,
                                vertical:
                                    width * .008,
                              ),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  width * .04,
                                ),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize:
                                      width * .024,
                                  color:
                                      statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: width * .01),

                        Text(
                          owner,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * .03,
                            color:
                                Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),

                        SizedBox(height: width * .012),

                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: width * .03,
                              color:
                                  Colors.grey.shade500,
                            ),
                            SizedBox(width: width * .01),
                            Expanded(
                              child: Text(
                                address,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style: TextStyle(
                                  fontSize:
                                      width * .03,
                                  color: Colors
                                      .grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: width * .025),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: width * .05,
                          fontWeight:
                              FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                      SizedBox(height: width * .04),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade500,
                        size: width * .06,
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

