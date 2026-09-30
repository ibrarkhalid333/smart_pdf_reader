import 'dart:typed_data';

import 'package:pdfx/pdfx.dart';

class PdfThumbnailService {
  PdfThumbnailService._();

  static final PdfThumbnailService instance = PdfThumbnailService._();
  final Map<String, Future<Uint8List?>> _cache = {};

  Future<Uint8List?> load(String filePath) {
    return _cache.putIfAbsent(filePath, () => _renderFirstPage(filePath));
  }

  Future<int> pageCount(String filePath) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openFile(filePath);
      return document.pagesCount;
    } catch (_) {
      return 0;
    } finally {
      await document?.close();
    }
  }

  Future<Uint8List?> _renderFirstPage(String filePath) async {
    PdfDocument? document;
    PdfPage? page;
    try {
      document = await PdfDocument.openFile(filePath);
      page = await document.getPage(1);
      final image = await page.render(
        width: 160,
        height: 220,
        format: PdfPageImageFormat.jpeg,
        quality: 80,
        backgroundColor: '#FFFFFF',
      );
      return image?.bytes;
    } catch (_) {
      return null;
    } finally {
      await page?.close();
      await document?.close();
    }
  }
}
