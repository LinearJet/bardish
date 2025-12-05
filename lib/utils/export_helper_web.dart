import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

void downloadForWeb(String content, String fileName, String mimeType) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> saveToMobileFile(String content, String fileName, String directory) async {
  // Not used on web
}