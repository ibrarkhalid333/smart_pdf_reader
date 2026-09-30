import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/tool/controller/tool_controller.dart';
import 'package:smart_pdf_reader/presentation/tool/widgets/tool_purchase_bottom_sheet.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class LockedToolsCardWidget extends StatelessWidget {
  const LockedToolsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolController controller = Get.find<ToolController>();

    return Obx(() {
      final locked = controller.lockedTools;
      if (locked.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(16.adaptSize),
        decoration: BoxDecoration(
          color: appTheme.warmWhite,
          borderRadius: BorderRadius.circular(18.adaptSize),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: count + Open store link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${locked.length} more tools available',
                  style: textTheme.textStyleRedditSansBold.copyWith(
                    fontSize: 14.fSize,
                    color: appTheme.textPrimaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: controller.openStore,
                  child: Text(
                    'Open store',
                    style: textTheme.textStyleRedditSansSemiBold.copyWith(
                      fontSize: 13.fSize,
                      color: appTheme.primaryMid,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.v),

            // Horizontal locked chips
            SizedBox(
              height: 38.v,
              child: ListView.separated(
                controller: controller.lockedScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: locked.length,
                separatorBuilder: (context, index) => SizedBox(width: 8.h),
                itemBuilder: (context, index) {
                  final tool = locked[index];
                  return GestureDetector(
                    onTap: () {
                      final shopItem = controller.getShopItemForTool(tool);
                      if (shopItem != null) {
                        ToolPurchaseBottomSheet.show(context, shopItem);
                      } else {
                        controller.openStore();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 6.v,
                      ),
                      decoration: BoxDecoration(
                        color: appTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12.adaptSize),
                        border: Border.all(
                          color: appTheme.borderDefault,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 14.fSize,
                            color: appTheme.textMutedColor,
                          ),
                          SizedBox(width: 6.h),
                          Text(
                            tool.name,
                            style: textTheme.textStyleRedditSansMedium.copyWith(
                              fontSize: 12.fSize,
                              color: appTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 12.v),

            // Horizontal Scroll indicator with arrows
            Row(
              children: [
                GestureDetector(
                  onTap: controller.scrollLeft,
                  child: Icon(
                    Icons.arrow_left,
                    size: 20.fSize,
                    color: appTheme.textMutedColor,
                  ),
                ),
                SizedBox(width: 4.h),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Obx(() {
                        final progress = controller.scrollProgress.value;
                        final trackWidth = constraints.maxWidth;
                        final thumbWidth = trackWidth * 0.4;
                        final leftOffset =
                            (trackWidth - thumbWidth) * progress;

                        return Container(
                          height: 6.v,
                          decoration: BoxDecoration(
                            color: appTheme.borderMid,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: leftOffset,
                                top: 0,
                                bottom: 0,
                                width: thumbWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: appTheme.lockedBorderColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                ),
                SizedBox(width: 4.h),
                GestureDetector(
                  onTap: controller.scrollRight,
                  child: Icon(
                    Icons.arrow_right,
                    size: 20.fSize,
                    color: appTheme.textMutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
