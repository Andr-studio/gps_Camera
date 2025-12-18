import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'camera_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String _statusMessage = 'Verificando permisos...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      setState(() {
        _statusMessage = 'Solicitando permisos de cámara...';
      });

      // Solicitar permisos uno por uno para mejor control
      final cameraStatus = await Permission.camera.request();

      setState(() {
        _statusMessage = 'Solicitando permisos de micrófono...';
      });

      final microphoneStatus = await Permission.microphone.request();

      setState(() {
        _statusMessage = 'Solicitando permisos de ubicación...';
      });

      final locationStatus = await Permission.locationWhenInUse.request();

      setState(() {
        _statusMessage = 'Solicitando permisos de almacenamiento...';
      });

      final photosStatus = await Permission.photos.request();
      final videosStatus = await Permission.videos.request();

      // Verificar si todos los permisos críticos fueron concedidos
      final allGranted = cameraStatus.isGranted &&
          microphoneStatus.isGranted &&
          locationStatus.isGranted &&
          (photosStatus.isGranted || photosStatus.isLimited) &&
          (videosStatus.isGranted || videosStatus.isLimited);

      if (allGranted) {
        // Esperar un momento antes de navegar
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        }
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = 'Permisos necesarios no otorgados';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Error al solicitar permisos: $e';
        _isLoading = false;
      });
    }
  }

  void _retryPermissions() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _statusMessage = 'Verificando permisos...';
    });
    _requestPermissions();
  }

  void _openSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o icono de la app
                const Icon(
                  Icons.camera_alt,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'GPS Photo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),

                // Indicador de carga o error
                if (_isLoading) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (_hasError) ...[
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Esta aplicación necesita los siguientes permisos:\n\n'
                    '• Cámara: Para tomar fotos y videos\n'
                    '• Micrófono: Para grabar audio en videos\n'
                    '• Ubicación: Para agregar datos GPS\n'
                    '• Almacenamiento: Para guardar fotos y videos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _retryPermissions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _openSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Abrir Ajustes'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
