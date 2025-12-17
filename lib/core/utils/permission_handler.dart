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

  static Future<bool> requestAllPermissions() async {
    final results = await [
      Permission.camera,
      Permission.locationWhenInUse,
      Permission.photos,
    ].request();

    return results.values.every((status) => status.isGranted);
  }
}
