import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'app.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const PhotoApp());
}
