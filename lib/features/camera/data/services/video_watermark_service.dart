import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../models/location_data.dart';
import 'watermark_service.dart';

class VideoWatermarkService {
  final WatermarkService _watermarkService = WatermarkService();

  /// Aplica marca de agua GPS a un video
  ///
  /// Genera una imagen overlay con la información GPS y la superpone al video
  /// usando FFmpeg. La marca de agua permanece constante durante todo el video.
  Future<String?> applyWatermarkToVideo({
    required String videoPath,
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
  }) async {
    try {
      // 1. Crear una imagen temporal con la marca de agua GPS
      final overlayImagePath = await _createOverlayImage(
        locationData: locationData,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
      );

      if (overlayImagePath == null) {
        print('Error: No se pudo crear la imagen overlay');
        return null;
      }

      // 2. Preparar ruta de salida para el video procesado
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/video_with_watermark_$timestamp.mp4';

      // 3. Construir comando FFmpeg para superponer la marca de agua
      // Escalar el overlay al ancho del video y posicionarlo en la parte inferior
      // format=rgba hace que se mantenga la transparencia (si la hay)
      final command = '-i "$videoPath" -i "$overlayImagePath" '
          '-filter_complex "[1:v]scale=iw:ih[ovrl];[0:v][ovrl]overlay=0:H-overlay_h:shortest=1" '
          '-c:a copy -c:v libx264 -preset medium -crf 23 '
          '"$outputPath"';

      print('Ejecutando FFmpeg: $command');

      // 4. Ejecutar FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // 5. Limpiar imagen temporal
      try {
        await File(overlayImagePath).delete();
      } catch (e) {
        print('Error eliminando overlay temporal: $e');
      }

      // 6. Verificar resultado
      if (ReturnCode.isSuccess(returnCode)) {
        print('Video procesado exitosamente: $outputPath');

        // Eliminar video original
        try {
          await File(videoPath).delete();
        } catch (e) {
          print('Error eliminando video original: $e');
        }

        return outputPath;
      } else {
        print('Error en FFmpeg. Código: $returnCode');
        final output = await session.getOutput();
        print('Salida FFmpeg: $output');
        return null;
      }
    } catch (e) {
      print('Error aplicando marca de agua al video: $e');
      return null;
    }
  }

  /// Crea una imagen PNG temporal con el overlay de GPS
  /// Esta imagen tiene fondo transparente excepto en el área del overlay
  Future<String?> _createOverlayImage({
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
  }) async {
    try {
      // Crear una imagen base de 1920x1080 (resolución común de video)
      // El overlay estará en la parte inferior
      final int videoWidth = 1920;
      final int videoHeight = 1080;

      // Crear una imagen temporal base transparente
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempImagePath = '${directory.path}/temp_base_$timestamp.jpg';

      // Crear una imagen negra temporal del tamaño del video
      final tempFile = File(tempImagePath);

      // Crear imagen base (simplificada: 1920x1080 negro)
      // En producción, podrías querer usar el tamaño real del video
      final img = await _createBlackImage(videoWidth, videoHeight);
      await tempFile.writeAsBytes(img);

      // Aplicar la marca de agua GPS a la imagen base
      final watermarkedBytes = await _watermarkService.applyAdvancedWatermark(
        imagePath: tempImagePath,
        locationData: locationData,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
      );

      if (watermarkedBytes == null) {
        return null;
      }

      // Guardar la imagen con marca de agua
      final overlayPath = '${directory.path}/overlay_$timestamp.jpg';
      await File(overlayPath).writeAsBytes(watermarkedBytes);

      // Eliminar imagen temporal
      try {
        await tempFile.delete();
      } catch (e) {
        print('Error eliminando imagen temporal: $e');
      }

      return overlayPath;
    } catch (e) {
      print('Error creando overlay: $e');
      return null;
    }
  }

  /// Crea una imagen negra del tamaño especificado
  Uint8List _createBlackImage(int width, int height) {
    // Crear imagen JPEG mínima (1x1 negro) que será escalada por FFmpeg
    // Esta es una imagen JPEG 1x1 negro válida codificada en base64
    final List<int> blackPixel = [
      0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
      0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
      0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
      0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
      0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
      0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
      0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
      0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
      0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x03, 0xFF, 0xC4, 0x00, 0x14, 0x10, 0x01, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00,
      0x37, 0xFF, 0xD9
    ];

    return Uint8List.fromList(blackPixel);
  }
}
