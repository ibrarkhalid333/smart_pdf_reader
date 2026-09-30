import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ExternalPdfFile {
  final String path;
  final String name;

  const ExternalPdfFile({required this.path, required this.name});
}

class ExternalPdfService {
  ExternalPdfService._();

  static final instance = ExternalPdfService._();

  static const _methodChannel = MethodChannel('smart_pdf_reader/external_pdf');
  static const _eventChannel = EventChannel(
    'smart_pdf_reader/external_pdf_events',
  );

  final _filesController = StreamController<ExternalPdfFile>.broadcast();
  StreamSubscription<Object?>? _subscription;
  ExternalPdfFile? initialFile;
  bool _initialized = false;

  Stream<ExternalPdfFile> get files => _filesController.stream;

  Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _initialized = true;

    final initial = await _methodChannel.invokeMethod<Object?>('getInitialPdf');
    initialFile = _parseFile(initial);
    _subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final file = _parseFile(event);
      if (file != null) _filesController.add(file);
    });
  }

  ExternalPdfFile? _parseFile(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    final name = value['name'];
    if (path is! String || name is! String || path.isEmpty) return null;
    return ExternalPdfFile(path: path, name: name);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _filesController.close();
  }
}
