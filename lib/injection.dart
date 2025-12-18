import 'package:get_it/get_it.dart';
import 'features/camera/data/services/camera_service.dart';
import 'features/camera/data/services/location_service.dart';
import 'features/camera/data/services/geocoding_service.dart';
import 'features/camera/data/services/map_service.dart';
import 'features/camera/data/services/weather_service.dart';
import 'features/camera/data/services/flag_service.dart';
import 'features/camera/data/services/watermark_service.dart';
import 'features/camera/data/services/video_watermark_service.dart';
import 'features/camera/data/services/gallery_service.dart';
import 'features/camera/data/repositories/photo_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerLazySingleton(() => CameraService());
  getIt.registerLazySingleton(() => LocationService());
  getIt.registerLazySingleton(() => GeocodingService());
  getIt.registerLazySingleton(() => MapService());
  getIt.registerLazySingleton(() => WeatherService());
  getIt.registerLazySingleton(() => FlagService());
  getIt.registerLazySingleton(() => WatermarkService());
  getIt.registerLazySingleton(() => VideoWatermarkService());
  getIt.registerLazySingleton(() => GalleryService());

  // Repositories
  getIt.registerLazySingleton(() => PhotoRepository(
        cameraService: getIt(),
        locationService: getIt(),
        geocodingService: getIt(),
        mapService: getIt(),
        weatherService: getIt(),
        flagService: getIt(),
        watermarkService: getIt(),
        videoWatermarkService: getIt(),
        galleryService: getIt(),
      ));
}
