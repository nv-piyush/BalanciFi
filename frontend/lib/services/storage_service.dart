import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadProfilePhoto(String photoUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Convert data URL to Blob
      final response = await html.window.fetch(photoUrl);
      final blob = await response.blob();
      
      // Create a reference to the file path
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      
      // Create upload task
      final uploadTask = ref.putBlob(blob);
      
      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Update user profile with new photo URL
      await user.updatePhotoURL(downloadUrl);
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      throw Exception('Failed to upload profile photo');
    }
  }
} 