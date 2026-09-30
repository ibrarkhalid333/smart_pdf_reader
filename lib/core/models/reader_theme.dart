import 'package:flutter/material.dart';

enum ReaderTheme { light, dark, sepia }

extension ReaderThemePresentation on ReaderTheme {
  String get label => switch (this) {
    ReaderTheme.light => 'Light',
    ReaderTheme.dark => 'Dark',
    ReaderTheme.sepia => 'Sepia',
  };

  ColorFilter? get colorFilter => switch (this) {
    ReaderTheme.light => null,
    ReaderTheme.dark => const ColorFilter.matrix([
      -1,
      0,
      0,
      0,
      255,
      0,
      -1,
      0,
      0,
      255,
      0,
      0,
      -1,
      0,
      255,
      0,
      0,
      0,
      1,
      0,
    ]),
    ReaderTheme.sepia => const ColorFilter.matrix([
      0.393,
      0.769,
      0.189,
      0,
      0,
      0.349,
      0.686,
      0.168,
      0,
      0,
      0.272,
      0.534,
      0.131,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]),
  };

  static ReaderTheme fromStorage(String? value) =>
      ReaderTheme.values.where((theme) => theme.name == value).firstOrNull ??
      ReaderTheme.light;
}
