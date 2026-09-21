import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SensorHandler {
  CameraController? _cameraController;
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  /// Initializes the device camera.
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera available on this device.');
    }

    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
  }

  /// Captures an image and converts it to Base64.
  ///
  /// Returns only the Base64 string.
  Future<String> captureImageAsBase64() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }

    final XFile image = await _cameraController!.takePicture();
    final bytes = await File(image.path).readAsBytes();

    return base64Encode(bytes);
  }

  /// Initializes speech recognition.
  Future<bool> initializeSpeech() async {
    return await _speechToText.initialize();
  }

  /// Returns the raw speech text.
  ///
  /// No loan parsing or AI processing happens here.
  Future<String> listenForSpeech() async {
    final available = await initializeSpeech();

    if (!available) {
      throw Exception('Speech recognition is not available.');
    }

    String recognizedText = '';

    await _speechToText.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        recognizedText = result.recognizedWords;
      },
    );

    // Give the engine a moment to start
    await Future.delayed(const Duration(milliseconds: 200));

    // Wait until speech recognition naturally stops (due to pause or max duration)
    while (_speechToText.isListening) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _speechToText.stop();

    return recognizedText;
  }

  /// Releases camera resources.
  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}