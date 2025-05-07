import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class DeviceService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }

  // Get currency based on location
  Future<String> getCurrencyFromLocation() async {
    try {
      final position = await getCurrentLocation();
      // TODO: Implement currency detection based on coordinates
      // For now, return a default currency
      return 'USD';
    } catch (e) {
      // Return default currency if location services fail
      return 'USD';
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Pick image from gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) throw Exception('No image selected');

    // Upload to Firebase Storage
    final file = File(image.path);
    final ref = _storage.ref().child('profile_pictures/${user.uid}');
    await ref.putFile(file);

    // Get download URL
    return await ref.getDownloadURL();
  }

  // Update user profile with new picture
  Future<void> updateProfilePicture(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await user.updatePhotoURL(imageUrl);
  }

  // Get device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    // TODO: Implement device information gathering
    // This would include device model, OS version, etc.
    return {
      'platform': 'Flutter',
      'version': '1.0.0',
    };
  }

  // Check for required permissions
  Future<Map<String, bool>> checkPermissions() async {
    final locationPermission = await Geolocator.checkPermission();
    final cameraPermission = await _checkCameraPermission();

    return {
      'location': locationPermission == LocationPermission.whileInUse ||
          locationPermission == LocationPermission.always,
      'camera': cameraPermission,
    };
  }

  // Check camera permission
  Future<bool> _checkCameraPermission() async {
    // TODO: Implement camera permission check
    // For now, return true
    return true;
  }
}
