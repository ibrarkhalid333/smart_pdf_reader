import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pdf_reader/core/models/reader_theme.dart';

class ReaderAppearanceController extends GetxController {
  static const _themePreferenceKey = 'reader_theme';

  final Rx<ReaderTheme> theme = ReaderTheme.light.obs;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    theme.value = ReaderThemePresentation.fromStorage(
      preferences.getString(_themePreferenceKey),
    );
  }

  Future<void> setTheme(ReaderTheme value) async {
    theme.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, value.name);
  }
}
