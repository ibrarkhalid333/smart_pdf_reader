import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/base/controller/base_controller.dart';

class BaseBindings extends Bindings {
   @override
  void dependencies() {
    Get.lazyPut(() => BaseController());
  }
}  