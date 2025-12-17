import 'package:geocoding/geocoding.dart';
import '../models/location_data.dart';

class GeocodingService {
  /// Obtiene la dirección completa a partir de coordenadas
  Future<LocationData> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Construir dirección completa
        final List<String> addressParts = [
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.postalCode != null && place.postalCode!.isNotEmpty)
            place.postalCode!,
          if (place.country != null && place.country!.isNotEmpty)
            place.country!,
        ];

        return LocationData(
          latitude: latitude,
          longitude: longitude,
          city: place.locality,
          state: place.administrativeArea,
          country: place.country,
          countryCode: place.isoCountryCode,
          street: place.street,
          postalCode: place.postalCode,
          fullAddress: addressParts.join(', '),
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error en geocodificación: $e');
    }

    return LocationData(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }
}
