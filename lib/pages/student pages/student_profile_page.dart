import 'dart:convert';
import 'dart:ui';
import 'package:deped_reading_app_laravel/api/auth_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late Future<Student> _studentFuture;
  XFile? _pickedImageFile;
  String _baseUrl = 'http://10.0.2.2:8000';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _studentFuture = _initializeStudentData();
  }

  Future<Student> _initializeStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    _baseUrl = '${uri.scheme}://${uri.authority}';

    Student student;

    try {
      // Try fetching from API
      final profileData =
          await AuthService.getAuthProfile(); // your existing function
      debugPrint('📡 API profileData: $profileData');

      student = Student.fromJson(profileData['student']);
      debugPrint('✅ Student from API: ${student.toJson()}');

      await student.saveToPrefs(); // save to SharedPreferences
    } catch (e) {
      debugPrint('⚠️ Error fetching from API: $e');
      // Fallback to saved data
      student = await Student.fromPrefs();
      debugPrint('📦 Student from SharedPreferences: ${student.toJson()}');
    }

    // Normalize profile picture path if needed
    if (student.profilePicture != null &&
        !student.profilePicture!.startsWith('http')) {
      student = student.copyWith(
        profilePicture:
            '$_baseUrl/storage/profile_images/${student.profilePicture}',
      );
      debugPrint(
        '🖼️ Normalized profile picture URL: ${student.profilePicture}',
      );
    }

    return student;
  }

  Future<void> _pickAndUploadImage(Student student) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() => _pickedImageFile = pickedFile);

      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => ConfirmationDialog(
              imagePath: pickedFile.path,
              title: "Confirm Upload",
            ),
      );

      if (confirmed != true) {
        setState(() => _pickedImageFile = null);
        return;
      }

      setState(() => _isUploading = true);
      final uploadStartTime = DateTime.now();

      final response = await UserService.uploadProfilePicture(
        userId: student.userId.toString(),
        role: 'student',
        filePath: pickedFile.path,
      );

      final elapsed = DateTime.now().difference(uploadStartTime);
      final remainingDelay = const Duration(seconds: 2) - elapsed;
      if (remainingDelay > Duration.zero) {
        await Future.delayed(remainingDelay);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        final newProfileUrl =
            data['profile_picture']?.startsWith('http')
                ? data['profile_picture']
                : '$_baseUrl/storage/profile_images/${data['profile_picture']}';

        final updatedStudent = student.copyWith(profilePicture: newProfileUrl);
        await updatedStudent.saveToPrefs();

        setState(() {
          _studentFuture = Future.value(updatedStudent);
          _pickedImageFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(UploadSuccessSnackBar());
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(UploadErrorSnackBar(response.statusCode));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: FutureBuilder<Student>(
          future: _studentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Lottie.asset(
                  'assets/animation/loading_rainbow.json',
                  width: 90,
                  height: 90,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/confused_owl.png', width: 120),
                    const SizedBox(height: 20),
                    Text(
                      'Oops! Couldn\'t load profile',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              );
            }

            final student = snapshot.data!;
            return _buildProfileContent(student);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 80),
          // Profile Card
          _GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ProfileAvatar(
                  student: student,
                  pickedImage: _pickedImageFile,
                  isUploading: _isUploading,
                  onTap: () => _pickAndUploadImage(student),
                ),
                const SizedBox(height: 18),
                Text(
                  student.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicNeue',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Super Reader",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Info Card
          _GlassCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.school_rounded,
                  text: "LRN: ${student.studentLrn ?? 'Not set'}",
                  iconColor: Colors.pink,
                ),
                const Divider(
                  height: 0,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.white70,
                ),
                _InfoTile(
                  icon: Icons.star_rounded,
                  text: "Grade: ${student.studentGrade ?? 'Not set'}",
                  iconColor: Colors.yellow,
                ),
                const Divider(
                  height: 0,
                  indent: 16,
                  endIndent: 16,
                  color: Colors.white70,
                ),
                _InfoTile(
                  icon: Icons.group_rounded,
                  text: "Section: ${student.studentSection ?? 'Not set'}",
                  iconColor: Colors.lightBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Progress indicator
          _TaskProgressIndicator(completedTasks: student.completedTasks),
          const SizedBox(height: 20),
          // Fun decoration
          Image.asset('assets/activity_images/reading_owl.jpg', width: 100),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final Student student;
  final XFile? pickedImage;
  final bool isUploading;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.student,
    this.pickedImage,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'student-profile-image',
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child:
                isUploading
                    ? Lottie.asset('assets/animation/loading_rainbow.json')
                    : CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: _getProfileImage(student),
                      child:
                          pickedImage == null && student.profilePicture == null
                              ? Icon(
                                Icons.person,
                                size: 50,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              )
                              : null,
                    ),
          ),
          Positioned(
            bottom: 0,
            right: 4,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider<Object> _getProfileImage(Student student) {
    if (pickedImage != null) return FileImage(File(pickedImage!.path));
    if (student.profilePicture != null)
      return NetworkImage(student.profilePicture!);
    return const AssetImage('assets/placeholder/student_placeholder.png');
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _InfoTile({
    required this.icon,
    required this.text,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor?.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
      ),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }
}

class _TaskProgressIndicator extends StatelessWidget {
  final int completedTasks;

  const _TaskProgressIndicator({required this.completedTasks});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Reading Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ComicNeue',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Completed $completedTasks of 13 stories',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'ComicNeue',
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completedTasks / 13,
            backgroundColor: Colors.grey[300],
            color: Colors.amber,
            minHeight: 16,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(color: Colors.white, fontFamily: 'ComicNeue'),
              ),
              Text(
                '13',
                style: TextStyle(color: Colors.white, fontFamily: 'ComicNeue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String imagePath;
  final String title;

  const ConfirmationDialog({required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.file(
                  File(imagePath),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Use this as your new profile picture?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'ComicNeue',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Yes!',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UploadSuccessSnackBar extends SnackBar {
  UploadSuccessSnackBar()
    : super(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Yay! New profile picture saved!",
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class UploadErrorSnackBar extends SnackBar {
  UploadErrorSnackBar(int? statusCode)
    : super(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              "Oops! Upload failed${statusCode != null ? ' (Code: $statusCode)' : ''}",
              style: const TextStyle(fontFamily: 'ComicNeue'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}
