import 'dart:convert';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_quiz_pages.dart';
import 'package:flutter/material.dart';
class StudentQuizzesPage extends StatefulWidget {
  final String studentId;
  const StudentQuizzesPage({super.key, required this.studentId});

  @override
  State<StudentQuizzesPage> createState() => _StudentQuizzesPageState();
}

class _StudentQuizzesPageState extends State<StudentQuizzesPage> {
  List<Map<String, dynamic>> quizzes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final result = await ClassroomService.fetchStudentQuizzes(widget.studentId);
    setState(() {
      quizzes = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("My Quizzes")),
      body: ListView.builder(
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return ListTile(
            title: Text(quiz['quiz_title']),
            subtitle: Text("Class: ${quiz['class_name']}"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentQuizPage(
                    quizId: quiz['quiz_id'],
                    assignmentId: quiz['assignment_id'],
                    studentId: widget.studentId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
