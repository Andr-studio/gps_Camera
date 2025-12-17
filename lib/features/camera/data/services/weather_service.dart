import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String description;
  final String iconCode;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.iconCode,
  });

  /// URL del icono del clima
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}

class WeatherService {
  // API Key gratuita de OpenWeatherMap (registrarse en openweathermap.org)
  // IMPORTANTE: Reemplazar con tu propia API key
  static const String _apiKey = 'cd6c6917bee7cfe56f7f79828199afd1';

  Future<WeatherData?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=$latitude'
        '&lon=$longitude'
        '&appid=$_apiKey'
        '&units=metric'
        '&lang=es',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return WeatherData(
          temperature: (data['main']['temp'] as num).toDouble(),
          description: data['weather'][0]['description'],
          iconCode: data['weather'][0]['icon'],
        );
      }
    } catch (e) {
      print('Error obteniendo clima: $e');
    }
    return null;
  }

  /// Descarga el icono del clima como bytes
  Future<Uint8List?> downloadWeatherIcon(String iconCode) async {
    try {
      final url = 'https://openweathermap.org/img/wn/$iconCode@2x.png';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('Error descargando icono: $e');
    }
    return null;
  }
}
