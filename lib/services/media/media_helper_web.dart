import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'media_helper.dart';

class MediaHelperWeb implements MediaHelper {
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();

  @override
  Future<String?> pickImageAndExtractText() async {
    // OCR on Web is complex without heavy external JS libs.
    // For now, we return a placeholder to avoid crashing.
    return "[OCR not fully supported on Web yet]";
  }

  @override
  Future<String?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // On web, path is a blob URL
    return image != null ? '![Image](${image.path})' : null;
  }

  @override
  Future<void> startListening({
    required Function(String text) onResult, 
    required Function(bool isListening) onStateChanged
  }) async {
    bool available = await _speechToText.initialize(
      onStatus: (status) => onStateChanged(status == 'listening'),
      onError: (error) => onStateChanged(false),
    );

    if (available) {
      onStateChanged(true);
      _speechToText.listen(
        onResult: (result) => onResult(result.recognizedWords),
      );
    }
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}

MediaHelper getHelper() => MediaHelperWeb();
