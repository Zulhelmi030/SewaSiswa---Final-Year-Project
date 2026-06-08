import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  final SupabaseClient _supabaseClient;
  static const String _bucketName = 'listing-images';

  ImageService(this._supabaseClient);

  /// Uploads a single image to Supabase Storage and returns its public URL.
  /// Returns null if the upload fails.
  Future<String?> uploadListingImage(File imageFile) async {
    try {
      // Use milliseconds + random suffix to avoid filename collisions
      final random = Random().nextInt(999999).toString().padLeft(6, '0');
      final ext = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$random.$ext';
      final filePath = 'listings/$fileName';

      await _supabaseClient.storage
          .from(_bucketName)
          .upload(filePath, imageFile);

      final publicUrl = _supabaseClient.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
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
