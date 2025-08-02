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

  /// ✅ Grade to Task Mapping
  final Map<int, List<int>> gradeTaskMap = {
    1: [1, 2],
    2: [3],
    3: [4],
    4: [5, 6, 7, 8, 9],
    5: [10, 11, 12, 13],
  };

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

  int _extractGradeLevel(dynamic grade) {
    if (grade == null) return 1;

    final gradeString = grade.toString();

    // ✅ If it's already a plain number
    if (int.tryParse(gradeString) != null) {
      return int.parse(gradeString).clamp(1, 5); // Ensure 1-5 range
    }

    // ✅ Extract digits if format is like "Grade 1", "G1", "Grade 05"
    final match = RegExp(r'(\d+)').firstMatch(gradeString);
    if (match != null) {
      final number = int.parse(match.group(0)!);
      return number.clamp(1, 5); // Ensure only 1-5 allowed
    }

    return 1; // Default fallback
  }

  /// ✅ Build card with progress bar (DYNAMIC based on grade)
  Widget _buildProgressCard(Student student) {
    final int gradeLevel = _extractGradeLevel(student.studentGrade);
    final int totalTasks = gradeTaskMap[gradeLevel]?.length ?? 0;

    final int completedTasks = student.completedTasks ?? 0;

    // Avoid dividing by 0
    final double progress =
        totalTasks > 0 ? (completedTasks / totalTasks).clamp(0, 1) : 0;

    return FutureBuilder<String>(
      future: _getBaseUrl(),
      builder: (context, snapshot) {
        final profileUrl =
            (snapshot.hasData &&
                    student.profilePicture != null &&
                    student.profilePicture!.isNotEmpty)
                ? "${snapshot.data}/storage/profile_images/${student.profilePicture}"
                : null;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Profile or fallback
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child:
                      profileUrl != null
                          ? Image.network(
                            profileUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildFallbackAvatar(student),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Grade $gradeLevel • ${student.studentSection ?? ''}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
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
                        "$completedTasks / $totalTasks Tasks Completed",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              progress >= 1
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

  Widget _buildEmptyStateCard() {
    return Center(
      child: Card(
        elevation: 6,
        shadowColor: Colors.deepPurple.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple.withOpacity(0.1),
                child: Icon(
                  Icons.person_off_rounded,
                  size: 36,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "No Students Yet 👥",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Students have not been assigned to this class.\nPlease check again later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.5,
                  height: 1.4,
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
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadAssignedStudents,
                child:
                    assignedStudents.isEmpty
                        ? ListView(children: [_buildEmptyStateCard()])
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: assignedStudents.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildProgressCard(assignedStudents[index]),
                        ),
              ),
    );
  }
}
