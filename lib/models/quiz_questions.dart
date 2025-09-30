// lib/models/quiz_questions.dart
import 'dart:convert';
import 'dart:io';

enum QuestionType { multipleChoice, fillInTheBlank, dragAndDrop, matching, trueFalse }

class QuizQuestion {
  final String? id;
  String questionText;
  QuestionType type;
  List<String>? options;         // MCQ or drag order
  String? correctAnswer;         // single correct answer (MCQ / fill-in / order encoded)
  List<MatchingPair>? matchingPairs; // for matching type
  String userAnswer;             // student's typed / selected answer

  QuizQuestion({
     this.id,
    required this.questionText,
    required this.type,
    this.options,
    this.correctAnswer,
    this.matchingPairs,
    String? userAnswer,
  }) : userAnswer = userAnswer ?? '';

  /// Flexible parser from a Map (works with Supabase rows or JSON)
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final questionText = (map['question_text'] ?? map['questionText'] ?? map['text'] ?? '').toString();
    final typeStr = (map['question_type'] ?? map['type'] ?? '').toString();

    QuestionType type;
    switch (typeStr) {
      case 'multiple_choice':
      case 'multipleChoice':
      case 'MCQ':
        type = QuestionType.multipleChoice;
        break;
      case 'fill_in_the_blank':
      case 'fillInTheBlank':
        type = QuestionType.fillInTheBlank;
        break;
      case 'drag_and_drop':
      case 'dragAndDrop':
        type = QuestionType.dragAndDrop;
        break;
      case 'matching':
        type = QuestionType.matching;
        break;
      case 'true_false':
      case 'trueFalse':
        type = QuestionType.trueFalse;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    // Options: could be stored as List or JSON string or as question_options with option_text
    List<String>? options;
    final rawOptions = map['options'] ?? map['question_options'];
    if (rawOptions != null) {
      if (rawOptions is String) {
        try {
          final decoded = jsonDecode(rawOptions);
          if (decoded is List) options = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          options = [rawOptions];
        }
      } else if (rawOptions is List) {
        // If it's a list of maps (question_options), extract text
        options = rawOptions.map<String>((o) {
          if (o is Map && (o['option_text'] ?? o['text'] ?? o['label']) != null) {
            return (o['option_text'] ?? o['text'] ?? o['label']).toString();
          }
          return o.toString();
        }).toList();
      }
    }

    // correctAnswer (flexible names)
    String? correctAnswer = map['correct_answer']?.toString() ?? map['answer']?.toString() ?? map['correct']?.toString();

    // Matching pairs (flexible keys)
    List<MatchingPair>? matchingPairs;
    final rawPairs = map['matching_pairs'] ?? map['matchingPairs'] ?? map['pairs'] ?? map['matching'];
    if (rawPairs != null && rawPairs is List) {
      matchingPairs = rawPairs.map<MatchingPair>((p) {
        if (p is Map<String, dynamic>) return MatchingPair.fromMap(p);
        // if it's a simple structure, attempt parsing
        return MatchingPair(leftItem: p.toString());
      }).toList();
    }

    final userAnswer = map['userAnswer']?.toString();

    return QuizQuestion(
      id: id,
      questionText: questionText,
      type: type,
      options: options,
      correctAnswer: correctAnswer,
      matchingPairs: matchingPairs,
      userAnswer: userAnswer,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'question_text': questionText,
    'question_type': type.toString(),
    'options': options,
    'correct_answer': correctAnswer,
    'matching_pairs': matchingPairs?.map((p) => p.toMap()).toList(),
    'userAnswer': userAnswer,
  };
}

class MatchingPair {
  String leftItem;       // text to drag
  File? rightItemFile;   // optional local file (not used when loaded from DB)
  String? rightItemUrl;  // URL of image/asset
  String userSelected;   // track student's selection (non-null)
  String? correctAnswer; // expected match text (so we can validate)

  MatchingPair({
    required this.leftItem,
    this.rightItemFile,
    this.rightItemUrl,
    String? userSelected,
    this.correctAnswer,
  }) : userSelected = userSelected ?? '';

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      leftItem: (map['leftItem'] ?? map['left'] ?? map['text'] ?? map['label'] ?? '').toString(),
      rightItemUrl: (map['rightItemUrl'] ?? map['right'] ?? map['imageUrl'] ?? map['url'])?.toString(),
      userSelected: map['userSelected']?.toString() ?? '',
      correctAnswer: map['correct_answer']?.toString() ??
          map['correctAnswer']?.toString() ??
          map['answer']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'leftItem': leftItem,
    'rightItemUrl': rightItemUrl,
    'userSelected': userSelected,
    'correct_answer': correctAnswer,
  };
}
