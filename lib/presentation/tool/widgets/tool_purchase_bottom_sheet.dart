import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/tool/controller/tool_controller.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ToolPurchaseBottomSheet extends StatelessWidget {
  final ShopItem item;

  const ToolPurchaseBottomSheet({super.key, required this.item});

  static void show(BuildContext context, ShopItem item) {
    Get.bottomSheet(
      ToolPurchaseBottomSheet(item: item),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ToolController controller = Get.find<ToolController>();
    final GlobalCoinController globalCoin = controller.globalCoin;
    final canAfford = globalCoin.balance.value >= item.cost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: appTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: appTheme.tealTintBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    color: appTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: textTheme.textStyleRedditSansSemiBold.copyWith(
                          fontSize: 18,
                          color: appTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium PDF feature',
                        style: textTheme.textStyleRedditSansRegular.copyWith(
                          fontSize: 14,
                          color: appTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: appTheme.coinBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.isPermanent ? 'Unlock permanently' : 'Unlock pack',
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      fontSize: 14,
                      color: appTheme.coinTextDark,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: appTheme.coinGold,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.cost} coins',
                        style: textTheme.textStyleRedditSansSemiBold.copyWith(
                          fontSize: 14,
                          color: appTheme.coinTextDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final bal = globalCoin.balance.value;
              final rem = bal - item.cost;
              return Text(
                rem >= 0
                    ? 'You have $bal coins · $rem remaining after unlock'
                    : 'You have $bal coins · Need ${item.cost - bal} more',
                style: textTheme.textStyleRedditSansRegular.copyWith(
                  fontSize: 13,
                  color: appTheme.textMutedColor,
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford
                    ? () async {
                        final success = await controller.purchaseTool(item);
                        if (success) Get.back();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: appTheme.borderDefault,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  canAfford
                      ? 'Unlock for ${item.cost} coins'
                      : 'Not enough coins',
                  style: textTheme.textStyleRedditSansSemiBold.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!canAfford)
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.openStore();
                },
                child: Text(
                  'Earn more coins first',
                  style: textTheme.textStyleRedditSansRegular.copyWith(
                    color: appTheme.textMutedColor,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
