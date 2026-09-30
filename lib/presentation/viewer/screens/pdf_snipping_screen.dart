import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

enum _HandleType {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
  inside,
}

/// Interactive Snipping Tool screen inspired by the Windows Snipping Tool.
/// Supports multi-page continuous documents (page above + current page + page below),
/// allowing the user to stretch the crop rectangle freely across page seams.
class PdfSnippingScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String documentTitle;
  final int startPage;
  final int endPage;
  final int activePage;
  final int totalPages;
  final Rect? initialCropFraction;
  final Future<Uint8List?> Function(int start, int end)? onExtendRange;

  const PdfSnippingScreen({
    super.key,
    required this.imageBytes,
    required this.documentTitle,
    required this.startPage,
    required this.endPage,
    required this.activePage,
    required this.totalPages,
    this.initialCropFraction,
    this.onExtendRange,
  });

  @override
  State<PdfSnippingScreen> createState() => _PdfSnippingScreenState();
}

class _PdfSnippingScreenState extends State<PdfSnippingScreen> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExtending = false;

  late int _startPage;
  late int _endPage;
  Rect? _currentCropFraction;

  // Image layout inside viewport
  Rect _imageRect = Rect.zero;

  // Selected crop rect in screen coordinates
  Rect _cropRect = Rect.zero;

  // Minimum crop dimension in points
  static const double _minCropSize = 44.0;
  static const double _handleTouchSize = 38.0;

  // Active drag state
  _HandleType? _activeHandle;
  Offset? _dragStartOffset;
  Rect? _initialCropOnDrag;

  @override
  void initState() {
    super.initState();
    _startPage = widget.startPage;
    _endPage = widget.endPage;
    _currentCropFraction = widget.initialCropFraction;
    _decodeImage(widget.imageBytes);
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _decodedImage = frame.image;
        _isLoading = false;
        // Trigger layout calculation with new image
        _imageRect = Rect.zero;
        _cropRect = Rect.zero;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar(
        'Image Error',
        'Could not load document pages for snipping: $e',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _extendRange({required bool above}) async {
    if (_isExtending || widget.onExtendRange == null) return;

    final newStart = above ? (_startPage - 1).clamp(1, widget.totalPages) : _startPage;
    final newEnd = !above ? (_endPage + 1).clamp(1, widget.totalPages) : _endPage;

    if (newStart == _startPage && newEnd == _endPage) return;

    setState(() => _isExtending = true);

    try {
      final newBytes = await widget.onExtendRange!(newStart, newEnd);
      if (!mounted) return;

      if (newBytes != null) {
        _startPage = newStart;
        _endPage = newEnd;
        _currentCropFraction = null; // keep current view or reset
        await _decodeImage(newBytes);
      }
    } catch (e) {
      debugPrint('Extend range failed: $e');
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  void _calculateLayout(Size viewportSize) {
    if (_decodedImage == null) return;

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();

    // Available area accounting for top app bar and bottom action pill
    final availableHeight = viewportSize.height - 150;
    final availableWidth = viewportSize.width - 20;

    final scale = math.min(availableWidth / imgW, availableHeight / imgH);
    final renderedW = imgW * scale;
    final renderedH = imgH * scale;

    final left = (viewportSize.width - renderedW) / 2;
    final top = 70 + (availableHeight - renderedH) / 2;

    final newImageRect = Rect.fromLTWH(left, top, renderedW, renderedH);

    if (_imageRect != newImageRect) {
      final wasInitial = _cropRect == Rect.zero;
      _imageRect = newImageRect;

      if (wasInitial) {
        if (_currentCropFraction != null && _currentCropFraction != Rect.zero) {
          final frac = _currentCropFraction!;
          _cropRect = Rect.fromLTRB(
            newImageRect.left + frac.left * newImageRect.width,
            newImageRect.top + frac.top * newImageRect.height,
            newImageRect.left + frac.right * newImageRect.width,
            newImageRect.top + frac.bottom * newImageRect.height,
          );
        } else {
          _cropRect = newImageRect;
        }
      }
    }
  }

  void _resetToActivePage() {
    if (widget.initialCropFraction != null && widget.initialCropFraction != Rect.zero) {
      final frac = widget.initialCropFraction!;
      setState(() {
        _cropRect = Rect.fromLTRB(
          _imageRect.left + frac.left * _imageRect.width,
          _imageRect.top + frac.top * _imageRect.height,
          _imageRect.left + frac.right * _imageRect.width,
          _imageRect.top + frac.bottom * _imageRect.height,
        );
      });
    } else {
      _resetToFullPage();
    }
  }

  void _resetToFullPage() {
    setState(() {
      _cropRect = _imageRect;
    });
  }

  _HandleType? _hitTestHandle(Offset pos) {
    final tl = _cropRect.topLeft;
    final tr = _cropRect.topRight;
    final bl = _cropRect.bottomLeft;
    final br = _cropRect.bottomRight;

    if ((pos - tl).distance <= _handleTouchSize) return _HandleType.topLeft;
    if ((pos - tr).distance <= _handleTouchSize) return _HandleType.topRight;
    if ((pos - bl).distance <= _handleTouchSize) return _HandleType.bottomLeft;
    if ((pos - br).distance <= _handleTouchSize) return _HandleType.bottomRight;

    // Check edges
    if ((pos.dx >= _cropRect.left - 14 && pos.dx <= _cropRect.right + 14) &&
        (pos.dy - _cropRect.top).abs() <= 18) {
      return _HandleType.top;
    }
    if ((pos.dx >= _cropRect.left - 14 && pos.dx <= _cropRect.right + 14) &&
        (pos.dy - _cropRect.bottom).abs() <= 18) {
      return _HandleType.bottom;
    }
    if ((pos.dy >= _cropRect.top - 14 && pos.dy <= _cropRect.bottom + 14) &&
        (pos.dx - _cropRect.left).abs() <= 18) {
      return _HandleType.left;
    }
    if ((pos.dy >= _cropRect.top - 14 && pos.dy <= _cropRect.bottom + 14) &&
        (pos.dx - _cropRect.right).abs() <= 18) {
      return _HandleType.right;
    }

    // Inside crop rect (moving the entire box)
    if (_cropRect.contains(pos)) {
      return _HandleType.inside;
    }

    return null;
  }

  void _onPanStart(DragStartDetails details) {
    final pos = details.localPosition;
    _activeHandle = _hitTestHandle(pos);
    if (_activeHandle != null) {
      _dragStartOffset = pos;
      _initialCropOnDrag = _cropRect;
    } else {
      // Outside crop rect: allow drawing a new rectangle if tapped on document
      if (_imageRect.contains(pos)) {
        setState(() {
          _cropRect = Rect.fromCenter(
            center: pos,
            width: _minCropSize,
            height: _minCropSize,
          );
          _activeHandle = _HandleType.bottomRight;
          _dragStartOffset = pos;
          _initialCropOnDrag = _cropRect;
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeHandle == null || _initialCropOnDrag == null || _dragStartOffset == null) {
      return;
    }

    final delta = details.localPosition - _dragStartOffset!;
    final init = _initialCropOnDrag!;

    double left = init.left;
    double top = init.top;
    double right = init.right;
    double bottom = init.bottom;

    // Notice: Boundaries are constrained to the full multi-page document (_imageRect),
    // allowing the user to stretch freely through previous and next pages!
    switch (_activeHandle!) {
      case _HandleType.topLeft:
        left = (init.left + delta.dx).clamp(_imageRect.left, right - _minCropSize);
        top = (init.top + delta.dy).clamp(_imageRect.top, bottom - _minCropSize);
        break;
      case _HandleType.topRight:
        right = (init.right + delta.dx).clamp(left + _minCropSize, _imageRect.right);
        top = (init.top + delta.dy).clamp(_imageRect.top, bottom - _minCropSize);
        break;
      case _HandleType.bottomLeft:
        left = (init.left + delta.dx).clamp(_imageRect.left, right - _minCropSize);
        bottom = (init.bottom + delta.dy).clamp(top + _minCropSize, _imageRect.bottom);
        break;
      case _HandleType.bottomRight:
        right = (init.right + delta.dx).clamp(left + _minCropSize, _imageRect.right);
        bottom = (init.bottom + delta.dy).clamp(top + _minCropSize, _imageRect.bottom);
        break;
      case _HandleType.top:
        top = (init.top + delta.dy).clamp(_imageRect.top, bottom - _minCropSize);
        break;
      case _HandleType.bottom:
        bottom = (init.bottom + delta.dy).clamp(top + _minCropSize, _imageRect.bottom);
        break;
      case _HandleType.left:
        left = (init.left + delta.dx).clamp(_imageRect.left, right - _minCropSize);
        break;
      case _HandleType.right:
        right = (init.right + delta.dx).clamp(left + _minCropSize, _imageRect.right);
        break;
      case _HandleType.inside:
        final width = init.width;
        final height = init.height;
        left = (init.left + delta.dx).clamp(_imageRect.left, _imageRect.right - width);
        top = (init.top + delta.dy).clamp(_imageRect.top, _imageRect.bottom - height);
        right = left + width;
        bottom = top + height;
        break;
    }

    setState(() {
      _cropRect = Rect.fromLTRB(left, top, right, bottom);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _activeHandle = null;
    _dragStartOffset = null;
    _initialCropOnDrag = null;
  }

  /// Extracts the cropped portion of the multi-page document at native resolution.
  Future<Uint8List?> _cropImage() async {
    if (_decodedImage == null || _imageRect.width <= 0 || _imageRect.height <= 0) {
      return null;
    }

    final scaleX = _decodedImage!.width / _imageRect.width;
    final scaleY = _decodedImage!.height / _imageRect.height;

    // Relative crop in original image pixels
    final cropX = ((_cropRect.left - _imageRect.left) * scaleX).clamp(0.0, _decodedImage!.width.toDouble());
    final cropY = ((_cropRect.top - _imageRect.top) * scaleY).clamp(0.0, _decodedImage!.height.toDouble());
    final cropW = (_cropRect.width * scaleX).clamp(1.0, _decodedImage!.width - cropX);
    final cropH = (_cropRect.height * scaleY).clamp(1.0, _decodedImage!.height - cropY);

    final srcRect = Rect.fromLTWH(cropX, cropY, cropW, cropH);
    final dstRect = Rect.fromLTWH(0, 0, cropW, cropH);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, dstRect);
    // Draw pure white background so saved output is never transparent or dark
    canvas.drawRect(dstRect, Paint()..color = Colors.white);
    canvas.drawImageRect(_decodedImage!, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
    final picture = recorder.endRecording();
    final croppedImg = await picture.toImage(cropW.round(), cropH.round());
    final byteData = await croppedImg.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveSnip() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final croppedBytes = await _cropImage();
      if (croppedBytes == null) {
        throw Exception('Failed to crop image area');
      }

      final pageLabel = _startPage == _endPage ? 'p$_startPage' : 'p$_startPage-$_endPage';
      final fileName = 'snip_${pageLabel}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ImageGallerySaverPlus.saveImage(
        croppedBytes,
        quality: 100,
        name: fileName,
      );

      final bool saved = result['isSuccess'] == true || result['filePath'] != null;

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (saved) {
        _showSuccessSheet(croppedBytes, 'Saved to Gallery');
      } else {
        Get.snackbar(
          'Notice',
          'Image processed but could not confirm gallery save.',
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Get.snackbar(
        'Save Failed',
        e.toString(),
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _shareSnip() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final croppedBytes = await _cropImage();
      if (croppedBytes == null) throw Exception('Failed to crop image area');

      final pageLabel = _startPage == _endPage ? 'p$_startPage' : 'p$_startPage-$_endPage';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/snip_${pageLabel}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(croppedBytes);

      if (!mounted) return;
      setState(() => _isSaving = false);

      final pageDesc = _startPage == _endPage ? 'page $_startPage' : 'pages $_startPage–$_endPage';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Snip from $pageDesc of "${widget.documentTitle}"',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Get.snackbar(
        'Share Failed',
        e.toString(),
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  void _showSuccessSheet(Uint8List croppedBytes, String title) {
    final pageLabel = _startPage == _endPage ? 'Page $_startPage' : 'Pages $_startPage–$_endPage';
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appTheme.warmWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
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
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.textStyleRedditSansBold.copyWith(
                            fontSize: 16,
                            color: appTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '$pageLabel • High-resolution snip',
                          style: textTheme.textStyleRedditSansRegular.copyWith(
                            fontSize: 13,
                            color: appTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  color: Colors.black12,
                  child: Image.memory(
                    croppedBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        _shareSnip();
                      },
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text('Share', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _calculateLayout(size);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E24),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      'Preparing document pages...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Interactive snipping canvas
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _SnippingPainter(
                          image: _decodedImage,
                          imageRect: _imageRect,
                          cropRect: _cropRect,
                          primaryColor: appTheme.primaryColor,
                          activeHandle: _activeHandle,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),

                  // Top App Bar
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: _buildTopBar(),
                  ),

                  // Bottom Action Floating Pill
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildBottomActions(),
                  ),

                  if (_isExtending)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    final hasMultiPages = _startPage != _endPage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Explicit Cancel Button
              TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                label: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Snipping Tool',
                      style: textTheme.textStyleRedditSansBold.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      hasMultiPages
                          ? 'Pages $_startPage–$_endPage of ${widget.totalPages} • Stretch across pages'
                          : 'Page $_startPage of ${widget.totalPages} • Drag handles to crop',
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Reset to active page
              if (hasMultiPages)
                TextButton(
                  onPressed: _resetToActivePage,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Page ${widget.activePage}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              if (hasMultiPages) const SizedBox(width: 6),
              // Full Span button
              TextButton.icon(
                onPressed: _resetToFullPage,
                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                label: Text(
                  hasMultiPages ? 'All Pages' : 'Full Page',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          // Extend Range Bar if pages are available above or below
          if (widget.onExtendRange != null && (_startPage > 1 || _endPage < widget.totalPages))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_startPage > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _extendRange(above: true),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.tealAccent),
                              const SizedBox(width: 4),
                              Text(
                                '+ Add Page ${_startPage - 1} Above',
                                style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_endPage < widget.totalPages)
                    InkWell(
                      onTap: () => _extendRange(above: false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.25),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.tealAccent),
                            const SizedBox(width: 4),
                            Text(
                              '+ Add Page ${_endPage + 1} Below',
                              style: const TextStyle(color: Colors.tealAccent, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Explicit Cancel Button in bottom bar
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
              label: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Share button
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _isSaving ? null : _shareSnip,
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Share',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Save to Gallery button
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSnip,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 20, color: Colors.white),
              label: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.primaryColor,
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws the multi-page image, darkened backdrop mask,
/// crop rectangle with glowing border, and 8 corner/edge handles.
class _SnippingPainter extends CustomPainter {
  final ui.Image? image;
  final Rect imageRect;
  final Rect cropRect;
  final Color primaryColor;
  final _HandleType? activeHandle;

  _SnippingPainter({
    required this.image,
    required this.imageRect,
    required this.cropRect,
    required this.primaryColor,
    required this.activeHandle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final fullScreenRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Draw subtle drop shadow under the document paper
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(imageRect, const Radius.circular(2)),
      shadowPaint,
    );

    // 2. Draw crisp pure-white paper background for the document
    canvas.drawRect(imageRect, Paint()..color = Colors.white);

    // 3. Draw the base PDF multi-page image on top of white paper
    final src = Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());
    canvas.drawImageRect(image!, src, imageRect, Paint()..filterQuality = FilterQuality.high);

    // 4. Darken the ENTIRE background outside the selected crop rectangle
    final maskPath = Path()
      ..addRect(fullScreenRect)
      ..addRect(cropRect);
    maskPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(
      maskPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill,
    );

    // 5. Draw crisp selection border around the snip
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(cropRect, borderPaint);

    // 6. Corner Handles
    _drawCornerGrip(canvas, cropRect.topLeft, _HandleType.topLeft);
    _drawCornerGrip(canvas, cropRect.topRight, _HandleType.topRight);
    _drawCornerGrip(canvas, cropRect.bottomLeft, _HandleType.bottomLeft);
    _drawCornerGrip(canvas, cropRect.bottomRight, _HandleType.bottomRight);

    // 7. Edge Pill Handles
    _drawEdgePill(canvas, Offset(cropRect.center.dx, cropRect.top), true, _HandleType.top);
    _drawEdgePill(canvas, Offset(cropRect.center.dx, cropRect.bottom), true, _HandleType.bottom);
    _drawEdgePill(canvas, Offset(cropRect.left, cropRect.center.dy), false, _HandleType.left);
    _drawEdgePill(canvas, Offset(cropRect.right, cropRect.center.dy), false, _HandleType.right);
  }

  void _drawCornerGrip(Canvas canvas, Offset center, _HandleType type) {
    final bool isActive = activeHandle == type;
    final radius = isActive ? 9.0 : 7.0;

    canvas.drawCircle(
      center,
      radius + 2,
      Paint()..color = Colors.black38,
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      radius - 2.5,
      Paint()..color = primaryColor,
    );
  }

  void _drawEdgePill(Canvas canvas, Offset center, bool isHorizontal, _HandleType type) {
    final bool isActive = activeHandle == type;
    final w = isHorizontal ? (isActive ? 28.0 : 22.0) : (isActive ? 6.0 : 5.0);
    final h = isHorizontal ? (isActive ? 6.0 : 5.0) : (isActive ? 28.0 : 22.0);

    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _SnippingPainter oldDelegate) {
    return oldDelegate.imageRect != imageRect ||
        oldDelegate.cropRect != cropRect ||
        oldDelegate.activeHandle != activeHandle ||
        oldDelegate.image != image;
  }
}
