import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Bottom sheet displaying the result of a screenshot with share and save status.
class ScreenshotResultSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final bool saved;
  final String title;
  final String? subtitle;
  final VoidCallback onShare;

  const ScreenshotResultSheet({
    super.key,
    required this.imageBytes,
    required this.saved,
    this.title = 'Screenshot taken',
    this.subtitle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appTheme.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: appTheme.tealTintBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: appTheme.primaryMid,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.textStyleRedditSansBold.copyWith(
                          fontSize: 15,
                          color: appTheme.textPrimaryColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: textTheme.textStyleRedditSansMedium.copyWith(
                            fontSize: 12,
                            color: saved
                                ? appTheme.primaryMid
                                : appTheme.dangerRed,
                          ),
                        )
                      else if (saved)
                        Text(
                          'Saved to your gallery',
                          style: textTheme.textStyleRedditSansMedium.copyWith(
                            fontSize: 12,
                            color: appTheme.primaryMid,
                          ),
                        )
                      else
                        Text(
                          'Could not save to gallery',
                          style: textTheme.textStyleRedditSansMedium.copyWith(
                            fontSize: 12,
                            color: appTheme.dangerRed,
                          ),
                        ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: appTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: appTheme.textMutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Screenshot preview ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Share button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                      onShare();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [appTheme.primaryMid, appTheme.primaryColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: appTheme.primaryColor.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Share',
                            style: textTheme.textStyleRedditSansSemiBold
                                .copyWith(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
