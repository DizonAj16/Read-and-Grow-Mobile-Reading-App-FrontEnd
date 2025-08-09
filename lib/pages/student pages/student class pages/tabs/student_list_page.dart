import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/widgets/student_view_page.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

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
  int? currentStudentId;

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
      final fetchedStudents = await ClassroomService.getAssignedStudents(
        widget.classId,
      );

      if (mounted) {
        fetchedStudents.sort((a, b) {
          if (a.id == currentStudentId) return -1;
          if (b.id == currentStudentId) return 1;
          return 0;
        });

        setState(() => students = fetchedStudents);
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      _showErrorSnackbar("Oops! Couldn't load classmates");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalStudents = students.length;
    final int totalPages = (totalStudents / _studentsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body:
          loading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animation/loading_rainbow.json',
                      width: 90,
                      height: 90,
                    ),
                  ],
                ),
              )
              : students.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/empty_classroom.json',
                      width: 250,
                      height: 250,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No classmates yet!",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Classmates counter with fun emoji
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[200]!, Colors.blue[400]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "👫 ${totalStudents} Students",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'ComicNeue',
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
                        setState(() => _currentPage = index);
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
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: studentsToShow.length,
                          itemBuilder: (context, index) {
                            final student = studentsToShow[index];
                            final isCurrentUser =
                                currentStudentId != null &&
                                student.id == currentStudentId;
                            final displayName =
                                isCurrentUser
                                    ? '${student.studentName} (You)'
                                    : student.studentName;
                            final sanitizedBaseUrl =
                                baseUrl?.replaceAll(RegExp(r'/api/?$'), '') ??
                                '';
                            final profileUrl =
                                (student.profilePicture != null &&
                                        student.profilePicture!.isNotEmpty)
                                    ? "$sanitizedBaseUrl/storage/profile_images/${student.profilePicture}"
                                    : null;

                            return _buildStudentCard(
                              context,
                              student: student,
                              name: displayName,
                              avatarLetter: student.avatarLetter,
                              profileUrl: profileUrl,
                              isCurrentUser: isCurrentUser,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Page indicator
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: _currentPage == index ? 16.0 : 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color:
                                  _currentPage == index
                                      ? Colors.blue
                                      : Colors.blue.withOpacity(0.3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context, {
    required Student student,
    required String name,
    required String avatarLetter,
    required String? profileUrl,
    required bool isCurrentUser,
  }) {
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    final avatarColor = colors[student.id % colors.length];

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
        elevation: 4,
        shadowColor: avatarColor.withOpacity(0.2),
        child: Stack(
          children: [
            // Background decoration
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      avatarColor.withOpacity(0.1),
                      avatarColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            // "You" badge
            if (isCurrentUser)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "YOU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Main content column
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar container with centered alignment
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: avatarColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            (profileUrl != null && profileUrl.isNotEmpty)
                                ? FadeInImage.assetNetwork(
                                  placeholder:
                                      'assets/placeholder/avatar_placeholder.jpg',
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
                  const SizedBox(height: 12),
                  // Name container with proper constraints
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      name.split(' ')[0], // Show only first name
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'ComicNeue',
                        color: Colors.blueGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String letter, Color backgroundColor) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }
}
