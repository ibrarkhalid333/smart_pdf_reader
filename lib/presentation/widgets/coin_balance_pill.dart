import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class CoinBalancePill extends StatelessWidget {
  const CoinBalancePill({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalCoinController controller = Get.find<GlobalCoinController>();
    return Obx(
      () => Container(
        // padding: EdgeInsets.symmetric(horizontal: 12.h,vertical: 6.v),
        decoration: BoxDecoration(
          color: appTheme.coinGold.withAlpha(10),
          borderRadius: BorderRadius.circular(20.adaptSize),
        ),
        child: Row(
          children: [
            Icon(
              Icons.monetization_on,
              color: appTheme.coinGold,
              size: 16.fSize,
            ),
            SizedBox(width: 4.h),
            Text(
              '${controller.balance.value}',
              style: textTheme.textStyleRedditSansBold.copyWith(
                color: appTheme.coinGold,
                fontSize: 14.fSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
