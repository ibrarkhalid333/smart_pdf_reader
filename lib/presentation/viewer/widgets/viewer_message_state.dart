import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Message state widget for displaying error, empty, or unavailable states in the PDF viewer.
class ViewerMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ViewerMessageState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: appTheme.textMutedColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.textStyleRedditSansBold.copyWith(
                color: appTheme.textPrimaryColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.textStyleRedditSansRegular.copyWith(
                color: appTheme.textMutedColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: Get.back,
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
