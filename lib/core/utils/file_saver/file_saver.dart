import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart' as impl;

Future<void> saveAndDownloadFile(Uint8List bytes, String fileName) async {
  await impl.saveAndDownloadFile(bytes, fileName);
}
