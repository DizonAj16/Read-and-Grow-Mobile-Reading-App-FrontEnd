import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignStudentPage extends StatefulWidget {
  final int classId;

  const AssignStudentPage({super.key, required this.classId});

  @override
  State<AssignStudentPage> createState() => _AssignStudentPageState();
}

class _AssignStudentPageState extends State<AssignStudentPage> {
  List<Student> allStudents = [];
  List<Student> assignedStudents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ Load students
  Future<void> _loadStudents() async {
    if (!mounted) return; // ✅ avoid unnecessary setState if disposed

    setState(() {
      loading = true;
      allStudents = [];
      assignedStudents = [];
    });

    try {
      final assigned = await ApiService.getAssignedStudents(widget.classId);
      final unassigned = await ApiService.getUnassignedStudents();

      if (!mounted) return; // ✅ Check again after async
      setState(() {
        assignedStudents = assigned;
        allStudents = unassigned;
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to load students: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _assignStudent(Student student) async {
    final res = await ApiService.assignStudent(
      studentId: student.id,
      classRoomId: widget.classId,
    );

    if (res.statusCode == 200) {
      setState(() {
        final updatedStudent = student.copyWith(classRoomId: widget.classId);
        allStudents.removeWhere((s) => s.id == student.id);
        assignedStudents.add(updatedStudent);
      });
      _showSnackBar("Student assigned successfully");
    } else {
      _showSnackBar("Failed to assign student: ${res.body}", isError: true);
    }
  }

  Future<void> _unassignStudent(Student student) async {
    final res = await ApiService.unassignStudent(studentId: student.id);

    if (res.statusCode == 200) {
      setState(() {
        final updatedStudent = student.copyWith(classRoomId: null);
        assignedStudents.removeWhere((s) => s.id == student.id);
        allStudents.add(updatedStudent);
      });
      _showSnackBar("Student unassigned successfully");
    } else {
      _showSnackBar("Failed to unassign student: ${res.body}", isError: true);
    }
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  Widget _buildStudentCard(Student student, {bool isAssigned = false}) {
    return FutureBuilder<String>(
      future: _getBaseUrl(),
      builder: (context, snapshot) {
        final String? profileUrl =
            (snapshot.hasData &&
                    student.profilePicture != null &&
                    student.profilePicture!.isNotEmpty)
                ? "${snapshot.data}/storage/profile_images/${student.profilePicture}"
                : null;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: isAssigned ? Colors.green.shade200 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Profile Picture (or Fallback Avatar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child:
                      profileUrl != null
                          ? Image.network(
                            profileUrl,
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback(student, isAssigned);
                            },
                          )
                          : _buildAvatarFallback(student, isAssigned),
                ),
                const SizedBox(width: 14),

                /// ✅ Student Name & Chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: -8,
                        children: [
                          Chip(
                            label: Text(
                              "Grade ${student.studentGrade ?? 'N/A'}",
                            ),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: const TextStyle(fontSize: 12),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          if (student.studentSection != null &&
                              student.studentSection!.isNotEmpty)
                            Chip(
                              label: Text(student.studentSection!),
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: const TextStyle(fontSize: 12),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// ✅ Assign / Unassign Button
                isAssigned
                    ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text(
                        "Unassign",
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        // ✅ Unassign
                        final confirmed = await _showConfirmationDialog(
                          title: "Unassign Student",
                          content:
                              "Are you sure you want to unassign ${student.studentName} from this class? All the student's data will be lost.",
                          highlightText:
                              student.studentName, // ✅ Highlights in red
                          confirmText: "Unassign",
                          isDestructive: true,
                        );
                        if (confirmed) {
                          _unassignStudent(student);
                        }
                      },
                    )
                    : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        "Assign",
                        style: TextStyle(fontSize: 13),
                      ),
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          title: "Assign Student",
                          content:
                              "Are you sure you want to assign ${student.studentName} to this class?",
                          highlightText:
                              student.studentName, // ✅ Highlights in blue
                          confirmText: "Assign",
                        );
                        if (confirmed) {
                          _assignStudent(student);
                        }
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(Student student, bool isAssigned) {
    return CircleAvatar(
      radius: 22,
      backgroundColor:
          isAssigned ? Colors.green.shade100 : Colors.blue.shade100,
      child: Text(
        student.avatarLetter,
        style: TextStyle(
          color: isAssigned ? Colors.green.shade700 : Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    String? highlightText, // ✅ Dynamic text to highlight
    String confirmText = "Yes",
    String cancelText = "Cancel",
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(
                    isDestructive
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline,
                    color: isDestructive ? Colors.redAccent : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content:
                  highlightText != null
                      ? RichText(
                        text: TextSpan(
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          children: _buildHighlightedText(
                            content,
                            highlightText,
                            isDestructive ? Colors.redAccent : Colors.blue,
                          ),
                        ),
                      )
                      : Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(cancelText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDestructive ? Colors.redAccent : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// ✅ Helper: Splits the text and highlights the first occurrence only
  List<TextSpan> _buildHighlightedText(
    String content,
    String highlight,
    Color highlightColor,
  ) {
    final startIndex = content.indexOf(highlight);

    if (startIndex == -1) {
      return [TextSpan(text: content)];
    }

    return [
      TextSpan(text: content.substring(0, startIndex)),
      TextSpan(
        text: highlight,
        style: TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
      ),
      TextSpan(text: content.substring(startIndex + highlight.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadStudents,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Available Students",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (allStudents.isEmpty)
                        const Text(
                          "No unassigned students found.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ...allStudents.map(
                        (student) =>
                            _buildStudentCard(student, isAssigned: false),
                      ),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1),

                      Text(
                        "Assigned Students",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (assignedStudents.isEmpty)
                        const Text(
                          "No students assigned to this class.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ...assignedStudents.map(
                        (student) =>
                            _buildStudentCard(student, isAssigned: true),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
