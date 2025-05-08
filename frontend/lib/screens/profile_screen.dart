import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:async';
import '../services/storage_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isCameraActive = false;

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _mediaStream = null;
    }
    if (_videoElement != null) {
      _videoElement?.remove();
      _videoElement = null;
    }
    _isCameraActive = false;
  }

  Future<void> _initializeCamera() async {
    try {
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user',
        },
        'audio': false,
      });

      if (_mediaStream != null) {
        _videoElement = html.VideoElement()
          ..srcObject = _mediaStream
          ..autoplay = true
          ..style.width = '100%'
          ..style.height = '100%';

        // Create a container for the video element
        final container = html.DivElement()
          ..id = 'camera-container'
          ..style.position = 'fixed'
          ..style.top = '50%'
          ..style.left = '50%'
          ..style.transform = 'translate(-50%, -50%)'
          ..style.zIndex = '1000'
          ..style.backgroundColor = 'rgba(0, 0, 0, 0.8)'
          ..style.padding = '20px'
          ..style.borderRadius = '12px';

        final videoWrapper = html.DivElement()
          ..style.width = '400px'
          ..style.height = '300px'
          ..style.position = 'relative';

        final captureButton = html.ButtonElement()
          ..innerText = 'Capture'
          ..style.position = 'absolute'
          ..style.bottom = '20px'
          ..style.left = '50%'
          ..style.transform = 'translateX(-50%)'
          ..style.padding = '10px 20px'
          ..style.backgroundColor = '#1B4242'
          ..style.color = 'white'
          ..style.border = 'none'
          ..style.borderRadius = '8px'
          ..style.cursor = 'pointer';

        final closeButton = html.ButtonElement()
          ..innerText = '×'
          ..style.position = 'absolute'
          ..style.top = '10px'
          ..style.right = '10px'
          ..style.backgroundColor = 'transparent'
          ..style.color = 'white'
          ..style.border = 'none'
          ..style.fontSize = '24px'
          ..style.cursor = 'pointer';

        captureButton.onClick.listen((event) async {
          final canvas = html.CanvasElement(
            width: _videoElement!.videoWidth,
            height: _videoElement!.videoHeight,
          );
          canvas.context2D.drawImage(_videoElement!, 0, 0);
          final blob = await canvas.toBlob('image/jpeg', 0.8);
          final url = html.Url.createObjectUrlFromBlob(blob);
          setState(() {
            _imageUrl = url;
          });
          _stopCamera();
          container.remove();
        });

        closeButton.onClick.listen((event) {
          _stopCamera();
          container.remove();
        });

        videoWrapper.children.add(_videoElement!);
        container.children.addAll([closeButton, videoWrapper, captureButton]);
        
        html.document.querySelector('body')?.children.add(container);
        
        setState(() {
          _isCameraActive = true;
        });
      }
    } catch (e) {
      print('Error accessing camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing camera: Please ensure camera permissions are granted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditPhotoOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _initializeCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        // For web, we'll just store the image URL temporarily
        if (kIsWeb) {
          setState(() {
            _imageUrl = pickedFile.path;
          });
        }
        // TODO: Implement proper image upload to cloud storage
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF1B4242)),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                // Navigate to login screen and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error signing out: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              SizedBox(height: 16),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: _imageUrl != null
                        ? NetworkImage(_imageUrl!)
                        : (user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : NetworkImage('https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=facearea&w=256&q=80')),
                    child: _imageUrl == null && user?.photoURL == null
                        ? Icon(Icons.person, size: 70, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _showEditPhotoOptions,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(Icons.edit, size: 24, color: Color(0xFF1B4242)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    color: Color(0xFF5C6F6F),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 16),
              _infoField('Account Number', '3024982387'),
              SizedBox(height: 12),
              _infoField('Username', user?.displayName ?? 'No name set'),
              SizedBox(height: 12),
              _infoField('Email', user?.email ?? 'No email'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF5C6F6F),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFFB0B3B8),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
