
class StudentProgress {
  final String studentId;
  final String studentName;
  final int readingTime;
  final int miscues;
  final double quizAverage;
  final List<Map<String, dynamic>> quizResults;

  StudentProgress({
    required this.studentId,
    required this.studentName,
    required this.readingTime,
    required this.miscues,
    required this.quizAverage,
    required this.quizResults,
  });
}
