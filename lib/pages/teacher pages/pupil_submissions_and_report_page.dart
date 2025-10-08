import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSubmissionsPage extends StatefulWidget {
  const StudentSubmissionsPage({super.key});

  @override
  State<StudentSubmissionsPage> createState() => _StudentSubmissionsPageState();
}

class _StudentSubmissionsPageState extends State<StudentSubmissionsPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> submissions = [];
  Map<String, String> studentNames = {}; // user_id -> student_name

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      // Step 1: Fetch all submissions
      final subsRes = await supabase
          .from('student_submissions')
          .select('id, student_id, attempt_number, score, max_score, audio_file_path, submitted_at, quiz_answers')
          .order('submitted_at', ascending: false);

      final List<Map<String, dynamic>> subs = List<Map<String, dynamic>>.from(subsRes);

      final userIds = subs.map((s) => s['student_id']).toSet().toList();
      final usersRes = await supabase
          .from('students')
          .select('user_id, student_name')
          .filter('user_id', 'in', userIds);

      final Map<String, String> names = {
        for (var u in usersRes) u['user_id'] as String: u['student_name'] as String
      };

      setState(() {
        submissions = subs;
        studentNames = names;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading submissions: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (submissions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No submissions found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Student Submissions")),
      body: ListView.builder(
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final sub = submissions[index];
          final studentName = studentNames[sub['student_id']] ?? 'Unknown';

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text("Student: $studentName"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Score: ${sub['score'] ?? '-'} / ${sub['max_score'] ?? '-'}"),
                  Text("Attempt: ${sub['attempt_number']}"),
                  if (sub['audio_file_path'] != null)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Text("Audio Answer:"),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            final audioUrl = sub['audio_file_path'];
                            // TODO: implement audio playback with just_audio or audioplayers
                          },
                        ),
                      ],
                    ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
