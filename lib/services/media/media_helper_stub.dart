import 'media_helper.dart';

class MediaHelperStub implements MediaHelper {
  @override
  Future<String?> pickImageAndExtractText() async => throw UnsupportedError('Platform not supported');

  @override
  Future<String?> pickImage() async => throw UnsupportedError('Platform not supported');

  @override
  Future<void> startListening({
    required Function(String text) onResult, 
    required Function(bool isListening) onStateChanged
  }) async => throw UnsupportedError('Platform not supported');

  @override
  Future<void> stopListening() async => throw UnsupportedError('Platform not supported');
}

MediaHelper getHelper() => MediaHelperStub();
