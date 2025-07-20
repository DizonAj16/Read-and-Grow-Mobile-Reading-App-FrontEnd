import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void showLoadingDialog(String lottieAsset, String loadingText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Lottie.asset(lottieAsset),
                  ),
                  SizedBox(height: 12),
                  Text(
                    loadingText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> hideLoadingDialog() async {
    await Future.delayed(Duration(milliseconds: 2500));
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// Shows a dialog with student info
  void _showStudentInfoDialog(Student student) async {
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ Get base URL from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    final baseUrl = '${uri.scheme}://${uri.authority}';

    // ✅ Build full image URL if profilePicture exists
    final String? profileUrl =
        (student.profilePicture != null && student.profilePicture!.isNotEmpty)
            ? "$baseUrl/storage/profile_images/${student.profilePicture}"
            : null;

    // ✅ Debugging the URL
    debugPrint("🖼️ Student Image URL: $profileUrl");

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: colorScheme.surfaceVariant.withOpacity(0.95),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_pin_rounded,
                  color: colorScheme.primary,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Text(
                  'Student Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Profile Picture (with fallback avatar)
                CircleAvatar(
                  radius: 60,
                  backgroundColor: colorScheme.primary,
                  backgroundImage:
                      profileUrl != null
                          ? NetworkImage(profileUrl)
                          : null, // ✅ Only load if URL is valid
                  child:
                      profileUrl == null
                          ? Text(
                            student.avatarLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 54,
                            ),
                          )
                          : null,
                ),
                const SizedBox(height: 12),
                Text(
                  student.studentName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  student.username ?? "-",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                // ✅ Info Box
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        icon: Icons.confirmation_num_rounded,
                        label: 'LRN',
                        value: student.studentLrn ?? "-",
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.school_rounded,
                        label: 'Grade',
                        value: student.studentGrade ?? "-",
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        icon: Icons.group_rounded,
                        label: 'Section',
                        value: student.studentSection ?? "-",
                        color: colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: colorScheme.primary),
                label: Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: color.withOpacity(0.9)),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
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
                Text(
                  "Show: ",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        if (widget.allStudents.isEmpty)
          Center(
            child: Text(
              'No students found.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: paginated.length,
              itemBuilder: (context, index) {
                final student = paginated[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 18,
                    ),
                    leading: FutureBuilder<String>(
                      future:
                          _getBaseUrl(), // ✅ Get the base URL you saved in SharedPreferences
                      builder: (context, snapshot) {
                        String? imageUrl;

                        if (snapshot.hasData &&
                            student.profilePicture != null &&
                            student.profilePicture!.isNotEmpty) {
                          imageUrl =
                              "${snapshot.data}/storage/profile_images/${student.profilePicture}";
                          // ✅ DEBUG LOGS
                          debugPrint("✅ Student: ${student.studentName}");
                          debugPrint(
                            "✅ Profile Picture File: ${student.profilePicture}",
                          );
                          debugPrint("✅ Full Image URL: $imageUrl");
                        } else {
                          debugPrint(
                            "⚠️ No profile picture for ${student.studentName} ${student.studentGrade} ${student.profilePicture}",
                          );
                          debugPrint("✅ Full Image URL: $imageUrl");
                        }

                        return CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          backgroundImage:
                              (imageUrl != null)
                                  ? NetworkImage(imageUrl)
                                  : null, // ✅ Load network image if available
                          child:
                              (imageUrl == null)
                                  ? Text(
                                    student
                                        .avatarLetter, // ✅ Fallback if no image
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  )
                                  : null,
                        );
                      },
                    ),

                    title: Text(
                      student.studentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          if (student.studentSection != null &&
                              student.studentSection!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Section: ${student.studentSection}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          if (student.studentGrade != null &&
                              student.studentGrade!.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Grade: ${student.studentGrade}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
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
                                  title: Text(
                                    '✏️ Edit Student',
                                    style: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
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
                                    TextButton.icon(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      icon: Icon(Icons.cancel),
                                      label: Text('Cancel'),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      icon: Icon(Icons.check),
                                      label: Text('Update'),
                                    ),
                                  ],
                                ),
                          );
                          if (updated == true) {
                            showLoadingDialog(
                              'assets/animation/edit.json',
                              "Updating Student...",
                            );
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
                              await hideLoadingDialog(); // Always close the dialog after the request

                              if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                          size: 22,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Student Updated successfully!",
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.lightBlue[700],
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      top: 80,
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
                              await hideLoadingDialog();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating student'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 30,
                                      ),

                                      SizedBox(width: 8),
                                      Text(
                                        "Confirm Delete",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete this Student?",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  actions: [
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.cancel,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      label: Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            showLoadingDialog(
                              'assets/animation/loading4.json',
                              "Deleting Student...",
                            );
                            try {
                              if (student.userId != null) {
                                final response = await ApiService.deleteUser(
                                  student.userId,
                                );
                                await hideLoadingDialog();

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
                                          Text(
                                            "Student deleted successfully!",
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.red[700],
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        top: 80,
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
                                await hideLoadingDialog(); // Ensure the loading closes even if userId is null
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Student user ID is missing'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              await hideLoadingDialog(); // ✅ Ensure the loading closes on error

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
                              value: 'add_to_class',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Add to Class'),
                                ],
                              ),
                            ),
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
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
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

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType inputType = TextInputType.text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: colorScheme.primary.withOpacity(0.07),
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
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
      ),
    );
  }
}
