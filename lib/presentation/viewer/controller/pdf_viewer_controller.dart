import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/database/app_database.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/viewer/models/pdf_text_markup_style.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/screenshot_result_sheet.dart';
import 'package:smart_pdf_reader/presentation/viewer/models/multi_page_capture_result.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;
// ignore: implementation_imports
import 'package:syncfusion_flutter_pdfviewer/src/annotation/annotation.dart';

/// Controller for the PDF Viewer screen.
///
/// Holds all pure business logic that does not depend on Flutter widget keys,
/// overlays, or vsync — matching the same pattern used in [HomeController].
///
/// Responsibilities:
/// - Reading progress (page opened recording)
/// - Bookmark CRUD (load, add, remove, display sheet)
/// - Annotation persistence (save to disk)
/// - Screenshot gallery save & share sheet
/// - Reactive state: currentPage, pageCount, isSaving, bookmarkedPages
class PdfViewerController extends GetxController {
  final PdfDocument pdf;

  PdfViewerController({required this.pdf});

  // ── Reactive State ─────────────────────────────────────────────────────────
  final RxInt currentPage = 0.obs;
  final RxInt pageCount = 0.obs;
  final RxBool isSaving = false.obs;
  final RxBool isBookMode = false.obs;
  final RxBool isAutoScrolling = false.obs;
  final RxDouble autoScrollSpeed = 1.0.obs;
  final RxSet<int> bookmarkedPages = <int>{}.obs;
  Timer? _autoScrollTimer;
  DateTime? _lastAutoScrollTick;
  double _bookScrollElapsed = 0;
  double _lastScrollOffset = 0;
  int _stalledScrollTicks = 0;
  sf.PdfTextSearchResult? _searchResult;
  String _currentSearchText = '';
  String _lastSuccessfulSearchText = '';
  VoidCallback? _onSearchResultChanged;

  sf.PdfTextSearchResult? get searchResult => _searchResult;
  String get currentSearchText => _currentSearchText;

