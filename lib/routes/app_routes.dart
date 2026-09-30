import 'package:get/get.dart';
import 'package:smart_pdf_reader/presentation/base/binding/base_bindings.dart';
import 'package:smart_pdf_reader/presentation/base/screen/base_screen.dart';
import 'package:smart_pdf_reader/presentation/home/binding/home_binding.dart';
import 'package:smart_pdf_reader/presentation/profile/binding/profile_binding.dart';
import 'package:smart_pdf_reader/presentation/store/binding/store_binding.dart';
import 'package:smart_pdf_reader/presentation/tool/binding/tool_binding.dart';
import 'package:smart_pdf_reader/presentation/wallet/binding/wallet_binding.dart';

class AppRoutes {
  static const String initialRoute = '/';
  static const String base = '/base';

  static List<GetPage> pages = [
    GetPage(
      name: initialRoute,
      page: () => BaseScreen(),
      bindings: [
        BaseBindings(),
        HomeBinding(),
        StoreBinding(),
        WalletBinding(),
        ProfileBinding(),
        ToolBinding()
      ],
    ),
  ];
}
