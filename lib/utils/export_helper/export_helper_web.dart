// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExportHelper {
  static Future<String> saveFile(List<int> bytes, String fileName) async {
    downloadForWeb(bytes, fileName, 'application/octet-stream');
    return fileName;
  }

  static Future<void> shareFile(List<int> bytes, String fileName, String mimeType) async {
    downloadForWeb(bytes, fileName, mimeType);
  }

  static void downloadForWeb(List<int> bytes, String fileName, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    
    html.document.body!.children.add(anchor);
    anchor.click();
    
    // Cleanup
    Future.delayed(const Duration(milliseconds: 100), () {
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    });
  }
}