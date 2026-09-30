import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/store/controller/store_controller.dart';

class StoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StoreController());
  }
}