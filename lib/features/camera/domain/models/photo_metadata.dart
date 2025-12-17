class PhotoMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final String filePath;

  PhotoMetadata({
    this.latitude,
    this.longitude,
    required this.capturedAt,
    required this.filePath,
  });

  String get formattedCoordinates {
    if (latitude == null || longitude == null) {
      return 'GPS no disponible';
    }
    return 'Lat: ${latitude!.toStringAsFixed(6)}, Lon: ${longitude!.toStringAsFixed(6)}';
  }
}
