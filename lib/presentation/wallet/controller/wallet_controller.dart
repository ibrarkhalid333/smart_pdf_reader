import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';

class WalletController extends GetxController{
  var earnTasks = <EarnTask>[].obs;
    @override
  void onInit() {
    super.onInit();
    fetchEarnTasks();
  }

  void fetchEarnTasks() {
    earnTasks.assignAll(AppConstants.earnTasks);
  }

  void watchAd() {
    // Mock logic for watching ad
    Get.find<GlobalCoinController>().earnCoins(5);
    Get.snackbar('Reward Earned', 'You earned 5 coins!');
  }
}