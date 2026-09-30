import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ViewerCaptureMenuSheet extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onMultiPageSnip;
  final VoidCallback onVisibleViewSnip;
  final VoidCallback onSaveFullPage;
  final VoidCallback onQuickScreenshot;

  const ViewerCaptureMenuSheet({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onMultiPageSnip,
    required this.onVisibleViewSnip,
    required this.onSaveFullPage,
    required this.onQuickScreenshot,
  });

  static Future<void> show({
    required int currentPage,
    required int pageCount,
    required VoidCallback onMultiPageSnip,
    required VoidCallback onVisibleViewSnip,
    required VoidCallback onSaveFullPage,
    required VoidCallback onQuickScreenshot,
  }) {
    return Get.bottomSheet<void>(
      ViewerCaptureMenuSheet(
        currentPage: currentPage,
        pageCount: pageCount,
        onMultiPageSnip: onMultiPageSnip,
        onVisibleViewSnip: onVisibleViewSnip,
        onSaveFullPage: onSaveFullPage,
        onQuickScreenshot: onQuickScreenshot,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: appTheme.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Page Capture & Tools',
                      style: textTheme.textStyleRedditSansBold.copyWith(
                        fontSize: 17,
                        color: appTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Page $currentPage of $pageCount',
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        fontSize: 13,
                        color: appTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: Get.back,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CaptureActionTile(
              icon: Icons.crop_rounded,
              iconColor: appTheme.primaryColor,
              iconBgColor: appTheme.tealTintBackground,
              title: 'Snipping Tool (Multi-Page)',
              subtitle:
                  'Stretch across pages (above & below). Not limited to 1 page.',
              badge: 'Continuous',
              onTap: onMultiPageSnip,
            ),
            const SizedBox(height: 12),
            _CaptureActionTile(
              icon: Icons.fullscreen_rounded,
              iconColor: Colors.teal.shade700,
              iconBgColor: Colors.teal.shade50,
              title: 'Snip Visible Screen View',
              subtitle:
                  'Crop directly from current visible zoom and scroll position.',
              onTap: onVisibleViewSnip,
            ),
            const SizedBox(height: 12),
            _CaptureActionTile(
              icon: Icons.photo_library_outlined,
              iconColor: appTheme.dangerRed,
              iconBgColor: appTheme.dangerRedLight,
              title: 'Save Page as Image (Adobe Style)',
              subtitle: 'Export clean, high-res full page directly to Gallery.',
              onTap: onSaveFullPage,
            ),
            const SizedBox(height: 12),
            _CaptureActionTile(
              icon: Icons.camera_alt_outlined,
              iconColor: Colors.deepPurple,
              iconBgColor: appTheme.purpleAccentLight,
              title: 'Quick Screenshot',
              subtitle: 'Capture current visible screen as currently zoomed.',
              onTap: onQuickScreenshot,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _CaptureActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.back();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: appTheme.borderDefault.withValues(alpha: 0.7),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: textTheme.textStyleRedditSansBold.copyWith(
                              fontSize: 14,
                              color: appTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: appTheme.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: appTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        fontSize: 12,
                        color: appTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: appTheme.textMutedColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
