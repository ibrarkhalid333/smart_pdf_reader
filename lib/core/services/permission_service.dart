import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralised service for all runtime permission requests.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  // Cache the SDK int so we only query once per app session.
  int? _androidSdkVersion;

  // ─── Storage ─────────────────────────────────────────────────────────────

  /// Returns the current storage permission status (API-level aware).
  Future<PermissionStatus> checkStoragePermission() async {
    final sdk = await _fetchAndroidSdk();
    if (sdk >= 30) {
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return PermissionStatus.granted;
      // Also check standard storage permission as fallback
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return PermissionStatus.granted;
      return manageStatus;
    }
    return Permission.storage.status;
  }

  Future<PermissionStatus> requestStoragePermission() async {
    final sdk = await _fetchAndroidSdk();
    if (sdk >= 30) {
      // API 30+: Request All Files Access
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return PermissionStatus.granted;
      // Fallback: also try storage request
      return await Permission.storage.request();
    }
    // API ≤ 29: single READ_EXTERNAL_STORAGE permission.
    return Permission.storage.request();
  }

  // ─── Camera ──────────────────────────────────────────────────────────────

  Future<PermissionStatus> checkCameraPermission() =>
      Permission.camera.status;

  Future<PermissionStatus> requestCameraPermission() =>
      Permission.camera.request();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Future<bool> openSettings() => openAppSettings();



  Future<int> _fetchAndroidSdk() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return 0; // Fallback: treat as old Android → use storage permission.
    }
  }
}
