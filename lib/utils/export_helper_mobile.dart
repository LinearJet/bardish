import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportHelper {
  static Future<String> saveFile(List<int> bytes, String fileName) async {
    Directory? directory;
    
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory(); 
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception("Storage directory not available");
    }

    String nameWithoutExt = fileName;
    String ext = "";
    if (fileName.contains('.')) {
      nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      ext = fileName.substring(fileName.lastIndexOf('.'));
    }

    String filePath = '${directory.path}/$fileName';
    File file = File(filePath);
    int counter = 1;

    while (await file.exists()) {
      filePath = '${directory.path}/$nameWithoutExt ($counter)$ext';
      file = File(filePath);
      counter++;
    }

    await file.writeAsBytes(bytes);
    return filePath;
  }

  static Future<void> shareFile(List<int> bytes, String fileName, String mimeType) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(path, mimeType: mimeType)],
      subject: fileName,
    );
  }

  static void downloadForWeb(List<int> bytes, String fileName, String mimeType) {
    throw UnsupportedError('downloadForWeb is only supported on web');
  }
}
