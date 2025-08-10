import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/widgets/student_view_page.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

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
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          // Header stays outside RefreshIndicator
          _buildHeader(totalStudents),

          // List content with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _fetchStudents,
              color: Colors.blue,
              backgroundColor: Colors.white,
              displacement: 40,
              edgeOffset: 20,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child:
                        loading
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 80),
                                child: Lottie.asset(
                                  'assets/animation/loading_rainbow.json',
                                  width: 90,
                                  height: 90,
                                ),
                              ),
                            )
                            : students.isEmpty
                            ? _buildEmptyState()
                            : Column(
                              children: [
                                _buildPagedStudentGrid(totalPages),
                                _buildPageIndicators(totalPages),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty.json', width: 250, height: 250),
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
    );
  }

  Widget _buildHeader(int totalStudents) {
    return ClipPath(
      clipper: WaveClipperOne(reverse: false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            Text(
              "$totalStudents Students",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagedStudentGrid(int totalPages) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
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
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: studentsToShow.length,
            itemBuilder: (context, index) {
              final student = studentsToShow[index];
              final isCurrentUser =
                  currentStudentId != null && student.id == currentStudentId;
              final displayName =
                  isCurrentUser
                      ? '${student.studentName} (You)'
                      : student.studentName;
              final sanitizedBaseUrl =
                  baseUrl?.replaceAll(RegExp(r'/api/?$'), '') ?? '';
              final profileUrl =
                  (student.profilePicture != null &&
                          student.profilePicture!.isNotEmpty)
                      ? "$sanitizedBaseUrl/storage/profile_images/${student.profilePicture}"
                      : null;

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.8, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: _buildStudentCard(
                      context,
                      student: student,
                      name: displayName,
                      avatarLetter: student.avatarLetter,
                      profileUrl: profileUrl,
                      isCurrentUser: isCurrentUser,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: _currentPage == index ? 18.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color:
                  _currentPage == index
                      ? Colors.blue[700]
                      : Colors.blue.withOpacity(0.3),
            ),
          );
        }),
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
    final avatarColor = Colors.blue[300]!;

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // "YOU" badge in upper right
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
                    borderRadius: BorderRadius.circular(8),
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

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: avatarColor, width: 2),
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
                                : _buildAvatarFallback(avatarLetter, avatarColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.split(' ')[0],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
