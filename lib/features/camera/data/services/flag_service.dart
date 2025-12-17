import 'dart:typed_data';
import 'package:http/http.dart' as http;

class FlagService {
  /// Obtiene la URL de la bandera del país
  String getFlagUrl(String countryCode, {int width = 80}) {
    // Usando flagcdn.com (gratuito)
    return 'https://flagcdn.com/w$width/${countryCode.toLowerCase()}.png';
  }

  /// Descarga la imagen de la bandera
  Future<Uint8List?> downloadFlag(String countryCode) async {
    try {
      final url = getFlagUrl(countryCode);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error descargando bandera: $e');
    }
    return null;
  }
}
