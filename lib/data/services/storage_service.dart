import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload signature image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadSignature(String userId, String base64Image) async {
    try {
      // Decode base64 to bytes
      final Uint8List imageBytes = base64Decode(base64Image);

      // Create a reference to the file location
      final Reference ref = _storage.ref().child('signatures/$userId.png');

      // Upload the file
      final UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload signature: $e');
    }
  }

  /// Upload contract document to Firebase Storage
  /// Returns the download URL of the uploaded document
  Future<String> uploadContract(String userId, String contractContent) async {
    try {
      // Convert contract content to bytes
      final Uint8List contentBytes = utf8.encode(contractContent);

      // Create a reference to the file location
      final Reference ref = _storage.ref().child('contracts/$userId.txt');

      // Upload the file
      final UploadTask uploadTask = ref.putData(
        contentBytes,
        SettableMetadata(contentType: 'text/plain'),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload contract: $e');
    }
  }

  /// Upload profile image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadProfileImage(String userId, Uint8List imageBytes, String extension) async {
    try {
      // Create a reference to the file location
      final Reference ref = _storage.ref().child('profile_images/$userId.$extension');

      // Upload the file
      final UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/$extension'),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String filePath) async {
    try {
      final Reference ref = _storage.ref().child(filePath);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