  bool get isCurrentPageBookmarked =>
      bookmarkedPages.contains(currentPage.value);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    currentPage.value = pdf.currentPage > 0 ? pdf.currentPage : 1;
    pageCount.value = pdf.pages;
  }

  @override
  void onClose() {
    stopAutoScroll();
    detachSearchListener();
    super.onClose();
  }

  void toggleBookMode() {
    isBookMode.toggle();
  }

  void setAutoScrollSpeed(double speed) {
    autoScrollSpeed.value = speed.clamp(0.5, 3.0);
  }

  void startAutoScroll({
    required sf.PdfViewerController viewerController,
    required bool Function() onAdvanceBookPage,
  }) {
    if (isAutoScrolling.value) return;
    isAutoScrolling.value = true;
    _lastAutoScrollTick = DateTime.now();
    _bookScrollElapsed = 0;
    _lastScrollOffset = viewerController.scrollOffset.dy;
    _stalledScrollTicks = 0;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!isAutoScrolling.value) return;
      final now = DateTime.now();
      final elapsed =
          now.difference(_lastAutoScrollTick!).inMicroseconds /
          Duration.microsecondsPerSecond;
      _lastAutoScrollTick = now;

      if (isBookMode.value) {
        _bookScrollElapsed += elapsed;
        final pageInterval = 4.0 / autoScrollSpeed.value;
        if (_bookScrollElapsed < pageInterval) return;
        _bookScrollElapsed = 0;
        if (currentPage.value >= pageCount.value || !onAdvanceBookPage()) {
          stopAutoScroll();
        }
        return;
      }

      final offset = viewerController.scrollOffset;
      if ((offset.dy - _lastScrollOffset).abs() < 0.1) {
        _stalledScrollTicks++;
        if (_stalledScrollTicks > 20) {
          stopAutoScroll();
          return;
        }
      } else {
        _stalledScrollTicks = 0;
      }
      _lastScrollOffset = offset.dy;
      viewerController.jumpTo(
        xOffset: offset.dx,
        yOffset: offset.dy + 40 * autoScrollSpeed.value * elapsed,
      );
    });
  }

  void stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _lastAutoScrollTick = null;
    isAutoScrolling.value = false;
  }

  /// Runs document search and returns the query that should remain in the UI.
  String? search(
    String input, {
    required sf.PdfViewerController viewerController,
    required VoidCallback onChanged,
  }) {
    final query = input.trim();
    if (query.isEmpty) return null;

    _onSearchResultChanged = onChanged;
    final isRepeatSearch =
        query == _currentSearchText &&
        _searchResult != null &&
        _searchResult!.hasResult;

    if (isRepeatSearch) {
      _searchResult!.nextInstance();
      return null;
    }

    _currentSearchText = query;
    _replaceSearchResult(viewerController.searchText(query));

    if (_searchResult!.hasResult) {
      _lastSuccessfulSearchText = query;
      return query;
    }

    if (_lastSuccessfulSearchText.isNotEmpty &&
        _lastSuccessfulSearchText != query) {
      _currentSearchText = _lastSuccessfulSearchText;
      _replaceSearchResult(
        viewerController.searchText(_lastSuccessfulSearchText),
      );
      return _lastSuccessfulSearchText;
    }
    return null;
  }

  void clearSearch({
    required sf.PdfViewerController viewerController,
    required VoidCallback onChanged,
  }) {
    _onSearchResultChanged = onChanged;
    _currentSearchText = '';
    _lastSuccessfulSearchText = '';
    _replaceSearchResult(viewerController.searchText(''));
  }

  void detachSearchListener() {
    _searchResult?.removeListener(_notifySearchChanged);
    _onSearchResultChanged = null;
  }

  void _replaceSearchResult(sf.PdfTextSearchResult result) {
    _searchResult?.removeListener(_notifySearchChanged);
    _searchResult = result;
    _searchResult!.addListener(_notifySearchChanged);
    _notifySearchChanged();
  }

  void _notifySearchChanged() {
    _onSearchResultChanged?.call();
  }

  // ── Page Progress ──────────────────────────────────────────────────────────

  /// Records that a page was opened in the database for reading progress tracking.
  Future<void> recordPageOpened(int pageNumber) async {
    final filePath = pdf.filePath;
    if (filePath == null) return;
    await AppDatabase.instance.recordPageOpened(filePath, pageNumber);
  }

  /// Persists the page count discovered by the PDF rendering widget.
  Future<void> updatePageCount(int count) async {
    final filePath = pdf.filePath;
    if (filePath == null || count <= 0) return;
    pageCount.value = count;
    await AppDatabase.instance.updateDocumentPageCount(filePath, count);
  }

  // ── Bookmarks ──────────────────────────────────────────────────────────────

  Future<void> loadBookmarks() async {
    final filePath = pdf.filePath;
    if (filePath == null) return;
    final pages = await AppDatabase.instance.getBookmarkedPages(filePath);
    bookmarkedPages.assignAll(pages);
  }

  /// Toggles bookmark for the currently viewed page.
  /// Shows appropriate GetX snackbars on success.
  Future<void> toggleCurrentPageBookmark({
    required VoidCallback onShowAllBookmarks,
  }) async {
    final filePath = pdf.filePath;
    if (filePath == null || currentPage.value < 1) return;

    final page = currentPage.value;
    final wasBookmarked = isCurrentPageBookmarked;

    if (wasBookmarked) {
      await AppDatabase.instance.removeBookmark(filePath, page);
      bookmarkedPages.remove(page);
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            'Bookmark removed for Page $page',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.viewerDarkBar,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: const Icon(
            Icons.bookmark_remove_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
      );
    } else {
      await AppDatabase.instance.addBookmark(filePath, page, title: pdf.title);
      bookmarkedPages.add(page);
      if (Get.isRegistered<GlobalCoinController>()) {
        Get.find<GlobalCoinController>().onBookmarkAdded();
      }
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            'Page $page bookmarked',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          mainButton: TextButton(
            onPressed: () {
              Get.closeCurrentSnackbar();
              onShowAllBookmarks();
            },
            child: Text(
              'View All',
              style: TextStyle(color: appTheme.primaryPale),
            ),
          ),
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.viewerDarkBar,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
          icon: Icon(
            Icons.bookmark_added_rounded,
            color: appTheme.bookmarkGold,
            size: 20,
          ),
        ),
      );
    }
  }

  /// Removes a bookmark for a specific page (called from the bookmarks sheet).
  Future<void> removeBookmark(int page) async {
    final filePath = pdf.filePath;
    if (filePath == null) return;
    await AppDatabase.instance.removeBookmark(filePath, page);
    bookmarkedPages.remove(page);
  }

  /// Fetches the list of bookmarks for this document from the database.
  Future<List<Map<String, dynamic>>> fetchBookmarks() async {
    final filePath = pdf.filePath;
    if (filePath == null) return [];
    return AppDatabase.instance.getBookmarks(filePath);
  }

  // ── Annotation Persistence ─────────────────────────────────────────────────

  List<sf.HighlightAnnotation> getIntersectingHighlights(
    sf.PdfViewerController viewerController,
    List<sf.PdfTextLine> lines,
  ) {
    if (lines.isEmpty) return [];
    try {
      final annotations = viewerController.getAnnotations();
      final highlights = annotations
          .whereType<sf.HighlightAnnotation>()
          .toList();
      final intersecting = <sf.HighlightAnnotation>[];

      for (final annotation in highlights) {
        for (final line in lines) {
          if (annotation.pageNumber == line.pageNumber &&
              annotation.boundingBox.overlaps(line.bounds) &&
              !intersecting.contains(annotation)) {
            intersecting.add(annotation);
          }
        }
      }
      return intersecting;
    } catch (_) {
      return [];
    }
  }

  void addTextMarkup({
    required sf.PdfViewerController viewerController,
    required List<sf.PdfTextLine> lines,
    required Color color,
    required double opacity,
    required PdfTextMarkupStyle style,
    required VoidCallback onSelectionCleared,
  }) {
    if (lines.isEmpty) return;
    try {
      final sf.Annotation annotation = switch (style) {
        PdfTextMarkupStyle.highlight => sf.HighlightAnnotation(
          textBoundsCollection: lines,
        ),
        PdfTextMarkupStyle.underline => sf.UnderlineAnnotation(
          textBoundsCollection: lines,
        ),
        PdfTextMarkupStyle.strikethrough => sf.StrikethroughAnnotation(
          textBoundsCollection: lines,
        ),
      };
      annotation.color = color.withValues(
        alpha: opacity.clamp(0.1, 1.0).toDouble(),
      );
      viewerController.addAnnotation(annotation);
      viewerController.clearSelection();
      onSelectionCleared();

      if (Get.isRegistered<GlobalCoinController>()) {
        Get.find<GlobalCoinController>().onAnnotationAdded();
      }
      saveViewerAnnotations(viewerController);
    } catch (error) {
      debugPrint('Failed to add highlight: $error');
    }
  }

  void removeHighlights({
    required sf.PdfViewerController viewerController,
    required List<sf.HighlightAnnotation> highlights,
    required VoidCallback onSelectionCleared,
  }) {
    if (highlights.isEmpty) return;
    for (final annotation in highlights) {
      try {
        viewerController.removeAnnotation(annotation);
      } catch (_) {}
    }
    viewerController.clearSelection();
    onSelectionCleared();
    saveViewerAnnotations(viewerController);
  }

  void deleteAnnotation({
    required sf.PdfViewerController viewerController,
    required sf.Annotation annotation,
  }) {
    viewerController.removeAnnotation(annotation);
    saveViewerAnnotations(viewerController);
  }

  void updateHighlightColor({
    required sf.PdfViewerController viewerController,
    required sf.HighlightAnnotation annotation,
    required Color color,
  }) {
    annotation.color = color.withValues(alpha: 0.45);
    saveViewerAnnotations(viewerController);
  }

  Future<void> saveViewerAnnotations(
    sf.PdfViewerController viewerController,
  ) async {
    try {
      final bytes = await viewerController.saveDocument();
      await saveAnnotations(Uint8List.fromList(bytes));
    } catch (error) {
      debugPrint('Error saving annotations to PDF: $error');
    }
  }

  /// Writes the PDF bytes (with annotations) back to disk.
  Future<void> saveAnnotations(Uint8List bytes) async {
    final filePath = pdf.filePath;
    if (filePath == null) return;
    try {
      if (bytes.isNotEmpty) {
        await File(filePath).writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      debugPrint('Error saving annotations to PDF: $e');
    }
  }

  Future<Uint8List?> captureCleanPageImage({
    required Future<Uint8List?> Function() captureViewport,
  }) async {
    final filePath = pdf.filePath;
    if (filePath != null) {
      try {
        final document = await pdfx.PdfDocument.openFile(filePath);
        final pageNumber = currentPage.value > 0 ? currentPage.value : 1;
        final page = await document.getPage(pageNumber);
        final image = await page.render(
          width: (page.width * 2.0).clamp(700, 2400),
          height: (page.height * 2.0).clamp(900, 3200),
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        await document.close();
        if (image?.bytes != null) return image!.bytes;
      } catch (error) {
        debugPrint('PDF page render failed; using viewport capture: $error');
      }
    }
    return captureViewport();
  }

  Future<MultiPageCaptureResult?> captureMultiPageStrip({
    required int centerPage,
    int range = 1,
  }) async {
    final filePath = pdf.filePath;
    if (filePath == null) return null;
    return _capturePageStrip(
      startPage: centerPage - range,
      endPage: centerPage + range,
      activePage: centerPage,
      cropPage: centerPage,
    );
  }

  Future<MultiPageCaptureResult?> captureRangeStrip({
    required int startPage,
    required int endPage,
  }) async {
    return _capturePageStrip(
      startPage: startPage,
      endPage: endPage,
      activePage: currentPage.value,
    );
  }

  Future<MultiPageCaptureResult?> _capturePageStrip({
    required int startPage,
    required int endPage,
    required int activePage,
    int? cropPage,
  }) async {
    final filePath = pdf.filePath;
    if (filePath == null) return null;

    pdfx.PdfDocument? document;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
      final count = document.pagesCount;
      if (count <= 0) return null;
      final firstPage = startPage.clamp(1, count);
      final lastPage = endPage.clamp(1, count);
      final frames = <ui.Image>[];
      final pageNumbers = <int>[];
      double maxWidth = 0;
      double totalHeight = 0;
      const gap = 8.0;

      for (var pageNumber = firstPage; pageNumber <= lastPage; pageNumber++) {
        final page = await document.getPage(pageNumber);
        final image = await page.render(
          width: 1200.0,
          height: (page.height * (1200.0 / page.width)).clamp(600.0, 3200.0),
          format: pdfx.PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        if (image?.bytes == null) continue;

        final codec = await ui.instantiateImageCodec(image!.bytes);
        final frame = await codec.getNextFrame();
        frames.add(frame.image);
        pageNumbers.add(pageNumber);
        if (frame.image.width > maxWidth) {
          maxWidth = frame.image.width.toDouble();
        }
        totalHeight += frame.image.height;
      }
      await document.close();
      document = null;

      if (frames.isEmpty) return null;
      totalHeight += gap * (frames.length - 1);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, maxWidth, totalHeight),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, maxWidth, totalHeight),
        Paint()..color = const Color(0xFFE2E8F0),
      );

      double currentY = 0;
      Rect cropRect = Rect.zero;
      for (var index = 0; index < frames.length; index++) {
        final image = frames[index];
        final destination = Rect.fromLTWH(
          0,
          currentY,
          maxWidth,
          image.height.toDouble(),
        );
        canvas.drawRect(destination, Paint()..color = Colors.white);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          destination,
          Paint()..filterQuality = FilterQuality.high,
        );
        if (pageNumbers[index] == cropPage) cropRect = destination;
        currentY += image.height;
        if (index < frames.length - 1) {
          canvas.drawRect(
            Rect.fromLTWH(0, currentY, maxWidth, gap),
            Paint()..color = const Color(0xFFCBD5E1),
          );
          currentY += gap;
        }
      }

      if (cropPage != null && cropRect == Rect.zero) {
        cropRect = Rect.fromLTWH(0, 0, maxWidth, totalHeight);
      }

      final picture = recorder.endRecording();
      final stitched = await picture.toImage(
        maxWidth.round(),
        totalHeight.round(),
      );
      final bytes = await stitched.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;

      final cropFraction = cropPage == null
          ? Rect.zero
          : Rect.fromLTRB(
              cropRect.left / maxWidth,
              cropRect.top / totalHeight,
              cropRect.right / maxWidth,
              cropRect.bottom / totalHeight,
            );
      return MultiPageCaptureResult(
        imageBytes: bytes.buffer.asUint8List(),
        startPage: firstPage,
        endPage: lastPage,
        activePage: activePage,
        totalPages: count,
        initialCropFraction: cropFraction,
      );
    } catch (error) {
      debugPrint('Error stitching PDF page strip: $error');
      return null;
    } finally {
      await document?.close();
    }
  }

  // ── Screenshot / Gallery Save ──────────────────────────────────────────────

  Future<void> captureAndSavePage({
    required int pageNumber,
    required Future<Uint8List?> Function() capturePage,
  }) async {
    if (isSaving.value) return;
    isSaving.value = true;

    try {
      final imageBytes = await capturePage();
      if (imageBytes == null) return;
      await savePageToGallery(
        imageBytes: imageBytes,
        pageNumber: pageNumber,
        onShare: () => shareScreenshot(imageBytes),
      );
    } catch (error) {
      Get.snackbar(
        'Save Failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> captureAndSaveScreenshot({
    required Future<Uint8List?> Function() captureViewport,
  }) async {
    if (isSaving.value) return;
    isSaving.value = true;

    try {
      final imageBytes = await captureViewport();
      if (imageBytes == null) return;
      await saveScreenshot(
        imageBytes: imageBytes,
        onShare: () => shareScreenshot(imageBytes),
      );
    } catch (error) {
      Get.snackbar(
        'Screenshot failed',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Saves an image to the device gallery and shows the result sheet.
  Future<void> savePageToGallery({
    required Uint8List imageBytes,
    required int pageNumber,
    required VoidCallback onShare,
  }) async {
    try {
      final name =
          'page_${pageNumber}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: name,
      );
      final bool saved =
          result['isSuccess'] == true || result['filePath'] != null;

      showScreenshotResultSheet(
        imageBytes: imageBytes,
        saved: saved,
        title: 'Page $pageNumber Saved',
        subtitle: saved
            ? 'Saved clean high-res image to gallery'
            : 'Could not save to gallery',
        onShare: onShare,
      );
    } catch (e) {
      Get.snackbar(
        'Save Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Saves a screenshot to gallery and shows the result sheet.
  Future<void> saveScreenshot({
    required Uint8List imageBytes,
    required VoidCallback onShare,
  }) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name:
            'screenshot_page_${currentPage.value}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final bool saved =
          result['isSuccess'] == true || result['filePath'] != null;

      showScreenshotResultSheet(
        imageBytes: imageBytes,
        saved: saved,
        title: 'Screenshot taken',
        subtitle: saved ? 'Saved to your gallery' : 'Could not save to gallery',
        onShare: onShare,
      );
    } catch (e) {
      Get.snackbar(
        'Screenshot failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Shows the screenshot result bottom sheet.
  void showScreenshotResultSheet({
    required Uint8List imageBytes,
    required bool saved,
    String title = 'Screenshot taken',
    String? subtitle,
    required VoidCallback onShare,
  }) {
    Get.bottomSheet(
      ScreenshotResultSheet(
        imageBytes: imageBytes,
        saved: saved,
        title: title,
        subtitle: subtitle,
        onShare: onShare,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  /// Shares an image file via the system share sheet.
  Future<void> shareScreenshot(Uint8List imageBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/screenshot_page_${currentPage.value}.png');
      await file.writeAsBytes(imageBytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Page ${currentPage.value} of "${pdf.title}"',
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Share failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }
}
