import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/store/controller/store_controller.dart';
import 'package:smart_pdf_reader/presentation/widgets/coin_balance_pill.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class StoreScreen extends GetWidget<StoreController> {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // print(controller.getItemsByTier('Tier 1'));
    return Scaffold(
      backgroundColor: appTheme.screenBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140.v),
        child: AppBar(
          backgroundColor: appTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 140.v,
          titleSpacing: 20.h,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          'Feature store',
                          style: textTheme.textStyleRedditSansBold.copyWith(
                            fontSize: 22.fSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.v),
                        Text(
                          'Unlock with coins earned from reading',
                          style: textTheme.textStyleRedditSansRegular.copyWith(
                            fontSize: 13.fSize,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CoinBalancePill(),
                ],
              ),
              SizedBox(height: 14.v),
              Obx(() {
                final coinController = Get.find<GlobalCoinController>();
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.h,
                    vertical: 8.v,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: appTheme.coinGold,
                        size: 16.fSize,
                      ),
                      SizedBox(width: 6.h),
                      Text(
                        '${coinController.balance.value} coins available',
                        style: textTheme.textStyleRedditSansMedium.copyWith(
                          fontSize: 13.fSize,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.shopItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                _buildTierSection(
                  'Tier 1',
                  'Quick wins · day 1',
                  const Color(0xFF2563EB),
                  controller.getItemsByTier('Tier 1'),
                ),
                SizedBox(height: 24.v),
                _buildTierSection(
                  'Tier 2',
                  'Short term · day 2-4',
                  const Color(0xFF9333EA),
                  controller.getItemsByTier('Tier 2'),
                ),
                SizedBox(height: 24.v),
                _buildTierSection(
                  'Tier 3',
                  'Mid term · day 5-10',
                  const Color(0xFFEA580C),
                  controller.getItemsByTier('Tier 3'),
                ),
                SizedBox(height: 24.v),
                _buildTierSection(
                  'Tier 4',
                  'Long term · day 10-20',
                  const Color(0xFFDC2626),
                  controller.getItemsByTier('Tier 4'),
                ),
                SizedBox(height: 20.v),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTierSection(
    String tierLabel,
    String tierSubtitle,
    Color badgeColor,
    List<ShopItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 5.v),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tierLabel,
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 12.fSize,
                  color: badgeColor,
                ),
              ),
            ),
            SizedBox(width: 10.h),
            Text(
              tierSubtitle,
              style: textTheme.textStyleRedditSansRegular.copyWith(
                fontSize: 13.fSize,
                color: appTheme.textMutedColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.v),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildShopItemCard(items[index]),
        ),
      ],
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    return Obx(() {
      final isOwned = controller.isItemUnlocked(item.id);
      return GestureDetector(
        onTap: isOwned ? null : () => _showPurchaseSheet(item),
        child: Container(
          padding: EdgeInsets.all(5.h),
          decoration: BoxDecoration(
            color: appTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10.h),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Container(
                width: 28.h,
                height: 28.v,
                decoration: BoxDecoration(
                  color: isOwned
                      ? appTheme.tealTintBackground
                      : appTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFeatureIcon(item.id),
                  color: isOwned
                      ? appTheme.primaryMid
                      : appTheme.lockedIconColor,
                  size: 18.fSize,
                ),
              ),
              SizedBox(height: 8.v),
              Text(
                item.name,
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 13.fSize,
                  color: appTheme.textPrimaryColor,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.v),
              if (isOwned)
                Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: appTheme.primaryMid,
                      size: 12.fSize,
                    ),
                    SizedBox(width: 3.h),
                    Text(
                      'Owned',
                      style: textTheme.textStyleRedditSansMedium.copyWith(
                        fontSize: 11.fSize,
                        color: appTheme.primaryMid,
                        height: 1,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: appTheme.coinGold,
                      size: 11.fSize,
                    ),
                    SizedBox(width: 4.h),
                    Text(
                      _getCostLabel(item),
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        fontSize: 11.fSize,
                        color: appTheme.textSecondaryColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showPurchaseSheet(ShopItem item) {
    final coinController = Get.find<GlobalCoinController>();
    final canAfford = coinController.balance.value >= item.cost;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: appTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.h)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: .min,
            children: [
              Container(
                width: 40.h,
                height: 4.v,
                decoration: BoxDecoration(
                  color: appTheme.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20.v),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: appTheme.tealTintBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getFeatureIcon(item.id),
                      color: appTheme.primaryColor,
                      size: 24.fSize,
                    ),
                  ),
                  SizedBox(width: 16.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          item.name,
                          style: textTheme.textStyleRedditSansSemiBold.copyWith(
                            fontSize: 18.fSize,
                            color: appTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 4.v),
                        Text(
                          'Premium PDF feature',
                          style: textTheme.textStyleRedditSansRegular.copyWith(
                            fontSize: 14.fSize,
                            color: appTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.v),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
                decoration: BoxDecoration(
                  color: appTheme.coinBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(
                      item.isPermanent ? 'Unlock permanently' : 'Unlock pack',
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        fontSize: 14.fSize,
                        color: appTheme.coinTextDark,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: appTheme.coinGold,
                          size: 18.fSize,
                        ),
                        SizedBox(width: 4.h),
                        Text(
                          '${item.cost} coins',
                          style: textTheme.textStyleRedditSansSemiBold.copyWith(
                            fontSize: 14.fSize,
                            color: appTheme.coinTextDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.v),
              Obx(() {
                final bal = coinController.balance.value;
                final rem = bal - item.cost;
                return Text(
                  rem >= 0
                      ? 'You have $bal coins · $rem remaining after unlock'
                      : 'You have $bal coins · Need ${item.cost - bal} more',
                  style: textTheme.textStyleRedditSansRegular.copyWith(
                    fontSize: 13.fSize,
                    color: appTheme.textMutedColor,
                  ),
                );
              }),
              SizedBox(height: 20.v),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canAfford
                      ? () async {
                          final success = await controller.purchaseItem(item);
                          if (success) Get.back();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: appTheme.borderDefault,
                    padding: EdgeInsets.symmetric(vertical: 16.v),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    canAfford
                        ? 'Unlock for ${item.cost} coins'
                        : 'Not enough coins',
                    style: textTheme.textStyleRedditSansSemiBold.copyWith(
                      fontSize: 16.fSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.v),
              if (!canAfford)
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Earn more coins first',
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      color: appTheme.textMutedColor,
                      fontSize: 14.fSize,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // Widget _buildShopItemCard(ShopItem item) {
  //   bool isUnlocked = controller.unlockedItems.contains(item.id);

  //   return Container(
  //     margin: EdgeInsets.only(bottom: 8.v),
  //     padding: EdgeInsets.all(12.h),
  //     decoration: BoxDecoration(
  //       color: appTheme.surfaceColor,
  //       borderRadius: BorderRadius.circular(12.h),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 40.h,
  //           height: 40.v,
  //           decoration: BoxDecoration(
  //             color: appTheme.primaryColor.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8.h),
  //           ),
  //           child: Icon(
  //             Icons.lock_outline,
  //             color: appTheme.primaryColor,
  //             size: 20.fSize,
  //           ),
  //         ),
  //         SizedBox(width: 12.h),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 item.name,
  //                 style: textTheme.textStyleRedditSansSemiBold.copyWith(
  //                   fontSize: 14.fSize,
  //                   color: appTheme.textPrimaryColor,
  //                 ),
  //               ),
  //               Text(
  //                 item.isPermanent ? 'Permanent' : 'Temporary',
  //                 style: textTheme.textStyleRedditSansRegular.copyWith(
  //                   fontSize: 12.fSize,
  //                   color: appTheme.textSecondaryColor,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         if (isUnlocked)
  //           Icon(Icons.check_circle, color: Colors.green, size: 24.fSize)
  //         else
  //           Row(
  //             children: [
  //               Icon(
  //                 Icons.monetization_on,
  //                 color: appTheme.coinGold,
  //                 size: 16.fSize,
  //               ),
  //               SizedBox(width: 4.h),
  //               Text(
  //                 '${item.cost}',
  //                 style: textTheme.textStyleRedditSansBold.copyWith(
  //                   fontSize: 14.fSize,
  //                   color: appTheme.textPrimaryColor,
  //                 ),
  //               ),
  //               SizedBox(width: 8.h),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   bool success = controller.purchaseItem(item);
  //                   if (!success) {
  //                     Get.snackbar(
  //                       'Not enough coins',
  //                       'Read more pages to earn coins!',
  //                     );
  //                   }
  //                 },
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: appTheme.primaryColor,
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: 12.h,
  //                     vertical: 4.v,
  //                   ),
  //                   minimumSize: Size(40.h, 30.v),
  //                 ),
  //                 child: Text(
  //                   'Buy',
  //                   style: textTheme.textStyleRedditSansMedium.copyWith(
  //                     color: Colors.white,
  //                     fontSize: 12.fSize,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //       ],
  //     ),
  //   );
  // }

  IconData _getFeatureIcon(String id) {
    if (id.contains('dark') || id.contains('theme'))
      return Icons.dark_mode_outlined;
    if (id.contains('sticky') || id.contains('note'))
      return Icons.sticky_note_2_outlined;
    if (id.contains('highlight') || id.contains('color'))
      return Icons.color_lens_outlined;
    if (id.contains('auto_scroll')) return Icons.play_arrow_outlined;
    if (id.contains('screenshot')) return Icons.crop_free_outlined;
    if (id.contains('drawing') || id.contains('freehand'))
      return Icons.brush_outlined;
    if (id.contains('shape')) return Icons.shape_line_outlined;
    if (id.contains('reorder') || id.contains('page')) return Icons.reorder;
    if (id.contains('export')) return Icons.upload_outlined;
    if (id.contains('fill') || id.contains('sign') || id.contains('form'))
      return Icons.edit_note_outlined;
    if (id.contains('split')) return Icons.call_split_outlined;
    if (id.contains('merge')) return Icons.merge_type_outlined;
    if (id.contains('read_aloud') || id.contains('tts'))
      return Icons.volume_up_outlined;
    if (id.contains('compress')) return Icons.compress_outlined;
    if (id.contains('reflow') || id.contains('ebook'))
      return Icons.menu_book_outlined;
    if (id.contains('password')) return Icons.lock_outline;
    if (id.contains('multi_tab')) return Icons.tab_outlined;
    if (id.contains('annotation')) return Icons.comment_outlined;
    if (id.contains('signature')) return Icons.draw_outlined;
    if (id.contains('stamp') || id.contains('text'))
      return Icons.approval_outlined;
    return Icons.star_outline;
  }

  String _getCostLabel(ShopItem item) {
    if (item.id.contains('color')) return '${item.cost} / color';
    if (item.id.contains('screenshot') &&
        !item.id.contains('month') &&
        !item.id.contains('unlimited')) {
      return '${item.cost} · 5 uses';
    }
    if (item.isPermanent) return '${item.cost} · permanent';
    if (item.id.contains('month')) return '${item.cost} · monthly';
    return '${item.cost} · pack';
  }
}
