import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

class SpeechToTextWindows extends SpeechToTextPlatform {
  static void registerWith() {
    SpeechToTextPlatform.instance = SpeechToTextWindows();
  }

  @override
  Future<bool> initialize({
    debugLogging = false, 
    List<SpeechConfigOption>? options
  }) async {
    return false; // Not supported
  }
}
