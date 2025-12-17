import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import '../../../../core/constants/app_constants.dart';

class GalleryService {
  Future<bool> compressAndSave({
    required Uint8List imageBytes,
    required String fileName,
    int quality = AppConstants.jpegQuality,
  }) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return false;

      // Redimensionar si es necesario
      if (image.width > AppConstants.maxImageDimension ||
          image.height > AppConstants.maxImageDimension) {
        image = img.copyResize(
          image,
          width: image.width > image.height
              ? AppConstants.maxImageDimension
              : null,
          height: image.height >= image.width
              ? AppConstants.maxImageDimension
              : null,
        );
      }

      final compressed =
          Uint8List.fromList(img.encodeJpg(image, quality: quality));
      await Gal.putImageBytes(compressed, name: fileName);

      return true;
    } catch (e) {
      return false;
    }
  }
}
