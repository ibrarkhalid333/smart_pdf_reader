import 'package:flutter/material.dart';

/// Singleton Theme Helper (no dark/light mode switching)
class ThemeHelper {
  static final ThemeHelper _instance = ThemeHelper._internal();
  ThemeHelper._internal();
  factory ThemeHelper() => _instance;
  AppColors themeColor() => AppColors();
  TextStyles themeText() => TextStyles();
}

/// Unified App Colors
class AppColors {
  ///////// Primary — Deep Teal /////////////
  Color get primaryColor => const Color(
    0xFF0F4A42,
  ); // Primary Dark: headers, active nav, primary buttons
  Color get primaryMid =>
      const Color(0xFF1A6B60); // icons, links, progress bars
  Color get primaryLight => const Color(0xFF1F8273); // secondary icons, accents
  Color get primaryPale => const Color(0xFF2F9485); // gradient end
  Color get primaryGradientStart => const Color(0xFF14564C); // gradient start

  ///////// Teal Tints — Backgrounds & Fills /////////////
  Color get tealTintBackground =>
      const Color(0xFFE9F6F2); // icon backgrounds, active tool backgrounds
  Color get tealTintBorder =>
      const Color(0xFFCFE9E1); // topbar border, file thumb border
  Color get tealTextOnDark =>
      const Color(0xFFD9F1EB); // text on dark gradient headers

  ///////// Coin / Gold — Currency System /////////////
  Color get coinGold =>
      const Color(0xFFD4920A); // coin pill background, coin icons
  Color get coinBackground =>
      const Color(0xFFFEF3DC); // coin tag backgrounds, unlock sheet highlight
  Color get coinTextDark =>
      const Color(0xFF7A5000); // coin amounts on light backgrounds
  Color get coinTextDarker => const Color(0xFF412402); // large coin amounts

  ///////// Neutral — Surfaces & Text /////////////
  Color get screenBackgroundColor =>
      const Color(0xFFFBFAF7); // app background, cards
  Color get surfaceLight =>
      const Color(0xFFF5F4F0); // locked icon backgrounds, chip backgrounds
  Color get warmWhite =>
      const Color(0xFFFFFFFF); // file cards, bottom nav, tool sheet
  Color get borderDefault =>
      const Color(0xFFE5E2D8); // all card borders, dividers
  Color get borderMid => const Color(0xFFEAE8E3); // progress bar track

  ///////// Text Colors /////////////
  Color get textPrimaryColor =>
      const Color(0xFF2E2D29); // file names, headings, body labels
  Color get textSecondaryColor =>
      const Color(0xFF6B6862); // subtitles, descriptions, PDF body text
  Color get textMutedColor =>
      const Color(0xFF9E9B93); // timestamps, page counts, inactive tabs

  ///////// Status & Feedback /////////////
  Color get lockedIconColor => const Color(0xFFB4B2A9); // locked tool icons
  Color get lockedBorderColor =>
      const Color(0xFFD4D1CA); // inactive dots, handles, muted borders

  // Success / Owned: Primary background with tint text
  Color get successBackground => const Color(0xFFE9F6F2);
  Color get successText => const Color(0xFF0F4A42);

  ///////// PDF Viewer & Annotation Colors /////////////
  Color get highlightYellow => const Color(0xFFFFEB3B);
  Color get highlightGreen => const Color(0xFFA5D6A7);
  Color get highlightPink => const Color(0xFFF48FB1);
  Color get highlightSkyBlue => const Color(0xFF90CAF9);
  Color get highlightOrange => const Color(0xFFFFCC80);
  List<Color> get highlightPalette => [
    highlightYellow,
    highlightGreen,
    highlightPink,
    highlightSkyBlue,
    highlightOrange,
  ];

  Color get viewerOverlayDark => const Color(0xFF1E1E24);
  Color get viewerDarkBar => const Color(0xFF2C2C2E);
  Color get viewerDarkBackground => const Color(0xFF1C1C1E);
  Color get highlightBannerBackground => const Color(0xFF2C2416);
  Color get highlightBannerGold => const Color(0xFFFFD54F);
  Color get highlightBannerGoldLight => const Color(0xFFFFE082);
  Color get bookmarkGold => const Color(0xFFFFD54F);
  Color get bookmarkGoldMid => const Color(0xFFFFB300);
  Color get dangerRed => const Color(0xFFD32F2F);
  Color get dangerRedLight => const Color(0xFFFFEBEE);
  Color get purpleAccentLight => const Color(0xFFEDE7F6);

  ///////// Deprecated/Old mappings (for backward compatibility if needed, can be removed later) /////////////
  // Mapping old names to new ones so we don't break existing code while we update UI
  Color get surfaceColor => warmWhite;

  Color get streakOrange => const Color(0xFFEA580C);
}

/// Text Styles  /////////////////////////////////
class TextStyles {
  TextStyle get textStyleRedditSansRegular =>
      const TextStyle(fontFamily: "RedditSans-Regular");
  TextStyle get textStyleRedditSansMedium =>
      const TextStyle(fontFamily: "RedditSans-Medium");
  TextStyle get textStyleRedditSansSemiBold =>
      const TextStyle(fontFamily: "RedditSans-SemiBold");
  TextStyle get textStyleRedditSansLight =>
      const TextStyle(fontFamily: "RedditSans-Light");
  TextStyle get textStyleRedditSansBold =>
      const TextStyle(fontFamily: "RedditSans-Bold");
  TextStyle get textStyleRedditSansItalic =>
      const TextStyle(fontFamily: "RedditSans-Italic");
}

/// Global getters
AppColors get appTheme => ThemeHelper().themeColor();
TextStyles get textTheme => ThemeHelper().themeText();
