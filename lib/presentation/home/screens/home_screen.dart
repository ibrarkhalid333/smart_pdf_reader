import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/home/controller/home_controller.dart';
import 'package:smart_pdf_reader/presentation/home/widgets/home_header_coin_pill.dart';
import 'package:smart_pdf_reader/presentation/home/widgets/home_pdf_card_widget.dart';
import 'package:smart_pdf_reader/presentation/home/widgets/home_source_actions_widget.dart';
import 'package:smart_pdf_reader/presentation/home/widgets/home_streak_card_widget.dart';
import 'package:smart_pdf_reader/presentation/home/widgets/home_tab_bar_widget.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class HomeScreen extends GetWidget<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.screenBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(115.v),
        child: AppBar(
          backgroundColor: appTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 115.v,
          titleSpacing: 20.h,
          title: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: 6.v, bottom: 8.v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Status Pill Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [HomeHeaderCoinPill()],
                  ),
                  SizedBox(height: 6.v),

                  // Brand Title & Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PageCoin',
                        style: textTheme.textStyleRedditSansBold.copyWith(
                          fontSize: 24.fSize,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: controller.onSearchTapped,
                            child: Icon(
                              Icons.search,
                              size: 24.fSize,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 14.h),
                          GestureDetector(
                            onTap: controller.onNotificationTapped,
                            child: Icon(
                              Icons.notifications_none_outlined,
                              size: 24.fSize,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: appTheme.primaryColor,
          onRefresh: () => controller.loadDevicePdfs(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Source Action Buttons (Local files, Cloud, URL, Scan)
                HomeSourceActionsWidget(
                  onSourceSelected: controller.onSourceAction,
                ),

                SizedBox(height: 14.v),

                // 2. Streak Status Banner
                const HomeStreakCardWidget(),

                SizedBox(height: 16.v),

                // 3. Tab Bar (Recent, Favourites, All files)
                Obx(
                  () => HomeTabBarWidget(
                    tabs: controller.tabs,
                    selectedIndex: controller.selectedTabIndex.value,
                    onTabSelected: controller.changeTab,
                  ),
                ),

                SizedBox(height: 14.v),

                // 4. PDF Documents List
                Obx(() {
                  if (controller.selectedTabIndex.value == 2 &&
                      controller.isLoadingAllFiles.value) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.v),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 36.adaptSize,
                              height: 36.adaptSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  appTheme.primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 14.v),
                            Text(
                              'Scanning device for PDF files...',
                              style: textTheme.textStyleRedditSansMedium
                                  .copyWith(
                                    color: appTheme.textMutedColor,
                                    fontSize: 14.fSize,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final pdfList = controller.currentPdfList;

                  if (pdfList.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.v),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 48.fSize,
                              color: appTheme.textMutedColor,
                            ),
                            SizedBox(height: 8.v),
                            Text(
                              controller.selectedTabIndex.value == 2
                                  ? 'No PDF documents found'
                                  : 'No documents found',
                              style: textTheme.textStyleRedditSansMedium
                                  .copyWith(
                                    color: appTheme.textMutedColor,
                                    fontSize: 14.fSize,
                                  ),
                            ),
                            if (controller.selectedTabIndex.value == 2) ...[
                              SizedBox(height: 12.v),
                              TextButton.icon(
                                onPressed: () => controller.loadDevicePdfs(
                                  requestIfNeeded: true,
                                ),
                                icon: Icon(
                                  Icons.refresh,
                                  color: appTheme.primaryMid,
                                  size: 18.fSize,
                                ),
                                label: Text(
                                  'Scan Again',
                                  style: textTheme.textStyleRedditSansSemiBold
                                      .copyWith(
                                        color: appTheme.primaryMid,
                                        fontSize: 13.fSize,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pdfList.length,
                    itemBuilder: (context, index) {
                      final pdf = pdfList[index];
                      return HomePdfCardWidget(
                        pdf: pdf,
                        onTap: () => controller.onPdfSelected(pdf),
                        onMoreTap: () => controller.onPdfMoreOptions(pdf),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
