import 'package:deped_reading_app_laravel/pages/student%20pages/my%20class%20pages/student_view_page.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentListPage extends StatefulWidget {
  final int classId;

  const StudentListPage({super.key, required this.classId});

  @override
  _StudentListPageState createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  List<Student> students = [];
  bool loading = true;
  int _currentPage = 0;
  final int _studentsPerPage = 6;
  final PageController _pageController = PageController();
  String? baseUrl;
  int? currentStudentId; // 👈 Logged-in student ID

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:8000';

    final studentIdString = prefs.getString('student_id');
    if (studentIdString != null) {
      currentStudentId = int.tryParse(studentIdString);
    }

    await _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      setState(() => loading = true);

      final fetchedStudents = await ApiService.getAssignedStudents(
        widget.classId,
      );

      if (mounted) {
        // Sort so that current student is first
        fetchedStudents.sort((a, b) {
          if (a.id == currentStudentId) return -1;
          if (b.id == currentStudentId) return 1;
          return 0;
        });

        setState(() {
          students = fetchedStudents;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading students: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalStudents = students.length;
    final int totalPages = (totalStudents / _studentsPerPage).ceil();

    return loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.lightBlue.shade100,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade50,
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("👦👧 ", style: TextStyle(fontSize: 20)),
                    Text(
                      "Total Students: $totalStudents",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ComicNeue',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: totalPages,
                itemBuilder: (context, pageIndex) {
                  final studentsToShow =
                      students
                          .skip(pageIndex * _studentsPerPage)
                          .take(_studentsPerPage)
                          .toList();

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: studentsToShow.length,
                    itemBuilder: (context, index) {
                      final student = studentsToShow[index];

                      final isCurrentUser =
                          currentStudentId != null &&
                          student.id == currentStudentId;

                      debugPrint(
                        'Comparing → currentStudentId: $currentStudentId vs student.id: ${student.id}',
                      );

                      final displayName =
                          isCurrentUser
                              ? '${student.studentName} (Me)'
                              : student.studentName;

                      final sanitizedBaseUrl =
                          baseUrl?.replaceAll(RegExp(r'/api/?$'), '') ?? '';

                      final profileUrl =
                          (student.profilePicture != null &&
                                  student.profilePicture!.isNotEmpty)
                              ? "$sanitizedBaseUrl/storage/profile_images/${student.profilePicture}"
                              : null;

                      return _buildStudentCard(
                        context,
                        name: displayName,
                        avatarLetter: student.avatarLetter,
                        avatarColor:
                            Colors.primaries[Random().nextInt(
                              Colors.primaries.length,
                            )],
                        profileUrl: profileUrl,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: _currentPage == index ? 14.0 : 10.0,
                      height: _currentPage == index ? 14.0 : 10.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
  }

  Widget _buildAvatarFallback(String letter, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            fontFamily: 'ComicNeue',
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context, {
    required String name,
    required String avatarLetter,
    required Color avatarColor,
    required String? profileUrl,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StudentProfilePage(
                  name: name,
                  avatarLetter: avatarLetter,
                  avatarColor: avatarColor,
                  profileUrl: profileUrl,
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: avatarColor.withOpacity(0.3),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'avatar_$name',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        child:
                            (profileUrl != null && profileUrl.isNotEmpty)
                                ? FadeInImage.assetNetwork(
                                  placeholder:
                                      'assets/placeholder/avatar_placeholder.png',
                                  image: profileUrl,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder:
                                      (_, __, ___) => _buildAvatarFallback(
                                        avatarLetter,
                                        avatarColor,
                                      ),
                                )
                                : _buildAvatarFallback(
                                  avatarLetter,
                                  avatarColor,
                                ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'ComicNeue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
