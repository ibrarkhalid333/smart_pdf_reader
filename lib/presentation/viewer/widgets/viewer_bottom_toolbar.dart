import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/presentation/viewer/widgets/book_nav_button.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Bottom toolbar for the PDF viewer supporting both Book mode (page flip)
/// and standard scroll/zoom mode.
class ViewerBottomToolbar extends StatelessWidget {
  final bool isBookMode;
  final int currentPage;
  final int pageCount;
  final bool isHighlightMode;
  final VoidCallback? onToggleHighlightMode;
  final VoidCallback? onMoreTools;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onFitPage;
  final ValueChanged<int>? onRapidFlipStart;
  final VoidCallback? onRapidFlipEnd;

  const ViewerBottomToolbar({
    super.key,
    required this.isBookMode,
    required this.currentPage,
    required this.pageCount,
    this.isHighlightMode = false,
    this.onToggleHighlightMode,
    this.onMoreTools,
    this.onPreviousPage,
    this.onNextPage,
    this.onZoomIn,
    this.onZoomOut,
    this.onFitPage,
    this.onRapidFlipStart,
    this.onRapidFlipEnd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFirst = currentPage <= 1;
    final bool isLast = currentPage >= pageCount;

    if (isBookMode) {
      return SafeArea(
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: appTheme.viewerDarkBar,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookNavButton(
                icon: Icons.chevron_left_rounded,
                label: 'Prev',
                enabled: !isFirst,
                onTap: onPreviousPage ?? () {},
                onLongPressStart: onRapidFlipStart != null
                    ? () => onRapidFlipStart!(-1)
                    : null,
                onLongPressEnd: onRapidFlipEnd,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $currentPage of $pageCount',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'RedditSans-Medium',
                  ),
                ),
              ),
              BookNavButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next',
                enabled: !isLast,
                onTap: onNextPage ?? () {},
                onLongPressStart: onRapidFlipStart != null
                    ? () => onRapidFlipStart!(1)
                    : null,
                onLongPressEnd: onRapidFlipEnd,
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: appTheme.warmWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: appTheme.borderDefault.withValues(alpha: 0.7),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          10,
          8,
          MediaQuery.paddingOf(context).bottom + 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToolbarAction(
                tooltip: 'Edit PDF (not available yet)',
                label: 'Edit PDF',
                icon: Icons.edit_note_rounded,
                enabled: false,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                tooltip: 'Comment (not available yet)',
                label: 'Comment',
                icon: Icons.comment_outlined,
                enabled: false,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                tooltip: isHighlightMode
                    ? 'Turn off highlighting'
                    : 'Highlight',
                label: 'Highlight',
                icon: Icons.border_color_rounded,
                selected: isHighlightMode,
                onPressed: onToggleHighlightMode,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                tooltip: 'Draw (not available yet)',
                label: 'Draw',
                icon: Icons.gesture_rounded,
                enabled: false,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                tooltip: 'Fill & Sign (not available yet)',
                label: 'Fill & Sign',
                icon: Icons.draw_outlined,
                enabled: false,
              ),
            ),
            Expanded(
              child: _ToolbarAction(
                tooltip: 'More tools',
                label: 'More tools',
                icon: Icons.grid_view_rounded,
                onPressed: onMoreTools,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  final String tooltip;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool selected;
  final VoidCallback? onPressed;

  const _ToolbarAction({
    required this.tooltip,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.selected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;
    final color = selected
        ? appTheme.primaryColor
        : isEnabled
        ? appTheme.textPrimaryColor
        : appTheme.textMutedColor;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 58,
            decoration: selected
                ? BoxDecoration(
                    color: appTheme.tealTintBackground,
                    borderRadius: BorderRadius.circular(10),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontFamily: 'RedditSans-Medium',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
