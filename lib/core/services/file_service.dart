import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/services/pdf_thumbnail_service.dart';

/// Scans the device storage for PDFs and converts them to [PdfDocument].
class FileService {
  FileService._();
  static final FileService instance = FileService._();

  // Directories to skip during scanning (system / noisy folders).
  static const _skipDirs = {
    'Android',
    'data',
    'obb',
    '.thumbnails',
    '.trash',
    'LOST.DIR',
    'cache',
  };

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Returns all PDF files found on the device storage.
  /// Runs the heavy file-system scan in a background isolate via [compute].
  Future<List<PdfDocument>> loadAllPdfs() async {
    final paths = await scanPdfPaths();
    return loadPdfDocuments(paths);
  }

  /// Scans storage and returns PDF paths without opening each document.
  Future<List<String>> scanPdfPaths() async {
    final roots = await _getSearchRoots();
    if (roots.isEmpty) return [];

    // Run the recursive scan off the main thread.
    return compute(_scanDirectories, roots);
  }

  /// Loads metadata for a window of already-discovered PDF paths.
  Future<List<PdfDocument>> loadPdfDocuments(
    List<String> paths, {
    int startIndex = 0,
    int? limit,
  }) {
    return _toPdfDocuments(paths, startIndex: startIndex, limit: limit);
  }

  // ─── Search roots ─────────────────────────────────────────────────────────

  Future<List<String>> _getSearchRoots() async {
    final roots = <String>{};

    if (Platform.isAndroid) {
      // Primary internal shared storage
      final standardRoot = Directory('/storage/emulated/0');
      if (standardRoot.existsSync()) {
        roots.add(standardRoot.path);
      }

      // Removable SD cards in /storage
      try {
        final storageDir = Directory('/storage');
        if (storageDir.existsSync()) {
          for (final entity in storageDir.listSync()) {
            if (entity is Directory) {
              final name = entity.path.split(Platform.pathSeparator).last;
              if (name != 'self' &&
                  name != 'emulated' &&
                  !name.startsWith('.')) {
                roots.add(entity.path);
              }
            }
          }
        }
      } catch (_) {}
    }

    try {
      // Primary external storage
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        Directory dir = ext;
        for (int i = 0; i < 4; i++) {
          final parent = dir.parent;
          if (parent.path == dir.path) break;
          dir = parent;
        }
        roots.add(dir.path);
      }
    } catch (_) {}

    try {
      final externalDirs = await getExternalStorageDirectories() ?? [];
      for (final d in externalDirs) {
        Directory dir = d;
        for (int i = 0; i < 4; i++) {
          final parent = dir.parent;
          if (parent.path == dir.path) break;
          dir = parent;
        }
        roots.add(dir.path);
      }
    } catch (_) {}

    // Fallback for non-Android platforms (desktop/test).
    if (roots.isEmpty) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        roots.add(docs.path);
      } catch (_) {}
    }

    return roots.toList();
  }

  // ─── Background scan (runs in isolate — no Flutter engine access) ─────────

  static List<String> _scanDirectories(List<String> roots) {
    final resultSet = <String>{};
    for (final root in roots) {
      _scanDir(Directory(root), resultSet, depth: 0);
    }
    final results = resultSet.toList();
    // Sort: most recently modified first.
    results.sort((a, b) {
      try {
        final aTime = File(a).statSync().modified;
        final bTime = File(b).statSync().modified;
        return bTime.compareTo(aTime);
      } catch (_) {
        return 0;
      }
    });
    return results;
  }

  static void _scanDir(Directory dir, Set<String> results, {int depth = 0}) {
    if (depth > 8) return; // prevent runaway recursion
    try {
      final entries = dir.listSync(followLinks: false);
      for (final entry in entries) {
        final name = entry.path.split(Platform.pathSeparator).last;
        if (entry is Directory) {
          if (_skipDirs.contains(name) || name.startsWith('.')) continue;
          _scanDir(entry, results, depth: depth + 1);
        } else if (entry is File) {
          if (name.toLowerCase().endsWith('.pdf')) {
            results.add(entry.path);
          }
        }
      }
    } catch (_) {
      // Permission denied or IO error — skip this directory silently.
    }
  }

  // ─── Map File → PdfDocument ───────────────────────────────────────────────

  Future<List<PdfDocument>> _toPdfDocuments(
    List<String> paths, {
    int startIndex = 0,
    int? limit,
  }) async {
    final colors = [
      Colors.blue.shade100,
      Colors.purple.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
      Colors.indigo.shade100,
    ];

    final documents = <PdfDocument>[];
    final firstIndex = startIndex.clamp(0, paths.length).toInt();
    final lastIndex = limit == null
        ? paths.length
        : (firstIndex + limit).clamp(firstIndex, paths.length).toInt();
    for (var i = firstIndex; i < lastIndex; i++) {
      final path = paths[i];
      final file = File(path);
      final stat = file.statSync();

      final name = path.split(Platform.pathSeparator).last;
      final sizeBytes = stat.size;
      final modified = stat.modified;
      final dateLabel = _formatDate(modified);

      documents.add(
        PdfDocument(
          title: name,
          filePath: path,
          pages: await PdfThumbnailService.instance.pageCount(path),
          currentPage: 0,
          date: dateLabel,
          color: colors[i % colors.length],
          fileSizeBytes: sizeBytes,
        ),
      );
    }
    return documents;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today $h:$m';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} week${diff.inDays < 14 ? '' : 's'} ago';
    } else {
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    }
  }
}
