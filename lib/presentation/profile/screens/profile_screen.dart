import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/models/reader_theme.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/reader_appearance_controller.dart';
import 'package:smart_pdf_reader/presentation/profile/controller/profile_controller.dart';
import 'package:smart_pdf_reader/presentation/widgets/coin_balance_pill.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ProfileScreen extends GetWidget<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<GlobalCoinController>();
    final appearanceController = Get.find<ReaderAppearanceController>();
    return Scaffold(
      backgroundColor: appTheme.screenBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Dark Green Header (extends under status bar) ───
            Container(
              width: double.infinity,
              color: appTheme.primaryColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16.v,
                bottom: 28.v,
                left: 20.h,
                right: 20.h,
              ),
              child: Column(
                children: [
                  Row(mainAxisAlignment: .end, children: [CoinBalancePill()]),
                  SizedBox(height: 8.v),
                  // Avatar with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: appTheme.primaryLight,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Text(
                        'AX',
                        style: textTheme.textStyleRedditSansBold.copyWith(
                          fontSize: 24.fSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.v),
                  // Name
                  Obx(
                    () => Text(
                      controller.userName.value,
                      style: textTheme.textStyleRedditSansSemiBold.copyWith(
                        fontSize: 20.fSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.v),
                  // Member since + streak
                  Obx(
                    () => Text(
                      'Member since ${controller.memberSince.value} · ${controller.streakDays}-day streak 🔥',
                      style: textTheme.textStyleRedditSansRegular.copyWith(
                        fontSize: 13.fSize,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.v),
                  // Stats row with vertical dividers
                  Row(
                    mainAxisAlignment: .spaceEvenly,
                    children: [
                      _buildStatColumn('${controller.pdfsRead}', 'PDFs read'),
                      Container(
                        width: 1,
                        height: 40.v,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildStatColumn('${controller.pagesRead}', 'pages read'),
                      Container(
                        width: 1,
                        height: 40.v,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildStatColumn(
                        '${controller.readingTimeHours}h',
                        'reading time',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Scrollable Content ───
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 20.v),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    // Achievements header
                    Row(
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        Text(
                          'ACHIEVEMENTS',
                          style: textTheme.textStyleRedditSansSemiBold.copyWith(
                            fontSize: 12.fSize,
                            color: appTheme.textMutedColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'See all',
                          style: textTheme.textStyleRedditSansSemiBold.copyWith(
                            fontSize: 13.fSize,
                            color: appTheme.primaryMid,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.v),

                    // Achievements Grid
                    Obx(() {
                      final achievements =
                          Get.find<GlobalCoinController>().achievements;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 7,
                        crossAxisSpacing: 7,
                        childAspectRatio: 0.70,
                        children: controller.achievementItems.map((item) {
                          final isUnlocked = achievements.any(
                            (a) => a.achievementId == item.id && a.isCompleted,
                          );
                          return _buildAchievementCard(
                            icon: item.icon,
                            title: item.title,
                            reward: item.reward,
                            isUnlocked: isUnlocked,
                          );
                        }).toList(),
                      );
                    }),
                    SizedBox(height: 28.v),
                    // Settings header
                    Text(
                      'SETTINGS',
                      style: textTheme.textStyleRedditSansSemiBold.copyWith(
                        fontSize: 12.fSize,
                        color: appTheme.textMutedColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16.v),

                    // Settings tiles
                    _buildSettingTile(
                      icon: Icons.palette_outlined,
                      title: 'Reading theme',
                      onTap: () =>
                          _showReadingThemePicker(appearanceController),
                      trailing: Obx(
                        () => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appearanceController.theme.value.label,
                              style: textTheme.textStyleRedditSansMedium
                                  .copyWith(
                                    fontSize: 13.fSize,
                                    color: appTheme.textSecondaryColor,
                                  ),
                            ),
                            SizedBox(width: 4.h),
                            Icon(
                              Icons.chevron_right,
                              color: appTheme.textMutedColor,
                              size: 20.fSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      icon: Icons.notifications_outlined,
                      title: 'Daily reading reminder',
                      trailing: Switch(
                        value: true,
                        onChanged: (_) {},
                        activeColor: appTheme.primaryColor,
                        activeTrackColor: appTheme.primaryColor.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy and data',
                    ),
                    _buildSettingTile(
                      icon: Icons.help_outline,
                      title: 'Help and support',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: textTheme.textStyleRedditSansBold.copyWith(
            fontSize: 22.fSize,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4.v),
        Text(
          label,
          style: textTheme.textStyleRedditSansRegular.copyWith(
            fontSize: 12.fSize,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard({
    required IconData icon,
    required String title,
    required int reward,
    required bool isUnlocked,
  }) {
    return Container(
      padding: EdgeInsets.all(8.h),
      decoration: BoxDecoration(
        color: appTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? appTheme.tealTintBackground
                  : appTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isUnlocked
                  ? appTheme.primaryMid
                  : appTheme.lockedIconColor,
              size: 24.fSize,
            ),
          ),
          SizedBox(height: 10.v),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.textStyleRedditSansMedium.copyWith(
              fontSize: 12.fSize,
              color: isUnlocked
                  ? appTheme.textPrimaryColor
                  : appTheme.lockedIconColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.v),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monetization_on,
                size: 12,
                color: isUnlocked
                    ? appTheme.coinGold
                    : appTheme.lockedIconColor,
              ),
              SizedBox(width: 2.h),
              Text(
                '+$reward',
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 12.fSize,
                  color: isUnlocked
                      ? appTheme.coinGold
                      : appTheme.lockedIconColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.v),
        padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 14.v),
        decoration: BoxDecoration(
          color: appTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: appTheme.primaryColor, size: 22.fSize),
            SizedBox(width: 14.h),
            Expanded(
              child: Text(
                title,
                style: textTheme.textStyleRedditSansMedium.copyWith(
                  fontSize: 15.fSize,
                  color: appTheme.textPrimaryColor,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: appTheme.textMutedColor,
                  size: 20.fSize,
                ),
          ],
        ),
      ),
    );
  }

  void _showReadingThemePicker(
    ReaderAppearanceController appearanceController,
  ) {
    Get.bottomSheet(
      SafeArea(
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'PDF reading theme',
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 17.fSize,
                  color: appTheme.textPrimaryColor,
                ),
              ),
              for (final theme in ReaderTheme.values)
                ListTile(
                  leading: Icon(
                    theme == ReaderTheme.dark
                        ? Icons.dark_mode_outlined
                        : theme == ReaderTheme.sepia
                        ? Icons.filter_vintage_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(theme.label),
                  trailing: appearanceController.theme.value == theme
                      ? Icon(Icons.check, color: appTheme.primaryColor)
                      : null,
                  onTap: () async {
                    await appearanceController.setTheme(theme);
                    Get.back();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      backgroundColor: appTheme.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }
}
