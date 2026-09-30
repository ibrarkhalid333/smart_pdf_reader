import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ViewerSearchResultsBar extends StatelessWidget {
  final String query;
  final int currentIndex;
  final int resultCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const ViewerSearchResultsBar({
    super.key,
    required this.query,
    required this.currentIndex,
    required this.resultCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        border: Border(
          top: BorderSide(color: appTheme.borderDefault.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Search: $query • $currentIndex/$resultCount',
              style: textTheme.textStyleRedditSansMedium.copyWith(
                color: appTheme.textPrimaryColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Previous result',
            onPressed: onPrevious,
            icon: const Icon(Icons.navigate_before_rounded),
          ),
          IconButton(
            tooltip: 'Next result',
            onPressed: onNext,
            icon: const Icon(Icons.navigate_next_rounded),
          ),
        ],
      ),
    );
  }
}
