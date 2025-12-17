import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/location_data.dart';

class GpsOverlayPreview extends StatelessWidget {
  final LocationData locationData;
  final Uint8List? minimapBytes;
  final Uint8List? flagBytes;

  const GpsOverlayPreview({
    super.key,
    required this.locationData,
    this.minimapBytes,
    this.flagBytes,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 720.0;

    final overlayHeight = 200.0 * scale;
    final margin = 10.0 * scale;

    // Overlay principal SIN badge flotante
    return Container(
      height: overlayHeight,
      width: screenWidth,
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 3, 3, 3).withAlpha(150),
      ),
      child: Padding(
        padding: EdgeInsets.all(margin),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MINIMAPA REAL O PLACEHOLDER
            _buildMinimap(scale, margin, overlayHeight),

            SizedBox(width: 15 * scale),

            // Área de texto
            Expanded(
              child: _buildTextArea(scale),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el minimapa con la imagen real descargada
  Widget _buildMinimap(double scale, double margin, double overlayHeight) {
    final mapWidth = 130.0 * scale;
    final mapHeight = overlayHeight - margin * 2;

    return SizedBox(
      width: mapWidth,
      height: mapHeight,
      child: Stack(
        children: [
          // Imagen del mapa o placeholder
          if (minimapBytes != null)
            ClipRect(
              child: Image.memory(
                minimapBytes!,
                width: mapWidth,
                height: mapHeight,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              color: Colors.grey[300],
              child: CustomPaint(
                painter: _MapGridPainter(),
              ),
            ),

          // Pin rojo central
          Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.red[700],
                size: 26 * scale,
              ),
            ),
          ),

          // Texto "Google" en la esquina inferior
          Positioned(
            bottom: 4 * scale,
            left: 4 * scale,
            child: Text(
              'Google',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11 * scale,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(0.5, 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el área de texto
  Widget _buildTextArea(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Título: Ciudad, País + bandera emoji
        Row(
          children: [
            Flexible(
              child: Text(
                locationData.locationTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (locationData.countryCode != null) ...[
              SizedBox(width: 6 * scale),
              Text(
                _getCountryFlag(locationData.countryCode!),
                style: TextStyle(fontSize: 16 * scale),
              ),
            ],
          ],
        ),

        SizedBox(height: 6 * scale),

        // Dirección (máximo 2 líneas)
        Text(
          locationData.addressLine,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11 * scale,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: 5 * scale),

        // Coordenadas
        Text(
          'Lat ${locationData.latitude.toStringAsFixed(6)}  '
          'Long ${locationData.longitude.toStringAsFixed(6)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11 * scale,
          ),
        ),

        SizedBox(height: 5 * scale),

        // Fecha y hora
        Text(
          _formatDateTime(locationData.timestamp),
          style: TextStyle(
            color: Colors.white,
            fontSize: 11 * scale,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
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

  String _getCountryFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';

    final int firstLetter =
        countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter =
        countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }
}

/// Painter para simular cuadrícula de mapa (cuando no hay imagen)
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
