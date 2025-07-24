import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentsProgressPage extends StatefulWidget {
  final int classId;

  const StudentsProgressPage({super.key, required this.classId});

  @override
  State<StudentsProgressPage> createState() => _StudentsProgressPageState();
}

class _StudentsProgressPageState extends State<StudentsProgressPage> {
  List<Student> assignedStudents = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedStudents();
  }

  Future<void> _loadAssignedStudents() async {
    setState(() => loading = true);
    try {
      final students = await ApiService.getAssignedStudents(widget.classId);
      if (mounted) {
        setState(() => assignedStudents = students);
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// ✅ Build card with progress bar
  Widget _buildProgressCard(Student student) {
    final completedTasks = student.completedTasks ?? 0; // ✅ Make sure your API adds this field
    final progress = completedTasks / 13;

    return FutureBuilder<String>(
      future: _getBaseUrl(),
      builder: (context, snapshot) {
        final profileUrl = (snapshot.hasData &&
                student.profilePicture != null &&
                student.profilePicture!.isNotEmpty)
            ? "${snapshot.data}/storage/profile_images/${student.profilePicture}"
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Profile or fallback
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: profileUrl != null
                      ? Image.network(
                          profileUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(student),
                        )
                      : _buildFallbackAvatar(student),
                ),
                const SizedBox(width: 14),

                /// ✅ Name & Progress
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Grade ${student.studentGrade ?? 'N/A'} • ${student.studentSection ?? ''}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation(
                          progress >= 1 ? Colors.green : Colors.deepPurple,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$completedTasks / 13 Tasks Completed",
                        style: TextStyle(
                          fontSize: 12,
                          color: progress >= 1
                              ? Colors.green.shade700
                              : Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackAvatar(Student student) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.deepPurple.shade100,
      child: Text(
        student.avatarLetter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple.shade700,
        ),
      ),
    );
  }

  /// ✅ Stylized Empty State Card
  Widget _buildEmptyStateCard() {
    return Center(
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.deepPurple.shade400,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                "No students assigned yet.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssignedStudents,
              child: assignedStudents.isEmpty
                  ? ListView(children: [_buildEmptyStateCard()])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: assignedStudents.length,
                      itemBuilder: (context, index) =>
                          _buildProgressCard(assignedStudents[index]),
                    ),
            ),
    );
  }
}
