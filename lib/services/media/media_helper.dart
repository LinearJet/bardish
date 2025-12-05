import 'media_helper_stub.dart'
    if (dart.library.io) 'media_helper_mobile.dart'
    if (dart.library.html) 'media_helper_web.dart';

abstract class MediaHelper {
  Future<String?> pickImageAndExtractText();
  Future<String?> pickImage();
  Future<void> startListening({
    required Function(String text) onResult, 
    required Function(bool isListening) onStateChanged
  });
  Future<void> stopListening();
}

MediaHelper getMediaHelper() => getHelper();
