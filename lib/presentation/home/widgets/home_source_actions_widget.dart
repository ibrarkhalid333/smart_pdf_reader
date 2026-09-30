import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomeSourceActionsWidget extends StatelessWidget {
  final Function(String source) onSourceSelected;

  const HomeSourceActionsWidget({
    super.key,
    required this.onSourceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sources = [
      {'label': 'Local files', 'icon': Icons.folder_outlined},
      {'label': 'Cloud', 'icon': Icons.cloud_outlined},
      {'label': 'URL', 'icon': Icons.link_rounded},
      {'label': 'Scan', 'icon': Icons.camera_alt_outlined},
    ];

    return Row(
      children: sources.map((item) {
        final String label = item['label'];
        final IconData icon = item['icon'];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.h),
            child: GestureDetector(
              onTap: () => onSourceSelected(label),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.v, horizontal: 4.h),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: appTheme.primaryMid,
                      size: 22.fSize,
                    ),
                    SizedBox(height: 6.v),
                    Text(
                      label,
                      style: textTheme.textStyleRedditSansMedium.copyWith(
                        fontSize: 11.fSize,
                        color: appTheme.textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
