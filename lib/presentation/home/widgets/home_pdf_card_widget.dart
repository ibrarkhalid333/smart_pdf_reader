import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/services/pdf_thumbnail_service.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomePdfCardWidget extends StatelessWidget {
  final PdfDocument pdf;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const HomePdfCardWidget({
    super.key,
    required this.pdf,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = pdf.pages > 0
        ? (pdf.pagesRead / pdf.pages).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.v),
        padding: EdgeInsets.all(14.adaptSize),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File preview box
            Container(
              width: 46.adaptSize,
              height: 46.adaptSize,
              decoration: BoxDecoration(
                color: appTheme.tealTintBackground,
                borderRadius: BorderRadius.circular(12.adaptSize),
              ),
              clipBehavior: Clip.antiAlias,
              child: pdf.filePath == null
                  ? _buildFileIcon()
                  : FutureBuilder<Uint8List?>(
                      future: PdfThumbnailService.instance.load(pdf.filePath!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          );
                        }
                        return _buildFileIcon();
                      },
                    ),
            ),
            SizedBox(width: 14.h),

            // Middle info: Title, pages/date, and progress bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pdf.title,
                    style: textTheme.textStyleRedditSansBold.copyWith(
                      fontSize: 14.fSize,
                      color: appTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.v),
                  Text(
                    pdf.subtitle,
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      fontSize: 12.fSize,
                      color: appTheme.textMutedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.v),

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.h),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: (3.5.v > 0) ? 3.5.v : 3.5,
                            backgroundColor: appTheme.borderMid,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              appTheme.primaryMid,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.h),
                      Text(
                        '${pdf.pagesRead}/${pdf.pages} read',
                        style: textTheme.textStyleRedditSansMedium.copyWith(
                          fontSize: 10.fSize,
                          color: appTheme.textMutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.h),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pdf.isFavourite)
                  Padding(
                    padding: EdgeInsets.only(right: 8.h),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18.fSize,
                    ),
                  ),
                GestureDetector(
                  onTap: onMoreTap,
                  child: Padding(
                    padding: EdgeInsets.all(4.adaptSize),
                    child: Icon(
                      Icons.more_vert,
                      color: appTheme.textMutedColor,
                      size: 20.fSize,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.description_outlined,
          color: appTheme.primaryMid,
          size: 28.fSize,
        ),
        Positioned(
          bottom: 9.v,
          child: Text(
            'PDF',
            style: textTheme.textStyleRedditSansBold.copyWith(
              fontSize: 8.fSize,
              color: appTheme.primaryMid,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
