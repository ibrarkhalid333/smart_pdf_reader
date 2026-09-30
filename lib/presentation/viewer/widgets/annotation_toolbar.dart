import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/viewer/models/pdf_text_markup_style.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Floating popup displayed when text is selected in the PDF viewer.
class TextSelectionPopup extends StatelessWidget {
  final bool hasHighlight;
  final Color selectedColor;
  final List<Color> palette;
  final VoidCallback onRemoveHighlight;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onCopy;
  final bool isMarkupMode;
  final String markupLabel;
  final VoidCallback? onApplyMarkup;

  const TextSelectionPopup({
    super.key,
    required this.hasHighlight,
    required this.selectedColor,
    required this.palette,
    required this.onRemoveHighlight,
    required this.onColorSelected,
    required this.onCopy,
    this.isMarkupMode = false,
    this.markupLabel = 'Highlight',
    this.onApplyMarkup,
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
          if (isMarkupMode) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            Tooltip(
              message: 'Apply $markupLabel',
              child: InkWell(
                onTap: onApplyMarkup,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ] else
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
  final String markupLabel;
  final VoidCallback onColorTap;
  final VoidCallback onClose;

  const HighlightModeBanner({
    super.key,
    required this.selectedColor,
    this.markupLabel = 'Highlight',
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
              '$markupLabel mode: Select text to apply',
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

const _highlightPickerColors = <Color>[
  Color(0xFF1800F5),
  Color(0xFF5DDC28),
  Color(0xFFFFCC00),
  Color(0xFFFF7900),
  Color(0xFFE61B38),
  Color(0xFF992E8C),
  Color(0xFF36D5ED),
  Color(0xFFBBF768),
  Color(0xFFF8F18F),
  Color(0xFFFFBB95),
  Color(0xFFF07498),
  Color(0xFFE478ED),
  Color(0xFFFFFFFF),
  Color(0xFFD0D0D0),
  Color(0xFFAFAFAF),
  Color(0xFF7D7D7D),
  Color(0xFF424242),
  Color(0xFF000000),
];

/// Bottom sheet for selecting text-markup color, opacity, and style.
class HighlightPaletteSheet extends StatefulWidget {
  final Color selectedColor;
  final double selectedOpacity;
  final PdfTextMarkupStyle selectedStyle;
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<PdfTextMarkupStyle> onStyleSelected;

  const HighlightPaletteSheet({
    super.key,
    required this.selectedColor,
    required this.selectedOpacity,
    required this.selectedStyle,
    required this.onColorSelected,
    required this.onOpacityChanged,
    required this.onStyleSelected,
  });

  @override
  State<HighlightPaletteSheet> createState() => _HighlightPaletteSheetState();

  static void show({
    required BuildContext context,
    required Color selectedColor,
    required double selectedOpacity,
    required PdfTextMarkupStyle selectedStyle,
    required ValueChanged<Color> onColorSelected,
    required ValueChanged<double> onOpacityChanged,
    required ValueChanged<PdfTextMarkupStyle> onStyleSelected,
  }) {
    Get.bottomSheet(
      HighlightPaletteSheet(
        selectedColor: selectedColor,
        selectedOpacity: selectedOpacity,
        selectedStyle: selectedStyle,
        onColorSelected: onColorSelected,
        onOpacityChanged: onOpacityChanged,
        onStyleSelected: onStyleSelected,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _HighlightPaletteSheetState extends State<HighlightPaletteSheet> {
  late Color _selectedColor = widget.selectedColor;
  late double _opacity = widget.selectedOpacity.clamp(0.1, 1.0).toDouble();
  late PdfTextMarkupStyle _selectedStyle = widget.selectedStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.lockedBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Highlight color',
              style: textTheme.textStyleRedditSansSemiBold.copyWith(
                color: appTheme.textPrimaryColor,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 12,
              children: _highlightPickerColors.map(_buildColorSwatch).toList(),
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(trackHeight: 8),
              child: Slider(
                value: _opacity,
                min: 0.1,
                max: 1,
                divisions: 18,
                activeColor: _selectedColor,
                onChanged: (opacity) {
                  setState(() => _opacity = opacity);
                  widget.onOpacityChanged(opacity);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStyleButton(
                    PdfTextMarkupStyle.highlight,
                    Icons.border_color_rounded,
                  ),
                ),
                Expanded(
                  child: _buildStyleButton(
                    PdfTextMarkupStyle.underline,
                    Icons.format_underlined_rounded,
                  ),
                ),
                Expanded(
                  child: _buildStyleButton(
                    PdfTextMarkupStyle.strikethrough,
                    Icons.strikethrough_s,
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: appTheme.borderDefault,
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: _opacity),
                    border: Border.all(color: appTheme.borderDefault),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color) {
    final isSelected = color == _selectedColor;
    final iconColor = color.computeLuminance() < 0.45
        ? Colors.white
        : Colors.black87;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedColor = color);
        widget.onColorSelected(color);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: _opacity),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? appTheme.primaryMid : appTheme.borderDefault,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, color: iconColor, size: 22)
            : null,
      ),
    );
  }

  Widget _buildStyleButton(PdfTextMarkupStyle style, IconData icon) {
    final isSelected = _selectedStyle == style;
    return IconButton(
      tooltip: style.label,
      onPressed: () {
        setState(() => _selectedStyle = style);
        widget.onStyleSelected(style);
      },
      style: IconButton.styleFrom(
        foregroundColor: isSelected
            ? appTheme.primaryColor
            : appTheme.textPrimaryColor,
        backgroundColor: isSelected
            ? appTheme.tealTintBackground
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 24),
    );
  }
}
