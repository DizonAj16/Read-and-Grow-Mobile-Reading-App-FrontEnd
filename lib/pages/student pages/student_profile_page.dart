import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:deped_reading_app_laravel/api/api_service.dart'; // adjust your import path

/// StudentProfilePage displays the student's profile information,
/// allows updating the profile picture, and shows student details.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  // Student info fields
  String _studentName = '';
  String _studentLrn = '';
  String _studentGrade = '';
  String _studentSection = '';
  String _studentUserId = ''; // Used for profile picture upload
  XFile? _pickedImageFile; // Holds the picked image file for preview/upload
  String baseUrl = 'http://10.0.2.2:8000'; // Default base URL for images
  String _profilePictureUrl = ''; // URL for the student's profile picture
  bool _isUploading = false; // Controls loading animation during upload

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Loads student data and profile picture from SharedPreferences.
  /// Sets up the base URL and ensures the profile picture URL is complete.
  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    baseUrl = '${uri.scheme}://${uri.authority}';

    String storedProfilePicture = prefs.getString('profile_picture') ?? '';

    // If the profile picture is not a complete URL, add the baseUrl
    if (storedProfilePicture.isNotEmpty &&
        !storedProfilePicture.contains(baseUrl)) {
      storedProfilePicture =
          '$baseUrl/storage/profile_images/$storedProfilePicture';
    }

    setState(() {
      _studentUserId = prefs.getString('user_id') ?? '';
      _studentName = prefs.getString('student_name') ?? '';
      _studentLrn = prefs.getString('student_lrn') ?? '';
      _studentGrade = prefs.getString('student_grade') ?? '';
      _studentSection = prefs.getString('student_section') ?? '';
      _profilePictureUrl = storedProfilePicture;
    });

    print("Loaded profile picture URL: $_profilePictureUrl");
  }

  /// Handles picking an image from the gallery and uploading it as the profile picture.
  /// Shows a confirmation dialog before uploading.
  /// Updates the profile picture both locally and in SharedPreferences.
  Future<void> _pickAndUploadImage({required String userId}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _pickedImageFile = pickedFile;
      });

      // Show confirmation dialog before uploading
      // Show confirmation dialog before uploading
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            elevation: 10,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 26,
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  "Confirm Upload",
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Modern circular avatar with border and shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    child: CircleAvatar(
                      radius: 58,
                      backgroundImage: FileImage(File(pickedFile.path)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Do you want to set this as your new profile picture?",
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    color: Theme.of(dialogContext).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text("Cancel"),
                onPressed: () {
                  if (dialogContext.mounted)
                    Navigator.pop(dialogContext, false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text("Upload"),
                onPressed: () {
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          );
        },
      );

      // If cancelled, reset picked image and return
      if (confirmed != true) {
        setState(() {
          _pickedImageFile = null;
        });
        return;
      }

      setState(() {
        _isUploading = true;
      });

      // Upload the image using the API service
      final response = await ApiService.uploadProfilePicture(
        userId: userId,
        role: 'student',
        filePath: pickedFile.path,
      );

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 2));
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        String newProfileUrl = data['profile_picture'];
        if (!newProfileUrl.startsWith('http')) {
          newProfileUrl = '$baseUrl/storage/profile_images/$newProfileUrl';
        }

        setState(() {
          _profilePictureUrl = newProfileUrl;
          _pickedImageFile = null;
        });

        // Save new profile picture URL to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_picture', newProfileUrl);

        print('[DEBUG] New profile picture URL: $_profilePictureUrl');

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(child: Text("Profile picture updated!")),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error snackbar if upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to upload image. Code: ${response.statusCode}",
            ),
          ),
        );
      }
    } catch (e) {
      // Show error snackbar if an exception occurs
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isUploading = false; // Hide loading animation
      });
    }
  }

  /// Returns the correct ImageProvider for the profile avatar.
  /// If a new image is picked, shows the preview.
  /// Otherwise, shows the network image or a placeholder.
  ImageProvider<Object> _getProfileImage() {
    if (_pickedImageFile != null) {
      print('Picked file path: ${_pickedImageFile!.path}');
      return FileImage(File(_pickedImageFile!.path));
    } else if (_profilePictureUrl.isNotEmpty) {
      print('Profile picture URL: $_profilePictureUrl');
      return NetworkImage(_profilePictureUrl);
    } else {
      return const AssetImage('assets/placeholder/student_placeholder.png');
    }
  }

  /// Creates a glassmorphism card for visual effect.
  /// Used for profile and info sections.
  Widget _glassCard({
    required Widget child,
    double blur = 0.5,
    double opacity = 0.18,
    EdgeInsets? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(0),
          child: child,
        ),
      ),
    );
  }

  /// Main build method for the student profile page.
  /// Assembles the app bar, background, profile card, info card, and edit button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Student Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.85),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Blended background image with color overlay for readability
          Image.asset(
            'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            color: Colors.black.withOpacity(0.35),
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      (MediaQuery.of(context).padding.top + kToolbarHeight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    // Glassmorphism profile card with avatar and name
                    _glassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          // Profile avatar with upload button
                          Hero(
                            tag: 'student-profile-image',
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white70,
                                  child:
                                      _isUploading
                                          ? Lottie.asset(
                                            'assets/animation/loading3.json',
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.contain,
                                          ) // Lottie loading animation during upload
                                          : CircleAvatar(
                                            radius: 58,
                                            backgroundImage: _getProfileImage(),
                                          ),
                                ),
                                // Camera icon for picking new profile image
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () async {
                                      if (_studentUserId.isNotEmpty) {
                                        await _pickAndUploadImage(
                                          userId: _studentUserId,
                                        );
                                      }
                                    },
                                    child: ClipOval(
                                      child: Container(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          // Student name
                          Text(
                            _studentName.isNotEmpty ? _studentName : "Student",
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          // Student role label
                          Text(
                            "Student",
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 3,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    // Glassmorphism info card with student details
                    _glassCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.badge, color: Colors.white70),
                            title: Text(
                              "LRN: ${_studentLrn.isNotEmpty ? _studentLrn : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(
                            height: 0,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.white70,
                          ),
                          ListTile(
                            leading: Icon(Icons.grade, color: Colors.white70),
                            title: Text(
                              "Grade: ${_studentGrade.isNotEmpty ? _studentGrade : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Divider(
                            height: 0,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.white70,
                          ),
                          ListTile(
                            leading: Icon(Icons.class_, color: Colors.white70),
                            title: Text(
                              "Section: ${_studentSection.isNotEmpty ? _studentSection : 'Not set'}",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Edit profile button (future implementation)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement edit profile
                      },
                      icon: Icon(Icons.edit),
                      label: Text("Edit Profile"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
