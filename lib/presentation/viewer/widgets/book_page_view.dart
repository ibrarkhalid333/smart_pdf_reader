import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:smart_pdf_reader/core/database/app_database.dart';

/// A Quran-app–style horizontal page-by-page PDF reader.
///
/// Each page is rendered at high resolution via [pdfx] and cached in memory.
/// The user swipes left/right to navigate, with full pinch-to-zoom on each
/// individual page (using [InteractiveViewer]).
///
/// Reading direction is LTR by default; set [reverseDirection] to `true` for
/// Arabic/Quran RTL mode (right-to-left page order).
class BookPageView extends StatefulWidget {
  /// Absolute path to the PDF file on device.
  final String filePath;

  /// Total number of pages in the document.
  final int pageCount;

  /// 1-indexed page to open on first load.
  final int initialPage;

  /// Called whenever the visible page changes (1-indexed).
  final ValueChanged<int> onPageChanged;

  /// Set of 1-indexed page numbers that are currently bookmarked.
  final Set<int>? bookmarkedPages;

  /// Set to `true` for RTL reading (Arabic/Quran style).
  /// Currently unused — reserved for future language-based switching.
  final bool reverseDirection;

  const BookPageView({
    super.key,
    required this.filePath,
    required this.pageCount,
    required this.initialPage,
    required this.onPageChanged,
    this.bookmarkedPages,
    this.reverseDirection = false,
  });

  @override
  State<BookPageView> createState() => BookPageViewState();
}

