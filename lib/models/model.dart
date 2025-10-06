import 'package:deped_reading_app_laravel/models/student_model.dart';

class Parent {
  final String id;
  final String name;
  final List<Student> children;

  Parent({
    required this.id,
    required this.name,
    required this.children,
  });
}

class StudentProgress {
  final String studentId;
  final String studentName;
  final String readingLevel;
  final double averageScore;
  final List<QuizSubmission> quizSubmissions;

  StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.readingLevel,
    required this.averageScore,
    required this.quizSubmissions,
  });
}

class QuizSubmission {
  final String quizTitle;
  final double score;
  final DateTime submittedAt;

  QuizSubmission({
    required this.quizTitle,
    required this.score,
    required this.submittedAt,
  });
}
