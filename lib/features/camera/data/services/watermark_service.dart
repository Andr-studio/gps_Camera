import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../models/location_data.dart';
import 'watermark_config.dart';
import 'weather_service.dart';

/// Servicio de marca de agua para fotos usando Canvas y Google Fonts
/// Soporta UTF-8 completo (acentos, ñ, etc.)
class WatermarkService {
  /// Aplica marca de agua GPS a una foto
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

      // Preparar textos con acentos
      final String title = locationData.locationTitle;
      final String address =
          locationData.fullAddress ?? locationData.addressLine;
      final String coords = 'Lat ${locationData.latitude.toStringAsFixed(6)}°  '
          'Long ${locationData.longitude.toStringAsFixed(6)}°';
      final String dateTime = _formatFullDateTime(locationData.timestamp);

      // Crear overlay con Canvas usando Google Fonts
      final overlayBytes = await _createTextOverlay(
        width: originalImage.width,
        height: originalImage.height,
        title: title,
        address: address,
        coords: coords,
        dateTime: dateTime,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
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

      // Agregar minimapa si está disponible (en la esquina inferior IZQUIERDA)
      if (minimapBytes != null) {
        final minimapImage = img.decodeImage(minimapBytes);
        if (minimapImage != null) {
          // Redimensionar minimapa usando configuración
          final resizedMinimap = img.copyResize(
            minimapImage,
            width: WatermarkConfig.photoMinimapWidth,
            height: WatermarkConfig.photoMinimapHeight,
          );

          // Posicionar en la esquina inferior IZQUIERDA usando configuración
          final minimapX = WatermarkConfig.photoMinimapMarginLeft;
          final minimapY = originalImage.height -
              WatermarkConfig.photoMinimapHeight -
              WatermarkConfig.photoMinimapMarginBottom;

          img.compositeImage(originalImage, resizedMinimap, dstX: minimapX, dstY: minimapY);
        }
      }

      // Agregar bandera y clima en la esquina superior derecha
      if (flagBytes != null || weatherIconBytes != null) {
        int currentX = originalImage.width - WatermarkConfig.photoFlagMarginRight;
        final topY = WatermarkConfig.photoFlagMarginTop;

        // Agregar icono del clima si está disponible
        if (weatherIconBytes != null && weatherData != null) {
          final weatherIcon = img.decodeImage(weatherIconBytes);
          if (weatherIcon != null) {
            // Redimensionar icono del clima
            final resizedWeatherIcon = img.copyResize(weatherIcon, width: 50, height: 50);

            currentX -= 50;
            img.compositeImage(originalImage, resizedWeatherIcon, dstX: currentX, dstY: topY);

            // Agregar temperatura en texto
            final tempText = '${weatherData.temperature.toStringAsFixed(0)}°C';
            final tempImage = await _createTemperatureOverlay(tempText, 50, 20);
            if (tempImage != null) {
              final decodedTempImage = img.decodePng(tempImage);
              if (decodedTempImage != null) {
                img.compositeImage(originalImage, decodedTempImage,
                    dstX: currentX, dstY: topY + 50);
              }
            }

            currentX -= 10; // Espacio entre clima y bandera
          }
        }

        // Agregar bandera si está disponible
        if (flagBytes != null) {
          final flagImage = img.decodeImage(flagBytes);
          if (flagImage != null) {
            // Redimensionar bandera usando configuración
            final resizedFlag = img.copyResize(
              flagImage,
              width: WatermarkConfig.photoFlagWidth,
              height: WatermarkConfig.photoFlagHeight,
            );

            currentX -= WatermarkConfig.photoFlagWidth;
            img.compositeImage(originalImage, resizedFlag, dstX: currentX, dstY: topY);
          }
        }
      }

      // Codificar a JPEG
      final resultBytes =
          Uint8List.fromList(img.encodeJpg(originalImage, quality: 95));

      return resultBytes;
    } catch (e) {
      print('Error aplicando marca de agua: $e');
      return null;
    }
  }

  /// Crea un overlay de texto usando Canvas y Google Fonts
  Future<Uint8List?> _createTextOverlay({
    required int width,
    required int height,
    required String title,
    required String address,
    required String coords,
    required String dateTime,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
  }) async {
    try {
      // Crear un PictureRecorder para dibujar
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fondo oscuro semitransparente en la parte inferior
      final overlayHeight = WatermarkConfig.photoOverlayHeight;
      final overlayPaint = Paint()
        ..color =
            Colors.black.withOpacity(WatermarkConfig.photoBackgroundOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(
            0, height - overlayHeight, width.toDouble(), overlayHeight),
        overlayPaint,
      );

      // Configurar estilo de texto con Google Fonts Roboto
      final titleTextStyle = GoogleFonts.roboto(
        fontSize: WatermarkConfig.photoTitleFontSize,
        fontWeight:
            FontWeight.values[WatermarkConfig.photoTitleFontWeight ~/ 100 - 1],
        color: Colors.white,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      final textStyle = GoogleFonts.roboto(
        fontSize: WatermarkConfig.photoTextFontSize,
        fontWeight:
            FontWeight.values[WatermarkConfig.photoTextFontWeight ~/ 100 - 1],
        color: Colors.white,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      // Dibujar título
      _drawText(
        canvas: canvas,
        text: title,
        style: titleTextStyle,
        x: WatermarkConfig.photoTextMarginLeft,
        y: height - WatermarkConfig.photoTitlePositionY,
        maxWidth: width - (WatermarkConfig.photoTextMarginLeft * 2),
      );

      // Dibujar dirección
      _drawText(
        canvas: canvas,
        text: address,
        style: textStyle,
        x: WatermarkConfig.photoTextMarginLeft,
        y: height - WatermarkConfig.photoAddressPositionY,
        maxWidth: width - (WatermarkConfig.photoTextMarginLeft * 2),
      );

      // Dibujar coordenadas
      _drawText(
        canvas: canvas,
        text: coords,
        style: textStyle,
        x: WatermarkConfig.photoTextMarginLeft,
        y: height - WatermarkConfig.photoCoordsPositionY,
        maxWidth: width - (WatermarkConfig.photoTextMarginLeft * 2),
      );

      // Dibujar fecha y hora
      _drawText(
        canvas: canvas,
        text: dateTime,
        style: textStyle,
        x: WatermarkConfig.photoTextMarginLeft,
        y: height - WatermarkConfig.photoDatePositionY,
        maxWidth: width - (WatermarkConfig.photoTextMarginLeft * 2),
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
      print('Error creando overlay de texto: $e');
      return null;
    }
  }

  /// Dibuja texto en el canvas
  void _drawText({
    required Canvas canvas,
    required String text,
    required TextStyle style,
    required double x,
    required double y,
    required double maxWidth,
  }) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: maxWidth);
    textPainter.paint(canvas, Offset(x, y));
  }

  /// Crea un overlay de texto para la temperatura
  Future<Uint8List?> _createTemperatureOverlay(
      String text, int width, int height) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Estilo de texto para la temperatura
      final textStyle = GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        shadows: [
          const Shadow(
            color: Colors.black,
            offset: Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      final textSpan = TextSpan(text: text, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout(maxWidth: width.toDouble());

      // Centrar el texto
      final xPosition = (width - textPainter.width) / 2;
      final yPosition = (height - textPainter.height) / 2;

      textPainter.paint(canvas, Offset(xPosition, yPosition));

      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      print('Error creando overlay de temperatura: $e');
      return null;
    }
  }

  /// Formatea fecha y hora con acentos
  String _formatFullDateTime(DateTime dt) {
    const dias = [
      'lunes',
      'martes',
      'miércoles', // Con acento!
      'jueves',
      'viernes',
      'sábado', // Con acento!
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
