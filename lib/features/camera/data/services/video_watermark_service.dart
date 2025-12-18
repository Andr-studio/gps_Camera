import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import '../models/location_data.dart';
import 'watermark_config.dart';

/// Servicio de marca de agua para videos usando FFmpeg
/// Soporta UTF-8 completo (acentos, ñ, etc.)
class VideoWatermarkService {
  /// Aplica marca de agua GPS a un video usando FFmpeg
  Future<String?> applyWatermarkToVideo({
    required String videoPath,
    required LocationData locationData,
    minimapBytes,
    flagBytes,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/video_with_watermark_$timestamp.mp4';

      // Preparar textos con acentos (FFmpeg soporta UTF-8)
      final String title = locationData.locationTitle;
      final String address = locationData.fullAddress ?? locationData.addressLine;
      final String coords = 'Lat ${locationData.latitude.toStringAsFixed(6)}°  '
          'Long ${locationData.longitude.toStringAsFixed(6)}°';
      final String dateTime = _formatFullDateTime(locationData.timestamp);

      // Escapar caracteres especiales para FFmpeg
      final String escapedTitle = _escapeText(title);
      final String escapedAddress = _escapeText(address);
      final String escapedCoords = _escapeText(coords);
      final String escapedDateTime = _escapeText(dateTime);

      // Construir filtro de texto usando drawtext de FFmpeg
      final String textFilter = _buildTextFilter(
        escapedTitle,
        escapedAddress,
        escapedCoords,
        escapedDateTime,
      );

      // Comando FFmpeg para aplicar overlay de texto al video
      final command = '-i "$videoPath" '
          '-vf "$textFilter" '
          '-c:a copy -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p '
          '"$outputPath"';

      print('Ejecutando FFmpeg para video: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // Limpiar video original
      try {
        await File(videoPath).delete();
      } catch (e) {
        print('Error eliminando video original: $e');
      }

      if (ReturnCode.isSuccess(returnCode)) {
        print('Video procesado exitosamente: $outputPath');
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

  /// Construye el filtro de texto para FFmpeg
  String _buildTextFilter(
    String title,
    String address,
    String coords,
    String dateTime,
  ) {
    // Obtener tamaños desde la configuración
    final int titleSize = WatermarkConfig.getVideoTitleFontSize();
    final int textSize = WatermarkConfig.getVideoTextFontSize();

    // Obtener posiciones desde la configuración
    final int bottomMargin = WatermarkConfig.getVideoBottomMargin();
    final int lineHeight = WatermarkConfig.getVideoLineHeight();

    // Crear overlay oscuro en la parte inferior
    final int overlayHeight = WatermarkConfig.getVideoOverlayHeight();
    String filter = 'drawbox=0:h-$overlayHeight:w:$overlayHeight:color=black@${WatermarkConfig.videoBackgroundOpacity}:t=fill';

    // Posición X para el texto
    final int textX = WatermarkConfig.getVideoMarginLeft();

    // Agregar textos con fuente Roboto (que soporta UTF-8)
    // Título (más grande)
    filter += ',drawtext=text=\'$title\':fontfile=/system/fonts/Roboto-Regular.ttf:'
        'fontsize=$titleSize:fontcolor=white:x=$textX:y=h-${overlayHeight - bottomMargin}:'
        'shadowcolor=black:shadowx=1:shadowy=1';

    // Dirección
    filter += ',drawtext=text=\'$address\':fontfile=/system/fonts/Roboto-Regular.ttf:'
        'fontsize=$textSize:fontcolor=white:x=$textX:y=h-${overlayHeight - bottomMargin - lineHeight}:'
        'shadowcolor=black:shadowx=1:shadowy=1';

    // Coordenadas
    filter += ',drawtext=text=\'$coords\':fontfile=/system/fonts/Roboto-Regular.ttf:'
        'fontsize=$textSize:fontcolor=white:x=$textX:y=h-${overlayHeight - bottomMargin - lineHeight * 2}:'
        'shadowcolor=black:shadowx=1:shadowy=1';

    // Fecha y hora
    filter += ',drawtext=text=\'$dateTime\':fontfile=/system/fonts/Roboto-Regular.ttf:'
        'fontsize=$textSize:fontcolor=white:x=$textX:y=h-${overlayHeight - bottomMargin - lineHeight * 3}:'
        'shadowcolor=black:shadowx=1:shadowy=1';

    return filter;
  }

  /// Escapa caracteres especiales para FFmpeg
  String _escapeText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(':', '\\:')
        .replaceAll('\'', '\\\'');
  }

  /// Formatea fecha y hora con acentos (ahora soportado!)
  String _formatFullDateTime(DateTime dt) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',  // Con acento!
      'jueves',
      'viernes',
      'sábado',     // Con acento!
      'domingo'
    ];
    final String diaSemana = dias[dt.weekday - 1];

    final String fecha = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    int hora12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final String ampm = dt.hour >= 12 ? 'p. m.' : 'a. m.';
    final String hora =
        '${hora12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final Duration offset = dt.timeZoneOffset;
    final String signo = offset.isNegative ? '-' : '+';
    final String horas = offset.inHours.abs().toString().padLeft(2, '0');
    final String minutos =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    return '$diaSemana, $fecha $hora $ampm GMT $signo$horas:$minutos';
  }
}
