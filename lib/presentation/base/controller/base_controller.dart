import 'package:get/get.dart';

class BaseController extends GetxController {
  @override
  void onInit() {
    
    // TODO: implement onInit
    super.onInit();

  }

  var curruntIndex = 0.obs;

  void changeIndex(int newIndex) {
    curruntIndex.value = newIndex;
  }
}
