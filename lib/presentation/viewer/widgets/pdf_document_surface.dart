import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/models/reader_theme.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/viewer_message_state.dart';

class PdfDocumentSurface extends StatelessWidget {
  final Key repaintBoundaryKey;
  final String? filePath;
  final String? loadError;
  final Widget scrollView;
  final Widget bookView;
  final bool isBookMode;
  final ReaderTheme readerTheme;

  const PdfDocumentSurface({
    super.key,
    required this.repaintBoundaryKey,
    required this.filePath,
    required this.loadError,
    required this.scrollView,
    required this.bookView,
    required this.isBookMode,
    required this.readerTheme,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (filePath == null) {
      content = const ViewerMessageState(
        icon: Icons.picture_as_pdf_outlined,
        title: 'PDF file is unavailable',
        message: 'This document does not have a readable file path.',
      );
    } else if (loadError != null) {
      content = ViewerMessageState(
        icon: Icons.error_outline,
        title: 'Could not open PDF',
        message: loadError!,
      );
    } else {
      content = isBookMode ? bookView : scrollView;
    }

    final colorFilter = filePath != null && loadError == null
        ? readerTheme.colorFilter
        : null;
    final themedContent = colorFilter == null
        ? content
        : ColorFiltered(colorFilter: colorFilter, child: content);

    return RepaintBoundary(key: repaintBoundaryKey, child: themedContent);
  }
}
