import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Floating popup displayed when text is selected in the PDF viewer.
class TextSelectionPopup extends StatelessWidget {
  final bool hasHighlight;
  final Color selectedColor;
  final List<Color> palette;
  final VoidCallback onRemoveHighlight;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onCopy;

  const TextSelectionPopup({
    super.key,
    required this.hasHighlight,
    required this.selectedColor,
    required this.palette,
    required this.onRemoveHighlight,
    required this.onColorSelected,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.viewerOverlayDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHighlight) ...[
            InkWell(
              onTap: onRemoveHighlight,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.format_color_reset_rounded,
                      color: Colors.red.shade300,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1,
              height: 18,
              color: Colors.white24,
            ),
          ],
          ...palette.map((color) {
            final isCurrent = color == selectedColor;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.black26,
                    width: isCurrent ? 2.2 : 1.0,
                  ),
                ),
              ),
            );
          }),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 1,
            height: 18,
            color: Colors.white24,
          ),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, color: Colors.white70, size: 15),
                  SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating toolbar displayed when an existing annotation is tapped.
class AnnotationEditToolbar extends StatelessWidget {
  final Color selectedColor;
  final List<Color> palette;
  final VoidCallback onDelete;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onClose;

  const AnnotationEditToolbar({
    super.key,
    required this.selectedColor,
    required this.palette,
    required this.onDelete,
    required this.onColorSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.viewerOverlayDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 1,
            height: 18,
            color: Colors.white24,
          ),
          ...palette.map((color) {
            final isCurrent = color == selectedColor;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? Colors.white : Colors.black26,
                    width: isCurrent ? 2.0 : 1.0,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white54, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown at the top of the viewer when "Highlight Mode" is toggled on.
class HighlightModeBanner extends StatelessWidget {
  final Color selectedColor;
  final VoidCallback onColorTap;
  final VoidCallback onClose;

  const HighlightModeBanner({
    super.key,
    required this.selectedColor,
    required this.onColorTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.highlightBannerBackground,
        border: Border(
          bottom: BorderSide(
            color: appTheme.highlightBannerGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: appTheme.highlightBannerGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.border_color_rounded,
              color: appTheme.highlightBannerGold,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Highlight Mode: Select text to highlight • Select highlighted text to remove',
              style: TextStyle(
                color: appTheme.highlightBannerGoldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onColorTap,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for picking the active highlight color.
class HighlightPaletteSheet extends StatelessWidget {
  final Color selectedColor;
  final List<Color> palette;
  final ValueChanged<Color> onColorSelected;

  const HighlightPaletteSheet({
    super.key,
    required this.selectedColor,
    required this.palette,
    required this.onColorSelected,
  });

  static void show({
    required BuildContext context,
    required Color selectedColor,
    required List<Color> palette,
    required ValueChanged<Color> onColorSelected,
  }) {
    Get.bottomSheet(
      HighlightPaletteSheet(
        selectedColor: selectedColor,
        palette: palette,
        onColorSelected: onColorSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appTheme.viewerOverlayDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Highlight Color',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: palette.map((color) {
                final isSelected = color == selectedColor;
                return GestureDetector(
                  onTap: () {
                    onColorSelected(color);
                    Get.back();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.black26,
                        width: isSelected ? 3.0 : 1.0,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
