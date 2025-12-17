import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Retorna la posición actual o null si hay error
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Formatea coordenadas como string
  String formatCoordinates(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, '
        'Lon: ${position.longitude.toStringAsFixed(6)}';
  }
}
