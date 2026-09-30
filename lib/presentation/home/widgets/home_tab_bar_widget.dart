import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomeTabBarWidget extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int index) onTabSelected;

  const HomeTabBarWidget({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: appTheme.borderDefault.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool isSelected = selectedIndex == index;
          final String title = tabs[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.v),
                    child: Text(
                      title,
                      style: isSelected
                          ? textTheme.textStyleRedditSansBold.copyWith(
                              fontSize: 14.fSize,
                              color: appTheme.primaryColor,
                            )
                          : textTheme.textStyleRedditSansMedium.copyWith(
                              fontSize: 14.fSize,
                              color: appTheme.textMutedColor,
                            ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Active indicator bar
                  Container(
                    height: 2.5.v,
                    margin: EdgeInsets.symmetric(horizontal: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? appTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
