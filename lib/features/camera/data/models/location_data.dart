// lib/features/camera/data/models/location_data.dart

class LocationData {
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;
  final String? countryCode;
  final String? street;
  final String? postalCode;
  final String? fullAddress;
  final DateTime timestamp;
  final double? temperature;
  final String? weatherIcon;
  final String? weatherDescription;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
    this.countryCode,
    this.street,
    this.postalCode,
    this.fullAddress,
    required this.timestamp,
    this.temperature,
    this.weatherIcon,
    this.weatherDescription,
  });

  String get formattedCoordinates =>
      'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}';

  /// Título sin duplicados: "Antofagasta, Chile"
  String get locationTitle {
    final List<String> parts = [];

    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }

    // Agregar estado SOLO si es diferente a ciudad
    if (state != null &&
        state!.isNotEmpty &&
        state!.toLowerCase() != city?.toLowerCase()) {
      parts.add(state!);
    }

    if (country != null && country!.isNotEmpty) {
      parts.add(country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Ubicación desconocida';
  }

  String get addressLine => fullAddress ?? 'Dirección no disponible';
}
