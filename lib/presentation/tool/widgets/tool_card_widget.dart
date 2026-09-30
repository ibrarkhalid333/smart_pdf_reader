import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/core/models/tool_model.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ToolCardWidget extends StatelessWidget {
  final ToolModel tool;
  final String status;
  final VoidCallback onTap;

  const ToolCardWidget({
    super.key,
    required this.tool,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44.adaptSize,
              height: 44.adaptSize,
              decoration: BoxDecoration(
                color: appTheme.tealTintBackground,
                borderRadius: BorderRadius.circular(14.adaptSize),
              ),
              child: Icon(
                tool.icon,
                color: appTheme.primaryMid,
                size: 22.fSize,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: textTheme.textStyleRedditSansBold.copyWith(
                    fontSize: 14.fSize,
                    color: appTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.v),
                Text(
                  status,
                  style: textTheme.textStyleRedditSansRegular.copyWith(
                    fontSize: 12.fSize,
                    color: appTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
