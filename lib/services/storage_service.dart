import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String folder = 'widget_gifs';

  // Upload a GIF or image (supports all image formats)
  Future<String> uploadGif(Uint8List fileBytes, String fileName) async {
    try {
      // Sanitize the file name and make it unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final uniqueFileName = '${timestamp}_$cleanFileName';

      // Determine the content type from the file extension
      String contentType = 'image/gif';
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
      }

      // Create the storage reference
      final ref = _storage.ref().child('$folder/$uniqueFileName');

      // Metadata ayarla
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      print('📤 Uploading: $uniqueFileName with content-type: $contentType');

      // Upload the file
      final uploadTask = await ref.putData(fileBytes, metadata);

      // Download URL al
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Upload complete: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete a GIF
  Future<void> deleteGif(String gifUrl) async {
    try {
      final ref = _storage.refFromURL(gifUrl);
      await ref.delete();
    } catch (e) {
      // The file may already be deleted; ignore the error
      print('Failed to delete GIF (ignored): $e');
    }
  }

  // List all GIFs for administrators
  Future<List<Map<String, dynamic>>> listAllGifs() async {
    try {
      final ref = _storage.ref().child(folder);
      final result = await ref.listAll();

      final gifs = <Map<String, dynamic>>[];
      for (var item in result.items) {
        final url = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        gifs.add({
          'name': item.name,
          'url': url,
          'size': metadata.size,
          'uploaded': metadata.timeCreated,
        });
      }

      return gifs;
    } catch (e) {
      throw Exception('Failed to fetch GIF list: $e');
    }
  }

  // Validate the file size (maximum 5 MB)
  bool isFileSizeValid(int sizeInBytes) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    return sizeInBytes <= maxSize;
  }

  // Validate the file type
  bool isGifFile(String fileName) {
    return fileName.toLowerCase().endsWith('.gif');
  }
}
