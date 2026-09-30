import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/models/reader_theme.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class PdfViewerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int currentPage;
  final int pageCount;
  final bool isSearchOpen;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final bool isHighlightMode;
  final VoidCallback onToggleHighlightMode;
  final bool isBookMode;
  final VoidCallback onToggleBookMode;
  final bool isCurrentPageBookmarked;
  final int bookmarkCount;
  final VoidCallback onToggleBookmark;
  final VoidCallback onShowBookmarks;
  final ReaderTheme readerTheme;
  final ValueChanged<ReaderTheme> onReaderThemeChanged;
  final bool isAutoScrolling;
  final VoidCallback onShowAutoScrollControls;

  const PdfViewerAppBar({
    super.key,
    required this.title,
    required this.currentPage,
    required this.pageCount,
    required this.isSearchOpen,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.isHighlightMode,
    required this.onToggleHighlightMode,
    required this.isBookMode,
    required this.onToggleBookMode,
    required this.isCurrentPageBookmarked,
    required this.bookmarkCount,
    required this.onToggleBookmark,
    required this.onShowBookmarks,
    required this.readerTheme,
    required this.onReaderThemeChanged,
    required this.isAutoScrolling,
    required this.onShowAutoScrollControls,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: isSearchOpen
          ? TextField(
              controller: searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: 'Search in PDF',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: onSearchSubmitted,
            )
          : Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.textStyleRedditSansSemiBold.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
      actions: [
        IconButton(
          tooltip: isSearchOpen ? 'Close search' : 'Search in PDF',
          onPressed: isSearchOpen ? onCloseSearch : onOpenSearch,
          icon: Icon(
            isSearchOpen ? Icons.close : Icons.search,
            color: Colors.white,
            size: 22,
          ),
        ),
        if (pageCount > 0) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '$currentPage / $pageCount',
                style: textTheme.textStyleRedditSansMedium.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          _ModeButton(
            tooltip: isHighlightMode
                ? 'Highlight Mode (ON) — tap to turn off'
                : 'Highlight Mode (OFF) — tap to turn on',
            onPressed: onToggleHighlightMode,
            active: isHighlightMode,
            activeColor: appTheme.highlightBannerGold,
            child: Icon(
              Icons.border_color_rounded,
              color: isHighlightMode
                  ? appTheme.highlightBannerGold
                  : Colors.white,
              size: 18,
            ),
          ),
          _ModeButton(
            tooltip: isBookMode
                ? 'Switch to scroll mode'
                : 'Switch to book mode',
            onPressed: onToggleBookMode,
            active: isBookMode,
            activeColor: Colors.white,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isBookMode
                  ? const Icon(
                      Icons.view_agenda_outlined,
                      key: ValueKey('scroll'),
                      color: Colors.white,
                      size: 18,
                    )
                  : const Icon(
                      Icons.menu_book_rounded,
                      key: ValueKey('book'),
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
          PopupMenuButton<ReaderTheme>(
            tooltip: 'PDF appearance',
            initialValue: readerTheme,
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            onSelected: onReaderThemeChanged,
            itemBuilder: (context) => ReaderTheme.values
                .map(
                  (theme) => CheckedPopupMenuItem<ReaderTheme>(
                    value: theme,
                    checked: theme == readerTheme,
                    child: Text(theme.label),
                  ),
                )
                .toList(),
          ),
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onSelected: (value) {
              if (value == 'bookmark') onToggleBookmark();
              if (value == 'all_bookmarks') onShowBookmarks();
              if (value == 'auto_scroll') onShowAutoScrollControls();
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'auto_scroll',
                child: Row(
                  children: [
                    Icon(
                      isAutoScrolling
                          ? Icons.pause_circle_outline
                          : Icons.auto_awesome_motion_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAutoScrolling ? 'Auto scroll settings' : 'Auto scroll',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'bookmark',
                child: Row(
                  children: [
                    Icon(
                      isCurrentPageBookmarked
                          ? Icons.bookmark_remove_rounded
                          : Icons.bookmark_add_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isCurrentPageBookmarked
                          ? 'Remove bookmark'
                          : 'Add bookmark',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'all_bookmarks',
                child: Row(
                  children: [
                    const Icon(Icons.bookmarks_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text('All bookmarks ($bookmarkCount)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;
  final Color activeColor;
  final Widget child;

  const _ModeButton({
    required this.tooltip,
    required this.onPressed,
    required this.active,
    required this.activeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? activeColor.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
