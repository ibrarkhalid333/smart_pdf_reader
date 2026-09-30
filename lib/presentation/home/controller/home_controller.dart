import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/database/app_database.dart';
import 'package:smart_pdf_reader/core/services/file_service.dart';
import 'package:smart_pdf_reader/core/services/external_pdf_service.dart';
import 'package:smart_pdf_reader/core/services/permission_service.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/widgets/permission_dialog.dart';
import 'package:smart_pdf_reader/presentation/viewer/binding/pdf_viewer_binding.dart';
import 'package:smart_pdf_reader/presentation/viewer/screens/pdf_viewer_screen.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomeController extends GetxController {
  final GlobalCoinController globalCoin = Get.find<GlobalCoinController>();

  final RxList<PdfDocument> recentPdfs = <PdfDocument>[].obs;
  final RxList<PdfDocument> favouritePdfs = <PdfDocument>[].obs;
  final RxList<PdfDocument> allPdfs = <PdfDocument>[].obs;

  final RxBool isLoadingAllFiles = false.obs;
  final RxBool isLoadingMoreAllFiles = false.obs;
  final RxString loadError = ''.obs;

  static const int _allFilesBatchSize = 30;
  List<String> _allFilePaths = [];

  /// Guard: device storage is only scanned once per app session.
  bool _allFilesLoaded = false;
  StreamSubscription<ExternalPdfFile>? _externalPdfSubscription;

  final List<String> tabs = const ['Recent', 'Favourites', 'All files'];
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPdfs();
    final initialExternalPdf = ExternalPdfService.instance.initialFile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openExternalPdf(initialExternalPdf);
    });
    _externalPdfSubscription = ExternalPdfService.instance.files.listen(
      _openExternalPdf,
    );
    // Request storage permission on first launch.
    if (initialExternalPdf == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _requestStoragePermission(),
      );
    }
  }

  Future<void> _openExternalPdf(ExternalPdfFile? file) async {
    if (file == null) return;
    final pdf = PdfDocument(
      title: file.name,
      pages: 0,
      currentPage: 0,
      date: 'Opened just now',
      color: Colors.blue.shade100,
      filePath: file.path,
    );
    onPdfSelected(pdf);
  }

  @override
  void onClose() {
    _externalPdfSubscription?.cancel();
    super.onClose();
  }

  void fetchPdfs() {
    recentPdfs.assignAll(AppConstants.recentPdfs);
    favouritePdfs.assignAll(AppConstants.favouritePdfs);
    _refreshRecentFromDb();
    _refreshFavouritesFromDb();
  }

  /// Scans for PDF paths, then loads only the first batch of file metadata.
  Future<void> loadDevicePdfs({bool requestIfNeeded = false}) async {
    if (isLoadingAllFiles.value || isLoadingMoreAllFiles.value) return;
    try {
      isLoadingAllFiles.value = true;
      loadError.value = '';

      var status = await PermissionService.instance.checkStoragePermission();
      if (!status.isGranted) {
        if (requestIfNeeded) {
          await _requestStoragePermission();
          status = await PermissionService.instance.checkStoragePermission();
        }
        if (!status.isGranted) return;
      }

      _allFilePaths = await FileService.instance.scanPdfPaths();
      allPdfs.clear();
      _allFilesLoaded = true;
      await loadMoreAllFiles();
      await _refreshRecentFromDb();
      await _refreshFavouritesFromDb();
    } catch (e) {
      loadError.value = e.toString();
    } finally {
      isLoadingAllFiles.value = false;
    }
  }

  Future<void> loadMoreAllFiles() async {
    if (isLoadingMoreAllFiles.value || allPdfs.length >= _allFilePaths.length) {
      return;
    }

    isLoadingMoreAllFiles.value = true;
    try {
      final files = await FileService.instance.loadPdfDocuments(
        _allFilePaths,
        startIndex: allPdfs.length,
        limit: _allFilesBatchSize,
      );
      if (files.isEmpty) return;

      try {
        await AppDatabase.instance.upsertDocuments(files);
        final progress = await AppDatabase.instance.loadDocumentProgress();
        final favouritePaths = {
          for (final row in await AppDatabase.instance.loadFavouriteDocuments())
            row['file_path'] as String,
        };
        allPdfs.addAll(
          files.map((file) {
            final saved = progress[file.filePath];
            final savedPageCount = saved?['pageCount'] ?? 0;
            return file.copyWith(
              currentPage: saved?['currentPage'],
              pagesRead: saved?['pagesRead'],
              pages: savedPageCount > 0 ? savedPageCount : file.pages,
              isFavourite: favouritePaths.contains(file.filePath),
            );
          }),
        );
      } catch (_) {
        allPdfs.addAll(files);
      }
    } catch (e) {
      loadError.value = e.toString();
    } finally {
      isLoadingMoreAllFiles.value = false;
    }
  }

  bool get hasMoreAllFiles => allPdfs.length < _allFilePaths.length;

  /// Loads recent documents from the DB and updates [recentPdfs].
  /// This is fast (DB-only, no file system scan) and safe to call often.
  Future<void> _refreshRecentFromDb() async {
    try {
      final rows = await AppDatabase.instance.loadRecentDocuments();
      if (rows.isEmpty) return;
      final recents = rows.map((row) {
        return PdfDocument(
          title: row['title'] as String,
          pages: (row['page_count'] as int?) ?? 0,
          currentPage: (row['current_page'] as int?) ?? 0,
          pagesRead: (row['pages_read'] as int?) ?? 0,
          date: (row['modified_at'] as String?) ?? '',
          color: Colors.blue.shade100,
          filePath: row['file_path'] as String?,
          fileSizeBytes: row['file_size_bytes'] as int?,
          isFavourite: (row['is_favourite'] as int?) == 1,
        );
      }).toList();
      AppConstants.recentPdfs
        ..clear()
        ..addAll(recents);
      recentPdfs.assignAll(recents);
    } catch (_) {
      // DB unavailable — keep whatever is in memory.
    }
  }

  Future<void> _refreshFavouritesFromDb() async {
    try {
      final rows = await AppDatabase.instance.loadFavouriteDocuments();
      final favouriteDocs = rows.map((row) {
        return PdfDocument(
          title: row['title'] as String,
          pages: (row['page_count'] as int?) ?? 0,
          currentPage: (row['current_page'] as int?) ?? 0,
          pagesRead: (row['pages_read'] as int?) ?? 0,
          date: (row['modified_at'] as String?) ?? '',
          color: Colors.amber.shade100,
          filePath: row['file_path'] as String?,
          fileSizeBytes: row['file_size_bytes'] as int?,
          isFavourite: true,
        );
      }).toList();

      AppConstants.favouritePdfs
        ..clear()
        ..addAll(favouriteDocs);
      favouritePdfs.assignAll(favouriteDocs);
    } catch (_) {
      // DB unavailable — keep whatever is in memory.
    }
  }

  /// Refreshes reading progress and page count for [allPdfs] from the database
  /// without re-scanning the file system.
  Future<void> _refreshAllFilesProgressFromDb() async {
    try {
      final progress = await AppDatabase.instance.loadDocumentProgress();
      if (allPdfs.isEmpty || progress.isEmpty) return;
      final favouritePaths = {
        for (final row in await AppDatabase.instance.loadFavouriteDocuments())
          row['file_path'] as String,
      };
      allPdfs.assignAll(
        allPdfs.map((file) {
          final saved = progress[file.filePath];
          if (saved == null) return file;
          final savedPageCount = saved['pageCount'] ?? 0;
          return file.copyWith(
            currentPage: saved['currentPage'],
            pagesRead: saved['pagesRead'],
            pages: savedPageCount > 0 ? savedPageCount : file.pages,
            isFavourite: favouritePaths.contains(file.filePath),
          );
        }).toList(),
      );
    } catch (_) {
      // DB unavailable — keep whatever is in memory.
    }
  }

  void changeTab(int index) {
    if (index < 0 || index >= tabs.length) return;
    selectedTabIndex.value = index;
    if (index == 0) {
      _refreshRecentFromDb();
    } else if (index == 1) {
      _refreshFavouritesFromDb();
    } else if (index == 2) {
      if (!_allFilesLoaded && !isLoadingAllFiles.value) {
        loadDevicePdfs(requestIfNeeded: true);
      } else {
        _refreshAllFilesProgressFromDb();
      }
    }
  }

  List<PdfDocument> get currentPdfList {
    switch (selectedTabIndex.value) {
      case 0:
        return recentPdfs;
      case 1:
        return favouritePdfs;
      case 2:
        return allPdfs;
      default:
        return recentPdfs;
    }
  }

  void onSourceAction(String source) {
    switch (source) {
      case 'Local files':
        loadDevicePdfs(requestIfNeeded: true);
        break;
      case 'Scan':
        _requestCameraPermission();
        break;
      default:
        Get.snackbar(
          source,
          'Opening $source importer...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: appTheme.primaryColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
    }
  }

  // ─── Permission helpers ───────────────────────────────────────────────────

  Future<void> _requestStoragePermission() async {
    final context = Get.context;
    if (context == null) return;

    final status = await PermissionService.instance.checkStoragePermission();

    if (status.isGranted) {
      _onStorageGranted();
      return;
    }

    // Permanently denied → show dialog with "Open Settings"
    if (status.isPermanentlyDenied) {
      final openSettings = await PermissionDialog.show(
        context,
        permissions: [PermissionDialog.storagePermission],
        isPermanentlyDenied: true,
      );
      if (openSettings) await PermissionService.instance.openSettings();
      return;
    }

    // Not yet requested or denied → show our rationale dialog first.
    final shouldRequest = await PermissionDialog.show(
      context,
      permissions: [PermissionDialog.storagePermission],
    );

    if (!shouldRequest) return;

    final result = await PermissionService.instance.requestStoragePermission();

    if (result == PermissionStatus.granted) {
      _onStorageGranted();
    } else if (result == PermissionStatus.permanentlyDenied) {
      final openSettings = await PermissionDialog.show(
        context,
        permissions: [PermissionDialog.storagePermission],
        isPermanentlyDenied: true,
      );
      if (openSettings) await PermissionService.instance.openSettings();
    } else {
      Get.snackbar(
        'Permission Denied',
        'Storage access is required to open PDF files.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _requestCameraPermission() async {
    final context = Get.context;
    if (context == null) return;

    final status = await PermissionService.instance.checkCameraPermission();

    if (status.isGranted) {
      _onCameraGranted();
      return;
    }

    if (status.isPermanentlyDenied) {
      final openSettings = await PermissionDialog.show(
        context,
        permissions: [PermissionDialog.cameraPermission],
        isPermanentlyDenied: true,
      );
      if (openSettings) await PermissionService.instance.openSettings();
      return;
    }

    final shouldRequest = await PermissionDialog.show(
      context,
      permissions: [PermissionDialog.cameraPermission],
    );

    if (!shouldRequest) return;

    final result = await PermissionService.instance.requestCameraPermission();

    if (result == PermissionStatus.granted) {
      _onCameraGranted();
    } else if (result == PermissionStatus.permanentlyDenied) {
      final openSettings = await PermissionDialog.show(
        context,
        permissions: [PermissionDialog.cameraPermission],
        isPermanentlyDenied: true,
      );
      if (openSettings) await PermissionService.instance.openSettings();
    } else {
      Get.snackbar(
        'Permission Denied',
        'Camera access is required to scan documents.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _onStorageGranted() {
    Get.snackbar(
      'Access Granted',
      'Open All files to browse PDFs on your device.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _onCameraGranted() {
    Get.snackbar(
      'Camera Ready',
      'You can now scan documents.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void onPdfSelected(PdfDocument pdf) {
    if (pdf.filePath == null) {
      Get.snackbar(
        'File unavailable',
        'This PDF is not available on the device.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    globalCoin.startReadingSession();

    // Update in-memory recent list immediately for instant UI feedback.
    AppConstants.recentPdfs
      ..removeWhere((recentPdf) => recentPdf.filePath == pdf.filePath)
      ..insert(0, pdf);
    recentPdfs.assignAll(AppConstants.recentPdfs);

    // Persist the open timestamp to DB so recents survive app restarts.
    if (pdf.filePath != null) {
      AppDatabase.instance
          .touchDocumentOpened(pdf.filePath!)
          .catchError((_) {});
    }

    // On viewer close: refresh fast DB-based lists (Recent, Favourites, All files)
    // without re-scanning device storage.
    Get.to(
      () => PdfViewerScreen(pdf: pdf),
      binding: PdfViewerBinding(pdf: pdf),
    )?.then((_) async {
      await Future.wait([
        _refreshRecentFromDb(),
        _refreshFavouritesFromDb(),
        _refreshAllFilesProgressFromDb(),
      ]);
    });
  }

  void onPdfMoreOptions(PdfDocument pdf) {
    final bool isFavourite =
        pdf.isFavourite ||
        (pdf.filePath != null &&
            AppConstants.favouritePdfs.any(
              (item) => item.filePath == pdf.filePath,
            ));

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: appTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pdf.title,
                style: textTheme.textStyleRedditSansBold.copyWith(
                  fontSize: 16,
                  color: appTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.share_outlined, color: appTheme.primaryMid),
                title: Text(
                  'Share PDF',
                  style: textTheme.textStyleRedditSansMedium,
                ),
                onTap: () => Get.back(),
              ),
              ListTile(
                leading: Icon(
                  isFavourite ? Icons.star_rounded : Icons.star_outline,
                  color: isFavourite ? Colors.amber : appTheme.primaryMid,
                ),
                title: Text(
                  isFavourite ? 'Remove from favourites' : 'Add to favourites',
                  style: textTheme.textStyleRedditSansMedium,
                ),
                onTap: () async {
                  if (pdf.filePath == null) {
                    Get.back();
                    return;
                  }
                  final newValue = !isFavourite;
                  await AppDatabase.instance.setFavourite(
                    pdf.filePath!,
                    newValue,
                  );
                  if (selectedTabIndex.value == 1) {
                    await _refreshFavouritesFromDb();
                  }
                  if (selectedTabIndex.value == 2) {
                    final updatedList = allPdfs.map((doc) {
                      if (doc.filePath == pdf.filePath) {
                        return doc.copyWith(isFavourite: newValue);
                      }
                      return doc;
                    }).toList();
                    allPdfs.assignAll(updatedList);
                  }
                  Get.back();
                  await _refreshFavouritesFromDb();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  'Remove from list',
                  style: textTheme.textStyleRedditSansMedium.copyWith(
                    color: Colors.red,
                  ),
                ),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void onSearchTapped() {
    Get.snackbar(
      'Search',
      'Search documents...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  void onNotificationTapped() {
    Get.snackbar(
      'Notifications',
      'No new notifications',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }
}
