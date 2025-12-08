import 'dart:convert';

import 'package:deped_reading_app_laravel/models/quiz_questions.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  /// Fetch all quizzes for a given class
  static Future<List<Map<String, dynamic>>> fetchTasksForClass(
    String classId,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('quizzes')
          .select(
            'id, title, task_id, class_room_id, tasks(id, title, created_at)',
          )
          .eq('class_room_id', classId);

      final list = List<Map<String, dynamic>>.from(response);

      // Sort by tasks.created_at descending
      list.sort((a, b) {
        final aDate = a['tasks']?['created_at'] != null
            ? DateTime.parse(a['tasks']['created_at'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b['tasks']?['created_at'] != null
            ? DateTime.parse(b['tasks']['created_at'])
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return list;
    } catch (e) {
      debugPrint("❌ Error fetching assignments: $e");
      return [];
    }
  }

  /// Fetch quiz info along with questions, options, and correct answers
/// Fetch quiz info along with questions, options, and correct answers
static Future<Map<String, dynamic>?> fetchQuizWithQuestions(
  String quizId,
) async {
  try {
    final supabase = Supabase.instance.client;

    debugPrint("\n\n================= FETCHING QUIZ =================");
    debugPrint("📌 Quiz ID: $quizId");
    debugPrint("=================================================\n");

    // 1️⃣ Fetch quiz info
    final quiz = await supabase
        .from('quizzes')
        .select('id, title, task_id')
        .eq('id', quizId)
        .maybeSingle();

    debugPrint("📘 Raw Quiz Info: $quiz");

    if (quiz == null) {
      debugPrint("❌ Quiz not found in the database.");
      return null;
    }

    // 2️⃣ Fetch questions with all relationships INCLUDING NEW IMAGE FIELDS
    // REMOVE ALL COMMENTS FROM THE QUERY STRING!
    final questions = await supabase
        .from('quiz_questions')
        .select('''
          id,
          question_text,
          question_type,
          sort_order,
          time_limit_seconds,
          question_image_url,
          option_images,
          question_options(*),
          matching_pairs(*)
        ''')
        .eq('quiz_id', quizId)
        .order('sort_order', ascending: true);

    debugPrint("📥 Raw Questions Fetched: ${questions.length}\n");

    final quizQuestions = <QuizQuestion>[];

    int i = 1;
    for (final q in questions) {
      debugPrint("\n-----------------------------------------------");
      debugPrint("🔍 QUESTION $i RAW DB DATA:");
      debugPrint("ID: ${q['id']}");
      debugPrint("Text: ${q['question_text']}");
      debugPrint("Type: ${q['question_type']}");
      debugPrint("Question Image URL: ${q['question_image_url']}");
      debugPrint("Option Images JSON: ${q['option_images']}");
      debugPrint("Option Images Type: ${q['option_images']?.runtimeType}");
      
      // Parse option_images from JSONB column
      Map<String, String>? parsedOptionImages;
      if (q['option_images'] != null) {
        try {
          // Check if option_images is already a Map
          if (q['option_images'] is Map) {
            final optionImagesMap = q['option_images'] as Map;
            parsedOptionImages = {};
            optionImagesMap.forEach((key, value) {
              if (value != null && value.toString().isNotEmpty) {
                parsedOptionImages![key.toString()] = value.toString();
              }
            });
            debugPrint("Parsed option images from Map: $parsedOptionImages");
          } 
          // Check if option_images is a String (JSON string)
          else if (q['option_images'] is String) {
            final jsonString = q['option_images'] as String;
            if (jsonString.isNotEmpty && jsonString != '{}') {
              final decoded = json.decode(jsonString) as Map<String, dynamic>;
              parsedOptionImages = {};
              decoded.forEach((key, value) {
                if (value != null && value.toString().isNotEmpty) {
                  parsedOptionImages![key] = value.toString();
                }
              });
              debugPrint("Parsed option images from JSON string: $parsedOptionImages");
            }
          }
        } catch (e) {
          debugPrint("❌ Error parsing option_images: $e");
        }
      }

      // Use QuizQuestion.fromMap for safe parsing
      final question = QuizQuestion.fromMap({
        'id': q['id'],
        'question_text': q['question_text'],
        'question_type': q['question_type'],
        'question_options': q['question_options'] ?? [],
        'matching_pairs': q['matching_pairs'] ?? [],
        'time_limit_seconds': q['time_limit_seconds'],
        'question_image_url': q['question_image_url'],
        'option_images': parsedOptionImages, // Pass the parsed option images
      });

      // Debug log
      question.debugQuestionDataDetailed();

      quizQuestions.add(question);
      i++;
    }

    debugPrint("\n================= SUMMARY =================");
    debugPrint("🟢 Quiz Title: ${quiz['title']}");
    debugPrint("🟢 Total Questions Built: ${quizQuestions.length}");
    
    // Count question types
    final typeCounts = <String, int>{};
    for (final q in quizQuestions) {
      final typeName = q.type.name;
      typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
    }
    
    debugPrint("🟢 Question Types Breakdown:");
    typeCounts.forEach((type, count) {
      debugPrint("  • $type: $count");
    });
    
    // Check for images
    int questionsWithImages = 0;
    int optionsWithImages = 0;
    
    for (final q in quizQuestions) {
      if (q.questionImageUrl != null && q.questionImageUrl!.isNotEmpty) {
        questionsWithImages++;
      }
      if (q.optionImages != null && q.optionImages!.isNotEmpty) {
        optionsWithImages++;
      }
    }
    
    debugPrint("🟢 Questions with question images: $questionsWithImages");
    debugPrint("🟢 Questions with option images: $optionsWithImages");
    debugPrint("===========================================\n");

    return {'quiz': quiz, 'questions': quizQuestions};
  } catch (e, st) {
    debugPrint('❌ ERROR FETCHING QUIZ: $e');
    debugPrint(st.toString());
    return null;
  }
}
}