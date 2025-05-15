import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'balancifi-457623.firebasestorage.app',
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadProfilePhoto(String photoUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Convert data URL to Blob
      final response = await html.window.fetch(photoUrl);
      final blob = await response.blob();
      
      // Create a reference to the file path
      final ref = _storage.ref().child('profile_photos/${user.uid}');
      
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

  // For web: photoUrl is a data URL; for mobile: file is an XFile
  Future<String> uploadProfilePhotoFlexible({String? photoUrl, XFile? file}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
    if (kIsWeb) {
      if (photoUrl == null) throw Exception('photoUrl required for web');
      final response = await html.window.fetch(photoUrl);
      final blob = await response.blob();
      final uploadTask = ref.putBlob(blob);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      if (file == null) throw Exception('file required for mobile');
      final uploadTask = ref.putFile(io.File(file.path));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
  }
} 