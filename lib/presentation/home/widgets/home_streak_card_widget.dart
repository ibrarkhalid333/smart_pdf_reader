import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomeStreakCardWidget extends StatelessWidget {
  const HomeStreakCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalCoinController globalCoin = Get.find<GlobalCoinController>();

    return Obx(() {
      final int streak = globalCoin.currentStreak.value > 0
          ? globalCoin.currentStreak.value
          : 5;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.v),
        decoration: BoxDecoration(
          color: appTheme.warmWhite,
          borderRadius: BorderRadius.circular(16.adaptSize),
          border: Border.all(
            color: appTheme.borderDefault.withValues(alpha: 0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flame Icon / Emoji
            Text(
              '🔥',
              style: TextStyle(fontSize: 24.fSize),
            ),
            SizedBox(width: 14.h),

            // Streak Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak-day streak',
                    style: textTheme.textStyleRedditSansBold.copyWith(
                      fontSize: 14.fSize,
                      color: appTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2.v),
                  Text(
                    'Read today to keep it going',
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      fontSize: 12.fSize,
                      color: appTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // +25 coins pill
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10.h,
                vertical: 5.v,
              ),
              decoration: BoxDecoration(
                color: appTheme.coinBackground,
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              child: Text(
                '+25 coins',
                style: textTheme.textStyleRedditSansBold.copyWith(
                  fontSize: 12.fSize,
                  color: appTheme.coinTextDark,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
