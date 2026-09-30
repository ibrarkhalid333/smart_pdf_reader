import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/wallet/controller/wallet_controller.dart';
import 'package:smart_pdf_reader/presentation/widgets/coin_balance_pill.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class WalletScreen extends GetWidget<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalCoinController coinController =
        Get.find<GlobalCoinController>();
    return Scaffold(
      backgroundColor: appTheme.screenBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient Hero Section (Extends to top of screen)

            // Balance Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).padding.top +
                    16.v, // Status bar padding
                bottom: 24.v,
                left: 20.h,
                right: 20.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    appTheme.primaryGradientStart, // #14564C
                    appTheme.primaryPale, // #2F9485
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text(
                        'Your Balance',
                        style: textTheme.textStyleRedditSansRegular.copyWith(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14.fSize,
                        ),
                      ),
                      const CoinBalancePill(),
                    ],
                  ),
                  SizedBox(height: 16.v),
                  Obx(
                    () => Row(
                      crossAxisAlignment: .baseline,
                      textBaseline: .alphabetic,
                      children: [
                        Text(
                          '${coinController.balance.value}',
                          style: textTheme.textStyleRedditSansBold.copyWith(
                            color: Colors.white,
                            fontSize: 48.fSize,
                            height: 1,
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Text(
                          'coins',
                          style: textTheme.textStyleRedditSansBold.copyWith(
                            color: appTheme.coinGold,
                            fontSize: 18.fSize,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.v),
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          '${coinController.totalEarned.value}',
                          'Total Earned',
                        ),
                        SizedBox(width: 2.h),
                        _buildStatCard(
                          '${coinController.totalSpent.value}',
                          'Total Spent',
                        ),
                        SizedBox(width: 2.h),
                        _buildStatCard(
                          '+${coinController.todayEarned.value}',
                          'Today',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // SizedBox(height: 24.v),
            Padding(
              padding: EdgeInsets.only(
                left: 20.h,
                right: 20.h,
                top: 24.v,
                bottom: 12.v,
              ),
              child: Align(
                alignment: .centerLeft,
                child: Text(
                  'HOW TO EARN',
                  style: textTheme.textStyleRedditSansSemiBold.copyWith(
                    fontSize: 12.fSize,
                    color: appTheme.textMutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Tasks List
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  itemCount: controller.earnTasks.length,

                  itemBuilder: (context, index) {
                    final task = controller.earnTasks[index];
                    return _buildTaskCard(task);
                    // return Container(
                    //   padding: EdgeInsets.all(12.h),
                    //   decoration: BoxDecoration(
                    //     color: appTheme.surfaceColor,
                    //     borderRadius: BorderRadius.circular(12.h),
                    //   ),
                    //   child: Row(
                    //     children: [
                    //       Container(
                    //         padding: EdgeInsets.all(8.h),
                    //         decoration: BoxDecoration(
                    //           color: appTheme.primaryColor.withOpacity(0.1),
                    //           shape: BoxShape.circle,
                    //         ),
                    //         child: Icon(
                    //           task.icon,
                    //           color: appTheme.primaryColor,
                    //           size: 20.fSize,
                    //         ),
                    //       ),
                    //       SizedBox(width: 12.h),
                    //       Expanded(
                    //         child: Column(
                    //           crossAxisAlignment: .start,

                    //           children: [
                    //             Text(
                    //               task.title,
                    //               style: textTheme.textStyleRedditSansSemiBold
                    //                   .copyWith(
                    //                     fontSize: 14.fSize,
                    //                     color: appTheme.textPrimaryColor,
                    //                   ),
                    //             ),
                    //             Text(
                    //               task.subtitle,
                    //               style: textTheme.textStyleRedditSansRegular
                    //                   .copyWith(
                    //                     fontSize: 12.fSize,
                    //                     color: appTheme.textSecondaryColor,
                    //                   ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //       Container(
                    //         padding: EdgeInsets.symmetric(
                    //           horizontal: 8.h,
                    //           vertical: 4.v,
                    //         ),
                    //         decoration: BoxDecoration(
                    //           color: appTheme.coinGold.withAlpha(15),
                    //           borderRadius: BorderRadius.circular(8.h),
                    //         ),
                    //         child: Text(
                    //           '${task.reward} coins',
                    //           style: textTheme.textStyleRedditSansBold.copyWith(
                    //             color: appTheme.coinGold,
                    //             fontSize: 12.fSize,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget for the balance card stats
Widget _buildStatCard(String value, String label) {
  return Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 14.v),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.textStyleRedditSansBold.copyWith(
              fontSize: 18.fSize,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            label,
            style: textTheme.textStyleRedditSansRegular.copyWith(
              fontSize: 12.fSize,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTaskCard(EarnTask task) {
  return Container(
    margin: EdgeInsets.only(bottom: 10.v),
    padding: EdgeInsets.all(10.h),
    decoration: BoxDecoration(
      color: appTheme.surfaceColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appTheme.tealTintBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(task.icon, color: appTheme.primaryMid, size: 22.fSize),
        ),
        SizedBox(width: 14.h),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 12.fSize,
                  color: appTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 4.v),
              Text(
                task.subtitle,
                style: textTheme.textStyleRedditSansRegular.copyWith(
                  fontSize: 8.fSize,
                  color: appTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        // Reward badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.h, vertical: 3.v),
          decoration: BoxDecoration(
            color: appTheme.coinBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                color: appTheme.coinGold,
                size: 14.fSize,
              ),
              SizedBox(width: 4.h),
              Text(
                '+${task.reward}',
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 13.fSize,
                  color: appTheme.coinGold,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
