import 'dart:typed_data';
import '../models/location_data.dart';
import '../services/camera_service.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/map_service.dart';
import '../services/weather_service.dart';
import '../services/flag_service.dart';
import '../services/watermark_service.dart';
import '../services/video_watermark_service.dart';
import '../services/gallery_service.dart';

class PhotoRepository {
  final CameraService _cameraService;
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final MapService _mapService;
  final WeatherService _weatherService;
  final FlagService _flagService;
  final WatermarkService _watermarkService;
  final VideoWatermarkService _videoWatermarkService;
  final GalleryService _galleryService;

  PhotoRepository({
    required CameraService cameraService,
    required LocationService locationService,
    required GeocodingService geocodingService,
    required MapService mapService,
    required WeatherService weatherService,
    required FlagService flagService,
    required WatermarkService watermarkService,
    required VideoWatermarkService videoWatermarkService,
    required GalleryService galleryService,
  })  : _cameraService = cameraService,
        _locationService = locationService,
        _geocodingService = geocodingService,
        _mapService = mapService,
        _weatherService = weatherService,
        _flagService = flagService,
        _watermarkService = watermarkService,
        _videoWatermarkService = videoWatermarkService,
        _galleryService = galleryService;

  Future<bool> captureAndSavePhoto() async {
    try {
      // 1. OBTENER COORDENADAS GPS
      final position = await _locationService.getCurrentPosition();
      if (position == null) return false;

      // 2. OBTENER DIRECCIÓN (Geocodificación inversa)
      final LocationData locationData =
          await _geocodingService.getAddressFromCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // 3. DESCARGAR RECURSOS EN PARALELO
      final results = await Future.wait([
        // Minimapa
        _mapService.downloadMapImage(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        // Clima
        _weatherService.getCurrentWeather(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        // Bandera
        if (locationData.countryCode != null)
          _flagService.downloadFlag(locationData.countryCode!)
        else
          Future.value(null),
      ]);

      final Uint8List? minimapBytes = results[0] as Uint8List?;
      final WeatherData? weather = results[1] as WeatherData?;
      final Uint8List? flagBytes =
          results.length > 2 ? results[2] as Uint8List? : null;

      // Descargar icono del clima si existe
      Uint8List? weatherIconBytes;
      if (weather != null) {
        weatherIconBytes =
            await _weatherService.downloadWeatherIcon(weather.iconCode);
      }

      // 4. CAPTURAR FOTO
      final photo = await _cameraService.takePicture();
      if (photo == null) return false;

      // 5. APLICAR MARCA DE AGUA CON GOOGLE FONTS (soporta UTF-8 completo)
      final Uint8List? watermarkedImage =
          await _watermarkService.applyWatermarkToPhoto(
        imagePath: photo.path,
        locationData: locationData,
        minimapBytes: minimapBytes,
        flagBytes: flagBytes,
        weatherData: weather,
        weatherIconBytes: weatherIconBytes,
      );

      if (watermarkedImage == null) return false;

      // 6. COMPRIMIR Y GUARDAR
      final fileName = 'GPS_PHOTO_${DateTime.now().millisecondsSinceEpoch}';
      return await _galleryService.compressAndSave(
        imageBytes: watermarkedImage,
        fileName: fileName,
      );
    } catch (e) {
      print('Error en captureAndSavePhoto: $e');
      return false;
    }
  }
}
