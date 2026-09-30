import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/reader_appearance_controller.dart';
import 'package:smart_pdf_reader/presentation/viewer/controller/pdf_viewer_controller.dart'
    as vc;
import 'package:smart_pdf_reader/presentation/viewer/models/multi_page_capture_result.dart';
import 'package:smart_pdf_reader/presentation/viewer/models/pdf_text_markup_style.dart';
import 'package:smart_pdf_reader/presentation/viewer/screens/pdf_snipping_screen.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/annotation_toolbar.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/book_page_view.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/bookmarks_sheet.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/pdf_document_surface.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/pdf_viewer_app_bar.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/viewer_bottom_toolbar.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/viewer_capture_fab.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/viewer_capture_menu_sheet.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/viewer_search_results_bar.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends GetWidget<vc.PdfViewerController> {
  final PdfDocument pdf;

  @override
  String? get tag => pdf.filePath ?? pdf.title;

  const PdfViewerScreen({super.key, required this.pdf});

  @override
  Widget build(BuildContext context) =>
      _PdfViewerContent(pdf: pdf, controller: controller);
}

class _PdfViewerContent extends StatefulWidget {
  final PdfDocument pdf;
  final vc.PdfViewerController controller;

  const _PdfViewerContent({required this.pdf, required this.controller});

  @override
  State<_PdfViewerContent> createState() => _PdfViewerContentState();
}

