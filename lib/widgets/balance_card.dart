import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../globalclass/chanzo_color.dart';
import '../globalclass/kiotapay_fontstyle.dart';

class BalanceCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final bool showValue;

  const BalanceCard({
    required this.title,
    required this.value,
    required this.backgroundColor,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              title.tr,
              style: pregular.copyWith(
                fontSize: 18,
                color: ChanzoColors.primary,
              ),
            ),
            Text(
              showValue ? value : "********",
              style: pmedium.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}