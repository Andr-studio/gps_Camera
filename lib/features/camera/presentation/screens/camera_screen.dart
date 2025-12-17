import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/camera_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/geocoding_service.dart';
import '../../data/services/map_service.dart';
import '../../data/services/weather_service.dart';
import '../../data/services/flag_service.dart';
import '../../data/services/watermark_service.dart';
import '../../data/services/gallery_service.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/models/location_data.dart';
import '../widgets/camera_preview.dart';
import '../widgets/capture_button.dart';
import '../widgets/gps_overlay_preview.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraService _cameraService;
  late PhotoRepository _photoRepository;
  late LocationService _locationService;
  late GeocodingService _geocodingService;
  late MapService _mapService;
  late FlagService _flagService;

  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;

  // Datos para la vista previa
  LocationData? _currentLocationData;
  Uint8List? _minimapBytes;
  Uint8List? _flagBytes;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _startLocationUpdates();
  }

  Future<void> _initializeServices() async {
    _cameraService = CameraService();
    await _cameraService.initialize();

    _locationService = LocationService();
    _geocodingService = GeocodingService();
    _mapService = MapService();
    _flagService = FlagService();

    _photoRepository = PhotoRepository(
      cameraService: _cameraService,
      locationService: _locationService,
      geocodingService: _geocodingService,
      mapService: _mapService,
      weatherService: WeatherService(),
      flagService: _flagService,
      watermarkService: WatermarkService(),
      galleryService: GalleryService(),
    );

    setState(() => _isInitialized = true);
  }

  /// Actualiza la ubicación cada 5 segundos
  Future<void> _startLocationUpdates() async {
    while (mounted) {
      await _updateLocation();
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _updateLocation() async {
    try {
      final Position? position = await _locationService.getCurrentPosition();

      if (position != null) {
        final LocationData locationData =
            await _geocodingService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        final results = await Future.wait([
          _mapService.downloadMapImage(
            latitude: position.latitude,
            longitude: position.longitude,
            width: 130,
            height: 180,
          ),
          if (locationData.countryCode != null)
            _flagService.downloadFlag(locationData.countryCode!)
          else
            Future.value(null),
        ]);

        if (mounted) {
          setState(() {
            _currentLocationData = locationData;
            _minimapBytes = results[0] as Uint8List?;
            _flagBytes = results.length > 1 ? results[1] as Uint8List? : null;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Error actualizando ubicación: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || _isRecording) return;

    setState(() => _isCapturing = true);

    final success = await _photoRepository.captureAndSavePhoto();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(success
                  ? '✓ Foto guardada en Galería'
                  : '✗ Error al guardar'),
            ],
          ),
          backgroundColor:
              success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() => _isCapturing = false);
    }
  }

  /// Alterna entre iniciar y detener la grabación de video
  Future<void> _toggleVideoRecording() async {
    if (_isCapturing) return;

    if (!_isRecording) {
      // Iniciar grabación
      try {
        await _cameraService.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
        _startRecordingTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Grabación iniciada'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al iniciar grabación: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    } else {
      // Detener grabación
      try {
        final video = await _cameraService.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });

        if (video != null) {
          // Guardar el video en la galería
          await Gal.putVideo(video.path);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('✓ Video guardado en Galería'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _isRecording = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al detener grabación: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  /// Timer para mostrar la duración de la grabación
  void _startRecordingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration += const Duration(seconds: 1);
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _openGallery() async {
    try {
      // 1. Identificar si es Android 13 o superior (API 33+)
      // El S25+ es Android 14, por lo que requiere permisos específicos.

      bool granted = false;

      // Solicitamos los permisos específicos de medios
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
      ].request();

      granted = statuses[Permission.photos]!.isGranted ||
          statuses[Permission.videos]!.isGranted;

      // 2. Manejo de "Acceso Limitado" (Característica de Android 14)
      if (statuses[Permission.photos]!.isLimited) {
        granted = true; // El usuario eligió solo algunas fotos
      }

      if (!granted) {
        if (mounted) {
          _showPermissionDialog(); // Función auxiliar para guiar al usuario
        }
        return;
      }

      // 3. Abrir la galería
      await Gal.open();
    } catch (e) {
      print('Error en galería: $e');

      if (mounted) {
        // Si falla, mostrar diálogo con opciones
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Acceso a galería'),
            content: const Text(
                'Abre la aplicación "Galería" o "Fotos" de tu dispositivo para ver las imágenes guardadas.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Abrir configuración'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Text(
          'Para ver tus fotos, la app necesita permiso para acceder a la galería. '
          'Por favor, habilítalo en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Abre la configuración de la app en el teléfono
            },
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
  }

  /// Formatea la duración en formato MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? Stack(
                children: [
                  // Preview de la cámara
                  Positioned.fill(
                    child: CameraPreviewWidget(
                      controller: _cameraService.controller!,
                    ),
                  ),

                  // Indicador de carga de GPS
                  if (_isLoadingLocation)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Obteniendo GPS...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Indicador GPS activo
                  if (!_isLoadingLocation && _currentLocationData != null && !_isRecording)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'GPS Activo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Indicador de grabación
                  if (_isRecording)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.fiber_manual_record,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'GRABANDO ${_formatDuration(_recordingDuration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Overlay GPS en tiempo real
                  if (_currentLocationData != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 120,
                      child: GpsOverlayPreview(
                        locationData: _currentLocationData!,
                        minimapBytes: _minimapBytes,
                        flagBytes: _flagBytes,
                      ),
                    ),

                  // Controles inferiores
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botón de galería
                        if (!_isRecording)
                          GestureDetector(
                            onTap: _openGallery,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                        if (!_isRecording) const SizedBox(width: 40),

                        // Botón de captura de foto (solo visible si no está grabando)
                        if (!_isRecording)
                          CaptureButton(
                            onPressed: _capturePhoto,
                            isLoading: _isCapturing,
                          ),

                        // Botón de grabación de video (siempre visible)
                        if (_isRecording)
                          GestureDetector(
                            onTap: _toggleVideoRecording,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),

                        if (!_isRecording) const SizedBox(width: 40),

                        // Botón de video (solo visible si no está grabando)
                        if (!_isRecording)
                          GestureDetector(
                            onTap: _toggleVideoRecording,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white70,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Inicializando cámara...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
