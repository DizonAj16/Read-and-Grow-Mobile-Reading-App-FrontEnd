import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/quiz_questions.dart';
import '../teacher pages/quiz_preview_screen.dart';

class ClassContentScreen extends StatelessWidget {
  final String classRoomId;

  const ClassContentScreen({super.key, required this.classRoomId});

  Future<List<Map<String, dynamic>>> _fetchLessons() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('assignments')
        .select('''
        id,
        task_id,
        tasks (
          id,
          title,
          description,
          quizzes (
            id,
            title,
            quiz_questions (
              id,
              question_text,
              question_type,
              sort_order,
              time_limit_seconds,
              question_options (
                id,
                option_text,
                is_correct
              ),
              matching_pairs!matching_pairs_question_id_fkey (
                id,
                left_item,
                right_item_url
              )
            )
          )
        )
      ''')
        .eq('class_room_id', classRoomId);

    if (response.isEmpty) return [];

    // Transform into lesson list
    return response.map((assignment) {
      final task = assignment['tasks'];
      return {
        "id": task['id'],
        "title": task['title'],
        "description": task['description'],
        "quizzes": task['quizzes'] ?? [],
      };
    }).toList();
  }

  Future<List<QuizQuestion>> _fetchQuizQuestions(String quizId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('quiz_questions')
        .select('''
      id,
      question_text,
      question_type,
      sort_order,
      question_options (
        id,
        option_text,
        is_correct
      ),
      matching_pairs!matching_pairs_question_id_fkey (
        id,
        left_item,
        right_item_url
      )
    ''')
        .eq('quiz_id', quizId)
        .order('sort_order', ascending: true);

    return response.map<QuizQuestion>((q) {
      final type = q['question_type'] as String;

      // ✅ Matching pairs from dedicated table
      if (type == 'matching') {
        final pairs = (q['matching_pairs'] as List<dynamic>? ?? [])
            .map((pair) => MatchingPair(
          leftItem: pair['left_item'] as String,
          rightItemUrl: pair['right_item_url'] as String?,
          userSelected: '',
        ))
            .toList();

        return QuizQuestion(
          id: q['id'],
          questionText: q['question_text'],
          type: QuestionType.matching,
          matchingPairs: pairs,
        );
      }

      // ✅ True/False
      if (type == 'true_false') {
        return QuizQuestion(
          id: q['id'],
          questionText: q['question_text'],
          type: QuestionType.trueFalse,
          options: ['True', 'False'],
          correctAnswer: (q['question_options'] as List<dynamic>?)
              ?.firstWhere((opt) => opt['is_correct'] == true,
              orElse: () => {'option_text': null})['option_text'] ??
              null,
        );
      }

      // ✅ Fill-in-the-blank
      if (type == 'fill_in_the_blank') {
        return QuizQuestion(
          id: q['id'],
          questionText: q['question_text'],
          type: QuestionType.fillInTheBlank,
          correctAnswer: (q['question_options'] as List<dynamic>?)
              ?.firstWhere((opt) => opt['is_correct'] == true,
              orElse: () => {'option_text': null})['option_text'] ??
              null,
        );
      }

      // ✅ Multiple choice (default)
      return QuizQuestion(
        id: q['id'],
        questionText: q['question_text'],
        type: QuestionType.multipleChoice,
        options: (q['question_options'] as List<dynamic>?)
            ?.map((opt) => opt['option_text'] as String)
            .toList() ??
            [],
        correctAnswer: (q['question_options'] as List<dynamic>?)
            ?.firstWhere((opt) => opt['is_correct'] == true,
            orElse: () => {'option_text': null})['option_text'],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lessons & Quizzes"),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('assignments')
            .stream(primaryKey: ['id'])
            .eq('class_room_id', classRoomId)
            .asyncMap((_) => _fetchLessons()), // refresh lessons each time
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final lessons = snapshot.data ?? [];

          if (lessons.isEmpty) {
            return const Center(
              child: Text("No lessons or quizzes assigned yet."),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _fetchLessons(); // manual refresh on pull-down
            },
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final quizzes =
                (lesson['quizzes'] as List<dynamic>).cast<Map<String, dynamic>>();

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: const Icon(Icons.menu_book, color: Colors.blue),
                    title: Text(
                      lesson['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      lesson['description'] ?? 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    children: [
                      if (quizzes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text("No quizzes for this lesson."),
                        )
                      else
                        ...quizzes.map(
                              (quiz) => ListTile(
                            leading:
                            const Icon(Icons.quiz, color: Colors.green),
                            title: Text(quiz['title']),
                            onTap: () async {
                              final questions =
                              await _fetchQuizQuestions(quiz['id']);

                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizPreviewScreen(
                                      title: quiz['title'],
                                      questions: questions,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
