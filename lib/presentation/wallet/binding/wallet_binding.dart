import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/wallet/controller/wallet_controller.dart';

class WalletBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut(() => WalletController());
  }
}