class _PdfViewerContentState extends State<_PdfViewerContent>
    with SingleTickerProviderStateMixin {
  // ── Syncfusion PDF Viewer (widget-level controller, must stay in State) ────
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey<SfPdfViewerState>();
  // RepaintBoundary key used for viewport capture — has zero rendering overhead
  // when idle (unlike Screenshot wrapper which intercepts every paint call).
  final GlobalKey _viewerRepaintKey = GlobalKey();

  // ── Business-logic controller (GetX) ─────────────────────────────────────
  vc.PdfViewerController get _ctrl => widget.controller;
  late final ReaderAppearanceController _appearanceController;

  // ── Highlight & Text Selection ───────────────────────────────────────────
  OverlayEntry? _selectionMenuOverlay;
  OverlayEntry? _annotationToolbarOverlay;
  Annotation? _selectedAnnotation;
  late Color _selectedHighlightColor = appTheme.highlightYellow;
  double _selectedHighlightOpacity = 0.45;
  PdfTextMarkupStyle _selectedMarkupStyle = PdfTextMarkupStyle.highlight;
  bool _isHighlightMode = false;

  List<Color> get _highlightPalette => appTheme.highlightPalette;

  // ── Book mode (horizontal page-swipe, Quran-app style) ───────────────────
  bool get _isBookMode => _ctrl.isBookMode.value;
  // Key to access BookPageViewState.goToPage() from the bottom toolbar
  final GlobalKey<BookPageViewState> _bookPageViewKey =
      GlobalKey<BookPageViewState>();

  String? _loadError;

  PdfTextSearchResult? get _searchResult => _ctrl.searchResult;
  String get _currentSearchText => _ctrl.currentSearchText;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  // FAB animation
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnim;

  // ── Convenience getters delegating to controller ──────────────────────────
  int get _currentPage => _ctrl.currentPage.value;
  set _currentPage(int v) => _ctrl.currentPage.value = v;
  int get _pageCount => _ctrl.pageCount.value;
  set _pageCount(int v) => _ctrl.pageCount.value = v;
  bool get _isSaving => _ctrl.isSaving.value;
  set _isSaving(bool v) => _ctrl.isSaving.value = v;
  Set<int> get _bookmarkedPages => _ctrl.bookmarkedPages;
  bool get _isCurrentPageBookmarked => _ctrl.isCurrentPageBookmarked;
  @override
  void initState() {
    super.initState();
    _appearanceController = Get.find<ReaderAppearanceController>();
    _loadBookmarks();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..value = 1.0;
    _fabScaleAnim = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _hideSelectionOverlay();
    _hideAnnotationToolbar();
    _ctrl.stopAutoScroll();
    _ctrl.saveViewerAnnotations(_pdfViewerController);
    _ctrl.detachSearchListener();
    _searchController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  // ── Highlight & Annotation Management ────────────────────────────────────

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    _hideAnnotationToolbar();
    if (details.selectedText == null || details.selectedText!.trim().isEmpty) {
      _hideSelectionOverlay();
      return;
    }

    final lines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
    final intersecting = _ctrl.getIntersectingHighlights(
      _pdfViewerController,
      lines,
    );

    if (_isHighlightMode) {
      _showSelectionOverlay(details, lines, intersecting, isMarkupMode: true);
      return;
    }

    _showSelectionOverlay(details, lines, intersecting);
  }

  void _showSelectionOverlay(
    PdfTextSelectionChangedDetails details,
    List<PdfTextLine> lines,
    List<HighlightAnnotation> intersectingHighlights, {
    bool isMarkupMode = false,
  }) {
    _hideSelectionOverlay();
    final region = details.globalSelectedRegion;
    if (region == null) return;

    final overlayState = Overlay.of(context, rootOverlay: true);
    final screenSize = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    const menuWidth = 270.0;
    const menuHeight = 48.0;

    double left = region.center.dx - (menuWidth / 2);
    left = left.clamp(
      16.0,
      (screenSize.width - menuWidth - 16.0).clamp(16.0, double.infinity),
    );

    double top = region.top - menuHeight - 12;
    if (top < topPadding + 56) {
      top = region.bottom + 12;
    }
    top = top.clamp(topPadding + 56, screenSize.height - menuHeight - 20);

    _selectionMenuOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _pdfViewerController.clearSelection();
                _hideSelectionOverlay();
              },
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: TextSelectionPopup(
                hasHighlight: intersectingHighlights.isNotEmpty,
                selectedColor: _selectedHighlightColor,
                palette: _highlightPalette,
                isMarkupMode: isMarkupMode,
                markupLabel: _selectedMarkupStyle.label,
                onApplyMarkup: () => _ctrl.addTextMarkup(
                  viewerController: _pdfViewerController,
                  lines: lines,
                  color: _selectedHighlightColor,
                  opacity: _selectedHighlightOpacity,
                  style: _selectedMarkupStyle,
                  onSelectionCleared: _hideSelectionOverlay,
                ),
                onRemoveHighlight: () => _ctrl.removeHighlights(
                  viewerController: _pdfViewerController,
                  highlights: intersectingHighlights,
                  onSelectionCleared: _hideSelectionOverlay,
                ),
                onColorSelected: (color) {
                  _selectedHighlightColor = color;
                  _ctrl.addTextMarkup(
                    viewerController: _pdfViewerController,
                    lines: lines,
                    color: color,
                    opacity: _selectedHighlightOpacity,
                    style: PdfTextMarkupStyle.highlight,
                    onSelectionCleared: _hideSelectionOverlay,
                  );
                },
                onCopy: () {
                  Clipboard.setData(
                    ClipboardData(text: details.selectedText ?? ''),
                  );
                  _pdfViewerController.clearSelection();
                  _hideSelectionOverlay();
                  Get.snackbar(
                    'Copied',
                    'Text copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                    backgroundColor: appTheme.viewerOverlayDark,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_selectionMenuOverlay!);
  }

  void _hideSelectionOverlay() {
    _selectionMenuOverlay?.remove();
    _selectionMenuOverlay = null;
  }

  void _onAnnotationSelected(Annotation annotation) {
    _hideSelectionOverlay();
    if (annotation is HighlightAnnotation) {
      _selectedAnnotation = annotation;
      _showAnnotationToolbar(annotation);
    }
  }

  void _onAnnotationDeselected(Annotation annotation) {
    if (_selectedAnnotation == annotation) {
      _selectedAnnotation = null;
      _hideAnnotationToolbar();
    }
  }

  void _showAnnotationToolbar(HighlightAnnotation annotation) {
    _hideAnnotationToolbar();
    final overlayState = Overlay.of(context, rootOverlay: true);
    final screenSize = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    const toolbarWidth = 280.0;
    final left = ((screenSize.width - toolbarWidth) / 2).clamp(
      16.0,
      double.infinity,
    );

    _annotationToolbarOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _selectedAnnotation = null;
                _hideAnnotationToolbar();
              },
            ),
          ),
          Positioned(
            top: topPadding + 62,
            left: left,
            child: Material(
              color: Colors.transparent,
              child: AnnotationEditToolbar(
                selectedColor: _selectedHighlightColor,
                palette: _highlightPalette,
                onDelete: () {
                  _ctrl.deleteAnnotation(
                    viewerController: _pdfViewerController,
                    annotation: annotation,
                  );
                  _selectedAnnotation = null;
                  _hideAnnotationToolbar();
                },
                onColorSelected: (color) {
                  _selectedHighlightColor = color;
                  _ctrl.updateHighlightColor(
                    viewerController: _pdfViewerController,
                    annotation: annotation,
                    color: color,
                  );
                  _hideAnnotationToolbar();
                },
                onClose: () {
                  _selectedAnnotation = null;
                  _hideAnnotationToolbar();
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_annotationToolbarOverlay!);
  }

  void _hideAnnotationToolbar() {
    _annotationToolbarOverlay?.remove();
    _annotationToolbarOverlay = null;
  }

  void _toggleHighlightMode() {
    final isEnabling = !_isHighlightMode;
    setState(() {
      _isHighlightMode = !_isHighlightMode;
      if (_isHighlightMode) {
        _selectedMarkupStyle = PdfTextMarkupStyle.highlight;
        _hideSelectionOverlay();
        _hideAnnotationToolbar();
      }
    });
    if (isEnabling) _showPaletteBottomSheet();
  }

  void _openHighlightTools() {
    if (!_isHighlightMode) {
      setState(() {
        _isHighlightMode = true;
        _selectedMarkupStyle = PdfTextMarkupStyle.highlight;
        _hideSelectionOverlay();
        _hideAnnotationToolbar();
      });
    }
    _showPaletteBottomSheet();
  }

  Widget _buildHighlightModeBanner() {
    return HighlightModeBanner(
      selectedColor: _selectedHighlightColor,
      markupLabel: _selectedMarkupStyle.label,
      onColorTap: _showPaletteBottomSheet,
      onClose: () => setState(() => _isHighlightMode = false),
    );
  }

  void _showPaletteBottomSheet() {
    HighlightPaletteSheet.show(
      context: context,
      selectedColor: _selectedHighlightColor,
      selectedOpacity: _selectedHighlightOpacity,
      selectedStyle: _selectedMarkupStyle,
      onColorSelected: (color) {
        setState(() => _selectedHighlightColor = color);
      },
      onOpacityChanged: (opacity) {
        setState(() => _selectedHighlightOpacity = opacity);
      },
      onStyleSelected: (style) {
        setState(() {
          _selectedMarkupStyle = style;
          _isHighlightMode = true;
          _hideSelectionOverlay();
          _hideAnnotationToolbar();
        });
      },
    );
  }

  void _handleSearchResultChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openSearchBar() {
    setState(() {
      _isSearchOpen = true;
      _searchController.text = _currentSearchText;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    });
  }

  void _closeSearchBar() {
    _searchController.clear();
    _ctrl.clearSearch(
      viewerController: _pdfViewerController,
      onChanged: _handleSearchResultChanged,
    );
    setState(() {
      _isSearchOpen = false;
    });
  }

  void _runSearch(String input) {
    final effectiveQuery = _ctrl.search(
      input,
      viewerController: _pdfViewerController,
      onChanged: _handleSearchResultChanged,
    );
    if (effectiveQuery != null && _searchController.text != effectiveQuery) {
      _searchController.value = TextEditingValue(
        text: effectiveQuery,
        selection: TextSelection.collapsed(offset: effectiveQuery.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filePath = widget.pdf.filePath;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: _isBookMode
          ? appTheme.viewerDarkBackground
          : appTheme.screenBackgroundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(
            () => PdfViewerAppBar(
              title: widget.pdf.title,
              currentPage: _currentPage,
              pageCount: _pageCount,
              isSearchOpen: _isSearchOpen,
              searchController: _searchController,
              onSearchSubmitted: _runSearch,
              onOpenSearch: _openSearchBar,
              onCloseSearch: _closeSearchBar,
              isHighlightMode: _isHighlightMode,
              onToggleHighlightMode: _toggleHighlightMode,
              isBookMode: _isBookMode,
              onToggleBookMode: _toggleBookMode,
              isCurrentPageBookmarked: _isCurrentPageBookmarked,
              bookmarkCount: _bookmarkedPages.length,
              onToggleBookmark: _toggleCurrentPageBookmark,
              onShowBookmarks: _showBookmarksSheet,
              readerTheme: _appearanceController.theme.value,
              onReaderThemeChanged: _appearanceController.setTheme,
              isAutoScrolling: _ctrl.isAutoScrolling.value,
              onShowAutoScrollControls: _showAutoScrollControls,
            ),
          ),
        ),
        body: Column(
          children: [
            if (_isHighlightMode && !_isBookMode) _buildHighlightModeBanner(),
            Expanded(
              child: Obx(
                () => PdfDocumentSurface(
                  repaintBoundaryKey: _viewerRepaintKey,
                  filePath: filePath,
                  loadError: _loadError,
                  isBookMode: _isBookMode,
                  readerTheme: _appearanceController.theme.value,
                  bookView: filePath == null
                      ? const SizedBox.shrink()
                      : _buildBookView(filePath),
                  scrollView: filePath == null
                      ? const SizedBox.shrink()
                      : Listener(
                          onPointerDown: (_) {
                            if (_ctrl.isAutoScrolling.value) {
                              _ctrl.stopAutoScroll();
                            }
                          },
                          child: SfPdfViewer.file(
                            File(filePath),
                            key: _pdfViewerKey,
                            controller: _pdfViewerController,
                            initialPageNumber: widget.pdf.currentPage > 0
                                ? widget.pdf.currentPage
                                : 1,
                            pageSpacing: 4.0,
                            canShowScrollHead: true,
                            canShowScrollStatus: true,
                            enableDoubleTapZooming: true,
                            enableTextSelection: true,
                            canShowTextSelectionMenu: false,
                            onTextSelectionChanged: _onTextSelectionChanged,
                            onAnnotationSelected: _onAnnotationSelected,
                            onAnnotationDeselected: _onAnnotationDeselected,
                            onDocumentLoaded: (details) {
                              if (!mounted) return;
                              _ctrl.recordPageOpened(
                                _pdfViewerController.pageNumber,
                              );
                              setState(() {
                                _pageCount = details.document.pages.count;
                                _currentPage = _pdfViewerController.pageNumber;
                              });
                              _ctrl
                                  .updatePageCount(details.document.pages.count)
                                  .catchError((_) {});
                            },
                            onPageChanged: (details) {
                              if (!mounted) return;
                              _ctrl.recordPageOpened(details.newPageNumber);
                              setState(
                                () => _currentPage = details.newPageNumber,
                              );
                            },
                            onDocumentLoadFailed: (details) {
                              if (!mounted) return;
                              setState(() => _loadError = details.description);
                            },
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: filePath == null || _loadError != null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchResult != null && _searchResult!.hasResult)
                    ViewerSearchResultsBar(
                      query: _currentSearchText,
                      currentIndex: _searchResult!.currentInstanceIndex,
                      resultCount: _searchResult!.totalInstanceCount,
                      onPrevious: () => _searchResult?.previousInstance(),
                      onNext: () => _searchResult?.nextInstance(),
                    ),
                  _buildViewerActions(),
                ],
              ),
        floatingActionButton: filePath == null || _loadError != null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Obx(
                    () => FloatingActionButton.small(
                      heroTag: 'pdf_auto_scroll',
                      tooltip: _ctrl.isAutoScrolling.value
                          ? 'Stop auto scroll'
                          : 'Start auto scroll',
                      backgroundColor: _ctrl.isAutoScrolling.value
                          ? appTheme.viewerDarkBar
                          : appTheme.primaryColor,
                      foregroundColor: Colors.white,
                      onPressed: _toggleAutoScroll,
                      child: Icon(
                        _ctrl.isAutoScrolling.value
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => ViewerCaptureFab(
                      scaleAnimation: _fabScaleAnim,
                      animationController: _fabAnimController,
                      isSaving: _isSaving,
                      onPressed: _showCaptureMenuSheet,
                    ),
                  ),
                ],
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ── Book mode helpers ─────────────────────────────────────────────────────

  /// Builds the BookPageView, reusing the current page as initial page.
  Widget _buildBookView(String filePath) {
    // If pageCount is not yet known (book mode opened before SfPdfViewer loaded),
    // we cannot show the BookPageView yet.
    if (_pageCount <= 0) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    return BookPageView(
      key: _bookPageViewKey,
      filePath: filePath,
      pageCount: _pageCount,
      initialPage: _currentPage > 0 ? _currentPage : 1,
      bookmarkedPages: _bookmarkedPages,
      onPageChanged: (page) {
        if (!mounted) return;
        _ctrl.recordPageOpened(page);
        setState(() => _currentPage = page);
      },
    );
  }

  /// Switches between scroll mode and book mode.
  /// When entering book mode: syncs the starting page from SfPdfViewer.
  /// When leaving book mode: jumps SfPdfViewer to the last page seen in book mode.
  void _toggleBookMode() {
    _ctrl.stopAutoScroll();
    _ctrl.toggleBookMode();
    setState(() {});
    if (!_isBookMode) {
      // Returning to scroll mode — jump SfPdfViewer to current page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageCount > 0 && _currentPage > 0) {
          _pdfViewerController.jumpToPage(_currentPage);
        }
      });
    }
  }

  // ── Bookmark helpers ──────────────────────────────────────────────────────

  Future<void> _loadBookmarks() async {
    await _ctrl.loadBookmarks();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleCurrentPageBookmark() async {
    if (widget.pdf.filePath == null || _currentPage < 1) return;
    HapticFeedback.mediumImpact();
    await _ctrl.toggleCurrentPageBookmark(
      onShowAllBookmarks: _showBookmarksSheet,
    );
    if (mounted) setState(() {});
  }

  Future<void> _showBookmarksSheet() async {
    final filePath = widget.pdf.filePath;
    if (filePath == null) return;

    final bookmarks = await _ctrl.fetchBookmarks();
    if (!mounted) return;

    Get.bottomSheet(
      BookmarksSheet(
        title: widget.pdf.title,
        bookmarks: bookmarks,
        currentPage: _currentPage,
        onSelectPage: (page) {
          Get.back();
          if (_isBookMode) {
            _bookPageViewKey.currentState?.goToPage(page);
          } else {
            _pdfViewerController.jumpToPage(page);
          }
          setState(() => _currentPage = page);
        },
        onDeleteBookmark: (page) async {
          await _ctrl.removeBookmark(page);
          if (mounted) {
            setState(() {});
          }
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<Uint8List?> _captureCleanPageImage() {
    return _ctrl.captureCleanPageImage(captureViewport: _captureViewportPixels);
  }

  /// Captures the currently visible viewport pixels using the RepaintBoundary.
  /// This is a lightweight fallback — the RepaintBoundary adds no overhead
  /// during normal scrolling since it only paints when explicitly asked.
  Future<Uint8List?> _captureViewportPixels() async {
    try {
      final pixelRatio = mounted
          ? MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0
          : 2.0;
      final boundary =
          _viewerRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('RepaintBoundary capture failed: $e');
      return null;
    }
  }

  /// Captures a continuous multi-page strip:
  /// Page N-1 (if exists), Page N, and Page N+1 (if exists) stitched together
  /// with dividers, allowing the user to snip across page seams.
  Future<MultiPageCaptureResult?> _captureMultiPageStrip({
    required int centerPage,
    int range = 1,
  }) async {
    return _ctrl.captureMultiPageStrip(centerPage: centerPage, range: range);
  }

  Future<MultiPageCaptureResult?> _captureRangeStrip(
    int startPage,
    int endPage,
  ) async {
    return _ctrl.captureRangeStrip(startPage: startPage, endPage: endPage);
  }

  /// Launches the interactive Snipping Tool overlay.
  /// When [useViewport] is false, generates a multi-page continuous strip (above & below)
  /// so the user can stretch the selection freely across page boundaries.
  /// When [useViewport] is true, renders the CURRENT page via pdfx at high resolution
  /// (same quality as full-page save) so the user can snip from a crisp image.
  Future<void> _openSnippingTool({bool useViewport = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (useViewport) {
        final pageNum = _currentPage > 0 ? _currentPage : 1;
        final bytes = await _ctrl.captureCleanPageImage(
          captureViewport: _captureViewportPixels,
        );

        if (!mounted) return;
        setState(() => _isSaving = false);

        if (bytes == null) {
          Get.snackbar(
            'Capture Failed',
            'Could not capture viewport.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfSnippingScreen(
              imageBytes: bytes,
              documentTitle: widget.pdf.title,
              startPage: pageNum,
              endPage: pageNum,
              activePage: pageNum,
              totalPages: _pageCount > 0 ? _pageCount : 1,
            ),
          ),
        );
        return;
      }

      // Default: Multi-page continuous capture (page above, current, page below)
      final multiResult = await _captureMultiPageStrip(
        centerPage: _currentPage > 0 ? _currentPage : 1,
        range: 1,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (multiResult == null) {
        final bytes = await _captureViewportPixels();
        if (!mounted) return;
        if (bytes == null) {
          Get.snackbar(
            'Capture Failed',
            'Could not render pages for snipping.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
          return;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfSnippingScreen(
              imageBytes: bytes,
              documentTitle: widget.pdf.title,
              startPage: _currentPage > 0 ? _currentPage : 1,
              endPage: _currentPage > 0 ? _currentPage : 1,
              activePage: _currentPage > 0 ? _currentPage : 1,
              totalPages: _pageCount > 0 ? _pageCount : 1,
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfSnippingScreen(
            imageBytes: multiResult.imageBytes,
            documentTitle: widget.pdf.title,
            startPage: multiResult.startPage,
            endPage: multiResult.endPage,
            activePage: multiResult.activePage,
            totalPages: multiResult.totalPages,
            initialCropFraction: multiResult.initialCropFraction,
            onExtendRange: (start, end) async {
              final res = await _captureRangeStrip(start, end);
              return res?.imageBytes;
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Get.snackbar(
        'Snipping Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  /// Saves the current full page directly to device gallery (Adobe Acrobat style).
  Future<void> _saveCurrentPageToGallery() => _ctrl.captureAndSavePage(
    pageNumber: _currentPage > 0 ? _currentPage : 1,
    capturePage: _captureCleanPageImage,
  );

  /// Captures the full screen as currently zoomed/visible.
  Future<void> _takeScreenshot() =>
      _ctrl.captureAndSaveScreenshot(captureViewport: _captureViewportPixels);

  void _showCaptureMenuSheet() {
    ViewerCaptureMenuSheet.show(
      currentPage: _currentPage,
      pageCount: _pageCount,
      onMultiPageSnip: () => _openSnippingTool(useViewport: false),
      onVisibleViewSnip: () => _openSnippingTool(useViewport: true),
      onSaveFullPage: _saveCurrentPageToGallery,
      onQuickScreenshot: _takeScreenshot,
    );
  }

  void _showMoreTools() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appTheme.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'More tools',
                      style: textTheme.textStyleRedditSansSemiBold.copyWith(
                        color: appTheme.textPrimaryColor,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    'Page $_currentPage of $_pageCount',
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      color: appTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: _currentPage > 1
                        ? () {
                            Navigator.pop(sheetContext);
                            if (_isBookMode) {
                              _bookPageViewKey.currentState?.goToPage(
                                _currentPage - 1,
                              );
                            } else {
                              _pdfViewerController.previousPage();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  if (!_isBookMode) ...[
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pdfViewerController.zoomLevel =
                            (_pdfViewerController.zoomLevel - 0.25).clamp(
                              1.0,
                              3.0,
                            );
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Fit page',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pdfViewerController.zoomLevel = 1.0;
                      },
                      icon: const Icon(Icons.fit_screen_outlined),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _pdfViewerController.zoomLevel =
                            (_pdfViewerController.zoomLevel + 0.25).clamp(
                              1.0,
                              3.0,
                            );
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: _currentPage < _pageCount
                        ? () {
                            Navigator.pop(sheetContext);
                            if (_isBookMode) {
                              _bookPageViewKey.currentState?.goToPage(
                                _currentPage + 1,
                              );
                            } else {
                              _pdfViewerController.nextPage();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const Divider(height: 8),
              ListTile(
                leading: const Icon(Icons.crop_rounded),
                title: const Text('Capture and snipping'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showCaptureMenuSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks_outlined),
                title: const Text('Bookmarks'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBookmarksSheet();
                },
              ),
              ListTile(
                leading: Icon(
                  _ctrl.isAutoScrolling.value
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                title: Text(
                  _ctrl.isAutoScrolling.value
                      ? 'Stop auto scroll'
                      : 'Auto scroll',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAutoScrollControls();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoScrollControls() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: appTheme.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(child: Obx(_buildAutoScrollSettings)),
    );
  }

  Widget _buildAutoScrollSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auto scroll',
            style: textTheme.textStyleRedditSansSemiBold.copyWith(
              fontSize: 17,
              color: appTheme.textPrimaryColor,
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _ctrl.isAutoScrolling.value ? 'Scrolling' : 'Start scrolling',
            ),
            secondary: Icon(
              _ctrl.isAutoScrolling.value
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            value: _ctrl.isAutoScrolling.value,
            onChanged: _setAutoScrollEnabled,
          ),
          Row(
            children: [
              const Text('Speed'),
              const Spacer(),
              Text('${_ctrl.autoScrollSpeed.value.toStringAsFixed(1)}x'),
            ],
          ),
          Slider(
            value: _ctrl.autoScrollSpeed.value,
            min: 0.5,
            max: 3.0,
            divisions: 5,
            label: '${_ctrl.autoScrollSpeed.value.toStringAsFixed(1)}x',
            onChanged: _ctrl.setAutoScrollSpeed,
          ),
        ],
      ),
    );
  }

  void _toggleAutoScroll() {
    _setAutoScrollEnabled(!_ctrl.isAutoScrolling.value);
  }

  void _setAutoScrollEnabled(bool enabled) {
    if (!enabled) {
      _ctrl.stopAutoScroll();
      return;
    }
    _ctrl.startAutoScroll(
      viewerController: _pdfViewerController,
      onAdvanceBookPage: () {
        final bookPageView = _bookPageViewKey.currentState;
        if (_currentPage >= _pageCount || bookPageView == null) return false;
        bookPageView.goToPage(_currentPage + 1);
        return true;
      },
    );
  }

  Widget _buildViewerActions() {
    return ViewerBottomToolbar(
      isBookMode: _isBookMode,
      currentPage: _currentPage,
      pageCount: _pageCount,
      isHighlightMode: _isHighlightMode,
      onToggleHighlightMode: _openHighlightTools,
      onMoreTools: _showMoreTools,
      onPreviousPage: () {
        if (_isBookMode) {
          _bookPageViewKey.currentState?.goToPage(_currentPage - 1);
        } else {
          _pdfViewerController.previousPage();
        }
      },
      onNextPage: () {
        if (_isBookMode) {
          _bookPageViewKey.currentState?.goToPage(_currentPage + 1);
        } else {
          _pdfViewerController.nextPage();
        }
      },
      onRapidFlipStart: (direction) {
        _bookPageViewKey.currentState?.startRapidFlip(direction);
      },
      onRapidFlipEnd: () {
        _bookPageViewKey.currentState?.stopRapidFlip();
      },
      onZoomIn: () {
        _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25)
            .clamp(1.0, 3.0);
      },
      onZoomOut: () {
        _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25)
            .clamp(1.0, 3.0);
      },
      onFitPage: () {
        _pdfViewerController.zoomLevel = 1.0;
      },
    );
  }
}
