import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service to handle quiz score submissions to the backend.
class QuizScoreService {
  final String baseUrl;
  final String? authToken; // Optional bearer token

  QuizScoreService({required this.baseUrl, this.authToken});

  /// Submit a score to the backend.
  ///
  /// [quizType] is a string ID like "match_words", "fill_in_blanks"
  /// [studentId] is the unique ID of the student (usually numeric).
  /// [score] is a value from 0 to 100.
  /// [timeLeft] and [wrongAnswers] are optional.
  Future<bool> submitScore({
    required String quizType,
    required int studentId,
    required int score,
    int? timeLeft,
    int? wrongAnswers,
  }) async {
    final uri = Uri.parse('$baseUrl/api/submit-score');

    final headers = {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

    final body = {
      'quiz_type': quizType,
      'student_id': studentId,
      'score': score,
      if (timeLeft != null) 'time_left': timeLeft,
      if (wrongAnswers != null) 'wrong_answers': wrongAnswers,
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Score submitted successfully!');
        return true;
      } else {
        print('❌ Submission failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('🚨 Exception during score submission: $e');
      return false;
    }
  }
}
