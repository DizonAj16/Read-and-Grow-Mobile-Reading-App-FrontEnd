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
        "id": task['id'],
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
                        ...quizzes.map((quiz) => ListTile(
                          leading:
                          const Icon(Icons.quiz, color: Colors.green),
                          title: Text(quiz['title']),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentQuizPage(
                                  quizId: quiz['id'],
                                  assignmentId: lesson['id'],
                                  studentId: Supabase
                                      .instance.client.auth.currentUser!.id,
                                ),
                              ),
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
