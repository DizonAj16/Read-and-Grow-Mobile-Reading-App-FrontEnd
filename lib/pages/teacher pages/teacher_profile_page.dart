import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/teacher.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  Teacher? _teacher;
  String baseUrl = 'http://10.0.2.2:8000'; // Default fallback
  XFile? _pickedImageFile;
  late Future<Teacher> _teacherFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _teacherFuture = _initializeData();
  }

  Future<Teacher> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    baseUrl = '${uri.scheme}://${uri.authority}';

    final teacher = await Teacher.fromPrefs();
    return teacher;
  }

  Future<void> _pickAndUploadImage({
    required String role,
    required String userId,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _pickedImageFile = pickedFile;
      });

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final primaryColor = Theme.of(dialogContext).colorScheme.primary;

          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.image, size: 24, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Confirm Upload",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(dialogContext).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(
                    dialogContext,
                  ).colorScheme.onSurface.withOpacity(0.1),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: FileImage(File(pickedFile.path)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Do you want to set this as your new profile picture?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
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
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload, size: 18),
                label: const Text("Upload"),
                onPressed: () {
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        setState(() {
          _pickedImageFile = null;
        });
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final response = await ApiService.uploadProfilePicture(
        userId: userId,
        role: role,
        filePath: pickedFile.path,
      );

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(seconds: 2));
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        final newProfileUrl = data['profile_picture'];

        _teacher = Teacher(
          id: _teacher?.id,
          userId: _teacher?.userId,
          name: _teacher?.name ?? 'Teacher',
          position: _teacher?.position,
          email: _teacher?.email,
          username: _teacher?.username,
          profilePicture: newProfileUrl,
          createdAt: _teacher?.createdAt,
          updatedAt: DateTime.now(),
        );
        await _teacher?.saveToPrefs();

        // Refresh the teacher data
        setState(() {
          _pickedImageFile = null;
          _teacherFuture = _initializeData();
        });

        // Success Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Profile picture updated!",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Failed to upload image. Code: ${response.statusCode}",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text("Error: $e")),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

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

  // Add this method in your _TeacherProfilePageState:
  ImageProvider<Object> _getProfileImage() {
    if (_pickedImageFile != null) {
      print('[DEBUG] Using picked image file: ${_pickedImageFile!.path}');
      return FileImage(File(_pickedImageFile!.path));
    } else if (_teacher?.profilePicture != null &&
        _teacher!.profilePicture!.isNotEmpty) {
      print('[DEBUG] Using network image URL: ${_teacher!.profilePicture}');
      return NetworkImage(_teacher!.profilePicture!);
    } else {
      print('[DEBUG] Using placeholder image');
      return const AssetImage('assets/placeholder/teacher_placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Teacher Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withOpacity(0.85),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<Teacher>(
        future: _teacherFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _teacher = snapshot.data; // assign loaded teacher

          final teacherName = _teacher?.name ?? "Teacher";
          final teacherPosition = _teacher?.position ?? "";
          final teacherEmail = _teacher?.email ?? "";

          return buildTeacherProfile(
            context,
            teacherName,
            teacherPosition,
            teacherEmail,
          );
        },
      ),
    );
  }

  Stack buildTeacherProfile(
    BuildContext context,
    String teacherName,
    String teacherPosition,
    String teacherEmail,
  ) {
    return Stack(
      children: [
        // Blended background image with color overlay for effect (copied from landing_page.dart)
        Image.asset(
          'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
        ),
        // Add a dark overlay for readability
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
                  // Glassmorphism profile card
                  _glassCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        _heroAvatarWithEditButton(),

                        SizedBox(height: 18),
                        Text(
                          teacherName,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: Colors.white, // Ensure high contrast
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              teacherPosition.isNotEmpty
                                  ? teacherPosition
                                  : "Position not set",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.85),
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
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  // Glassmorphism info card
                  _glassCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.email_outlined,
                            color: Colors.white70,
                          ),
                          title: Text(
                            teacherEmail.isNotEmpty
                                ? teacherEmail
                                : "Email not set",
                            style: TextStyle(
                              color: const Color.fromARGB(221, 255, 255, 255),
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
                          leading: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white70,
                          ),
                          title: Text(
                            _teacher?.createdAt != null
                                ? "Joined: ${DateFormat.yMMMMd().format(_teacher!.createdAt!.toLocal())}"
                                : "Joined date unknown",

                            style: TextStyle(
                              color: const Color.fromARGB(221, 255, 255, 255),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
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
    );
  }

  _heroAvatarWithEditButton() {
    return Hero(
      tag: 'teacher-profile-image',
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 70,
              child:
                  _isUploading
                      ? Lottie.asset(
                        'assets/animation/loading3.json',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ) // ✅ Lottie animation
                      : CircleAvatar(
                        radius: 70,
                        backgroundImage: _getProfileImage(),
                      ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: GestureDetector(
                onTap: () async {
                  if (_teacher?.userId != null) {
                    await _pickAndUploadImage(
                      role: 'teacher',
                      userId: _teacher!.userId.toString(),
                    );
                  }
                },
                child: ClipOval(
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
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
    );
  }
}
