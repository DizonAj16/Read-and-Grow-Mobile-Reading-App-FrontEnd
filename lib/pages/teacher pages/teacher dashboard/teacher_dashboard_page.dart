import 'package:deped_reading_app_laravel/pages/teacher%20pages/classes/class_details_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/create_class_or_student_dialog.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/students_list/teacher_student_list_modal.dart';
import 'package:deped_reading_app_laravel/widgets/navigation/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'cards/horizontal_card.dart';
import 'cards/class_card.dart';
import '../../../api/api_service.dart';
import '../../../models/student.dart';
import '../../../models/teacher.dart';
import '../../../models/classroom.dart';

/// Teacher Dashboard Page - Main entry point
class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  late Future<List<Student>> _studentsFuture;
  late Future<Teacher> _teacherFuture;
  late Future<int> _classCountFuture;
  late Future<List<Classroom>> _classesFuture;

  // Pagination state
  static const List<int> _pageSizes = [2, 5, 10, 20, 50];
  final int _pageSize = 10;
  List<Student> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _studentsFuture = _loadStudents();
    _teacherFuture = Teacher.fromPrefs();
    final classFuture = _loadClassesAndCount();
    _classesFuture = classFuture;
    _classCountFuture = classFuture.then((list) => list.length);
  }

  void _refreshStudentCount() {
    setState(() {
      _studentsFuture = _loadStudents();
    });
  }

  /// Loads students from API and local storage
  Future<List<Student>> _loadStudents() async {
    try {
      final apiList = await ApiService.fetchAllStudents();
      await ApiService.storeStudentsToPrefs(apiList);
    } catch (_) {
      // If API fails, try loading from local storage
      print("Failed to fetch students from API, loading from local storage.");
    }
    final students = await ApiService.getStudentsFromPrefs();
    setState(() {
      _allStudents = students;
    });
    return students;
  }

  void _refreshClasses() {
    setState(() {
      final classesFuture = _loadClassesAndCount();
      _classesFuture = classesFuture;
      _classCountFuture = classesFuture.then((list) => list.length);
    });
  }

  Future<List<Classroom>> _loadClassesAndCount() async {
    final classes = await ApiService.fetchTeacherClasses();
    await ApiService.storeClassesToPrefs(classes);
    return classes;
  }

  /// Shows the create class/student dialog
  /// Modify _showCreateClassOrStudentDialog to pass the refresh callback:
  void _showCreateClassOrStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => CreateClassOrStudentDialog(
            onStudentAdded: _refreshStudentCount,
            onClassAdded: _refreshClasses, // ✅ Refresh class list
          ),
    );
  }

  void showLoadingDialog(String lottieAsset, String loadingText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset(lottieAsset),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loadingText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> hideLoadingDialog(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
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

  void _viewClassDetails(BuildContext context, int classId) async {
    try {
      final details = await ApiService.getClassDetails(classId);
      if (!context.mounted) return;

      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(PageTransition(page: ClassDetailsPage(classDetails: details)));

      // ✅ Refresh after returning from ClassDetailsPage
      _refreshClasses();
    } catch (e) {
      print("Failed to load class details: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load class details.")),
      );
    }
  }

  void _editClass(BuildContext context, Classroom classroom) {
    final classNameController = TextEditingController(
      text: classroom.className,
    );
    final sectionController = TextEditingController(text: classroom.section);
    final schoolYearController = TextEditingController(
      text: classroom.schoolYear,
    );
    final gradeLevelController = TextEditingController(
      text: classroom.gradeLevel.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              const SizedBox(width: 8),
              Text(
                "Edit Class",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stylizedTextField(
                  context: context,
                  controller: classNameController,
                  label: "Class Name",
                ),
                const SizedBox(height: 12),
                _stylizedTextField(
                  context: context,
                  controller: sectionController,
                  label: "Section",
                ),
                const SizedBox(height: 12),
                _stylizedTextField(
                  context: context,
                  controller: schoolYearController,
                  label: "School Year (e.g., 2024-2025)",
                ),
                const SizedBox(height: 12),
                _stylizedTextField(
                  context: context,
                  controller: gradeLevelController,
                  label: "Grade Level",
                  inputType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              label: const Text("Cancel"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final newClassName = classNameController.text.trim();
                final newSection = sectionController.text.trim();
                final newSchoolYear = schoolYearController.text.trim();
                final newGradeLevel = gradeLevelController.text.trim();

                // Validate required fields
                if (newClassName.isEmpty ||
                    newSection.isEmpty ||
                    newSchoolYear.isEmpty ||
                    newGradeLevel.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }

                // Validate school year format (e.g., 2024-2025)
                final yearRegex = RegExp(r'^\d{4}-\d{4}$');
                if (!yearRegex.hasMatch(newSchoolYear)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Invalid school year format (e.g., 2024-2025).",
                      ),
                    ),
                  );
                  return;
                }

                // Validate grade level range
                final parsedGrade = int.tryParse(newGradeLevel);
                if (parsedGrade == null ||
                    parsedGrade < 1 ||
                    parsedGrade > 12) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Grade level must be a number between 1 and 12.",
                      ),
                    ),
                  );
                  return;
                }
                showLoadingDialog(
                  'assets/animation/edit.json',
                  'Updating Class...',
                );

                try {
                  final response = await ApiService.updateClass(
                    classId: classroom.id!,
                    body: {
                      'class_name': newClassName,
                      'grade_level': parsedGrade.toString(),
                      'section': newSection,
                      'school_year': newSchoolYear,
                    },
                  );
                  await hideLoadingDialog(context);

                  if (response.statusCode == 200) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext); // Close dialog
                      _refreshClasses(); // Refresh UI (you defined this earlier)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Class updated successfully!",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green[700],
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed: ${response.statusCode} ${response.body}",
                        ),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                } catch (e) {
                  await hideLoadingDialog(context);
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stylizedTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: primaryColor.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
    );
  }

  void _deleteClass(BuildContext context, int classId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              SizedBox(width: 8),
              Text(
                "Confirm Delete",
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this class?",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text("Cancel"),
              // Cancel button
              onPressed: () {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever, size: 18),
              onPressed: () {
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              label: const Text("Delete"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      showLoadingDialog('assets/animation/loading4.json', 'Deleting Class...');
      try {
        await ApiService.deleteClass(classId);
        await hideLoadingDialog(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "Class deleted successfully!",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
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
        _refreshClasses(); // Refresh or call setState
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete class')),
          );
        }
      }
    }
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
              FutureBuilder<int>(
                future: _classCountFuture,
                builder: (context, snapshot) {
                  final myClassCount = snapshot.data ?? 0;
                  return TeacherDashboardHorizontalCard(
                    title: "My Classes",
                    value: myClassCount.toString(),
                    gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                    icon: Icons.school,
                  );
                },
              ),
              SizedBox(width: 16),
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
        const SizedBox(height: 10),
        FutureBuilder<List<Classroom>>(
          future: _classesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final classrooms = snapshot.data ?? [];

            if (classrooms.isEmpty) {
              return Center(
                child: Text(
                  "No classes available",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            }

            return Column(
              children:
                  classrooms.map((classroom) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TeacherDashboardClassCard(
                        classId: classroom.id!,
                        className: classroom.className,
                        section:
                            "Grade ${classroom.gradeLevel} - ${classroom.section}",
                        studentCount: classroom.studentCount,
                        teacherName: classroom.teacherName ?? "Unknown",
                        onView: () => _viewClassDetails(context, classroom.id!),
                        onEdit: () => _editClass(context, classroom),
                        onDelete: () => _deleteClass(context, classroom.id!),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
