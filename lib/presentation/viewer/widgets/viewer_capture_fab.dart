import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ViewerCaptureFab extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final AnimationController animationController;
  final bool isSaving;
  final VoidCallback onPressed;

  const ViewerCaptureFab({
    super.key,
    required this.scaleAnimation,
    required this.animationController,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => animationController.reverse(),
        onTapUp: (_) {
          animationController.forward();
          if (!isSaving) onPressed();
        },
        onTapCancel: animationController.forward,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [appTheme.primaryMid, appTheme.primaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: appTheme.primaryColor.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }
}
