import 'package:flutter/material.dart';

import '../../api/student_progress_service.dart';
import '../../models/student_progress.dart';

class StudentProgressPage extends StatelessWidget {
  final String classId;
  const StudentProgressPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Student Progress"),
      ),
      body: FutureBuilder(
        future: StudentProgressService().getClassProgress(classId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!;
          if (students.isEmpty) {
            return const Center(child: Text("No student progress found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(student.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📖 Reading Time: ${student.readingTime} mins"),
                      Text("❌ Miscues: ${student.miscues}"),
                      Text("📝 Quiz Avg: ${student.quizAverage.toStringAsFixed(1)}%"),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailPage(student: student),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class StudentDetailPage extends StatelessWidget {
  final StudentProgress student;
  const StudentDetailPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(student.studentName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Reading Time: ${student.readingTime} mins",
                style: Theme.of(context).textTheme.titleMedium),
            Text("Miscues: ${student.miscues}",
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Text("Quiz Results", style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: student.quizResults.length,
                itemBuilder: (context, index) {
                  final quiz = student.quizResults[index];
                  return ListTile(
                    title: Text(quiz['quizzes']['title']),
                    subtitle: Text("Score: ${quiz['score']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // TODO: edit quiz score
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // TODO: delete quiz record
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
