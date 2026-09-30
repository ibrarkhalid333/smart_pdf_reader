import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ToolHeaderCoinPill extends StatelessWidget {
  const ToolHeaderCoinPill({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalCoinController coinController =
        Get.find<GlobalCoinController>();

    return Obx(
      () => Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.h,
          vertical: 6.v,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF3A026),
          borderRadius: BorderRadius.circular(20.adaptSize),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monetization_on,
              color: const Color(0xFF412402),
              size: 16.fSize,
            ),
            SizedBox(width: 4.h),
            Text(
              '${coinController.balance.value} coins',
              style: textTheme.textStyleRedditSansBold.copyWith(
                fontSize: 13.fSize,
                color: const Color(0xFF412402),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
