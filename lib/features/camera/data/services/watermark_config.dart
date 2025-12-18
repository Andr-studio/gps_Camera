/// Configuración centralizada para marcas de agua en fotos y videos
/// El diseño es idéntico al GpsOverlayPreview
class WatermarkConfig {
  // ============================================
  // CONFIGURACIÓN DEL OVERLAY (igual que GpsOverlayPreview)
  // ============================================

  /// Ancho de referencia para cálculo de escala
  /// La escala se calcula como: imageWidth / referenceWidth
  static const double referenceWidth = 720.0;

  /// Altura base del overlay (se multiplica por escala)
  static const double baseOverlayHeight = 200.0;

  /// Margen base alrededor del contenido (se multiplica por escala)
  static const double baseMargin = 10.0;

  /// Ancho base del minimapa (se multiplica por escala)
  static const double baseMinimapWidth = 130.0;

  /// Espacio entre minimapa y texto (se multiplica por escala)
  static const double baseMinimapTextGap = 15.0;

  // ============================================
  // TAMAÑOS DE FUENTE BASE (se multiplican por escala)
  // ============================================

  /// Tamaño de fuente para el título
  static const double baseTitleFontSize = 18.0;

  /// Tamaño de fuente para texto normal (dirección, coordenadas, fecha)
  static const double baseTextFontSize = 11.0;

  // ============================================
  // COLORES
  // ============================================

  /// Opacidad del fondo oscuro (0-255)
  /// Color: ARGB(150, 3, 3, 3)
  static const int backgroundAlpha = 150;

  // ============================================
  // MÉTODOS DE AYUDA
  // ============================================

  /// Calcula la escala basada en el ancho de la imagen
  static double getScale(int imageWidth) {
    return imageWidth / referenceWidth;
  }

  /// Obtiene la altura del overlay para una imagen
  static double getOverlayHeight(int imageWidth) {
    return baseOverlayHeight * getScale(imageWidth);
  }

  /// Obtiene el margen para una imagen
  static double getMargin(int imageWidth) {
    return baseMargin * getScale(imageWidth);
  }

  /// Obtiene el ancho del minimapa para una imagen
  static double getMinimapWidth(int imageWidth) {
    return baseMinimapWidth * getScale(imageWidth);
  }
}
