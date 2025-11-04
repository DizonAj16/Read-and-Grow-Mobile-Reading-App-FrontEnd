import 'package:deped_reading_app_laravel/pages/student%20pages/student_quiz_pages.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassContentScreen extends StatefulWidget {
  final String classRoomId;

  const ClassContentScreen({super.key, required this.classRoomId});

  @override
  State<ClassContentScreen> createState() => _ClassContentScreenState();
}

class _ClassContentScreenState extends State<ClassContentScreen> {
  late Future<List<Map<String, dynamic>>> _lessonsFuture;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessons();
  }

  /// Check if quiz has already been submitted by student
  Future<bool> _isQuizAlreadyTaken(String assignmentId, String quizId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final submissionRes = await supabase
          .from('student_submissions')
          .select('id')
          .eq('assignment_id', assignmentId)
          .eq('student_id', user.id)
          .limit(1);

      // Check if any submission exists (even if multiple)
      return submissionRes.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking quiz submission: $e');
      return false;
    }
  }

  /// Get quiz score if already submitted (get the most recent submission)
  Future<Map<String, dynamic>?> _getQuizScore(String assignmentId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final submissionRes = await supabase
          .from('student_submissions')
          .select('score, max_score, submitted_at')
          .eq('assignment_id', assignmentId)
          .eq('student_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return submissionRes;
    } catch (e) {
      debugPrint('Error getting quiz score: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLessons() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('assignments')
        .select('''
          id,
          task_id,
          tasks (
            id,
            title,
            description,
            quizzes (
              id,
              title
            )
          )
        ''')
        .eq('class_room_id', widget.classRoomId);

    if (response.isEmpty) return [];

    return response.map<Map<String, dynamic>>((assignment) {
      final task = assignment['tasks'];
      return {
        "assignment_id": assignment['id'], // Store assignment ID
        "task_id": task['id'], // Store task ID
        "title": task['title'],
        "description": task['description'],
        "quizzes": task['quizzes'] ?? [],
      };
    }).toList();
  }

  Future<void> _refreshLessons() async {
    final newLessons = await _fetchLessons();
    setState(() {
      _lessonsFuture = Future.value(newLessons);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lessons & Quizzes")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _lessonsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final lessons = snapshot.data ?? [];

          if (lessons.isEmpty) {
            return const Center(child: Text("No lessons or quizzes assigned yet."));
          }

          return RefreshIndicator(
            onRefresh: _refreshLessons,
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final quizzes = (lesson['quizzes'] as List)
                    .cast<Map<String, dynamic>>();

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    leading: const Icon(Icons.menu_book, color: Colors.blue),
                    title: Text(
                      lesson['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      lesson['description'] ?? 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      if (quizzes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("No quizzes for this lesson."),
                        )
                      else
                        ...quizzes.map((quiz) => FutureBuilder<bool>(
                          future: _isQuizAlreadyTaken(lesson['assignment_id'], quiz['id']),
                          builder: (context, takenSnapshot) {
                            final isTaken = takenSnapshot.data ?? false;
                            
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: isTaken ? _getQuizScore(lesson['assignment_id']) : Future.value(null),
                              builder: (context, scoreSnapshot) {
                                final score = scoreSnapshot.data;
                                
                                return ListTile(
                                  leading: Icon(
                                    isTaken ? Icons.check_circle : Icons.quiz,
                                    color: isTaken ? Colors.green : Colors.orange,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(quiz['title']),
                                      ),
                                      if (isTaken && score != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${score['score']}/${score['max_score']}',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: isTaken
                                      ? const Text(
                                          'Quiz already completed',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        )
                                      : const Text('Tap to take quiz'),
                                  trailing: isTaken
                                      ? const Icon(Icons.lock, color: Colors.grey)
                                      : const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: isTaken
                                      ? () {
                                          // Show quiz results dialog
                                          if (score != null) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Quiz Results'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'You have already completed this quiz.',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      padding: const EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            'Your Score',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            '${score['score']} / ${score['max_score']}',
                                                            style: TextStyle(
                                                              fontSize: 32,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.green.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => StudentQuizPage(
                                                quizId: quiz['id'],
                                                assignmentId: lesson['assignment_id'],
                                                studentId: Supabase.instance.client
                                                    .auth.currentUser!.id,
                                              ),
                                            ),
                                          ).then((_) {
                                            // Refresh after returning from quiz
                                            _refreshLessons();
                                          });
                                        },
                                );
                              },
                            );
                          },
                        )),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
