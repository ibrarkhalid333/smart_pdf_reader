import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

/// Describes a single permission row shown inside [PermissionDialog].
class PermissionItem {
  final IconData icon;
  final String title;
  final String description;

  const PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Android-style permission rationale dialog.
///
/// Shows a branded card with a list of required permissions, each with an icon,
/// title, and short rationale. Provides "Allow" and "Deny" actions.
///
/// Usage:
/// ```dart
/// final granted = await PermissionDialog.show(
///   context,
///   permissions: [PermissionDialog.storagePermission],
/// );
/// ```
class PermissionDialog extends StatelessWidget {
  final String appName;
  final List<PermissionItem> permissions;
  final bool isPermanentlyDenied;

  const PermissionDialog({
    super.key,
    required this.appName,
    required this.permissions,
    this.isPermanentlyDenied = false,
  });

  // ─── Pre-built common permission items ────────────────────────────────────

  static const PermissionItem storagePermission = PermissionItem(
    icon: Icons.folder_outlined,
    title: 'Files & Media',
    description:
        'Required to open, read and manage PDF documents stored on your device.',
  );

  static const PermissionItem cameraPermission = PermissionItem(
    icon: Icons.camera_alt_outlined,
    title: 'Camera',
    description:
        'Required to scan physical documents and convert them to PDF.',
  );

  // ─── Static helper to show the dialog ─────────────────────────────────────

  /// Returns `true` if the user tapped Allow / Open Settings, `false` if Deny.
  static Future<bool> show(
    BuildContext context, {
    String appName = 'Smart PDF Reader',
    required List<PermissionItem> permissions,
    bool isPermanentlyDenied = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => PermissionDialog(
        appName: appName,
        permissions: permissions,
        isPermanentlyDenied: isPermanentlyDenied,
      ),
    );
    return result ?? false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.v),
      child: SizedBox(
        width: double.infinity,
        child: _DialogCard(
          appName: appName,
          permissions: permissions,
          isPermanentlyDenied: isPermanentlyDenied,
        ),
      ),
    );
  }
}

// ─── Internal card widget ─────────────────────────────────────────────────────

class _DialogCard extends StatelessWidget {
  final String appName;
  final List<PermissionItem> permissions;
  final bool isPermanentlyDenied;

  const _DialogCard({
    required this.appName,
    required this.permissions,
    required this.isPermanentlyDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appTheme.warmWhite,
        borderRadius: BorderRadius.circular(20.adaptSize),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.adaptSize),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header gradient ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 24.h,
                vertical: 22.v,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    appTheme.primaryColor,
                    appTheme.primaryPale,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App icon placeholder
                  Container(
                    width: 48.adaptSize,
                    height: 48.adaptSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14.adaptSize),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 28.fSize,
                    ),
                  ),
                  SizedBox(height: 12.v),
                  Text(
                    '$appName wants to access',
                    style: textTheme.textStyleRedditSansBold.copyWith(
                      fontSize: 17.fSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.v),
                  Text(
                    isPermanentlyDenied
                        ? 'You have permanently denied a permission. Please allow it from App Settings.'
                        : 'The following permissions are needed to provide you the full experience.',
                    style: textTheme.textStyleRedditSansRegular.copyWith(
                      fontSize: 12.fSize,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // ── Permission list ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 16.v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...permissions.map((p) => _PermissionRow(item: p)),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────
            Divider(height: 1, color: appTheme.borderDefault),

            // ── Action buttons ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.h,
                vertical: 14.v,
              ),
              child: Row(
                children: [
                  // Deny / Not Now
                  Expanded(
                    child: _OutlineButton(
                      label: 'Not Now',
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  SizedBox(width: 12.h),
                  // Allow / Open Settings
                  Expanded(
                    flex: 2,
                    child: _PrimaryButton(
                      label: isPermanentlyDenied ? 'Open Settings' : 'Allow',
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission row ───────────────────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final PermissionItem item;
  const _PermissionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.adaptSize,
            height: 40.adaptSize,
            decoration: BoxDecoration(
              color: appTheme.tealTintBackground,
              borderRadius: BorderRadius.circular(10.adaptSize),
            ),
            child: Icon(
              item.icon,
              color: appTheme.primaryMid,
              size: 20.fSize,
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.textStyleRedditSansSemiBold.copyWith(
                    fontSize: 13.fSize,
                    color: appTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 2.v),
                Text(
                  item.description,
                  style: textTheme.textStyleRedditSansRegular.copyWith(
                    fontSize: 11.5.fSize,
                    color: appTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Buttons ──────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.v),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [appTheme.primaryColor, appTheme.primaryPale],
          ),
          borderRadius: BorderRadius.circular(12.adaptSize),
          boxShadow: [
            BoxShadow(
              color: appTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.textStyleRedditSansBold.copyWith(
            fontSize: 13.fSize,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.v),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(
            color: appTheme.borderDefault,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textTheme.textStyleRedditSansMedium.copyWith(
            fontSize: 13.fSize,
            color: appTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
