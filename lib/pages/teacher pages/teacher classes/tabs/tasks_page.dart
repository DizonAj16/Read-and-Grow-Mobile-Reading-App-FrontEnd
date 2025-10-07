import 'package:deped_reading_app_laravel/api/task_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class TasksPage extends StatefulWidget {
  final String classId;

  const TasksPage({super.key, required this.classId});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskService.fetchTasksForClass(widget.classId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Class Tasks")),
      body: FutureBuilder(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/animation/empty_box.json', width: 200),
                  const SizedBox(height: 24),
                  const Text("No Tasks Found"),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final item = tasks[index];
              final taskTitle = item['tasks']?['title'] ?? 'Untitled Task';
              final quizTitle = item['quizzes']?['title'];
              final dueDate = item['due_date'];

              return ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(quizTitle ?? taskTitle),
                subtitle: Text(
                  dueDate != null
                      ? "Due: ${DateTime.parse(dueDate).toLocal().toString().split(' ')[0]}"
                      : "No due date",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
