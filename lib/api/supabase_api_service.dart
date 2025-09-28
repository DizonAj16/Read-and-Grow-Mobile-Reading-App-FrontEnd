import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_questions.dart';
import 'package:mime/mime.dart';


class ApiService {
  static const String supabaseUrl = 'https://zrcynmiiduwrtlcyzvzi.supabase.co/rest/v1';
  static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyY3lubWlpZHV3cnRsY3l6dnppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyNDExMzIsImV4cCI6MjA3MjgxNzEzMn0.NPDpQKXC5h7qiSTPsIIty8qdNn1DnSHptIkagWlmTHM'; // truncated


  static final SupabaseClient supabase = SupabaseClient('https://zrcynmiiduwrtlcyzvzi.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpyY3lubWlpZHV3cnRsY3l6dnppIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzI0MTEzMiwiZXhwIjoyMDcyODE3MTMyfQ.2Bm8PCz6NS4uH4dRRSbcY9Ad7VLmCY7BitWSZjAjaB8');
  static Future<String?> uploadFile(File file) async {
    try {
      // Only the file name, no leading slash
      String fileName =
          'file_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      // Upload to the 'document' bucket
      final response = await supabase.storage.from('document').upload(fileName, file);

      if (response == null) {
        print('❌ Failed to upload file: $fileName');
        return null;
      }

      // Get public URL
      final fileUrl = supabase.storage.from('document').getPublicUrl(fileName);
      print('✅ Uploaded: $fileUrl');
      return fileUrl;
    } catch (e) {
      print('⚠️ Error uploading file: $e');
      return null;
    }
  }