class BookPageViewState extends State<BookPageView>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;

  // ── pdfx document ──────────────────────────────────────────────────────────
  pdfx.PdfDocument? _doc;
  bool _docError = false;

  // ── Rendered page cache: key = 1-indexed page number ──────────────────────
  final Map<int, Uint8List> _cache = {};
  final Map<int, ValueNotifier<Uint8List?>> _pageNotifiers = {};
  final Set<int> _rendering = {}; // pages currently being rendered
  final List<int> _renderQueue = [];
  bool _isProcessingRenderQueue = false;
  int _currentPage = 1;

  // ── Edge Hold & Fast Page Flipping (Thumbing through pages) ─────────────────
  Timer? _edgeHoldTimer;
  Timer? _rapidFlipTimer;
  bool _isFlippingActive = false;
  int _flipStartPage = 1;
  int _targetPage = 1;
  int _flipDirection = 0; // +1 = forward (next), -1 = backward (prev)
  Offset? _pointerDownPos;
  int? _activePointerId;
  int _tickCount = 0;
  double _inwardDragPixels = 0.0;

  // ── Swipe hint animation ───────────────────────────────────────────────────
  late final AnimationController _hintAnim;
  late final Animation<double> _hintOpacity;
  Timer? _hintTimer;

  // ── Target render width & cache limits ─────────────────────────────────────
  static const double _renderWidth = 1080.0;
  static const int _maxCachedPages = 20;

  ValueNotifier<Uint8List?> _getPageNotifier(int pageNum) {
    return _pageNotifiers.putIfAbsent(
      pageNum,
      () => ValueNotifier<Uint8List?>(_cache[pageNum]),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, widget.pageCount);
    _pageController = PageController(initialPage: _currentPage - 1);

    // Swipe hint: fades in after 400 ms, stays for 1.5 s, fades out.
    _hintAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hintOpacity = CurvedAnimation(parent: _hintAnim, curve: Curves.easeInOut);

    _hintTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _hintAnim.forward().then((_) {
        _hintTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) _hintAnim.reverse();
        });
      });
    });

    _openDocument();
  }

  @override
  void dispose() {
    _edgeHoldTimer?.cancel();
    _rapidFlipTimer?.cancel();
    _hintTimer?.cancel();
    _hintAnim.dispose();
    _pageController.dispose();
    for (final notifier in _pageNotifiers.values) {
      notifier.dispose();
    }
    _pageNotifiers.clear();
    _doc?.close();
    super.dispose();
  }

  // ── Document loading ───────────────────────────────────────────────────────

  Future<void> _openDocument() async {
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.filePath);
      if (!mounted) {
        await doc.close();
        return;
      }
      setState(() => _doc = doc);
      if (widget.filePath.isNotEmpty && doc.pagesCount > 0) {
        AppDatabase.instance
            .updateDocumentPageCount(widget.filePath, doc.pagesCount)
            .catchError((_) {});
      }
      _prefetchAround(_currentPage);
    } catch (e) {
      if (mounted) setState(() => _docError = true);
      debugPrint('BookPageView: failed to open document: $e');
    }
  }

  // ── Page rendering & caching ───────────────────────────────────────────────

  Future<void> _renderPage(int pageNum) async {
    if (_doc == null) return;
    if (_cache.containsKey(pageNum)) return;
    if (_rendering.contains(pageNum)) return;
    if (pageNum < 1 || pageNum > widget.pageCount) return;

    _rendering.add(pageNum);
    try {
      final page = await _doc!.getPage(pageNum);
      final targetH = (page.height * (_renderWidth / page.width)).clamp(
        600.0,
        4000.0,
      );
      final img = await page.render(
        width: _renderWidth,
        height: targetH,
        format: pdfx.PdfPageImageFormat.jpeg,
        quality: 85,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      final bytes = img?.bytes;
      if (bytes != null && mounted) {
        _cache[pageNum] = bytes;
        _pageNotifiers[pageNum]?.value = bytes;
      }
    } catch (e) {
      debugPrint('BookPageView: render error on page $pageNum: $e');
    } finally {
      _rendering.remove(pageNum);
    }
  }

  /// Renders the visible page first, then its immediate neighbors in turn direction.
  void _prefetchAround(int center, {int direction = 1}) {
    // Evict pages outside of our cache window to keep memory lean
    if (_cache.length > _maxCachedPages) {
      final sortedKeys = _cache.keys.toList()
        ..sort((a, b) => (b - center).abs().compareTo((a - center).abs()));
      while (_cache.length > _maxCachedPages && sortedKeys.isNotEmpty) {
        final toRemove = sortedKeys.removeAt(0);
        if ((toRemove - center).abs() > 3) {
          _cache.remove(toRemove);
          _pageNotifiers[toRemove]?.value = null;
        }
      }
    }

    _renderQueue
      ..clear()
      ..addAll(
        <int>[
          center,
          center + direction,
          center - direction,
        ].where((page) => page >= 1 && page <= widget.pageCount),
      );

    unawaited(_processRenderQueue());
  }

  Future<void> _processRenderQueue() async {
    if (_isProcessingRenderQueue) return;
    _isProcessingRenderQueue = true;
    try {
      while (mounted && _renderQueue.isNotEmpty) {
        final pageNum = _renderQueue.removeAt(0);
        if (!_cache.containsKey(pageNum)) {
          await _renderPage(pageNum);
        }
      }
    } finally {
      _isProcessingRenderQueue = false;
      if (mounted && _renderQueue.isNotEmpty) {
        unawaited(_processRenderQueue());
      }
    }
  }

  // ── Page change ────────────────────────────────────────────────────────────

  void _onPageViewChanged(int zeroBasedIndex) {
    final newPage = zeroBasedIndex + 1;
    final direction = newPage >= _currentPage ? 1 : -1;
    _currentPage = newPage;
    widget.onPageChanged(newPage);
    if (!_isFlippingActive) {
      _prefetchAround(newPage, direction: direction);
    }
  }

  // ── Public API: jump to page (called by bottom toolbar arrows) ─────────────

  void goToPage(int pageNum, {bool animate = true}) {
    final target = pageNum.clamp(1, widget.pageCount) - 1;
    if (animate) {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.jumpToPage(target);
    }
  }

  // ── Edge Hold & Fast Page Flipping (Thumbing through pages) ─────────────────

  void _onPointerDown(
    PointerDownEvent event,
    double screenWidth,
    double screenHeight,
  ) {
    if (_activePointerId != null) {
      _cancelEdgeHold();
      return;
    }

    // Ignore taps near top or bottom edges to avoid conflicts with app bars/toolbars
    if (event.localPosition.dy < 40 ||
        event.localPosition.dy > screenHeight - 40) {
      return;
    }

    const double edgeZoneWidth = 75.0;
    final bool isRightEdge =
        event.localPosition.dx >= screenWidth - edgeZoneWidth;
    final bool isLeftEdge = event.localPosition.dx <= edgeZoneWidth;

    if (!isRightEdge && !isLeftEdge) return;

    // Direction: right edge advances forward (+1), left edge goes backward (-1)
    // Inverted if reverseDirection (RTL) is active
    final int direction;
    if (widget.reverseDirection) {
      direction = isRightEdge ? -1 : 1;
    } else {
      direction = isRightEdge ? 1 : -1;
    }

    // Check bounds
    if (direction > 0 && _currentPage >= widget.pageCount) return;
    if (direction < 0 && _currentPage <= 1) return;

    _activePointerId = event.pointer;
    _pointerDownPos = event.localPosition;
    _inwardDragPixels = 0.0;

    _edgeHoldTimer?.cancel();
    _edgeHoldTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _activePointerId != event.pointer) return;
      startRapidFlip(direction);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId || _pointerDownPos == null) return;

    if (!_isFlippingActive) {
      // If pointer moved beyond touch slop threshold, user is performing a regular swipe
      final distance = (event.localPosition - _pointerDownPos!).distance;
      if (distance > 18.0) {
        _cancelEdgeHold();
      }
    } else {
      // User is dragging inward while flipping is active: increase speed
      final double inward;
      final bool isRightEdge = _pointerDownPos!.dx > 150;
      if (isRightEdge) {
        inward = (_pointerDownPos!.dx - event.localPosition.dx).clamp(
          0.0,
          250.0,
        );
      } else {
        inward = (event.localPosition.dx - _pointerDownPos!.dx).clamp(
          0.0,
          250.0,
        );
      }
      _inwardDragPixels = inward;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointerId) return;
    _finishFlip();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointerId) return;
    _finishFlip();
  }

  void _cancelEdgeHold() {
    _edgeHoldTimer?.cancel();
    _edgeHoldTimer = null;
    _activePointerId = null;
    _pointerDownPos = null;
  }

  /// Starts rapid page flipping in [direction] (+1 for next, -1 for prev).
  /// Can be triggered by edge hold or by long-pressing navigation buttons.
  void startRapidFlip(int direction) {
    if (!mounted) return;
    if (direction > 0 && _currentPage >= widget.pageCount) return;
    if (direction < 0 && _currentPage <= 1) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isFlippingActive = true;
      _flipDirection = direction;
      _flipStartPage = _currentPage;
      _targetPage = (_currentPage + direction).clamp(1, widget.pageCount);
      _tickCount = 0;
    });

    _pageController.jumpToPage(_targetPage - 1);
    _currentPage = _targetPage;
    widget.onPageChanged(_targetPage);

    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    if (!_isFlippingActive || !mounted) return;

    // Acceleration: starts at 240ms, accelerates down to 80ms
    int baseDelay = 240;
    if (_tickCount > 12) {
      baseDelay = 80;
    } else if (_tickCount > 6) {
      baseDelay = 120;
    } else if (_tickCount > 2) {
      baseDelay = 170;
    }

    if (_inwardDragPixels > 40) {
      baseDelay = (baseDelay * 0.6).round().clamp(60, 240);
    }

    _rapidFlipTimer?.cancel();
    _rapidFlipTimer = Timer(Duration(milliseconds: baseDelay), () {
      if (!_isFlippingActive || !mounted) return;
      _stepFlip();
    });
  }

  void _stepFlip() {
    if (!_isFlippingActive || !mounted) return;

    final nextTarget = _targetPage + _flipDirection;
    if (nextTarget < 1 || nextTarget > widget.pageCount) {
      // Hit book boundary
      HapticFeedback.heavyImpact();
      _rapidFlipTimer?.cancel();
      return;
    }

    HapticFeedback.selectionClick();
    _tickCount++;
    _targetPage = nextTarget;
    _currentPage = _targetPage;
    widget.onPageChanged(_targetPage);
    _pageController.jumpToPage(_targetPage - 1);
    setState(() {});

    _scheduleNextTick();
  }

  /// Stops rapid flipping and finalizes on the current target page.
  void stopRapidFlip() {
    _finishFlip();
  }

  void _finishFlip() {
    _cancelEdgeHold();
    _rapidFlipTimer?.cancel();
    _rapidFlipTimer = null;

    if (_isFlippingActive) {
      HapticFeedback.lightImpact();
      final finalPage = _targetPage;
      setState(() {
        _isFlippingActive = false;
        _inwardDragPixels = 0.0;
      });
      _currentPage = finalPage;
      widget.onPageChanged(finalPage);
      _prefetchAround(finalPage, direction: _flipDirection);
      if (_pageController.hasClients &&
          _pageController.page?.round() != finalPage - 1) {
        _pageController.jumpToPage(finalPage - 1);
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_docError) {
      return const Center(
        child: Text(
          'Could not open document in book mode.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final bool isFlipRightEdge = widget.reverseDirection
            ? _flipDirection < 0
            : _flipDirection > 0;

        return Listener(
          onPointerDown: (e) => _onPointerDown(e, screenWidth, screenHeight),
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Page view ──────────────────────────────────────────────────
              PageView.builder(
                controller: _pageController,
                reverse: widget.reverseDirection,
                physics: _isFlippingActive
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
                onPageChanged: _onPageViewChanged,
                itemCount: widget.pageCount,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  final notifier = _getPageNotifier(pageNum);
                  return ValueListenableBuilder<Uint8List?>(
                    valueListenable: notifier,
                    builder: (context, bytes, _) {
                      return _BookPage(
                        pageNum: pageNum,
                        bytes: bytes,
                        isBookmarked:
                            widget.bookmarkedPages?.contains(pageNum) ?? false,
                        isLoading:
                            _doc == null || (bytes == null && !_docError),
                      );
                    },
                  );
                },
              ),

              // ── Active Edge Glow Indicator ─────────────────────────────────
              if (_isFlippingActive)
                _EdgeGlowIndicator(isRightSide: isFlipRightEdge),

              // ── Fast-Flip Center HUD ───────────────────────────────────────
              if (_isFlippingActive)
                _FastFlipHud(
                  currentPage: _targetPage,
                  startPage: _flipStartPage,
                  pageCount: widget.pageCount,
                  isForward: _flipDirection > 0,
                ),

              // ── Swipe hint (← →) — fades in/out once on first open ──────────
              if (widget.pageCount > 1 && !_isFlippingActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _hintOpacity,
                      child: const _SwipeHint(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single book page cell
// ─────────────────────────────────────────────────────────────────────────────

class _BookPage extends StatelessWidget {
  final int pageNum;
  final Uint8List? bytes;
  final bool isLoading;
  final bool isBookmarked;

  const _BookPage({
    required this.pageNum,
    required this.bytes,
    required this.isLoading,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Horizontal margin gives a side-margin "book edge" feel
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            boxShadow: [
              // Right-side page-depth shadow (book thickness illusion)
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(6, 0),
                spreadRadius: -4,
              ),
              // Left spine shadow
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(-4, 0),
                spreadRadius: -2,
              ),
              // Ambient drop shadow
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Page content ───────────────────────────────────────────────
              if (bytes != null)
                InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  boundaryMargin: EdgeInsets.zero,
                  child: Image.memory(
                    bytes!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.medium,
                  ),
                )
              else if (isLoading)
                const _PageLoadingPlaceholder()
              else
                const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.black26,
                    size: 48,
                  ),
                ),

              // ── Spine gradient overlay (left edge binding shadow) ──────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Physical Bookmark Ribbon ──────────────────────────────────
              if (isBookmarked)
                const Positioned(top: 0, right: 18, child: _BookmarkRibbon()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Physical Bookmark Ribbon hanging from page top
// ─────────────────────────────────────────────────────────────────────────────

class _BookmarkRibbon extends StatelessWidget {
  const _BookmarkRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F), // Crimson bookmark ribbon
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.bookmark, color: Colors.white, size: 15),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading placeholder (animated shimmer-style pulse)
// ─────────────────────────────────────────────────────────────────────────────

class _PageLoadingPlaceholder extends StatefulWidget {
  const _PageLoadingPlaceholder();

  @override
  State<_PageLoadingPlaceholder> createState() =>
      _PageLoadingPlaceholderState();
}

class _PageLoadingPlaceholderState extends State<_PageLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        color: Color.lerp(
          const Color(0xFFF0F0F0),
          const Color(0xFFE0E0E0),
          _anim.value,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0F4A42),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rendering page...',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.35),
                  fontSize: 12,
                  fontFamily: 'RedditSans-Regular',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// First-open swipe hint overlay  ← →
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeHint extends StatefulWidget {
  const _SwipeHint();

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _leftArrow;
  late final Animation<Offset> _rightArrow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _leftArrow = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.15, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _rightArrow = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.15, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlideTransition(
              position: _leftArrow,
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Swipe or hold edge to turn pages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'RedditSans-Medium',
              ),
            ),
            const SizedBox(width: 6),
            SlideTransition(
              position: _rightArrow,
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing Edge Glow Indicator on the page-turning side
// ─────────────────────────────────────────────────────────────────────────────

class _EdgeGlowIndicator extends StatefulWidget {
  final bool isRightSide;

  const _EdgeGlowIndicator({required this.isRightSide});

  @override
  State<_EdgeGlowIndicator> createState() => _EdgeGlowIndicatorState();
}

class _EdgeGlowIndicatorState extends State<_EdgeGlowIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _glowPulse = Tween<double>(begin: 0.25, end: 0.60).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: widget.isRightSide ? 0 : null,
      left: widget.isRightSide ? null : 0,
      width: 52,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _glowPulse,
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: widget.isRightSide
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  end: widget.isRightSide
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  colors: [
                    const Color(0xFF0F4A42).withValues(alpha: _glowPulse.value),
                    const Color(
                      0xFF4DB6AC,
                    ).withValues(alpha: _glowPulse.value * 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  widget.isRightSide
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: Colors.white.withValues(alpha: _glowPulse.value * 1.5),
                  size: 38,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fast-Flip Center HUD Card (Quran/eBook style page dial)
// ─────────────────────────────────────────────────────────────────────────────

class _FastFlipHud extends StatelessWidget {
  final int currentPage;
  final int startPage;
  final int pageCount;
  final bool isForward;

  const _FastFlipHud({
    required this.currentPage,
    required this.startPage,
    required this.pageCount,
    required this.isForward,
  });

  @override
  Widget build(BuildContext context) {
    final delta = currentPage - startPage;
    final deltaSign = delta > 0 ? '+$delta' : '$delta';

    return Center(
      child: IgnorePointer(
        child: Container(
          width: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xF21C1C1E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF4DB6AC).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF0F4A42).withValues(alpha: 0.3),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isForward
                        ? Icons.fast_forward_rounded
                        : Icons.fast_rewind_rounded,
                    color: const Color(0xFF4DB6AC),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isForward ? 'Flipping Forward' : 'Flipping Backward',
                    style: const TextStyle(
                      color: Color(0xFF4DB6AC),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'RedditSans-SemiBold',
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$currentPage',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'RedditSans-Bold',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/ $pageCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 15,
                      fontFamily: 'RedditSans-Medium',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4A42).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4DB6AC).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '$deltaSign pages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'RedditSans-Medium',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pageCount > 1
                      ? (currentPage - 1) / (pageCount - 1)
                      : 1.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4DB6AC),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Release finger to stop here',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontFamily: 'RedditSans-Regular',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
