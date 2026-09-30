import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';

class StoreController extends GetxController {
  // Reactive list of shop items
  // var shopItems = <ShopItem>[].obs;
  final RxList<ShopItem> shopItems = <ShopItem>[].obs;

  // To keep track of what user has unlocked (Mock for now)
  var unlockedItems = <String>[].obs;
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    fetchShopItems();
  }
// Fetch data from AppConstants
  void fetchShopItems() {
    shopItems.assignAll(AppConstants.shopItems);
  }

  // Group items by tier for the UI
  List<ShopItem> getItemsByTier(String tier) {
    return shopItems.where((item) => item.tier == tier).toList();
  }

  // Check if a feature is already unlocked
  bool isItemUnlocked(String itemId) {
    return Get.find<GlobalCoinController>().isFeatureUnlocked(itemId);
  }

  // Get remaining uses for per-use pack features
  int getUsesRemaining(String itemId) {
    return Get.find<GlobalCoinController>().getUsesRemaining(itemId);
  }

  /// Handle purchase — returns true if successful
  Future<bool> purchaseItem(ShopItem item) async {
    final UnlockType type;
    if (item.isPermanent) {
      type = UnlockType.permanent;
    } else if (item.id.contains('month')) {
      type = UnlockType.monthly;
    } else {
      type = UnlockType.perUsePack;
    }

    final usesPerPack = item.id == 'area_screenshot_5' ? 5 : 0;

    return await Get.find<GlobalCoinController>().purchaseFeature(
      featureId: item.id,
      cost: item.cost,
      type: type,
      usesPerPack: usesPerPack,
    );
  }
}
