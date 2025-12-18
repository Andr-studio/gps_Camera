import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../models/location_data.dart';
import 'weather_service.dart';

/// Servicio de marca de agua para fotos usando Canvas y Google Fonts
/// Diseño idéntico a GpsOverlayPreview: minimapa a la izquierda, texto a la derecha
class WatermarkService {
  /// Aplica marca de agua GPS a una foto
  /// El diseño es idéntico al preview: minimapa integrado a la izquierda, texto a la derecha
  Future<Uint8List?> applyWatermarkToPhoto({
    required String imagePath,
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
    WeatherData? weatherData,
    Uint8List? weatherIconBytes,
  }) async {
    try {
      // Leer la imagen original
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        print('Error decodificando imagen');
        return null;
      }

      // Calcular escala basada en el ancho de la imagen (referencia: 720px como en el preview)
      final double scale = originalImage.width / 720.0;

      // Preparar textos
      final String title = locationData.locationTitle;
      final String address =
          locationData.fullAddress ?? locationData.addressLine;
      final String coords = 'Lat ${locationData.latitude.toStringAsFixed(6)}  '
          'Long ${locationData.longitude.toStringAsFixed(6)}';
      final String dateTime = _formatFullDateTime(locationData.timestamp);
      final String? countryFlag = locationData.countryCode != null
          ? _getCountryFlag(locationData.countryCode!)
          : null;

      // Crear overlay con diseño idéntico al preview
      final overlayBytes = await _createPreviewStyleOverlay(
        width: originalImage.width,
        height: originalImage.height,
        scale: scale,
        title: title,
        address: address,
        coords: coords,
        dateTime: dateTime,
        countryFlag: countryFlag,
        minimapBytes: minimapBytes,
      );

      if (overlayBytes == null) {
        print('Error creando overlay de texto');
        return null;
      }

      // Decodificar el overlay
      final overlayImage = img.decodePng(overlayBytes);
      if (overlayImage == null) {
        print('Error decodificando overlay');
        return null;
      }

      // Componer la imagen original con el overlay
      img.compositeImage(originalImage, overlayImage);

      // Codificar a JPEG
      final resultBytes =
          Uint8List.fromList(img.encodeJpg(originalImage, quality: 95));

      return resultBytes;
    } catch (e) {
      print('Error aplicando marca de agua: $e');
      return null;
    }
  }

  /// Crea un overlay con diseño idéntico a GpsOverlayPreview
  /// Minimapa a la izquierda, texto a la derecha, bandera junto al título
  Future<Uint8List?> _createPreviewStyleOverlay({
    required int width,
    required int height,
    required double scale,
    required String title,
    required String address,
    required String coords,
    required String dateTime,
    String? countryFlag,
    Uint8List? minimapBytes,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Dimensiones del overlay (igual que el preview)
      final double overlayHeight = 200.0 * scale;
      final double margin = 10.0 * scale;
      final double minimapWidth = 130.0 * scale;
      final double minimapHeight = overlayHeight - margin * 2;
      final double textAreaX = margin + minimapWidth + 15 * scale;
      final double textAreaWidth = width - textAreaX - margin;

      // Posición Y del overlay (parte inferior)
      final double overlayY = height - overlayHeight;

      // 1. Fondo oscuro semitransparente
      final overlayPaint = Paint()
        ..color = const Color.fromARGB(150, 3, 3, 3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, overlayY, width.toDouble(), overlayHeight),
        overlayPaint,
      );

      // 2. Dibujar minimapa
      if (minimapBytes != null) {
        await _drawMinimap(
          canvas: canvas,
          minimapBytes: minimapBytes,
          x: margin,
          y: overlayY + margin,
          width: minimapWidth,
          height: minimapHeight,
          scale: scale,
        );
      } else {
        // Dibujar placeholder de minimapa
        _drawMinimapPlaceholder(
          canvas: canvas,
          x: margin,
          y: overlayY + margin,
          width: minimapWidth,
          height: minimapHeight,
          scale: scale,
        );
      }

      // 3. Dibujar área de texto a la derecha del minimapa
      double currentY = overlayY + margin;

      // Título + bandera emoji
      final titleStyle = GoogleFonts.roboto(
        fontSize: 18 * scale,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      // Dibujar título
      final titleText = countryFlag != null ? '$title  $countryFlag' : title;
      _drawText(
        canvas: canvas,
        text: titleText,
        style: titleStyle,
        x: textAreaX,
        y: currentY,
        maxWidth: textAreaWidth,
      );

      currentY += 24 * scale; // Espacio después del título

      // Estilo para texto normal
      final textStyle = GoogleFonts.roboto(
        fontSize: 11 * scale,
        fontWeight: FontWeight.normal,
        color: Colors.white,
        height: 1.3,
      );

      // Dirección
      _drawText(
        canvas: canvas,
        text: address,
        style: textStyle,
        x: textAreaX,
        y: currentY,
        maxWidth: textAreaWidth,
        maxLines: 2,
      );

      currentY += 30 * scale; // Espacio para 2 líneas de dirección

      // Coordenadas
      _drawText(
        canvas: canvas,
        text: coords,
        style: textStyle,
        x: textAreaX,
        y: currentY,
        maxWidth: textAreaWidth,
      );

      currentY += 18 * scale;

      // Fecha y hora
      _drawText(
        canvas: canvas,
        text: dateTime,
        style: textStyle,
        x: textAreaX,
        y: currentY,
        maxWidth: textAreaWidth,
      );

      // Finalizar el dibujo
      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error creando overlay estilo preview: $e');
      return null;
    }
  }

  /// Dibuja el minimapa en el canvas
  Future<void> _drawMinimap({
    required Canvas canvas,
    required Uint8List minimapBytes,
    required double x,
    required double y,
    required double width,
    required double height,
    required double scale,
  }) async {
    try {
      // Decodificar imagen del minimapa
      final codec = await ui.instantiateImageCodec(minimapBytes);
      final frame = await codec.getNextFrame();
      final minimapImage = frame.image;

      // Dibujar minimapa
      final srcRect = Rect.fromLTWH(
        0,
        0,
        minimapImage.width.toDouble(),
        minimapImage.height.toDouble(),
      );
      final dstRect = Rect.fromLTWH(x, y, width, height);

      canvas.drawImageRect(minimapImage, srcRect, dstRect, Paint());

      // Dibujar pin rojo en el centro
      final pinPaint = Paint()
        ..color = Colors.red[700]!
        ..style = PaintingStyle.fill;

      // Sombra del pin
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final centerX = x + width / 2;
      final centerY = y + height / 2;
      final pinSize = 26 * scale;

      // Dibujar sombra
      canvas.drawCircle(
        Offset(centerX + 1, centerY + 1),
        pinSize / 3,
        shadowPaint,
      );

      // Dibujar pin (círculo simple por ahora)
      canvas.drawCircle(
        Offset(centerX, centerY - pinSize / 4),
        pinSize / 3,
        pinPaint,
      );

      // Triángulo inferior del pin
      final path = Path();
      path.moveTo(centerX - pinSize / 4, centerY - pinSize / 6);
      path.lineTo(centerX + pinSize / 4, centerY - pinSize / 6);
      path.lineTo(centerX, centerY + pinSize / 3);
      path.close();
      canvas.drawPath(path, pinPaint);

      // Texto "Google" en la esquina inferior del minimapa
      final googleStyle = GoogleFonts.roboto(
        fontSize: 11 * scale,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700]!,
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.7),
            offset: const Offset(0.5, 0.5),
          ),
        ],
      );

      _drawText(
        canvas: canvas,
        text: 'Google',
        style: googleStyle,
        x: x + 4 * scale,
        y: y + height - 15 * scale,
        maxWidth: width,
      );
    } catch (e) {
      print('Error dibujando minimapa: $e');
      // Si falla, dibujar placeholder
      _drawMinimapPlaceholder(
        canvas: canvas,
        x: x,
        y: y,
        width: width,
        height: height,
        scale: scale,
      );
    }
  }

  /// Dibuja un placeholder cuando no hay imagen de minimapa
  void _drawMinimapPlaceholder({
    required Canvas canvas,
    required double x,
    required double y,
    required double width,
    required double height,
    required double scale,
  }) {
    // Fondo gris claro
    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);

    // Dibujar cuadrícula
    final gridPaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final gridSize = 20.0 * scale;
    for (double gx = x; gx < x + width; gx += gridSize) {
      canvas.drawLine(Offset(gx, y), Offset(gx, y + height), gridPaint);
    }
    for (double gy = y; gy < y + height; gy += gridSize) {
      canvas.drawLine(Offset(x, gy), Offset(x + width, gy), gridPaint);
    }

    // Pin rojo en el centro
    final centerX = x + width / 2;
    final centerY = y + height / 2;
    final pinSize = 26 * scale;

    final pinPaint = Paint()
      ..color = Colors.red[700]!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY - pinSize / 4),
      pinSize / 3,
      pinPaint,
    );

    final path = Path();
    path.moveTo(centerX - pinSize / 4, centerY - pinSize / 6);
    path.lineTo(centerX + pinSize / 4, centerY - pinSize / 6);
    path.lineTo(centerX, centerY + pinSize / 3);
    path.close();
    canvas.drawPath(path, pinPaint);
  }

  /// Dibuja texto en el canvas
  void _drawText({
    required Canvas canvas,
    required String text,
    required TextStyle style,
    required double x,
    required double y,
    required double maxWidth,
    int maxLines = 1,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: maxWidth);
    textPainter.paint(canvas, Offset(x, y));
  }

  /// Formatea fecha y hora con acentos (igual que el preview)
  String _formatFullDateTime(DateTime dt) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
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

  /// Convierte código de país a emoji de bandera
  String _getCountryFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';

    final int firstLetter =
        countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter =
        countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}
