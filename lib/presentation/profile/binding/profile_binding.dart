import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/profile/controller/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController());
  }
}