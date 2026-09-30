import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Bottom sheet displaying saved bookmarks for the current PDF document.
class BookmarksSheet extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> bookmarks;
  final int currentPage;
  final ValueChanged<int> onSelectPage;
  final ValueChanged<int> onDeleteBookmark;

  const BookmarksSheet({
    super.key,
    required this.title,
    required this.bookmarks,
    required this.currentPage,
    required this.onSelectPage,
    required this.onDeleteBookmark,
  });

  @override
  State<BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<BookmarksSheet> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.bookmarks);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: appTheme.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appTheme.bookmarkGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: appTheme.bookmarkGoldMid,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookmarks',
                        style: textTheme.textStyleRedditSansBold.copyWith(
                          fontSize: 18,
                          color: appTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${_items.length} ${_items.length == 1 ? 'bookmark' : 'bookmarks'} in this document',
                        style: textTheme.textStyleRedditSansRegular.copyWith(
                          fontSize: 12,
                          color: appTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: appTheme.textMutedColor,
                  ),
                  onPressed: Get.back,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: appTheme.borderDefault.withValues(alpha: 0.6),
          ),

          // List of bookmarks
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 52,
                    color: appTheme.textMutedColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No bookmarks yet',
                    style: textTheme.textStyleRedditSansBold.copyWith(
                      fontSize: 16,
                      color: appTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the bookmark icon in the top toolbar on any page to save it for quick reference.',
                    textAlign: TextAlign.center,
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      fontSize: 13,
                      color: appTheme.textMutedColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final b = _items[index];
                  final pageNum = b['page_number'] as int;
                  final isCurrent = pageNum == widget.currentPage;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onSelectPage(pageNum),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? appTheme.primaryColor.withValues(alpha: 0.08)
                              : appTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? appTheme.primaryColor.withValues(alpha: 0.4)
                                : appTheme.borderDefault.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: appTheme.primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.bookmark_rounded,
                                  color: appTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Page $pageNum',
                                        style: textTheme.textStyleRedditSansBold
                                            .copyWith(
                                              fontSize: 15,
                                              color: appTheme.textPrimaryColor,
                                            ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: appTheme.primaryColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'Current',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: appTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to jump to this page',
                                    style: textTheme.textStyleRedditSansRegular
                                        .copyWith(
                                          fontSize: 12,
                                          color: appTheme.textMutedColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove bookmark',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: appTheme.dangerRed,
                                size: 20,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                final pageToDelete = pageNum;
                                setState(() {
                                  _items.removeAt(index);
                                });
                                widget.onDeleteBookmark(pageToDelete);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
