import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/location_data.dart';
import 'watermark_config.dart';
import 'watermark_service.dart';

/// Servicio de marca de agua para videos usando FFmpeg
/// Usa imagen overlay pre-renderizada para mejor compatibilidad con acentos
class VideoWatermarkService {
  final WatermarkService _watermarkService = WatermarkService();

  /// Aplica marca de agua GPS a un video
  /// Genera una imagen overlay con la información GPS y la superpone al video
  Future<String?> applyWatermarkToVideo({
    required String videoPath,
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
  }) async {
    try {
      // 1. Obtener información del video (resolución)
      final videoInfo = await _getVideoInfo(videoPath);
      if (videoInfo == null) {
        print('Error: No se pudo obtener información del video');
        return null;
      }

      final int videoWidth = videoInfo['width'] ?? 1080;
      final int videoHeight = videoInfo['height'] ?? 720;

      // 2. Crear una imagen overlay con la marca de agua GPS
      final overlayImagePath = await _createOverlayImage(
        locationData: locationData,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
      );

      if (overlayImagePath == null) {
        print('Error: No se pudo crear la imagen overlay');
        return null;
      }

      // 3. Preparar ruta de salida para el video procesado
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath =
          '${directory.path}/video_with_watermark_$timestamp.mp4';

      // 4. Construir comando FFmpeg para superponer la marca de agua
      // El overlay se posiciona en la parte inferior del video
      final command = '-i "$videoPath" -i "$overlayImagePath" '
          '-filter_complex "[0:v][1:v]overlay=0:main_h-overlay_h" '
          '-c:a copy -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p '
          '"$outputPath"';

      print('Ejecutando FFmpeg: $command');

      // 5. Ejecutar FFmpeg
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // 6. Limpiar imagen overlay temporal
      try {
        await File(overlayImagePath).delete();
      } catch (e) {
        print('Error eliminando overlay temporal: $e');
      }

      // 7. Verificar resultado
      if (ReturnCode.isSuccess(returnCode)) {
        print('Video procesado exitosamente: $outputPath');

        // Solo eliminar video original si FFmpeg tuvo éxito
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

  /// Obtiene información del video (ancho, alto)
  Future<Map<String, int>?> _getVideoInfo(String videoPath) async {
    try {
      final session = await FFmpegKit.execute('-i "$videoPath" -hide_banner');
      final output = await session.getOutput();

      if (output == null) return {'width': 1920, 'height': 1080};

      // Buscar resolución en el output (formato: 1920x1080)
      final regex = RegExp(r'(\d{3,4})x(\d{3,4})');
      final match = regex.firstMatch(output);

      if (match != null) {
        return {
          'width': int.parse(match.group(1)!),
          'height': int.parse(match.group(2)!),
        };
      }

      return {'width': 1920, 'height': 1080};
    } catch (e) {
      print('Error obteniendo info del video: $e');
      return {'width': 1920, 'height': 1080};
    }
  }

  /// Crea una imagen PNG con el overlay de GPS para superponer al video
  /// Solo contiene la franja inferior con la información GPS
  /// El diseño es idéntico al preview: minimapa a la izquierda, texto a la derecha
  /// El tamaño se controla con WatermarkConfig.videoScaleFactor
  Future<String?> _createOverlayImage({
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
    required int videoWidth,
    required int videoHeight,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Aplicar factor de escala para videos
      // Si videoScaleFactor = 0.7, el watermark será 70% del tamaño
      final double scaleFactor = WatermarkConfig.videoScaleFactor;

      // Calcular dimensiones virtuales para generar el watermark
      // Usamos estas dimensiones para que el watermark se genere al tamaño deseado
      final int virtualWidth = (videoWidth * scaleFactor).toInt();
      final int virtualHeight = (videoHeight * scaleFactor).toInt();

      // Crear imagen base negra del tamaño virtual
      final tempImagePath = '${directory.path}/temp_base_$timestamp.jpg';
      final baseImage = _createBlackImage(virtualWidth, virtualHeight);
      await File(tempImagePath).writeAsBytes(baseImage);

      // Aplicar la marca de agua GPS a la imagen base virtual
      final watermarkedBytes = await _watermarkService.applyWatermarkToPhoto(
        imagePath: tempImagePath,
        locationData: locationData,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
      );

      // Eliminar imagen temporal
      try {
        await File(tempImagePath).delete();
      } catch (e) {
        print('Error eliminando imagen temporal: $e');
      }

      if (watermarkedBytes == null) {
        print('Error: No se pudo aplicar marca de agua');
        return null;
      }

      // Decodificar la imagen con marca de agua
      final fullImage = img.decodeImage(watermarkedBytes);
      if (fullImage == null) {
        print('Error: No se pudo decodificar imagen con marca de agua');
        return null;
      }

      // Calcular altura del overlay usando la fórmula de WatermarkService
      // pero con las dimensiones virtuales
      final double scale = virtualWidth / WatermarkConfig.referenceWidth;
      final int overlayHeight = (WatermarkConfig.baseOverlayHeight * scale).toInt();

      // Recortar SOLO la franja inferior que contiene el overlay GPS
      final croppedOverlay = img.copyCrop(
        fullImage,
        x: 0,
        y: virtualHeight - overlayHeight,
        width: virtualWidth,
        height: overlayHeight,
      );

      // Redimensionar el overlay al ancho real del video
      // Esto mantiene la proporción pero adapta al tamaño del video
      final int finalOverlayHeight = (overlayHeight / scaleFactor).toInt();
      final resizedOverlay = img.copyResize(
        croppedOverlay,
        width: videoWidth,
        height: finalOverlayHeight,
      );

      // Guardar la imagen del overlay como PNG
      final overlayPath = '${directory.path}/overlay_$timestamp.png';
      await File(overlayPath).writeAsBytes(img.encodePng(resizedOverlay));

      return overlayPath;
    } catch (e) {
      print('Error creando overlay: $e');
      return null;
    }
  }

  /// Crea una imagen negra del tamaño especificado
  Uint8List _createBlackImage(int width, int height) {
    final img.Image image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 255));
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }
}
