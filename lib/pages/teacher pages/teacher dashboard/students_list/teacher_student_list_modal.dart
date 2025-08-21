import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dialog_utils.dart';
import 'student_info_dialog.dart';
import 'student_edit_dialog.dart';
import 'student_delete_dialog.dart';
import 'student_list_item.dart';

class TeacherStudentListModal extends StatefulWidget {
  final List<Student> allStudents;
  final List<int> pageSizes;
  final int initialPageSize;
  final VoidCallback? onDataChanged;

  const TeacherStudentListModal({
    super.key,
    required this.allStudents,
    required this.pageSizes,
    required this.initialPageSize,
    this.onDataChanged,
  });

  @override
  State<TeacherStudentListModal> createState() =>
      _TeacherStudentListModalState();
}

class _TeacherStudentListModalState extends State<TeacherStudentListModal> {
  late int _pageSize;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
  }

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
      setState(() => _currentPage--);
    }
  }

  void _goToNextPage() {
    if ((_currentPage + 1) * _pageSize < widget.allStudents.length) {
      setState(() => _currentPage++);
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

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  Future<void> _showStudentInfoDialog(Student student) async {
    final baseUrl = await _getBaseUrl();
    final profileUrl =
        (student.profilePicture != null && student.profilePicture!.isNotEmpty)
            ? "$baseUrl/${student.profilePicture}"
            : null;

    showDialog(
      context: context,
      builder:
          (context) => StudentInfoDialog(
            student: student,
            profileUrl: profileUrl,
            colorScheme: Theme.of(context).colorScheme,
          ),
    );
  }

  Future<void> _handleEditStudent(Student student) async {
    final nameController = TextEditingController(text: student.studentName);
    final lrnController = TextEditingController(text: student.studentLrn);
    final gradeController = TextEditingController(text: student.studentGrade);
    final sectionController = TextEditingController(
      text: student.studentSection,
    );
    final usernameController = TextEditingController(text: student.username);

    final updated = await showDialog<bool>(
      context: context,
      builder:
          (context) => StudentEditDialog(
            nameController: nameController,
            lrnController: lrnController,
            gradeController: gradeController,
            sectionController: sectionController,
            usernameController: usernameController,
          ),
    );

    if (updated == true) {
      await _performStudentUpdate(student, {
        "username": usernameController.text.trim(),
        "student_name": nameController.text.trim(),
        "student_lrn": lrnController.text.trim(),
        "student_grade": gradeController.text.trim(),
        "student_section": sectionController.text.trim(),
      });
    }
  }

  Future<void> _performStudentUpdate(
    Student student,
    Map<String, String> data,
  ) async {
    DialogUtils.showLoadingDialog(
      context,
      'assets/animation/edit.json',
      "Updating Student...",
    );

    try {
      final response = await UserService.updateUser(
        userId: student.userId!,
        body: data,
      );

      await DialogUtils.hideLoadingDialog(context);

      if (response.statusCode == 200) {
        _showSuccessSnackbar(
          "Student Updated successfully!",
          Colors.lightBlue[700],
        );
        widget.onDataChanged?.call();
      } else {
        _showErrorSnackbar('Failed to update student');
      }
    } catch (e) {
      await DialogUtils.hideLoadingDialog(context);
      _showErrorSnackbar('Error updating student');
    }
  }

  Future<void> _handleDeleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const StudentDeleteDialog(),
    );

    if (confirm == true) {
      await _performStudentDeletion(student);
    }
  }

  Future<void> _performStudentDeletion(Student student) async {
    DialogUtils.showLoadingDialog(
      context,
      'assets/animation/delete.json',
      "Deleting Student...",
    );

    try {
      if (student.userId != null) {
        final response = await UserService.deleteUser(student.userId);
        await DialogUtils.hideLoadingDialog(context);

        if (response.statusCode == 200) {
          _showSuccessSnackbar(
            "Student deleted successfully!",
            Colors.red[700],
          );
          setState(() {
            widget.allStudents.removeWhere((s) => s.userId == student.userId);
          });
          widget.onDataChanged?.call();
        } else {
          _showErrorSnackbar('Failed to delete student');
        }
      } else {
        await DialogUtils.hideLoadingDialog(context);
        _showErrorSnackbar('Student user ID is missing');
      }
    } catch (e) {
      await DialogUtils.hideLoadingDialog(context);
      _showErrorSnackbar('Error deleting student');
    }
  }

  void _showSuccessSnackbar(String message, Color? backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginated = _getPaginatedStudents();
    final totalPages = (widget.allStudents.length / _pageSize).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandleIndicator(context),
        _buildHeader(context),
        const SizedBox(height: 10),
        _buildStudentList(paginated),
        _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildHandleIndicator(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Student List",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        _buildPageSizeDropdown(),
      ],
    );
  }

  Widget _buildPageSizeDropdown() {
    return Row(
      children: [
        Text(
          "Show: ",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        Text(
          " per page",
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildStudentList(List<Student> students) {
    if (widget.allStudents.isEmpty) {
      return Center(
        child: Text(
          'No students found.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          return FutureBuilder<String>(
            future: _getBaseUrl(),
            builder: (context, snapshot) {
              String? imageUrl;
              if (snapshot.hasData &&
                  student.profilePicture != null &&
                  student.profilePicture!.isNotEmpty) {
                imageUrl = "${snapshot.data}/${student.profilePicture}";
              }

              return StudentListItem(
                student: student,
                imageUrl: imageUrl,
                onViewPressed: () => _showStudentInfoDialog(student),
                onEditPressed: () => _handleEditStudent(student),
                onDeletePressed: () => _handleDeleteStudent(student),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_circle_left_sharp, size: 40),
          onPressed: _currentPage > 0 ? _goToPreviousPage : null,
        ),
        Text(
          'Page ${widget.allStudents.isEmpty ? 0 : _currentPage + 1} of $totalPages',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_circle_right_sharp, size: 40),
          onPressed:
              (_currentPage + 1) * _pageSize < widget.allStudents.length
                  ? _goToNextPage
                  : null,
        ),
      ],
    );
  }
}
