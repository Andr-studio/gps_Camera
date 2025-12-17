import 'package:camera/camera.dart';
import '../../../../main.dart';

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;

  Future<void> initialize() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true, // Habilitado para grabación de video
    );

    await _controller!.initialize();
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }
    return await _controller!.takePicture();
  }

  /// Inicia la grabación de video
  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_isRecording) {
      return; // Ya está grabando
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
    } catch (e) {
      print('Error al iniciar grabación: $e');
      rethrow;
    }
  }

  /// Detiene la grabación de video y retorna el archivo
  Future<XFile?> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    if (!_isRecording) {
      return null;
    }

    try {
      final video = await _controller!.stopVideoRecording();
      _isRecording = false;
      return video;
    } catch (e) {
      print('Error al detener grabación: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Pausa la grabación de video (si está soportado)
  Future<void> pauseVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isRecording && _controller!.value.isRecordingVideo) {
      await _controller!.pauseVideoRecording();
    }
  }

  /// Reanuda la grabación de video (si está soportado)
  Future<void> resumeVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isRecording && _controller!.value.isRecordingPaused) {
      await _controller!.resumeVideoRecording();
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
