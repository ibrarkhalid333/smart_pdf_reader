import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/tool/controller/tool_controller.dart';

class ToolBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ToolController());
  }
}
