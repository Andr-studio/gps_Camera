import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Permiso de micrófono para grabación de video
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Permiso para acceder a videos de la galería
  static Future<bool> requestVideosPermission() async {
    final status = await Permission.videos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> requestAllPermissions() async {
    final results = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.photos,
      Permission.videos,
    ].request();

    return results.values.every((status) => status.isGranted || status.isLimited);
  }
}
