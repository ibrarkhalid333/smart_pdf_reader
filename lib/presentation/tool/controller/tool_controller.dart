import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/models/tool_model.dart';
import 'package:smart_pdf_reader/presentation/base/controller/base_controller.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class ToolController extends GetxController {
  final GlobalCoinController globalCoin = Get.find<GlobalCoinController>();
  final ScrollController lockedScrollController = ScrollController();
  final RxDouble scrollProgress = 0.0.obs;

  List<ToolModel> get allTools => AppConstants.allTools;

  @override
  void onInit() {
    super.onInit();
    lockedScrollController.addListener(_updateScrollProgress);
  }

  @override
  void onClose() {
    lockedScrollController.removeListener(_updateScrollProgress);
    lockedScrollController.dispose();
    super.onClose();
  }

  void _updateScrollProgress() {
    if (!lockedScrollController.hasClients) return;
    final maxScroll = lockedScrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      scrollProgress.value = 0.0;
    } else {
      scrollProgress.value =
          (lockedScrollController.offset / maxScroll).clamp(0.0, 1.0);
    }
  }

  void scrollLeft() {
    if (!lockedScrollController.hasClients) return;
    final target = (lockedScrollController.offset - 140).clamp(
      0.0,
      lockedScrollController.position.maxScrollExtent,
    );
    lockedScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void scrollRight() {
    if (!lockedScrollController.hasClients) return;
    final target = (lockedScrollController.offset + 140).clamp(
      0.0,
      lockedScrollController.position.maxScrollExtent,
    );
    lockedScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool isToolUnlocked(ToolModel tool) {
    if (tool.isFree) return true;
    final featureId = tool.shopItemId ?? tool.id;
    return globalCoin.isFeatureUnlocked(featureId);
  }

  String getToolStatus(ToolModel tool) {
    if (tool.isFree) return 'Free';
    final featureId = tool.shopItemId ?? tool.id;
    if (featureId.contains('screenshot')) {
      final uses = globalCoin.getUsesRemaining(featureId);
      if (uses > 0) return '$uses uses left';
    }
    if (globalCoin.isFeatureUnlocked(featureId)) {
      return 'Owned';
    }
    return 'Locked';
  }

  List<ToolModel> get availableTools {
    return allTools.where((tool) => isToolUnlocked(tool)).toList();
  }

  List<ToolModel> get lockedTools {
    return allTools.where((tool) => !isToolUnlocked(tool)).toList();
  }

  void openStore() {
    if (Get.isRegistered<BaseController>()) {
      Get.find<BaseController>().changeIndex(2);
    }
  }

  ShopItem? getShopItemForTool(ToolModel tool) {
    final searchId = tool.shopItemId ?? tool.id;
    return AppConstants.shopItems.firstWhereOrNull(
      (item) => item.id == searchId,
    );
  }

  Future<bool> purchaseTool(ShopItem item) async {
    final UnlockType type;
    if (item.isPermanent) {
      type = UnlockType.permanent;
    } else if (item.id.contains('month')) {
      type = UnlockType.monthly;
    } else {
      type = UnlockType.perUsePack;
    }

    final usesPerPack = item.id == 'area_screenshot_5' ? 5 : 0;

    return await globalCoin.purchaseFeature(
      featureId: item.id,
      cost: item.cost,
      type: type,
      usesPerPack: usesPerPack,
    );
  }

  void onAvailableToolTapped(ToolModel tool) {
    Get.snackbar(
      '${tool.name} Ready',
      'Open a document from Home to use ${tool.name}.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: appTheme.primaryColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}