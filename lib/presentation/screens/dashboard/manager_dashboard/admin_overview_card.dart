import 'package:flutter/material.dart';

class AdminOverviewCard extends StatelessWidget {
  const AdminOverviewCard();

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xff687184)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffE8E1D7)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 340,
            decoration: const BoxDecoration(
              color: Color(0xff635BFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                bottomLeft: Radius.circular(28),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ADMIN OVERVIEW",
                    style: TextStyle(
                      color: Color(0xff635BFF),
                      letterSpacing: 1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRow("Total Reps Registered", "24"),
                  const Divider(),
                  _buildRow("Shops in System", "186"),
                  const Divider(),
                  _buildRow("NFC Tags Deployed", "142 / 186"),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Manage System",
                          style: TextStyle(
                            color: Color(0xff635BFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Color(0xff635BFF)),
                      ],
                    ),
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