import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
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
      final outputPath =
          '${directory.path}/video_with_watermark_$timestamp.mp4';

      // 3. Construir comando FFmpeg para superponer la marca de agua
      // El overlay ya está recortado a solo la franja GPS
      // overlay=0:main_h-overlay_h posiciona el overlay en la parte inferior del video
      // NO usar shortest=1 porque eso detiene el video cuando termina el overlay (imagen estática)
      final command = '-i "$videoPath" -i "$overlayImagePath" '
          '-filter_complex "[0:v][1:v]overlay=0:main_h-overlay_h" '
          '-c:a copy -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p '
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
  /// Esta imagen contiene SOLO la franja inferior con la información GPS
  Future<String?> _createOverlayImage({
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
  }) async {
    try {
      // Crear una imagen base de 1920x1080 (resolución común de video)
      final int videoWidth = 1920;
      final int videoHeight = 1080;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempImagePath = '${directory.path}/temp_base_$timestamp.jpg';

      // Crear una imagen negra temporal del tamaño del video
      final tempFile = File(tempImagePath);
      final baseImage = _createBlackImage(videoWidth, videoHeight);
      await tempFile.writeAsBytes(baseImage);

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

      // Decodificar la imagen con marca de agua
      final fullImage = img.decodeImage(watermarkedBytes);
      if (fullImage == null) {
        return null;
      }

      // Calcular la altura del overlay (igual que en WatermarkService)
      // La escala se basa en ancho de 720px como referencia
      final double scale = videoWidth / 720.0;
      final int overlayHeight = (200 * scale).toInt();

      // Recortar SOLO la franja inferior que contiene el overlay GPS
      final croppedOverlay = img.copyCrop(
        fullImage,
        x: 0,
        y: videoHeight - overlayHeight,
        width: videoWidth,
        height: overlayHeight,
      );

      // Guardar la imagen recortada del overlay
      final overlayPath = '${directory.path}/overlay_$timestamp.jpg';
      await File(overlayPath).writeAsBytes(img.encodeJpg(croppedOverlay, quality: 92));

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

  /// Crea una imagen negra del tamaño especificado usando la librería image
  Uint8List _createBlackImage(int width, int height) {
    // Crear imagen negra del tamaño especificado
    final img.Image image = img.Image(width: width, height: height);

    // Llenar con negro
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 255));

    // Codificar como JPEG
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }
}
