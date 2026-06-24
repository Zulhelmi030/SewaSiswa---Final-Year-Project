import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  final SupabaseClient _supabaseClient;
  static const String _bucketName = 'listing-images';

  ImageService(this._supabaseClient);

  //Compress image
  //lossless compression
  Future<Uint8List?> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      format: CompressFormat.webp,
      quality: 80, //best compression ratio
      minWidth: 1920, //max width of image
      minHeight: 1080, //max height of image
    );
    return result;
  }

  /// Uploads a single image to Supabase Storage and returns its public URL.
  /// Returns null if the upload fails.
  Future<String?> uploadListingImage(File imageFile) async {
    try {
      // Use milliseconds + random suffix to avoid filename collisions
      final random = Random().nextInt(999999).toString().padLeft(6, '0');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$random.webp';
      
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Error: User not logged in');
        return null;
      }
      final filePath = '$userId/$fileName';
      debugPrint('Uploading image: ${imageFile.path}');
      final compressedImage = await compressImage(imageFile);
      if (compressedImage == null) {
        debugPrint('Error compressing image: returned null');
        return null;
      }
      debugPrint('Compressed image size: ${compressedImage.lengthInBytes} bytes');

      final uploadPath = await _supabaseClient.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            compressedImage,
            fileOptions: const FileOptions(contentType: 'image/webp'),
          );
      debugPrint('Supabase upload successful. Path: $uploadPath');

      final publicUrl = _supabaseClient.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      debugPrint('Generated public URL: $publicUrl');

      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('Error uploading image: $e');
      debugPrint('Stacktrace: $stackTrace');
      return null;
    }
  }

  /// Uploads a payment receipt to the dedicated 'receipts' bucket
  /// Supports both Images (compressed to webp) and PDFs (uploaded directly)
  Future<String?> uploadReceiptImage(File file) async {
    try {
      final random = Random().nextInt(999999).toString().padLeft(6, '0');
      final ext = file.path.split('.').last.toLowerCase();

      String fileName;
      Uint8List bytesToUpload;
      String contentType;

      if (ext == 'pdf') {
        fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}_$random.pdf';
        bytesToUpload = await file.readAsBytes();
        contentType = 'application/pdf';
      } else {
        fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}_$random.webp';
        final compressedImage = await compressImage(file);
        if (compressedImage == null) return null;
        bytesToUpload = compressedImage;
        contentType = 'image/webp';
      }

      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Error: User not logged in');
        return null;
      }
      
      final filePath = '$userId/$fileName';

      await _supabaseClient.storage
          .from('receipts')
          .uploadBinary(
            filePath,
            bytesToUpload,
            fileOptions: FileOptions(contentType: contentType),
          );

      return _supabaseClient.storage.from('receipts').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error uploading receipt: $e');
      return null;
    }
  }

  /// Uploads multiple images sequentially and returns a list of successful URLs.
  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadListingImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// Deletes an image from Supabase Storage by its public URL.
  /// Returns true if deletion was successful.
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Guard: ensure bucket name exists in the URL
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1) {
        debugPrint(
          'Error deleting image: bucket "$_bucketName" not found in URL: $imageUrl',
        );
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabaseClient.storage.from(_bucketName).remove([filePath]);

      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}
