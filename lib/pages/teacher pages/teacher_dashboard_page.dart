import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/teacher_page_widgets/horizontal_card.dart';
import '../../widgets/teacher_page_widgets/class_card.dart';
import '../../api/api_service.dart';
import '../../models/student.dart';
import '../../models/teacher.dart';

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

  /// Loads students from API and local storage
  Future<List<Student>> _loadStudents() async {
    try {
      final apiList = await ApiService.fetchAllStudents();
      await ApiService.storeStudentsToPrefs(apiList);
    } catch (_) {}
    final students = await ApiService.getStudentsFromPrefs();
    setState(() {
      _allStudents = students;
      _currentPage = 0;
    });
    return students;
  }

  /// Shows the create class/student dialog
  void _showCreateClassOrStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateClassOrStudentDialog(),
    );
  }

  /// Shows the student list modal bottom sheet
  Future<void> _showStudentListModal(BuildContext context) async {
    if (_allStudents.isEmpty) {
      await _studentsFuture;
    }
    showModalBottomSheet(
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
                    child: _TeacherStudentListModal(
                      allStudents: _allStudents,
                      pageSizes: _pageSizes,
                      initialPageSize: _pageSize,
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
            _buildViewStudentListButton(),
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
  Widget _buildViewStudentListButton() {
    return ElevatedButton.icon(
      icon: Image.asset(
        'assets/icons/graduating-student.png',
        width: 40,
        height: 40,
      ),
      label: Text(
        "View Student List",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
      onPressed: () => _showStudentListModal(context),
    );
  }

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

// --- Dialog for Create Class or Student (admin-style, API integrated for student) ---
class _CreateClassOrStudentDialog extends StatefulWidget {
  @override
  State<_CreateClassOrStudentDialog> createState() =>
      _CreateClassOrStudentDialogState();
}

class _CreateClassOrStudentDialogState
    extends State<_CreateClassOrStudentDialog> {
  int selectedTab = 0; // 0 = Class, 1 = Student

  // Controllers for form fields
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController classSectionController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLrnController = TextEditingController();
  final TextEditingController studentSectionController =
      TextEditingController();
  final TextEditingController studentGradeController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  final TextEditingController studentPasswordController =
      TextEditingController();
  final TextEditingController confirmStudentPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _studentPasswordVisible = false;
  bool _studentConfirmPasswordVisible = false;

  @override
  void dispose() {
    classNameController.dispose();
    classSectionController.dispose();
    studentNameController.dispose();
    studentLrnController.dispose();
    studentSectionController.dispose();
    studentGradeController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmStudentPasswordController.dispose();
    super.dispose();
  }

  /// Shows a loading dialog with a message
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Shows a success dialog
  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 35),
                SizedBox(width: 8),
                const Text('Success'),
              ],
            ),
            content: Text(message),
          ),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop(); // Close success dialog
  }

  /// Handles error dialog
  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close loading dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 35),
                  SizedBox(width: 8),
                  Text(title),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// Handles student creation via API
  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _showLoadingDialog("Creating student account...");
    try {
      final response = await ApiService.registerStudent({
        'student_username': studentUsernameController.text,
        'student_password': studentPasswordController.text,
        'student_password_confirmation': confirmStudentPasswordController.text,
        'student_name': studentNameController.text,
        'student_lrn': studentLrnController.text,
        'student_grade': studentGradeController.text,
        'student_section': studentSectionController.text,
      });

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _handleErrorDialog(
          title: 'Server Error',
          message:
              response.statusCode >= 500
                  ? 'A server error occurred. Please try again later.'
                  : 'Server error: Invalid response format.',
        );
        return;
      }

      if (response.statusCode == 201) {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog(data['message'] ?? 'Student account created!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text("Student account created successfully!"),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _handleErrorDialog(
          title: 'Registration Failed',
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      _handleErrorDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Builds a password field with show/hide toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.lock,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  /// Builds a simple text field with icon and validation
  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  /// Student creation form
  Widget _buildStudentForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSimpleTextField(
          controller: studentNameController,
          label: "Student Name",
          icon: Icons.person,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentLrnController,
          label: "LRN",
          icon: Icons.confirmation_number,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'LRN is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentGradeController,
          label: "Grade",
          icon: Icons.grade,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Grade is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentSectionController,
          label: "Section",
          icon: Icons.group,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Section is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentUsernameController,
          label: "Username",
          icon: Icons.account_circle,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Username is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: studentPasswordController,
          label: "Password",
          visible: _studentPasswordVisible,
          onToggle:
              () => setState(
                () => _studentPasswordVisible = !_studentPasswordVisible,
              ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Password is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: confirmStudentPasswordController,
          label: "Confirm Password",
          visible: _studentConfirmPasswordVisible,
          onToggle:
              () => setState(
                () =>
                    _studentConfirmPasswordVisible =
                        !_studentConfirmPasswordVisible,
              ),
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Confirm Password is required';
            if (value != studentPasswordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(
            selectedTab == 0 ? Icons.class_ : Icons.person_add,
            color: Theme.of(context).colorScheme.primary,
            size: 50,
          ),
          SizedBox(height: 8),
          Text(
            selectedTab == 0 ? "Create New Class" : "Create Student Account",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          // Toggle buttons for selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text("Class"),
                selected: selectedTab == 0,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => selectedTab = 0);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color:
                      selectedTab == 0
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              ChoiceChip(
                label: Text("Student"),
                selected: selectedTab == 1,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => selectedTab = 1);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color:
                      selectedTab == 1
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode:
              _autoValidate
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
          child:
              selectedTab == 0
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: classNameController,
                        decoration: InputDecoration(
                          labelText: "Class Name",
                          prefixIcon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: classSectionController,
                        decoration: InputDecoration(
                          labelText: "Class Section",
                          prefixIcon: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                  : _buildStudentForm(context),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (selectedTab == 0) {
                      // Create Class logic (local only)
                      String className = classNameController.text.trim();
                      String classSection = classSectionController.text.trim();

                      if (className.isNotEmpty && classSection.isNotEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Class created successfully!"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill in all fields")),
                        );
                      }
                    } else {
                      _addStudent();
                    }
                  },
          child: Text(
            selectedTab == 0 ? "Create" : "Create",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// --- Modal widget for student list (admin-style) ---
class _TeacherStudentListModal extends StatefulWidget {
  final List<Student> allStudents;
  final List<int> pageSizes;
  final int initialPageSize;

  const _TeacherStudentListModal({
    required this.allStudents,
    required this.pageSizes,
    required this.initialPageSize,
  });

  @override
  State<_TeacherStudentListModal> createState() =>
      _TeacherStudentListModalState();
}

class _TeacherStudentListModalState extends State<_TeacherStudentListModal> {
  late int _pageSize;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
  }

  /// Returns the students for the current page
  List<Student> _getPaginatedStudents() {
    final start = _currentPage * _pageSize;
    final end = ((_currentPage + 1) * _pageSize).clamp(
      0,
      widget.allStudents.length,
    );
    return widget.allStudents.sublist(start, end);
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if ((_currentPage + 1) * _pageSize < widget.allStudents.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _onPageSizeChanged(int? newSize) {
    if (newSize != null && newSize != _pageSize) {
      setState(() {
        _pageSize = newSize;
        _currentPage = 0;
      });
    }
  }

  /// Shows a dialog with student info
  void _showStudentInfoDialog(Student student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                SizedBox(width: 8),
                Text('Student Info'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar and Name
                Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.85),
                      radius: 36,
                      child: Text(
                        student.avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      student.studentName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Username: ${student.username ?? "-"}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: 18),
                // Info section
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'LRN: ${student.studentLrn ?? "-"}',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.grade,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Grade: ${student.studentGrade ?? "-"}',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Section: ${student.studentSection ?? "-"}',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginated = _getPaginatedStudents();
    final totalPages = (widget.allStudents.length / _pageSize).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Student List",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Text("Show: "),
                DropdownButton<int>(
                  value: _pageSize,
                  items:
                      widget.pageSizes
                          .map(
                            (size) => DropdownMenuItem<int>(
                              value: size,
                              child: Text(size.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: _onPageSizeChanged,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(" per page"),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        if (widget.allStudents.isEmpty)
          Center(child: Text('No students found.'))
        else
          Expanded(
            child: ListView.builder(
              itemCount: paginated.length,
              itemBuilder: (context, index) {
                final student = paginated[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.85),
                      child: Text(
                        student.avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      radius: 24,
                    ),
                    title: Text(
                      student.studentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (student.studentSection != null &&
                            student.studentSection!.isNotEmpty)
                          "Section: ${student.studentSection}",
                        if (student.studentGrade != null &&
                            student.studentGrade!.isNotEmpty)
                          "Grade: ${student.studentGrade}",
                      ].join("   "),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'view') {
                          _showStudentInfoDialog(student);
                        } else if (value == 'edit') {
                          // TODO: Implement edit logic
                        } else if (value == 'delete') {
                          // TODO: Implement delete logic
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Student'),
                                    ],
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this student?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            try {
                              if (student.userId != null) {
                                final response = await ApiService.deleteUser(
                                  student.userId,
                                );
                                final data =
                                    response.body.isNotEmpty
                                        ? response.body
                                        : '';
                                if (response.statusCode == 200) {
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
                                          Text("Student deleted successfully!"),
                                        ],
                                      ),
                                      backgroundColor: Colors.green[700],
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        top: 20,
                                        left: 20,
                                        right: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 8,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  // Refresh list

                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete student'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Student user ID is missing'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting student'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('View'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_circle_left_sharp, size: 40),
              onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            ),
            Text(
              'Page ${widget.allStudents.isEmpty ? 0 : _currentPage + 1} of $totalPages',
            ),
            IconButton(
              icon: Icon(Icons.arrow_circle_right_sharp, size: 40),
              onPressed:
                  (_currentPage + 1) * _pageSize < widget.allStudents.length
                      ? _goToNextPage
                      : null,
            ),
          ],
        ),
      ],
    );
  }
}
