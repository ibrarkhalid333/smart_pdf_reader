import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/database/app_database.dart';
import 'package:smart_pdf_reader/core/services/external_pdf_service.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/reader_appearance_controller.dart';
import 'package:smart_pdf_reader/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ExternalPdfService.instance.initialize();
  final readerAppearanceController = ReaderAppearanceController();
  await readerAppearanceController.load();
  Get.put(readerAppearanceController, permanent: true);
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    await AppDatabase.instance.database;
  }
  Get.lazyPut(() => GlobalCoinController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Smart PDF Reader',
      initialRoute: AppRoutes.initialRoute,
      getPages: AppRoutes.pages,
      builder: (context, child) {
        onBuildContext(context);
        return child ?? const SizedBox();
      },
    );
  }
}
