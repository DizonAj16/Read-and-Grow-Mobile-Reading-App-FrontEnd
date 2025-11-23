import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewGradedRecordingsPage extends StatefulWidget {
  const ViewGradedRecordingsPage({super.key});

  @override
  State<ViewGradedRecordingsPage> createState() => _ViewGradedRecordingsPageState();
}

class _ViewGradedRecordingsPageState extends State<ViewGradedRecordingsPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> gradedRecordings = [];
  Map<String, String> studentNames = {};
  Map<String, Map<String, dynamic>> taskDetails = {};

  @override
  void initState() {
    super.initState();
    _loadGradedRecordings();
  }

  Future<void> _loadGradedRecordings() async {
    setState(() => isLoading = true);

    try {
      // Fetch all graded recordings (with and without task_id)
      final recordingsRes = await supabase
          .from('student_recordings')
          .select('*')
          .eq('needs_grading', false)
          .not('score', 'is', null)
          .order('graded_at', ascending: false);

      setState(() {
        gradedRecordings = List<Map<String, dynamic>>.from(recordingsRes);
      });

      // Load student names
      final studentIds = gradedRecordings
          .map((r) => r['student_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      if (studentIds.isNotEmpty) {
        final studentsRes = await supabase
            .from('students')
            .select('id, student_name')
            .inFilter('id', studentIds);

        for (var student in studentsRes) {
          final uid = student['id']?.toString();
          if (uid != null) {
            studentNames[uid] = student['student_name']?.toString() ?? 'Unknown';
          }
        }
      }

      // Load task details (only for recordings with task_id)
      final taskIds = gradedRecordings
          .map((r) => r['task_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      if (taskIds.isNotEmpty) {
        final tasksRes = await supabase
            .from('tasks')
            .select('id, title, description')
            .inFilter('id', taskIds);

        for (var task in tasksRes) {
          final tid = task['id']?.toString();
          if (tid != null) {
            taskDetails[tid] = Map<String, dynamic>.from(task);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading graded recordings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading graded recordings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _getTaskTitle(Map<String, dynamic> recording) {
    final taskId = recording['task_id']?.toString();
    if (taskId != null && taskId.isNotEmpty && taskDetails.containsKey(taskId)) {
      return taskDetails[taskId]!['title']?.toString() ?? 'Unknown Task';
    }
    
    // Try to parse from teacher_comments for reading materials
    final comments = recording['teacher_comments']?.toString();
    if (comments != null && comments.startsWith('{')) {
      try {
        final materialInfo = jsonDecode(comments);
        return materialInfo['material_id']?.toString() ?? 'Reading Material';
      } catch (_) {
        // Not JSON
      }
    }
    
    return 'Reading Material';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✅ Graded Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGradedRecordings,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : gradedRecordings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No graded recordings yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGradedRecordings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: gradedRecordings.length,
                    itemBuilder: (context, index) {
                      final recording = gradedRecordings[index];
                      final studentId = recording['student_id']?.toString() ?? '';
                      final studentName = studentNames[studentId] ?? 'Unknown Student';
                      final taskTitle = _getTaskTitle(recording);
                      final score = recording['score'];
                      final scoreValue = score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0;
                      final comments = recording['teacher_comments']?.toString();
                      final gradedAt = recording['graded_at']?.toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getScoreColor(scoreValue / 10.0).withOpacity(0.2),
                            child: Icon(
                              Icons.check_circle,
                              color: _getScoreColor(scoreValue / 10.0),
                            ),
                          ),
                          title: Text(
                            studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(taskTitle),
                              if (gradedAt != null)
                                Text(
                                  _formatDateTime(gradedAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getScoreColor(scoreValue / 10.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${scoreValue.toStringAsFixed(1)}/10',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Score: ${scoreValue.toStringAsFixed(1)}/10',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comments != null && 
                                      comments.isNotEmpty && 
                                      !comments.startsWith('{'))
                                    ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.comment, color: Colors.blue, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comments,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Color _getScoreColor(double percent) {
    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime);
      return 'Graded: ${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Invalid date';
    }
  }
}

