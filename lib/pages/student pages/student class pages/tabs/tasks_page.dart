import 'package:deped_reading_app_laravel/constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../api/classroom_service.dart';
import '../../student_quiz_pages.dart';

// ✅ StudentTasksPage (StatelessWidget)
class StudentTasksPage extends StatelessWidget {
  final String classId;

  const StudentTasksPage({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Add refresh functionality here if needed
              },
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 140,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimaryColor, // main primary color
              Color(0xFFB71C1C), // darker shade for depth
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          "Class Tasks",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ⚠️ You need to define this (placeholder for now)
  Widget _buildContent(BuildContext context) {
    return const Center(
      child: Text("Task content goes here"),
    );
  }
}

// ✅ StudentQuizzesPage (StatefulWidget)
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
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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


class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 20);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    var secondControlPoint = Offset(
      size.width - (size.width / 4),
      size.height - 60,
    );
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
