import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportHelper {
  static Future<String> saveFile(List<int> bytes, String fileName) async {
    // 1. Get Downloads Directory manually for Android to ensure visibility
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory = await getExternalStorageDirectory(); // Fallback
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception("Could not access storage directory");
    }

    // 2. Conflict Handling (Duplicate with suffix)
    String filePath = '${directory.path}/$fileName';
    File file = File(filePath);
    
    // Parse name and extension
    String nameWithoutExt = fileName;
    String ext = "";
    if (fileName.contains('.')) {
      nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
      ext = fileName.substring(fileName.lastIndexOf('.'));
    }
    
    // Check for duplicates
    int counter = 1;
    while (file.existsSync()) {
      filePath = '${directory.path}/$nameWithoutExt ($counter)$ext';
      file = File(filePath);
      counter++;
    }

    // 3. Write File
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
