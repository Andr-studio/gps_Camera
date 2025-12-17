import 'dart:typed_data';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class MapService {
  /// Descarga imagen del minimapa con proveedores fallback
  Future<Uint8List?> downloadMapImage({
    required double latitude,
    required double longitude,
    int zoom = 16,
    int width = 300,
    int height = 200,
  }) async {
    // Intentar OpenStreetMap Tiles primero
    try {
      final result =
          await _downloadOsmTile(latitude, longitude, zoom, width, height);
      if (result != null) {
        return result;
      }
    } catch (e) {
      print('OSM Tiles falló: $e');
    }

    // Último recurso: placeholder
    return _generatePlaceholder(latitude, longitude, width, height);
  }

  /// Descarga un tile de OSM y lo procesa
  Future<Uint8List?> _downloadOsmTile(
    double lat,
    double lon,
    int zoom,
    int targetWidth,
    int targetHeight,
  ) async {
    try {
      // Calcular coordenadas del tile
      final tileX = _lonToTileX(lon, zoom);
      final tileY = _latToTileY(lat, zoom);

      // URL del tile de OpenStreetMap
      final url = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'GPSPhotoApp/1.0',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && _isValidImage(response.bodyBytes)) {
        // Decodificar tile
        img.Image? tile = img.decodePng(response.bodyBytes);
        if (tile == null) return null;

        // Redimensionar al tamaño deseado
        tile = img.copyResize(tile, width: targetWidth, height: targetHeight);

        // Añadir marcador central
        _addMarker(tile);

        return Uint8List.fromList(img.encodePng(tile));
      }
    } catch (e) {
      print('Error descargando tile OSM: $e');
    }
    return null;
  }

  /// Genera un placeholder visual con coordenadas
  Uint8List? _generatePlaceholder(
    double lat,
    double lon,
    int width,
    int height,
  ) {
    try {
      // Crear imagen base
      final image = img.Image(width: width, height: height);

      // Fondo gris azulado (estilo mapa)
      img.fill(image, color: img.ColorRgba8(200, 210, 220, 255));

      // Cuadrícula de mapa
      _drawGrid(image);

      // Marcador rojo central
      _addMarker(image);

      // Texto de coordenadas
      img.drawString(
        image,
        '${lat.toStringAsFixed(4)}',
        font: img.arial14,
        x: 8,
        y: height - 35,
        color: img.ColorRgba8(60, 60, 60, 255),
      );

      img.drawString(
        image,
        '${lon.toStringAsFixed(4)}',
        font: img.arial14,
        x: 8,
        y: height - 20,
        color: img.ColorRgba8(60, 60, 60, 255),
      );

      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      print('Error generando placeholder: $e');
      return null;
    }
  }

  /// Dibuja cuadrícula en la imagen
  void _drawGrid(img.Image image) {
    final paint = img.ColorRgba8(180, 190, 200, 255);

    // Líneas verticales
    for (int x = 0; x < image.width; x += 25) {
      for (int y = 0; y < image.height; y++) {
        if (x < image.width) {
          image.setPixel(x, y, paint);
        }
      }
    }

    // Líneas horizontales
    for (int y = 0; y < image.height; y += 25) {
      for (int x = 0; x < image.width; x++) {
        if (y < image.height) {
          image.setPixel(x, y, paint);
        }
      }
    }
  }

  /// Añade marcador rojo al centro de la imagen
  void _addMarker(img.Image image) {
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final radius = 12;

    // Sombra
    img.fillCircle(
      image,
      x: centerX + 2,
      y: centerY + 2,
      radius: radius,
      color: img.ColorRgba8(0, 0, 0, 100),
    );

    // Pin rojo
    img.fillCircle(
      image,
      x: centerX,
      y: centerY,
      radius: radius,
      color: img.ColorRgba8(220, 50, 50, 255),
    );

    // Centro blanco
    img.fillCircle(
      image,
      x: centerX,
      y: centerY,
      radius: radius ~/ 3,
      color: img.ColorRgba8(255, 255, 255, 255),
    );
  }

  /// Convierte longitud a coordenada X del tile
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convierte latitud a coordenada Y del tile
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 -
                math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
            2.0 *
            (1 << zoom))
        .floor();
  }

  /// Verifica si los bytes son una imagen válida
  bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 8) return false;

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    return false;
  }
}
