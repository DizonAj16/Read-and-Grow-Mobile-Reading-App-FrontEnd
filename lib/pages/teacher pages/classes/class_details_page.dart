import 'dart:convert';

import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/classes/assign_student_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
  final uri = Uri.parse(baseUrl);

  final classId = widget.classDetails['id'].toString();

  // ✅ First, check if we stored an updated background locally
  final storedBg = prefs.getString("class_background_$classId");
  final bgImage = storedBg ?? widget.classDetails['background_image'];

  if (bgImage != null && bgImage.isNotEmpty) {
    return '${uri.scheme}://${uri.authority}/storage/class_backgrounds/$bgImage';
  }
  return '';
}

Future<void> _pickAndUploadBackground() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.image, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 8),
          Text("Change Background"),
        ],
      ),
      content: const Text("Are you sure you want to update this class background?"),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(ctx, false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.primary,
          ),
          child: const Text("Yes, Update"),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  // ✅ Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final response = await ApiService.uploadClassBackground(
      classId: int.parse(widget.classDetails['id'].toString()),
      filePath: pickedFile.path,
    );

    Navigator.pop(context); // ✅ Close loading dialog

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      setState(() {
        widget.classDetails['background_image'] = data['background_image'];
      });

      // ✅ Store the new background in SharedPreferences (so it persists after exit)
      final prefs = await SharedPreferences.getInstance();
      final classId = widget.classDetails['id'].toString();
      await prefs.setString("class_background_$classId", data['background_image']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Background updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload background.")),
      );
    }
  } catch (e) {
    Navigator.pop(context); // ✅ Ensure loading dialog closes on error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
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
                automaticallyImplyLeading:
                    false, // We will add our own back button
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
                    future: _getBackgroundUrl(), // 👇 define this below
                    builder: (context, snapshot) {
                      final bgUrl = snapshot.data;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'class-bg-${widget.classDetails['id']}',
                            child:
                                bgUrl != null && bgUrl.isNotEmpty
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
                            bottom: MediaQuery.of(context).padding.top + 8,
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
