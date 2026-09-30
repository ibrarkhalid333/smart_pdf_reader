import 'dart:typed_data';
import 'package:flutter/painting.dart';

/// Model representing the result of a multi-page PDF strip capture.
/// This is a viewer-local model and is not shared with other features.
class MultiPageCaptureResult {
  final Uint8List imageBytes;
  final int startPage;
  final int endPage;
  final int activePage;
  final int totalPages;
  final Rect initialCropFraction;

  const MultiPageCaptureResult({
    required this.imageBytes,
    required this.startPage,
    required this.endPage,
    required this.activePage,
    required this.totalPages,
    required this.initialCropFraction,
  });
}
