import 'dart:convert';
import 'dart:io';
import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/classes/assign_student_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'class_info.dart';

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

    // ✅ Remove `/api` if present
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.replaceAll('/api', '');
    }

    final classId = widget.classDetails['id'].toString();

    final storedBg = prefs.getString("class_background_$classId");
    final bgImage = storedBg ?? widget.classDetails['background_image'];

    debugPrint("🖼 Class ID: $classId");
    debugPrint("🖼 Stored background: $storedBg");
    debugPrint("🖼 From classDetails: $bgImage");

    if (bgImage != null && bgImage.isNotEmpty) {
      // ✅ If it's already a full URL, just return it
      if (bgImage.startsWith('http')) {
        debugPrint("✅ Already full URL: $bgImage");
        return bgImage;
      }

      // ✅ Otherwise, construct the full URL
      final fullUrl = '$baseUrl/storage/class_backgrounds/$bgImage';
      debugPrint("✅ Final constructed URL: $fullUrl");
      return fullUrl;
    }

    debugPrint("⚠ No background image found. Using default.");
    return '';
  }

  Future<void> _pickAndUploadBackground() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _previewBackground = pickedFile.path;
    });

    // ✅ Show preview dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.image, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Preview Image",
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(pickedFile.path),
                    fit: BoxFit.cover,
                    width:
                        MediaQuery.of(context).size.width *
                        0.8, // ✅ finite width
                    height: 180,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Do you want to set this as the new class background?",
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () {
                  Navigator.pop(ctx, false);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.primary,
                ),
                child: Text(
                  "Yes, Update",
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onPrimary),
                ),
                onPressed: () {
                  Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
    );

    if (confirm != true) {
      setState(() => _previewBackground = null); // ✅ Reset if canceled
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.uploadClassBackground(
        classId: int.parse(widget.classDetails['id'].toString()),
        filePath: pickedFile.path,
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        setState(() {
          widget.classDetails['background_image'] = data['background_image'];
          _previewBackground = null;
        });

        // ✅ Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final classId = widget.classDetails['id'].toString();
        await prefs.setString(
          "class_background_$classId",
          data['background_image'],
        );

        // ✅ Keep loading for 2s BEFORE showing the Snackbar
        await Future.delayed(const Duration(seconds: 2));

        // ✅ Now show success Snackbar
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
      } else {
        // ✅ Keep loading for 2s BEFORE showing the Snackbar
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
      // ✅ Hide Lottie AFTER showing the Snackbar
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classId =
        widget.classDetails['id'] ?? widget.classDetails['class_name'];
    final className = widget.classDetails['class_name'] ?? 'Class';
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (context, _) => [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: primary,
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
                        style: const TextStyle(
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
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'class-bg-${widget.classDetails['id']}',
                            child:
                                _previewBackground != null
                                    ? Image.file(
                                      File(_previewBackground!),
                                      fit: BoxFit.cover,
                                    )
                                    : (bgUrl.isNotEmpty
                                        ? Image.network(
                                          bgUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Image.asset(
                                                'assets/background/classroombg.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                        : Image.asset(
                                          'assets/background/classroombg.jpg',
                                          fit: BoxFit.cover,
                                        )),
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
                          AnimatedOpacity(
                            opacity: _isUploading ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: IgnorePointer(
                              ignoring:
                                  !_isUploading, // Prevent clicks while uploading
                              child: Container(
                                color: Colors.black.withOpacity(0.4), // overlay
                                child: Center(
                                  child: SizedBox(
                                    width:
                                        120, // smaller to fit inside appbar background
                                    height: 120,
                                    child: Lottie.asset(
                                      'assets/animation/loading3.json',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
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
          onPageChanged: (index) {
            if (_currentIndex != index) {
              setState(() => _currentIndex = index);
            }
          },
          children: [
            SingleChildScrollView(
              child: ClassInfoPage(classDetails: widget.classDetails),
            ),
            AssignStudentPage(
              classId: int.tryParse(widget.classDetails['id'].toString()) ?? 0,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Class Info"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Students"),
        ],
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
