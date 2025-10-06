
class StudentProgress {
  final String studentId;
  final String studentName;
  final int readingTime; // mapped to total score
  final int miscues; // mapped to wrong answers
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
