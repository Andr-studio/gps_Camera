/// Configuración centralizada para marcas de agua en fotos y videos
class WatermarkConfig {
  // ============================================
  // CONFIGURACIÓN PARA FOTOS
  // ============================================

  /// Tamaño de fuente para el título en fotos
  static const double photoTitleFontSize = 24.0;

  /// Tamaño de fuente para texto normal en fotos (dirección, coordenadas, fecha)
  static const double photoTextFontSize = 18.0;

  /// Altura del overlay oscuro en fotos
  static const double photoOverlayHeight = 200.0;

  /// Margen izquierdo del texto en fotos
  static const double photoTextMarginLeft = 20.0;

  /// Posición Y del título en fotos (desde abajo)
  static const double photoTitlePositionY = 180.0;

  /// Posición Y de la dirección en fotos (desde abajo)
  static const double photoAddressPositionY = 145.0;

  /// Posición Y de las coordenadas en fotos (desde abajo)
  static const double photoCoordsPositionY = 110.0;

  /// Posición Y de la fecha en fotos (desde abajo)
  static const double photoDatePositionY = 75.0;

  /// Opacidad del fondo oscuro en fotos (0.0 - 1.0)
  static const double photoBackgroundOpacity = 0.6;

  /// Peso de la fuente del título en fotos (w300=light, w400=regular, w500=medium, w700=bold)
  static const int photoTitleFontWeight = 500; // medium

  /// Peso de la fuente del texto en fotos
  static const int photoTextFontWeight = 400; // regular

  // ============================================
  // CONFIGURACIÓN DE MINIMAPA Y BANDERA
  // ============================================

  /// Ancho del minimapa en fotos
  static const int photoMinimapWidth = 120;

  /// Alto del minimapa en fotos
  static const int photoMinimapHeight = 120;

  /// Margen del minimapa desde el borde izquierdo en fotos
  static const int photoMinimapMarginLeft = 10;

  /// Margen del minimapa desde el borde inferior en fotos
  static const int photoMinimapMarginBottom = 10;

  /// Ancho de la bandera en fotos
  static const int photoFlagWidth = 60;

  /// Alto de la bandera en fotos
  static const int photoFlagHeight = 40;

  /// Margen de la bandera desde el borde derecho en fotos
  static const int photoFlagMarginRight = 10;

  /// Margen de la bandera desde el borde superior en fotos
  static const int photoFlagMarginTop = 10;

  // ============================================
  // CONFIGURACIÓN PARA VIDEOS
  // ============================================

  /// Escala general para videos (0.7 = 70% del tamaño de fotos)
  /// Ajusta este valor para hacer la marca de agua más grande o pequeña en videos
  static const double videoScale = 0.7;

  /// Tamaño de fuente base para el título en videos (se multiplica por videoScale)
  static const double videoBaseTitleFontSize = 24.0;

  /// Tamaño de fuente base para texto en videos (se multiplica por videoScale)
  static const double videoBaseTextFontSize = 18.0;

  /// Altura base del overlay en videos (se multiplica por videoScale)
  static const double videoBaseOverlayHeight = 200.0;

  /// Margen base para textos en videos (se multiplica por videoScale)
  static const double videoBaseMargin = 20.0;

  /// Espaciado base entre líneas en videos (se multiplica por videoScale)
  static const double videoBaseLineHeight = 35.0;

  /// Opacidad del fondo oscuro en videos (0.0 - 1.0)
  static const double videoBackgroundOpacity = 0.6;

  // ============================================
  // MÉTODOS DE AYUDA PARA VIDEOS
  // ============================================

  /// Obtiene el tamaño de fuente del título para videos
  static int getVideoTitleFontSize() {
    return (videoBaseTitleFontSize * videoScale).toInt();
  }

  /// Obtiene el tamaño de fuente del texto para videos
  static int getVideoTextFontSize() {
    return (videoBaseTextFontSize * videoScale).toInt();
  }

  /// Obtiene la altura del overlay para videos
  static int getVideoOverlayHeight() {
    return (videoBaseOverlayHeight * videoScale).toInt();
  }

  /// Obtiene el margen izquierdo para videos
  static int getVideoMarginLeft() {
    return (videoBaseMargin * videoScale).toInt();
  }

  /// Obtiene el espaciado entre líneas para videos
  static int getVideoLineHeight() {
    return (videoBaseLineHeight * videoScale).toInt();
  }

  /// Obtiene el margen inferior para videos
  static int getVideoBottomMargin() {
    return (20 * videoScale).toInt();
  }
}
