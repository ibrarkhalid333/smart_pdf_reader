import 'dart:ui';
import 'package:flutter/material.dart';

//BuildContext context
late BuildContext buildContext;
// This functions are responsible to make UI responsive across all the mobile devices.
MediaQueryData mediaQueryData = MediaQueryData.fromView(
  PlatformDispatcher.instance.views.first,
);
// ignore: non_constant_identifier_names
double STATUS_BAR = 0;
void onBuildContext(BuildContext context) {
  buildContext = context;
  STATUS_BAR = MediaQuery.of(context).padding.top;

  mediaQueryData = MediaQuery.of(context);
}

// These are the Viewport values of your Figma Design.
// These are used in the code as a reference to create your UI Responsively.
// ignore: constant_identifier_names
const num FIGMA_DESIGN_WIDTH = 375;
// ignore: constant_identifier_names
const num FIGMA_DESIGN_HEIGHT = 812;
// ignore: constant_identifier_names
const num FIGMA_DESIGN_STATUS_BAR = 44;

///This extension is used to set padding/margin (for the top and bottom side) & height of the screen or widget according to the Viewport height.
extension ResponsiveExtension on num {
  ///This method is used to get device viewport width.
  get _width {
    final w = mediaQueryData.size.width;
    return (w > 0) ? w : FIGMA_DESIGN_WIDTH;
  }

  ///This method is used to get device viewport height.
  get _height {
    num statusBar = mediaQueryData.viewPadding.top;
    num bottomBar = mediaQueryData.viewPadding.bottom;
    num screenHeight = mediaQueryData.size.height - statusBar - bottomBar;
    return (screenHeight > 0) ? screenHeight : (FIGMA_DESIGN_HEIGHT - FIGMA_DESIGN_STATUS_BAR);
  }

  ///This method is used to set padding/margin (for the left and Right side) & width of the screen or widget according to the Viewport width.
  double get h => ((this * _width) / FIGMA_DESIGN_WIDTH);

  ///This method is used to set padding/margin (for the top and bottom side) & height of the screen or widget according to the Viewport height.
  double get v =>
      (this * _height) / (FIGMA_DESIGN_HEIGHT - FIGMA_DESIGN_STATUS_BAR);

  ///This method is used to set smallest px in image height and width
  double get adaptSize {
    var height = v;
    var width = h;
    return height < width ? height.toDoubleValue() : width.toDoubleValue();
  }

  ///This method is used to set text font size according to Viewport
  double get fSize => adaptSize;
}

extension FormatExtension on double {
  /// Return a [double] value with formatted according to provided fractionDigits
  double toDoubleValue({int fractionDigits = 2}) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}
