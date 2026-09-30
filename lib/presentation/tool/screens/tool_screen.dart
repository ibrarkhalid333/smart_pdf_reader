import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/tool/controller/tool_controller.dart';
import 'package:smart_pdf_reader/presentation/tool/widgets/locked_tools_card_widget.dart';
import 'package:smart_pdf_reader/presentation/tool/widgets/tool_card_widget.dart';
import 'package:smart_pdf_reader/presentation/tool/widgets/tool_header_coin_pill.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ToolScreen extends GetWidget<ToolController> {
  const ToolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.screenBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(125.v),
        child: AppBar(
          backgroundColor: appTheme.primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 125.v,
          titleSpacing: 20.h,
          title: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: 8.v, bottom: 8.v),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tools',
                          style: textTheme.textStyleRedditSansBold.copyWith(
                            fontSize: 24.fSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.v),
                        Text(
                          'Tap a tool to use it on any PDF',
                          style: textTheme.textStyleRedditSansRegular.copyWith(
                            fontSize: 13.fSize,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ToolHeaderCoinPill(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header: YOUR TOOLS
              Text(
                'YOUR TOOLS',
                style: textTheme.textStyleRedditSansSemiBold.copyWith(
                  fontSize: 12.fSize,
                  color: appTheme.textMutedColor,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 12.v),

              // Available Tools Grid
              Obx(() {
                final tools = controller.availableTools;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.v,
                    crossAxisSpacing: 12.h,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return ToolCardWidget(
                      tool: tool,
                      status: controller.getToolStatus(tool),
                      onTap: () => controller.onAvailableToolTapped(tool),
                    );
                  },
                );
              }),

              SizedBox(height: 18.v),

              // Bottom Section: More tools available card
              const LockedToolsCardWidget(),

              SizedBox(height: 16.v),
            ],
          ),
        ),
      ),
    );
  }
}