  /// Converts Dart enum to snake_case for Supabase enum
  static String questionTypeToSnakeCase(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillInTheBlank:
        return 'fill_in_the_blank';
      case QuestionType.dragAndDrop:
        return 'drag_and_drop';
      case QuestionType.matching:
        return 'matching';
    }
  }

  // ========================
  // GET LESSONS
  // ========================
  static Future<List<Map<String, dynamic>>?> getLessons() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/tasks?select=*'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      print('Error fetching lessons: ${response.body}');
      return null;
    }
  }

  // ========================
  // GET QUIZZES
  // ========================
  static Future<List<Map<String, dynamic>>?> getQuizzes() async {
    final response = await http.get(
      Uri.parse('$supabaseUrl/quizzes?select=*'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      print('Error fetching quizzes: ${response.body}');
      return null;
    }
  }

  // ========================
  // GET QUIZ QUESTIONS
  // ========================
  static Future<List<QuizQuestion>?> getQuizQuestions(String quizId) async {
    // Use the explicit relationship for matching_pairs
    final response = await http.get(
      Uri.parse(
          '$supabaseUrl/quiz_questions?quiz_id=eq.$quizId&select=*,matching_pairs!fk_question(*)'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode != 200) {
      print('Error fetching questions: ${response.body}');
      return null;
    }

    final List data = jsonDecode(response.body);

    return data.map((q) {
      QuestionType type;
      switch (q['question_type']) {
        case 'multiple_choice':
          type = QuestionType.multipleChoice;
          break;
        case 'true_false':
          type = QuestionType.trueFalse;
          break;
        case 'fill_in_the_blank':
          type = QuestionType.fillInTheBlank;
          break;
        case 'drag_and_drop':
          type = QuestionType.dragAndDrop;
          break;
        case 'matching':
          type = QuestionType.matching;
          break;
        default:
          type = QuestionType.multipleChoice;
      }

      // Options for multiple choice or drag/drop
      List<String>? options;
      if ((type == QuestionType.multipleChoice || type == QuestionType.dragAndDrop) &&
          q['options'] != null) {
        options = List<String>.from(q['options']);
      }

      // Matching pairs
      List<MatchingPair>? matchingPairs;
      if (type == QuestionType.matching && q['matching_pairs'] != null) {
        matchingPairs = (q['matching_pairs'] as List)
            .map((pair) => MatchingPair(
          leftItem: pair['left_item'] ?? '',
          rightItemUrl: pair['right_item_url'] ?? '',
        ))
            .toList();
      }

      return QuizQuestion(
        questionText: q['question_text'] ?? '',
        type: type,
        options: options,
        matchingPairs: matchingPairs,
        correctAnswer: q['correct_answer'],
      );
    }).toList();
  }


  // ========================
  // ADD QUIZ
  // ========================
  static Future<Map<String, dynamic>?> addQuiz({
    required String taskId,
    required String title,
    required List<QuizQuestion> questions,
  }) async {
    try {
      // 1️⃣ Create the quiz
      final quizResponse = await http.post(
        Uri.parse('$supabaseUrl/quizzes'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({'task_id': taskId, 'title': title}),
      );

      print('Quiz response status: ${quizResponse.statusCode}');
      print('Quiz response body: ${quizResponse.body}');

      if (quizResponse.statusCode != 201) {
        print('❌ Error creating quiz: ${quizResponse.statusCode} ${quizResponse.body}');
        return null;
      }

      final quizData = jsonDecode(quizResponse.body);
      final quizId = quizData[0]['id'];
      print('✅ Quiz created with ID: $quizId');

      // 2️⃣ Add questions
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        try {
          final questionResponse = await http.post(
            Uri.parse('$supabaseUrl/quiz_questions'),
            headers: {
              'apikey': supabaseKey,
              'Authorization': 'Bearer $supabaseKey',
              'Content-Type': 'application/json',
              'Prefer': 'return=representation',
            },
            body: jsonEncode({
              'quiz_id': quizId,
              'question_text': q.questionText,
              'question_type': questionTypeToSnakeCase(q.type),
              'sort_order': i,
            }),
          );

          if (questionResponse.statusCode != 201) {
            print('❌ Error adding question ${i + 1}: ${questionResponse.body}');
            continue;
          }

          final questionId = jsonDecode(questionResponse.body)[0]['id'];
          print('✅ Question ${i + 1} added with ID: $questionId');

          // 3️⃣ Add options for multiple choice
          if (q.type == QuestionType.multipleChoice && q.options != null) {
            for (var option in q.options!) {
              await http.post(
                Uri.parse('$supabaseUrl/question_options'),
                headers: {
                  'apikey': supabaseKey,
                  'Authorization': 'Bearer $supabaseKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'question_id': questionId,
                  'option_text': option,
                  'is_correct': option == q.correctAnswer,
                }),
              );
            }
          }

          // 4️⃣ Add matching pairs or drag & drop items
          if ((q.type == QuestionType.dragAndDrop || q.type == QuestionType.matching) &&
              q.matchingPairs != null) {
            for (var pair in q.matchingPairs!) {
              await http.post(
                Uri.parse('$supabaseUrl/matching_pairs'),
                headers: {
                  'apikey': supabaseKey,
                  'Authorization': 'Bearer $supabaseKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'question_id': questionId,
                  'left_item': pair.leftItem,
                  'right_item_url': pair.rightItemUrl,
                }),
              );
            }
          }

          // 5️⃣ Add fill-in-the-blank answers
          if (q.type == QuestionType.fillInTheBlank && q.correctAnswer != null) {
            await http.post(
              Uri.parse('$supabaseUrl/fill_in_the_blank_answers'),
              headers: {
                'apikey': supabaseKey,
                'Authorization': 'Bearer $supabaseKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'question_id': questionId,
                'correct_answer': q.correctAnswer,
              }),
            );
          }
        } catch (e) {
          print('⚠️ Failed to add question ${i + 1}: $e');
        }
      }

      return {'quiz_id': quizId};
    } catch (e) {
      print('❌ Failed to create quiz: $e');
      return null;
    }
  }

  // ========================
  // ADD LESSON
  // ========================
  static Future<Map<String, dynamic>?> addLesson({
    required String readingLevelId,
    required String title,
    String? description,
    int? timeLimitMinutes,
    bool unlocksNextLevel = false,
  }) async {
    final response = await http.post(
      Uri.parse('$supabaseUrl/tasks'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'reading_level_id': readingLevelId,
        'title': title,
        'description': description,
        'time_limit_minutes': timeLimitMinutes,
        'unlocks_next_level': unlocksNextLevel,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)[0];
    } else {
      print('Error adding lesson: ${response.body}');
      return null;
    }
  }
}
