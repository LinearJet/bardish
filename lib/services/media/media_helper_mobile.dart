import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'media_helper.dart';

class MediaHelperMobile implements MediaHelper {
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();

  @override
  Future<String?> pickImageAndExtractText() async {
    // 1. Pick Image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    // 2. Process with ML Kit
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      return "Error recognizing text: $e";
    } finally {
      textRecognizer.close();
    }
  }

  @override
  Future<String?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // Return markdown image syntax
    return image != null ? '![Image](${image.path})' : null;
  }

  @override
  Future<void> startListening({
    required Function(String text) onResult, 
    required Function(bool isListening) onStateChanged
  }) async {
    // Check and request permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        onStateChanged(false);
        return;
      }
    }

    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          onStateChanged(status == 'listening');
        },
        onError: (error) {
          print('SpeechToText Error: ${error.errorMsg}');
          onStateChanged(false);
        },
      );

      if (available) {
        onStateChanged(true);
        await _speechToText.listen(
          onResult: (result) => onResult(result.recognizedWords),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          localeId: "en_US", // Optional: make configurable later
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        );
      } else {
        print('SpeechToText not available');
        onStateChanged(false);
      }
    } catch (e) {
      print('SpeechToText Initialization Exception: $e');
      onStateChanged(false);
    }
  }

  @override
  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}

MediaHelper getHelper() => MediaHelperMobile();
