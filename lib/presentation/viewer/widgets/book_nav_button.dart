import 'package:flutter/material.dart';

/// Navigation button used in the Book Mode bottom bar with tap and long-press rapid flipping support.
class BookNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const BookNavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPressStart: enabled && onLongPressStart != null
            ? (_) => onLongPressStart!()
            : null,
        onLongPressEnd: enabled && onLongPressEnd != null
            ? (_) => onLongPressEnd!()
            : null,
        onLongPressCancel: enabled && onLongPressEnd != null
            ? onLongPressEnd
            : null,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: enabled ? Colors.white : Colors.white24,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white24,
                    fontSize: 13,
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
