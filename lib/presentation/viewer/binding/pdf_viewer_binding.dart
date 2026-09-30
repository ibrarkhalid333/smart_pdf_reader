import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/presentation/viewer/controller/pdf_viewer_controller.dart';

class PdfViewerBinding extends Bindings {
  final PdfDocument pdf;

  PdfViewerBinding({required this.pdf});

  String get controllerTag => pdf.filePath ?? pdf.title;

  @override
  void dependencies() {
    Get.lazyPut<PdfViewerController>(
      () => PdfViewerController(pdf: pdf),
      tag: controllerTag,
    );
  }
}
