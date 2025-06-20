import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';



class TeacherStudentListModal extends StatefulWidget {
  final List<Student> allStudents;
  final List<int> pageSizes;
  final int initialPageSize;
  final VoidCallback? onDataChanged; // ✅ Add this line

  const TeacherStudentListModal({
    required this.allStudents,
    required this.pageSizes,
    required this.initialPageSize,
    this.onDataChanged, // ✅ Also include here
  });

  @override
  State<TeacherStudentListModal> createState() =>
      TeacherStudentListModalState();
}

class TeacherStudentListModalState extends State<TeacherStudentListModal> {
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
                          final nameController = TextEditingController(
                            text: student.studentName,
                          );
                          final lrnController = TextEditingController(
                            text: student.studentLrn,
                          );
                          final gradeController = TextEditingController(
                            text: student.studentGrade,
                          );
                          final sectionController = TextEditingController(
                            text: student.studentSection,
                          );
                          final usernameController = TextEditingController(
                            text: student.username,
                          );

                          final updated = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Edit Student'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildInputField(
                                          'Name',
                                          nameController,
                                        ),
                                        _buildInputField('LRN', lrnController),
                                        _buildInputField(
                                          'Grade',
                                          gradeController,
                                        ),
                                        _buildInputField(
                                          'Section',
                                          sectionController,
                                        ),
                                        _buildInputField(
                                          'Username',
                                          usernameController,
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text('Update'),
                                    ),
                                  ],
                                ),
                          );

                          if (updated == true) {
                            try {
                              final response = await ApiService.updateUser(
                                userId: student.userId!,
                                body: {
                                  "username": usernameController.text.trim(),
                                  "student_name": nameController.text.trim(),
                                  "student_lrn": lrnController.text.trim(),
                                  "student_grade": gradeController.text.trim(),
                                  "student_section":
                                      sectionController.text.trim(),
                                },
                              );
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
                                        Text("Student Updated successfully!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.lightBlue[700],
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
                                // Refresh the list
                                widget.onDataChanged?.call();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update student'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating student'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
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
                                  // Refresh page and list
                                  setState(() {
                                    widget.allStudents.removeWhere(
                                      (s) => s.userId == student.userId,
                                    );
                                  });
                                  widget.onDataChanged?.call();
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
  
// --- Modal widget for student list (admin-style) ---


Widget _buildInputField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    ),
  );
}
}