import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/location_data.dart';

class WatermarkService {
  /// Aplica marca de agua GPS - SIN badge flotante
  Future<Uint8List?> applyAdvancedWatermark({
    required String imagePath,
    required LocationData locationData,
    Uint8List? minimapBytes,
    Uint8List? flagBytes,
    Uint8List? weatherIconBytes,
    double? temperature,
  }) async {
    try {
      // Cargar imagen principal
      final File file = File(imagePath);
      final Uint8List bytes = await file.readAsBytes();
      img.Image? mainImage = img.decodeImage(bytes);
      if (mainImage == null) return null;

      final int imgWidth = mainImage.width;
      final int imgHeight = mainImage.height;

      // Escala basada en ancho (referencia 720px para móvil)
      final double scale = imgWidth / 720.0;

      // ============================================================
      // DIMENSIONES DEL OVERLAY PRINCIPAL
      // ============================================================
      final int overlayHeight = (200 * scale).toInt();
      final int overlayY = imgHeight - overlayHeight;
      final int margin = (10 * scale).toInt();

      // ============================================================
      // FONDO DEL OVERLAY (gris semi-transparente)
      // ============================================================
      img.fillRect(
        mainImage,
        x1: 0,
        y1: overlayY,
        x2: imgWidth,
        y2: imgHeight,
        color: img.ColorRgba8(0, 0, 0, 310),
      );

      // ============================================================
      // MINIMAPA (esquina inferior izquierda)
      // ============================================================
      final int mapSize = (130 * scale).toInt();
      final int mapX = margin;
      final int mapY = overlayY + margin;
      final int mapHeight = overlayHeight - margin * 2;

      if (minimapBytes != null) {
        img.Image? minimap = img.decodeImage(minimapBytes);
        if (minimap != null) {
          // Redimensionar el minimapa para que encaje en el espacio
          minimap = img.copyResize(minimap, width: mapSize, height: mapHeight);
          // Componer el minimapa sobre la imagen principal
          img.compositeImage(mainImage, minimap, dstX: mapX, dstY: mapY);
        } else {
          // Si falla la decodificación, mostrar placeholder gris
          img.fillRect(
            mainImage,
            x1: mapX,
            y1: mapY,
            x2: mapX + mapSize,
            y2: mapY + mapHeight,
            color: img.ColorRgba8(220, 215, 210, 255),
          );
        }
      } else {
        // Placeholder gris claro cuando no hay minimapBytes
        img.fillRect(
          mainImage,
          x1: mapX,
          y1: mapY,
          x2: mapX + mapSize,
          y2: mapY + mapHeight,
          color: img.ColorRgba8(220, 215, 210, 255),
        );
      }

      // Pin de ubicación (estilo Material Icons location_on)
      final int pinCenterX = mapX + mapSize ~/ 2;
      final int pinCenterY = mapY + mapHeight ~/ 2;
      _drawLocationPin(mainImage, pinCenterX, pinCenterY, scale);

      // Texto "Google" en el mapa
      img.drawString(
        mainImage,
        'Google',
        font: img.arial14,
        x: mapX + 3,
        y: mapY + mapHeight - 16,
        color: img.ColorRgba8(100, 100, 100, 255),
      );

      // ============================================================
      // ÁREA DE TEXTO (a la derecha del mapa)
      // ============================================================
      final int textX = mapX + mapSize + (15 * scale).toInt();
      final int textWidth = imgWidth -
          textX -
          margin -
          (70 * scale).toInt(); // Espacio para bandera

      // Línea vertical para cálculos
      int lineY = overlayY + margin;
      final int lineSpacing = (26 * scale).toInt();

      // ============================================================
      // TÍTULO: "Ciudad, País" + bandera pequeña
      // ============================================================
      final String title = locationData.locationTitle;

      img.drawString(
        mainImage,
        title,
        font: img.arial24,
        x: textX,
        y: lineY,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      // Bandera pequeña al lado del título
      if (flagBytes != null) {
        img.Image? flagSmall = img.decodeImage(flagBytes);
        if (flagSmall != null) {
          final int flagW = (28 * scale).toInt();
          final int flagH = (18 * scale).toInt();
          flagSmall = img.copyResize(flagSmall, width: flagW, height: flagH);

          // Calcular posición después del texto (aproximado)
          final int flagX = imgWidth - flagW - margin - (100 * scale).toInt();
          img.compositeImage(mainImage, flagSmall,
              dstX: flagX, dstY: lineY + 2);
        }
      }

      lineY += lineSpacing + (5 * scale).toInt();

      // ============================================================
      // DIRECCIÓN (multilínea)
      // ============================================================
      final String address =
          locationData.fullAddress ?? locationData.addressLine;
      final int maxChars =
          (textWidth / 8).toInt(); // ~8px por carácter en arial14
      final List<String> addressLines = _wrapText(address, maxChars);

      // Mostrar hasta 2 líneas de dirección
      for (int i = 0; i < math.min(addressLines.length, 2); i++) {
        img.drawString(
          mainImage,
          addressLines[i],
          font: img.arial14,
          x: textX,
          y: lineY,
          color: img.ColorRgba8(255, 255, 255, 255),
        );
        lineY += (18 * scale).toInt();
      }

      lineY += (3 * scale).toInt();

      // ============================================================
      // COORDENADAS
      // ============================================================
      final String coords = 'Lat ${locationData.latitude.toStringAsFixed(6)}  '
          'Long ${locationData.longitude.toStringAsFixed(6)}';

      img.drawString(
        mainImage,
        coords,
        font: img.arial14,
        x: textX,
        y: lineY,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      lineY += (20 * scale).toInt();

      // ============================================================
      // FECHA Y HORA CON ZONA HORARIA
      // ============================================================
      final String dateTime = _formatFullDateTime(locationData.timestamp);

      img.drawString(
        mainImage,
        dateTime,
        font: img.arial14,
        x: textX,
        y: lineY,
        color: img.ColorRgba8(255, 255, 255, 255),
      );

      return Uint8List.fromList(img.encodeJpg(mainImage, quality: 92));
    } catch (e) {
      print('Error aplicando marca de agua: $e');
      return null;
    }
  }

  /// Divide texto largo en múltiples líneas
  List<String> _wrapText(String text, int maxCharsPerLine) {
    if (maxCharsPerLine <= 0) maxCharsPerLine = 40;
    if (text.length <= maxCharsPerLine) return [text];

    final List<String> lines = [];
    final List<String> words = text.split(' ');
    String currentLine = '';

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxCharsPerLine) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }

  /// Formatea: "martes, 16/12/2025 03:04 p. m. GMT -03:00"
  String _formatFullDateTime(DateTime dt) {
    // Día de la semana en español
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

    // Fecha
    final String fecha = '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    // Hora en formato 12h
    int hora12 = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final String ampm = dt.hour >= 12 ? 'p. m.' : 'a. m.';
    final String hora =
        '${hora12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // Zona horaria
    final Duration offset = dt.timeZoneOffset;
    final String signo = offset.isNegative ? '-' : '+';
    final String horas = offset.inHours.abs().toString().padLeft(2, '0');
    final String minutos =
        (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    return '$diaSemana, $fecha $hora $ampm GMT $signo$horas:$minutos';
  }

  /// Dibuja un pin de ubicación estilo Material Icons.location_on
  void _drawLocationPin(
      img.Image image, int centerX, int centerY, double scale) {
    final int pinSize = (24 * scale).toInt();
    final int pinWidth = (pinSize * 0.7).toInt();
    final int pinHeight = pinSize;
    final int circleRadius = (pinWidth / 2).toInt();

    // Posición superior del pin (la parte redonda)
    final int topY = centerY - (pinHeight ~/ 2);
    final int circleCenterY = topY + circleRadius;

    // Sombra del pin
    _drawPinShape(
      image,
      centerX: centerX + 1,
      circleCenterY: circleCenterY + 1,
      circleRadius: circleRadius,
      pinHeight: pinHeight,
      color: img.ColorRgba8(0, 0, 0, 100),
    );

    // Pin rojo principal
    _drawPinShape(
      image,
      centerX: centerX,
      circleCenterY: circleCenterY,
      circleRadius: circleRadius,
      pinHeight: pinHeight,
      color: img.ColorRgba8(211, 47, 47, 255), // Rojo Material Design
    );

    // Círculo blanco interior
    final int innerRadius = (circleRadius * 0.35).toInt();
    img.fillCircle(
      image,
      x: centerX,
      y: circleCenterY,
      radius: innerRadius,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
  }

  /// Dibuja la forma del pin (círculo superior + triángulo inferior)
  void _drawPinShape(
    img.Image image, {
    required int centerX,
    required int circleCenterY,
    required int circleRadius,
    required int pinHeight,
    required img.Color color,
  }) {
    // Círculo superior
    img.fillCircle(
      image,
      x: centerX,
      y: circleCenterY,
      radius: circleRadius,
      color: color,
    );

    // Triángulo inferior (punta del pin)
    final int bottomY = circleCenterY + (pinHeight ~/ 2);
    final int triangleWidth = (circleRadius * 0.8).toInt();

    // Dibujar triángulo línea por línea
    for (int dy = 0; dy < (bottomY - circleCenterY - circleRadius); dy++) {
      final double progress = dy / (bottomY - circleCenterY - circleRadius);
      final int currentWidth = (triangleWidth * (1 - progress)).toInt();
      final int currentY = circleCenterY + circleRadius + dy;

      for (int dx = -currentWidth; dx <= currentWidth; dx++) {
        final int pixelX = centerX + dx;
        final int pixelY = currentY;

        if (pixelX >= 0 &&
            pixelX < image.width &&
            pixelY >= 0 &&
            pixelY < image.height) {
          image.setPixel(pixelX, pixelY, color);
        }
      }
    }
  }
}
