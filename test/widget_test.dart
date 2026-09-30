import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PDF favorites', () {
    test('toggle favorite persists in the database', () async {
      final filePath =
          '/tmp/favorite_test_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await AppDatabase.instance.upsertDocuments([
        PdfDocument(
          title: 'Favorite Test PDF',
          pages: 42,
          currentPage: 0,
          date: 'Today',
          color: Colors.blue.shade100,
          filePath: filePath,
        ),
      ]);

      await AppDatabase.instance.setFavourite(filePath, true);
      final favoritesAfterAdd = await AppDatabase.instance
          .loadFavouriteDocuments();
      expect(
        favoritesAfterAdd.any((row) => row['file_path'] == filePath),
        isTrue,
      );

      await AppDatabase.instance.setFavourite(filePath, false);
      final favoritesAfterRemove = await AppDatabase.instance
          .loadFavouriteDocuments();
      expect(
        favoritesAfterRemove.any((row) => row['file_path'] == filePath),
        isFalse,
      );
    });
  });
}
