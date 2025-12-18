/// Configuración centralizada para marcas de agua en fotos y videos
/// El diseño es idéntico al GpsOverlayPreview
///
/// INSTRUCCIONES: Modifica estos valores para personalizar la marca de agua
class WatermarkConfig {
  // ============================================
  // CONFIGURACIÓN DEL OVERLAY
  // ============================================

  /// Ancho de referencia para cálculo de escala
  /// La escala se calcula como: imageWidth / referenceWidth
  static const double referenceWidth = 720.0;

  /// Altura base del overlay (se multiplica por escala)
  /// Aumenta este valor para hacer el overlay más alto
  static const double baseOverlayHeight = 200.0;

  /// Margen base alrededor del contenido (se multiplica por escala)
  static const double baseMargin = 10.0;

  /// Ancho base del minimapa (se multiplica por escala)
  static const double baseMinimapWidth = 130.0;

  /// Espacio entre minimapa y texto (se multiplica por escala)
  static const double baseMinimapTextGap = 15.0;

  // ============================================
  // TAMAÑOS DE FUENTE (se multiplican por escala)
  // ============================================

  /// Tamaño de fuente para el título (Ciudad, País)
  /// Valor recomendado: 16-24
  static const double baseTitleFontSize = 24.0;

  /// Tamaño de fuente para texto normal (dirección, coordenadas, fecha)
  /// Valor recomendado: 10-14
  static const double baseTextFontSize = 24.0;

  // ============================================
  // COLORES DEL FONDO
  // ============================================

  /// Color del fondo - componente Rojo (0-255)
  static const int backgroundRed = 3;

  /// Color del fondo - componente Verde (0-255)
  static const int backgroundGreen = 3;

  /// Color del fondo - componente Azul (0-255)
  static const int backgroundBlue = 3;

  /// Opacidad/transparencia del fondo (0-255)
  /// 0 = completamente transparente, 255 = completamente opaco
  /// Valor actual: 150 (semi-transparente)
  static const int backgroundAlpha = 150;

  // ============================================
  // COLORES DEL TEXTO
  // ============================================

  /// Color del texto del título - Rojo (0-255)
  static const int titleTextRed = 255;

  /// Color del texto del título - Verde (0-255)
  static const int titleTextGreen = 255;

  /// Color del texto del título - Azul (0-255)
  static const int titleTextBlue = 255;

  /// Color del texto normal - Rojo (0-255)
  static const int normalTextRed = 255;

  /// Color del texto normal - Verde (0-255)
  static const int normalTextGreen = 255;

  /// Color del texto normal - Azul (0-255)
  static const int normalTextBlue = 255;

  // ============================================
  // SOMBRA DEL TEXTO
  // ============================================

  /// Opacidad de la sombra del título (0.0-1.0)
  static const double titleShadowOpacity = 0.5;

  /// Radio de difuminado de la sombra
  static const double shadowBlurRadius = 2.0;

  // ============================================
  // ESPACIADO ENTRE LÍNEAS (se multiplican por escala)
  // ============================================

  /// Espacio después del título
  static const double spacingAfterTitle = 26.0;

  /// Espacio para las líneas de dirección (2 líneas)
  static const double spacingAfterAddress = 56.0;

  /// Espacio después de las coordenadas
  static const double spacingAfterCoords = 24.0;

  // ============================================
  // MINIMAPA
  // ============================================

  /// Tamaño del pin de ubicación (se multiplica por escala)
  static const double pinSize = 26.0;

  /// Tamaño de fuente del texto "Google" en el minimapa
  static const double googleTextFontSize = 11.0;

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
