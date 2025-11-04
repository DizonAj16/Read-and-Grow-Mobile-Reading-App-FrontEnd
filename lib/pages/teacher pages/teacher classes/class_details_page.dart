import 'dart:convert';
import 'dart:io';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/tabs/students_management_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/tabs/materials_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/tabs/tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs/class_info.dart';

class ClassDetailsPage extends StatefulWidget {
  final Map<String, dynamic> classDetails;

  const ClassDetailsPage({super.key, required this.classDetails});

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isUploading = false;
  String? _previewBackground;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<String> _getBackgroundUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';

    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.replaceAll('/api', '');
    }

    final classId = widget.classDetails['id'].toString();
    final storedBg = prefs.getString("class_background_$classId");
    final bgImage = storedBg ?? widget.classDetails['background_image'];

    if (bgImage != null && bgImage.isNotEmpty) {
      if (bgImage.startsWith('http')) {
        return bgImage;
      }
      return '$baseUrl/storage/class_backgrounds/$bgImage';
    }
    return '';
  }

  // Replace the existing _pickAndUploadBackground method with this version
  Future<void> _pickAndUploadBackground() async {
    // First show confirmation dialog before picking file
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with icon
                Icon(
                  Icons.image_rounded,
                  color: Theme.of(dialogContext).colorScheme.primary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "Upload New Background",
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "Would you like to upload a new class background image?",
                  textAlign: TextAlign.center,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons with icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: Icon(
                          Icons.cancel_rounded,
                          size: 20,
                          color: Theme.of(
                            dialogContext,
                          ).colorScheme.onSurface.withOpacity(0.8),
                        ),
                        label: Text(
                          "Cancel",
                          style: TextStyle(
                            color:
                                Theme.of(dialogContext).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: Theme.of(dialogContext).colorScheme.onPrimary,
                        ),
                        label: Text(
                          "Yes",
                          style: TextStyle(
                            color:
                                Theme.of(dialogContext).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(dialogContext).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    // Now pick the image file
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    // Show the image preview dialog
    setState(() => _previewBackground = pickedFile.path);

    final confirmUpdate = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Preview Image",
                        style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Larger image preview
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(pickedFile.path),
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: 220,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Smaller and lighter text
                  Text(
                    "Do you want to set this as the new class background?",
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons with icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx, false),
                          icon: Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: Theme.of(
                              ctx,
                            ).colorScheme.onSurface.withOpacity(0.8),
                          ),
                          label: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                ctx,
                              ).colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx, true),
                          icon: Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: Theme.of(ctx).colorScheme.onPrimary,
                          ),
                          label: Text(
                            "Update",
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(ctx).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmUpdate != true) {
      setState(() => _previewBackground = null);
      return;
    }

    // Continue with the upload process...
    setState(() => _isUploading = true);

    try {

    final response = await ClassroomService.uploadClassBackground(
        classId: (widget.classDetails['id'].toString()),
        filePath: pickedFile.path,
      );

      if (response != null && response.statusCode == 200) {
        final responseBody = response.body;
        final data = jsonDecode(responseBody);
        final newBackgroundUrl = data['background_image'] as String?;

        if (newBackgroundUrl != null && newBackgroundUrl.isNotEmpty) {
          setState(() {
            _previewBackground = null;
          });

          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final classId = widget.classDetails['id'].toString();
          await prefs.setString(
            "class_background_$classId",
            newBackgroundUrl,
          );

          // Trigger rebuild by updating widget state through setState
          // Since widget.classDetails is final, we'll rely on SharedPreferences
          // which is already being read in _getBackgroundUrl()
          if (mounted) {
            setState(() {}); // Force rebuild to show new image
          }

          await Future.delayed(const Duration(seconds: 2));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Background image updated!",
                        style: TextStyle(color: Colors.white),
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
          }
        }
      } else {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "Failed to upload background. Please try again.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent.shade400,
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
      }
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
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
                Expanded(
                  child: Text(
                    "Something went wrong: $e",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
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
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classId =
        widget.classDetails['id'] ?? widget.classDetails['class_name'];
    final className = widget.classDetails['class_name'] ?? 'Class';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: colorScheme.primary,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 12),
                  title: Hero(
                    tag: 'class-title-$classId',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        className,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  background: FutureBuilder<String>(
                    future: _getBackgroundUrl(),
                    builder: (context, snapshot) {
                      final bgUrl = snapshot.data ?? '';

                      ImageProvider backgroundProvider;
                      if (_previewBackground != null) {
                        backgroundProvider = FileImage(
                          File(_previewBackground!),
                        );
                      } else if (bgUrl.isNotEmpty) {
                        backgroundProvider = NetworkImage(bgUrl);
                      } else {
                        backgroundProvider = const AssetImage(
                          'assets/background/classroombg.jpg',
                        );
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'class-bg-${widget.classDetails['id']}',
                            child: Image(
                              image: backgroundProvider,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Image.asset(
                                    'assets/background/classroombg.jpg',
                                    fit: BoxFit.cover,
                                  ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                color:
                                    Colors
                                        .white, // Slightly transparent for better overlay effect
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Image.asset(
                                          'assets/animation/upload.gif',
                                          width: 100,
                                          height: 100,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 16,
                                      ), // Space between GIF and text
                                      Text(
                                        "Uploading background image...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            left: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: _pickAndUploadBackground,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            ClassInfoPage(classDetails: widget.classDetails),
            StudentsManagementPage(classId: widget.classDetails['id'].toString()),
            MaterialsPage(classId: widget.classDetails['id'].toString()),
            TasksPage(classId: widget.classDetails['id'].toString()), // Tasks
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            activeIcon: Icon(Icons.info),
            label: "Info",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: "Students",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Materials",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: "Tasks",
          ),
        ],
      ),
    );
  }
}
