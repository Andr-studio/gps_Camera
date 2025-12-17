import 'package:image/image.dart' as img;

/// ============================================================
/// CONFIGURACIÓN DE MARCA DE AGUA - AJUSTES RÁPIDOS
/// ============================================================
/// Este archivo permite modificar fácilmente los parámetros
/// de la marca de agua para VIDEOS y FOTOS de forma separada.
/// ============================================================

// ************************************************************
// CONFIGURACIÓN PARA VIDEOS
// ************************************************************
class VideoWatermarkConfig {
  // ----------------------------------------------------------
  // ESCALA DEL OVERLAY
  // ----------------------------------------------------------
  /// Escala del overlay de video (0.0 a 1.0)
  /// Valores recomendados:
  /// - 0.30 = 30% (muy pequeño, discreto)
  /// - 0.40 = 40% (actual, discreto)
  /// - 0.50 = 50% (mediano)
  /// - 0.60 = 60% (visible)
  /// - 0.70 = 70% (grande)
  static const double overlayScale = 0.40;

  // ----------------------------------------------------------
  // COLOR DEL FONDO
  // ----------------------------------------------------------
  /// Color del fondo del overlay (RGB)
  /// Valores: 0-255 para cada componente
  static const int backgroundRed = 3;
  static const int backgroundGreen = 3;
  static const int backgroundBlue = 3;

  /// Opacidad del fondo (0-255)
  /// - 0 = completamente transparente
  /// - 128 = 50% opaco
  /// - 150 = ~59% opaco (actual)
  /// - 200 = ~78% opaco
  /// - 255 = completamente sólido
  static const int backgroundAlpha = 150;

  // ----------------------------------------------------------
  // POSICIÓN DEL OVERLAY EN EL VIDEO
  // ----------------------------------------------------------
  /// Margen desde los bordes del video (en píxeles)
  static const int marginFromEdge = 10;

  // ----------------------------------------------------------
  // RESOLUCIÓN BASE DEL VIDEO
  // ----------------------------------------------------------
  /// Resolución de referencia para crear el overlay
  static const int baseVideoWidth = 1920;
  static const int baseVideoHeight = 1080;

  // ----------------------------------------------------------
  // MÉTODOS AUXILIARES
  // ----------------------------------------------------------
  /// Retorna el color del fondo como ColorRgba8
  static img.Color get backgroundColor =>
      img.ColorRgba8(backgroundRed, backgroundGreen, backgroundBlue, backgroundAlpha);
}

// ************************************************************
// CONFIGURACIÓN PARA FOTOS
// ************************************************************
class PhotoWatermarkConfig {
  // ----------------------------------------------------------
  // ESCALA BASE
  // ----------------------------------------------------------
  /// Ancho de referencia para calcular la escala
  /// La escala se calcula como: anchoImagen / referenceWidth
  static const double referenceWidth = 720.0;

  // ----------------------------------------------------------
  // DIMENSIONES DEL OVERLAY
  // ----------------------------------------------------------
  /// Altura del overlay en píxeles (antes de escalar)
  /// Se multiplica por la escala: overlayBaseHeight * scale
  static const int overlayBaseHeight = 200;

  /// Margen interno del overlay (antes de escalar)
  static const int baseMargin = 10;

  // ----------------------------------------------------------
  // COLOR DEL FONDO
  // ----------------------------------------------------------
  /// Color del fondo del overlay (RGB)
  static const int backgroundRed = 3;
  static const int backgroundGreen = 3;
  static const int backgroundBlue = 3;

  /// Opacidad del fondo (0-255)
  static const int backgroundAlpha = 150;

  // ----------------------------------------------------------
  // TAMAÑOS DE FUENTE
  // ----------------------------------------------------------
  /// Fuente para texto pequeño (Google en mapa, etc.)
  /// Opciones disponibles: img.arial14, img.arial24, img.arial48
  static img.BitmapFont get smallFont => img.arial14;

  /// Fuente para texto principal (título, dirección, coordenadas, fecha)
  /// Opciones disponibles: img.arial14, img.arial24, img.arial48
  static img.BitmapFont get mainFont => img.arial24;

  // ----------------------------------------------------------
  // ESPACIADO DE LÍNEAS
  // ----------------------------------------------------------
  /// Espaciado entre líneas de texto (antes de escalar)
  static const int lineSpacing = 26;

  /// Espaciado después del título (antes de escalar)
  static const int titleSpacing = 15;

  /// Altura de línea para dirección (antes de escalar)
  static const int addressLineHeight = 30;

  /// Espacio antes de coordenadas (antes de escalar)
  static const int coordsSpacing = 10;

  // ----------------------------------------------------------
  // COLORES DE TEXTO
  // ----------------------------------------------------------
  /// Color del texto principal (blanco)
  static const int textRed = 255;
  static const int textGreen = 255;
  static const int textBlue = 255;
  static const int textAlpha = 255;

  /// Color de la sombra del texto
  static const int shadowRed = 0;
  static const int shadowGreen = 0;
  static const int shadowBlue = 0;
  static const int shadowAlpha = 128; // 50% opacidad

  // ----------------------------------------------------------
  // MINIMAPA
  // ----------------------------------------------------------
  /// Tamaño base del minimapa (antes de escalar)
  static const int mapBaseSize = 130;

  // ----------------------------------------------------------
  // MÉTODOS AUXILIARES
  // ----------------------------------------------------------
  /// Retorna el color del fondo como ColorRgba8
  static img.Color get backgroundColor =>
      img.ColorRgba8(backgroundRed, backgroundGreen, backgroundBlue, backgroundAlpha);

  /// Retorna el color del texto principal
  static img.Color get textColor =>
      img.ColorRgba8(textRed, textGreen, textBlue, textAlpha);

  /// Retorna el color de la sombra
  static img.Color get shadowColor =>
      img.ColorRgba8(shadowRed, shadowGreen, shadowBlue, shadowAlpha);
}
