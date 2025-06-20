import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/create_class_or_student_dialog';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/students_list/teacher_student_list_modal.dart';
import 'package:flutter/material.dart';
import 'cards/horizontal_card.dart';
import 'cards/class_card.dart';
import '../../../api/api_service.dart';
import '../../../models/student.dart';
import '../../../models/teacher.dart';

/// Teacher Dashboard Page - Main entry point
class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  late Future<List<Student>> _studentsFuture;
  late Future<Teacher> _teacherFuture;

  // Pagination state
  static const List<int> _pageSizes = [2, 5, 10, 20, 50];
  final int _pageSize = 10;
  int _currentPage = 0;
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
    _teacherFuture = Teacher.fromPrefs();
  }
  
  void _refreshStudentCount() {
  setState(() {
    // This will force the FutureBuilder to rebuild
    _studentsFuture = _loadStudents();
  });
}

  /// Loads students from API and local storage
  Future<List<Student>> _loadStudents() async {
    try {
      final apiList = await ApiService.fetchAllStudents();
      await ApiService.storeStudentsToPrefs(apiList);
    } catch (_) {
      // Do nothing
    }
    final students = await ApiService.getStudentsFromPrefs();
    setState(() {
      _allStudents = students;
      _currentPage = 0;
    });
    return students;
  }

  /// Shows the create class/student dialog
  /// Modify _showCreateClassOrStudentDialog to pass the refresh callback:
void _showCreateClassOrStudentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => CreateClassOrStudentDialog(
      onStudentAdded: _refreshStudentCount,
    ),
  );
}

  /// Shows the student list modal bottom sheet
  Future<void> _showStudentListModal(BuildContext context) async {
    if (_allStudents.isEmpty) {
      await _studentsFuture;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TeacherStudentListModal(
                      allStudents: _allStudents,
                      pageSizes: _pageSizes,
                      initialPageSize: _pageSize,
                      onDataChanged: () {
                        setState(() {
                          _studentsFuture = _loadStudents(); // REFRESH DATA
                        });
                      },
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating action button for create class/student
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateClassOrStudentDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Create Class or Student",
        shape: CircleBorder(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeMessage(),
            SizedBox(height: 20),
            _buildStatisticsCards(),
            SizedBox(height: 20),
            _buildMyClassesSection(),
          ],
        ),
      ),
    );
  }

  /// Welcome message for teacher
  Widget _buildWelcomeMessage() {
    return FutureBuilder<Teacher>(
      future: _teacherFuture,
      builder: (context, snapshot) {
        final username =
            snapshot.data?.username ?? snapshot.data?.name ?? "Teacher";
        return Text(
          "Welcome, $username!",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
    );
  }

  /// Horizontal statistics cards
  Widget _buildStatisticsCards() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        int studentCount = 0;
        if (snapshot.hasData) {
          studentCount = snapshot.data!.length;
        }
        return SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              TeacherDashboardHorizontalCard(
                title: "Students",
                value: studentCount.toString(),
                gradientColors: [Colors.blue, Colors.lightBlueAccent],
                icon: Icons.people,
                onPressed: () => _showStudentListModal(context),
              ),
              SizedBox(width: 16),
              TeacherDashboardHorizontalCard(
                title: "Sections",
                value: "0",
                gradientColors: [Colors.green, Colors.lightGreenAccent],
                icon: Icons.class_,
              ),
              SizedBox(width: 16),
              TeacherDashboardHorizontalCard(
                title: "My Classes",
                value: "0",
                gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                icon: Icons.school,
              ),
              SizedBox(width: 16),
              TeacherDashboardHorizontalCard(
                title: "Rankings",
                value: "Top 10",
                gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                icon: Icons.star,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Button to view student list


  /// My Classes section
  Widget _buildMyClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Classes",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 10),
        Column(
          children: [
            TeacherDashboardClassCard(
              className: "English 1",
              section: "Grade 1 - Section A",
              studentCount: 30,
            ),
            TeacherDashboardClassCard(
              className: "English 2",
              section: "Grade 2 - Section B",
              studentCount: 25,
            ),
            TeacherDashboardClassCard(
              className: "English 3",
              section: "Grade 3 - Section C",
              studentCount: 20,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement "See more" logic for Class List
                },
                child: Text(
                  "See more...",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}





